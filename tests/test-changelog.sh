#!/usr/bin/env bash
#
# changelog.sh 测试脚本
# 用法: bash tests/test-changelog.sh
#

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$SCRIPT_DIR/changelog.sh"
TMPDIR=$(mktemp -d)

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

red()   { printf "\033[0;31m%s\033[0m\n" "$1"; }
green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
cyan()  { printf "\033[0;36m%s\033[0m\n" "$1"; }

pass() {
  printf "  ✅ "
  green "PASS  $1"
  ((PASS++))
}

fail() {
  printf "  ❌ "
  red "FAIL  $1"
  ((FAIL++))
}

assert_contains() {
  local label="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -qF "$expected"; then
    pass "$label"
  else
    fail "$label (期望包含: '$expected')"
    echo "    实际输出: $(echo "$actual" | head -3 | tr '\n' ' ')"
  fi
}

SEP="═══════════════════════════════════════"

# ─── 测试 1: 脚本语法检查 ──────────────────────
cyan "$SEP"
cyan "  测试 1: 语法检查"
cyan "$SEP"
if bash -n "$SCRIPT"; then
  pass "bash -n 语法检查通过"
else
  fail "bash -n 语法检查失败"
fi

# ─── 测试 2: --help 输出 ──────────────────────
cyan "$SEP"
cyan "  测试 2: --help 输出"
cyan "$SEP"
HELP_OUTPUT=$(bash "$SCRIPT" --help 2>&1 || true)
assert_contains "显示用法" "用法" "$HELP_OUTPUT"
assert_contains "示例说明" "示例" "$HELP_OUTPUT"

# ─── 测试 3: -h 也输出 help ───────────────────
cyan "$SEP"
cyan "  测试 3: -h 输出"
cyan "$SEP"
H_OUTPUT=$(bash "$SCRIPT" -h 2>&1 || true)
assert_contains "-h 显示用法" "用法" "$H_OUTPUT"

# ─── 测试 4: 在模拟 git 仓库中运行 ────────────
cyan "$SEP"
cyan "  测试 4: 在模拟仓库中运行"
cyan "$SEP"

cd "$TMPDIR"
git init -q
git config user.email "test@test.com"
git config user.name "Test"

echo "init" > README.md
git add README.md
git commit -q -m "chore: initial commit"
git tag v1.0.0

echo "feat" > feat.txt
git add feat.txt
git commit -q -m "feat: add user authentication"

echo "fix" > fix.txt
git add fix.txt
git commit -q -m "fix: resolve login redirect bug"

echo "remove" > remove.txt
git add remove.txt
git commit -q -m "remove: drop deprecated API endpoint"

echo "refactor" > refactor.txt
git add refactor.txt
git commit -q -m "refactor: extract payment module"

echo "add" > add.txt
git add add.txt
git commit -q -m "add rate limiting support"

echo "update" > update.txt
git add update.txt
git commit -q -m "update dependencies to latest"

REPO_OUTPUT=$(bash "$SCRIPT" 2>/dev/null || true)

assert_contains "输出包含 Changelog 标题" "# Changelog" "$REPO_OUTPUT"
assert_contains "输出包含 Added 分类" "🚀 Added" "$REPO_OUTPUT"
assert_contains "输出包含 Fixed 分类" "🐛 Fixed" "$REPO_OUTPUT"
assert_contains "输出包含 Changed 分类" "🔄 Changed" "$REPO_OUTPUT"
assert_contains "输出包含 Removed 分类" "🗑️  Removed" "$REPO_OUTPUT"
assert_contains "包含 feat: add user authentication" "feat: add user authentication" "$REPO_OUTPUT"
assert_contains "包含 fix: resolve login redirect bug" "fix: resolve login redirect bug" "$REPO_OUTPUT"
assert_contains "包含 remove: drop deprecated API" "remove: drop deprecated API" "$REPO_OUTPUT"
assert_contains "包含 refactor: extract payment module" "refactor: extract payment module" "$REPO_OUTPUT"
assert_contains "包含 add rate limiting" "add rate limiting" "$REPO_OUTPUT"
assert_contains "包含 update dependencies" "update dependencies" "$REPO_OUTPUT"

# ─── 测试 5: 指定 tag 范围 ─────────────────────
cyan "$SEP"
cyan "  测试 5: 指定 tag 范围"
cyan "$SEP"

cd "$TMPDIR"
echo "hotfix" > hotfix.txt
git add hotfix.txt
git commit -q -m "hotfix: patch critical security issue"
git tag v1.1.0

RANGE_OUTPUT=$(bash "$SCRIPT" v1.0.0 v1.1.0 2>/dev/null || true)
assert_contains "指定范围包含 hotfix" "hotfix: patch critical security" "$RANGE_OUTPUT"

# ─── 测试 6: 无 tag 的情况 ─────────────────────
cyan "$SEP"
cyan "  测试 6: 无 tag 仓库"
cyan "$SEP"

NOTAG_DIR=$(mktemp -d)
cd "$NOTAG_DIR"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "file" > f.txt
git add f.txt
git commit -q -m "first commit"
echo "more" >> f.txt
git add f.txt
git commit -q -m "feat: add content"
echo "even more" >> f.txt
git add f.txt
git commit -q -m "fix: correct typo"

NOTAG_OUTPUT=$(bash "$SCRIPT" 2>/dev/null || true)
assert_contains "无 tag 也能工作" "# Changelog" "$NOTAG_OUTPUT"

rm -rf "$NOTAG_DIR"

# ─── 总结 ──────────────────────────────────────
echo ""
cyan "$SEP"
printf "  通过: "
green "$PASS"
printf "  |  失败: "
red "$FAIL"
printf "  |  总计: %d\n" "$((PASS + FAIL))"
cyan "$SEP"

[ "$FAIL" -eq 0 ]
