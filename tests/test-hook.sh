#!/usr/bin/env bash
# ============================================================
# 测试套件 — pre-tool-use.sh 危险命令拦截钩子
# ============================================================
# 测试方法：模拟 Claude Code 的 hook 调用，验证拦截和放行逻辑。
# 不依赖外部 Python（用 echo + pipe 模拟 JSON stdin）
# ============================================================

set -euo pipefail

HOOK_SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/pre-tool-use.sh"
PASS=0
FAIL=0
TOTAL=0

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- 辅助函数 ---
# 模拟 hook 调用：传入 tool_name 和 command，检查退出码
# 参数: $1 = 期望结果 (allow|block), $2 = 测试名, $3 = tool_name, $4 = command
test_hook() {
    local expected="$1"
    local name="$2"
    local tool_name="$3"
    local command="$4"

    TOTAL=$((TOTAL + 1))

    # 构建 JSON stdin
    local json
    json="{\"tool_name\":\"${tool_name}\",\"args\":{\"command\":\"${command}\"}}"

    # 模拟调用
    local exit_code=0
    echo "$json" | bash "$HOOK_SCRIPT" 2>/dev/null || exit_code=$?

    local expected_code=0
    [ "$expected" = "block" ] && expected_code=1

    if [ "$exit_code" -eq "$expected_code" ]; then
        echo -e "${GREEN}✓${NC} $name"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}✗${NC} $name (expected exit $expected_code, got $exit_code)"
        echo "  command: $command"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "========================================"
echo "  pre-tool-use.sh 测试套件"
echo "========================================"
echo ""

# ===== 测试：应该阻止的危险命令 =====
echo "--- 文件系统操作 ---"
test_hook "block" "rm -rf /"                    "Bash" "rm -rf /"
test_hook "block" "rm -rf /etc"                 "Bash" "rm -rf /etc"
test_hook "block" "rm -rf /home/*"              "Bash" "rm -rf /home/*"
test_hook "block" "rm -rf ~"                    "Bash" "rm -rf ~"
test_hook "block" "rm -rf /tmp/blah"            "Bash" "rm -rf /tmp/blah"

echo ""
echo "--- Git 强制推送 ---"
test_hook "block" "git push --force"            "Bash" "git push --force origin main"
test_hook "block" "git push --force-with-lease" "Bash" "git push --force-with-lease origin main"
test_hook "block" "git push -f"                 "Bash" "git push -f origin main"

echo ""
echo "--- SQL 破坏性操作 ---"
test_hook "block" "DROP TABLE"                  "Bash" "DROP TABLE users;"
test_hook "block" "TRUNCATE TABLE"              "Bash" "TRUNCATE TABLE users;"
test_hook "block" "DELETE FROM without WHERE"   "Bash" "DELETE FROM users;"
test_hook "block" "DROP DATABASE"               "Bash" "DROP DATABASE production;"

echo ""
echo "--- 系统危险操作 ---"
test_hook "block" "chmod -R 777 /"              "Bash" "chmod -R 777 /"
test_hook "block" "chown -R root:"              "Bash" "chown -R root: /home/user"
test_hook "block" "dd to block device"          "Bash" "dd if=/dev/zero of=/dev/sda bs=512 count=1"
test_hook "block" "mkfs.ext4"                   "Bash" "mkfs.ext4 /dev/sdb1"
test_hook "block" "shutdown -h now"             "Bash" "shutdown -h now"
test_hook "block" "reboot"                      "Bash" "reboot"
test_hook "block" "poweroff"                    "Bash" "poweroff"

# ===== 测试：应该放行的安全命令 =====
echo ""
echo "--- 安全操作（应放行）---"
test_hook "allow" "ls 命令"                     "Bash" "ls -la"
test_hook "allow" "git status"                  "Bash" "git status"
test_hook "allow" "git push (no force)"         "Bash" "git push origin main"
test_hook "allow" "npm install"                 "Bash" "npm install"
test_hook "allow" "curl GET request"            "Bash" "curl https://api.example.com"
test_hook "allow" "rm single file"              "Bash" "rm file.txt"
test_hook "allow" "rm empty dir"                "Bash" "rm -d dir"
test_hook "allow" "非 Bash 工具"                "Read" "cat /etc/passwd"
test_hook "allow" "空命令"                      "Bash" ""

echo ""
echo "========================================"
echo "  结果: ${PASS}/${TOTAL} 通过, ${FAIL} 失败"
echo "========================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
