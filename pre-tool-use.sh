#!/usr/bin/env bash
# ============================================================
# Claude Code Pre-Tool-Use Hook — Destructive Command Blocker
# ============================================================
# 安装在 ~/.claude/hooks/pre-tool-use.sh
# 在 Claude Code 每次执行工具前自动触发。
# 从 stdin 读取 JSON 工具调用，拦截危险 bash 命令。
# ============================================================
# Claude Code hooks 协议：
# - stdin 接收一个 JSON 对象：{ "tool_name": "...", "args": { "command": "..." } }
# - 退出码 0 = 允许继续；退出码 1 = 阻止调用
# - stderr 输出会显示给 Claude
# ============================================================

set -euo pipefail

# --- 路径 ---
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOCKED_LOG="$HOOK_DIR/blocked.log"

# --- 从 stdin 读取 JSON ---
INPUT="$(cat)"

# --- 提取工具名称和命令 ---
TOOL_NAME="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")"
BASH_CMD="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); a=d.get('args',{}); print(a.get('command',''))" 2>/dev/null || echo "")"

# --- 只拦截 Bash 工具 ---
if [ "$TOOL_NAME" != "Bash" ]; then
    exit 0
fi

# --- 空命令直接放行 ---
if [ -z "$BASH_CMD" ]; then
    exit 0
fi

# --- 危险模式定义（正则）---
# 格式: 显示名称:正则表达式
# 注意：正则与整个命令字符串匹配，不支持单词边界或零宽断言
DANGEROUS_PATTERNS=(
    # ===== 文件系统毁灭性操作 =====
    # rm -rf 配合系统根目录或家目录
    "rm-rf-root:rm[[:space:]]+-[rR][fF][[:space:]]+/[[:space:]]*$"
    "rm-rf-root2:rm[[:space:]]+-[rR][fF][[:space:]]+/([[:space:]]|$)"
    "rm-rf-slash:rm[[:space:]]+-[rR][fF][[:space:]]+/[a-z]+"
    "rm-rf-home:rm[[:space:]]+-[rR][fF][[:space:]]+~"

    # ===== Git 强制推送 =====
    "git-force-push:git[[:space:]]+push[[:space:]]+.*(--force|--force-with-lease)"
    "git-push-f:git[[:space:]]+push[[:space:]]+-[fF]"

    # ===== SQL DDL 破坏性操作 =====
    "drop-table:[Dd][Rr][Oo][Pp][[:space:]]+[Tt][Aa][Bb][Ll][Ee]"
    "truncate-table:[Tt][Rr][Uu][Nn][Cc][Aa][Tt][Ee][[:space:]]+[Tt][Aa][Bb][Ll][Ee]"
    "delete-no-where:[Dd][Ee][Ll][Ee][Tt][Ee][[:space:]]+[Ff][Rr][Oo][Mm][[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*;$"
    "drop-database:[Dd][Rr][Oo][Pp][[:space:]]+[Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee]"

    # ===== 系统危险操作 =====
    "chmod-777-recursive:chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+"
    "chown-root:chown[[:space:]]+(-R[[:space:]]+)?root:"
    "dd-to-device:dd[[:space:]]+.*of=/dev/(sda|sdb|nvme|mmcblk|xvd)"
    "mkfs-format:mkfs"
    "shutdown-now:shutdown[[:space:]]+(-h|-r|now)"
    "reboot-command:reboot"
    "poweroff-command:poweroff"
)

# --- 大小写不敏感匹配 ---
shopt -s nocasematch

matched_name=""
matched_pattern=""

for rule in "${DANGEROUS_PATTERNS[@]}"; do
    rule_name="${rule%%:*}"
    rule_pattern="${rule#*:}"

    if [[ "$BASH_CMD" =~ $rule_pattern ]]; then
        matched_name="$rule_name"
        matched_pattern="$rule_pattern"
        break
    fi
done

# --- 如果匹配到危险命令 ---
if [ -n "$matched_name" ]; then
    TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
    PROJECT_PATH="${PWD:-unknown}"

    # 记录日志
    mkdir -p "$(dirname "$BLOCKED_LOG")"
    echo "[$TIMESTAMP] BLOCKED: ${matched_name} | cmd: ${BASH_CMD} | pwd: ${PROJECT_PATH}" >> "$BLOCKED_LOG"

    # 输出阻止消息到 stderr（Claude 可以看到）
    >&2 echo ""
    >&2 echo "╔══════════════════════════════════════════════════════════╗"
    >&2 echo "║  🛑 COMMAND BLOCKED BY SAFETY HOOK                      ║"
    >&2 echo "╠══════════════════════════════════════════════════════════╣"
    >&2 echo "║  Reason:  Potential destructive operation detected      ║"
    >&2 echo "║  Pattern: ${matched_name}"
    >&2 echo "║  Command: ${BASH_CMD}"
    >&2 echo "║  Project: ${PROJECT_PATH}"
    >&2 echo "║                                                          ║"
    >&2 echo "║  What happened?                                         ║"
    >&2 echo "║  Claude tried to run a command matching destructive     ║"
    >&2 echo "║  pattern '${matched_name}'. This has been blocked.  "
    >&2 echo "║                                                          ║"
    >&2 echo "║  All blocked attempts logged at:                       ║"
    >&2 echo "║  ${BLOCKED_LOG}"
    >&2 echo "║                                                          ║"
    >&2 echo "║  To disable: rm ~/.claude/hooks/pre-tool-use.sh         ║"
    >&2 echo "╚══════════════════════════════════════════════════════════╝"
    >&2 echo ""

    exit 1
fi

exit 0
