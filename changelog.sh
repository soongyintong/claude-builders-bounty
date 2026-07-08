#!/usr/bin/env bash
#
# changelog.sh — 从 git history 自动生成结构化 CHANGELOG.md
#
# 用法:
#   bash changelog.sh              # 从上次 tag 到 HEAD
#   bash changelog.sh v1.0.0       # 从指定 tag 到 HEAD
#   bash changelog.sh v1.0.0 v2.0  # 两个 tag 之间
#
# 分类规则:
#   Added     → feat:, feature:, add:, new:
#   Fixed     → fix:, bugfix:, hotfix:, patch:, resolve:
#   Changed   → refactor:, chore:, update:, upgrade:, deprecate:, bump:, migrate:
#   Removed   → remove:, drop:, delete:, deprecate:
#   默认      → Changed (fallback)
#

set -eo pipefail

# ─── 颜色 ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── 用法 ──────────────────────────────────────
usage() {
  echo "用法: bash changelog.sh [<from> [<to>]]"
  echo ""
  echo "  不传参      — 从上次 git tag 到 HEAD"
  echo "  <from>      — 从指定 tag/revision 到 HEAD"
  echo "  <from> <to> — 两个 tag/revision 之间"
  echo ""
  echo "示例:"
  echo "  bash changelog.sh"
  echo "  bash changelog.sh v1.0.0"
  echo "  bash changelog.sh v1.0.0 v2.0.0"
  exit 0
}

# ─── 提交分类函数 ──────────────────────────────
# 根据 commit message 首行分类
classify() {
  local msg="$1"
  local msg_lower
  msg_lower=$(echo "$msg" | tr '[:upper:]' '[:lower:]')

  # 匹配 Added
  if echo "$msg_lower" | grep -qE '^(feat|feature|add|new)\b'; then
    echo "Added"
  # 匹配 Fixed
  elif echo "$msg_lower" | grep -qE '^(fix|bugfix|hotfix|patch|resolve)\b'; then
    echo "Fixed"
  # 匹配 Removed
  elif echo "$msg_lower" | grep -qE '^(remove|drop|delete|deprecate)\b' && \
       ! echo "$msg_lower" | grep -qE '^(deprecate.*bump|deprecate.*update)'; then
    echo "Removed"
  # 匹配 Changed（常见变更关键词）
  elif echo "$msg_lower" | grep -qE '^(refactor|chore|update|upgrade|bump|migrate|change|improve|optimize|revert)\b'; then
    echo "Changed"
  # 默认归入 Changed
  else
    echo "Changed"
  fi
}

# ─── 输出 CHANGELOG 区块 ──────────────────────
print_section() {
  local heading="$1"
  shift
  local commits=("$@")

  if [ ${#commits[@]} -eq 0 ]; then
    return
  fi

  echo ""
  echo "### $heading"
  echo ""
  for commit in "${commits[@]}"; do
    echo "$commit"
  done
}

# ─── 生成 CHANGELOG ──────────────────────────
generate() {
  local from="$1"
  local to="$2"

  # 获取 log 范围
  local range="${from}..${to}"

  # 检查范围是否有效
  if ! git rev-parse --quiet --verify "$from" >/dev/null 2>&1; then
    echo -e "${RED}✗ 无效的起始点: $from${NC}" >&2
    exit 1
  fi
  if ! git rev-parse --quiet --verify "$to" >/dev/null 2>&1; then
    echo -e "${RED}✗ 无效的结束点: $to${NC}" >&2
    exit 1
  fi

  # 获取 commit 列表 (hash + subject)
  local raw_commits
  raw_commits=$(git log --oneline --no-decorate "$range" 2>/dev/null || true)

  if [ -z "$raw_commits" ]; then
    echo -e "${YELLOW}⚠️  指定范围内没有 commit${NC}" >&2
    echo "# Changelog"
    echo ""
    echo "_该范围内无变更。_"
    return
  fi

  # 分类储存
  local added=()
  local fixed=()
  local changed=()
  local removed=()

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local hash="${line%% *}"
    local subject="${line#* }"
    local category
    category=$(classify "$subject")
    local formatted="- \`${hash}\` ${subject}"

    case "$category" in
      Added)   added+=("$formatted") ;;
      Fixed)   fixed+=("$formatted") ;;
      Removed) removed+=("$formatted") ;;
      *)       changed+=("$formatted") ;;
    esac
  done <<< "$raw_commits"

  # 输出
  local tag_label="${from} → ${to}"
  local today
  today=$(date +%Y-%m-%d)

  echo "# Changelog"
  echo ""
  echo "## [${tag_label}] - ${today}"
  echo ""

  print_section "🚀 Added" "${added[@]}"
  print_section "🐛 Fixed" "${fixed[@]}"
  print_section "🔄 Changed" "${changed[@]}"
  print_section "🗑️  Removed" "${removed[@]}"

  echo ""
  echo "---"
  echo "_自动生成于 ${today} 由 changelog.sh_"
}

# ─── 主逻辑 ────────────────────────────────────
main() {
  # 处理 help
  for arg in "$@"; do
    if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
      usage
    fi
  done

  # 确定范围
  local from to
  if [ $# -eq 0 ]; then
    # 自动检测上次 tag
    from=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    to="HEAD"
    if [ -z "$from" ]; then
      echo -e "${YELLOW}⚠️  没有找到 git tag，使用第一个 commit 作为起点${NC}" >&2
      from=$(git rev-list --max-parents=0 HEAD 2>/dev/null || echo "")
      if [ -z "$from" ]; then
        echo -e "${RED}✗ 无法确定起始 commit，请手动指定 tag 或 revision${NC}" >&2
        exit 1
      fi
    fi
  elif [ $# -eq 1 ]; then
    from="$1"
    to="HEAD"
  elif [ $# -eq 2 ]; then
    from="$1"
    to="$2"
  else
    usage
  fi

  echo -e "${CYAN}🔍 分析范围: ${from} → ${to}${NC}" >&2
  echo -e "${CYAN}📊 正在分类 commits...${NC}" >&2

  generate "$from" "$to"
}

# 如果是直接执行而非 source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
