# 🛡️ Claude Code Pre-Tool-Use Hook — Destructive Command Blocker

> A safety hook for Claude Code that intercepts dangerous bash commands before they execute.

## Installation

```bash
# Step 1: Copy the hook into Claude Code hooks directory
cp pre-tool-use.sh ~/.claude/hooks/pre-tool-use.sh

# Step 2: Make it executable
chmod +x ~/.claude/hooks/pre-tool-use.sh
```

That's it. The next time Claude Code runs, it will automatically call this hook before every tool execution.

## What It Blocks

| Category | Patterns Blocked |
|----------|-----------------|
| **File System** | `rm -rf /`, `rm -rf ~`, `rm -rf /etc/*`, forced recursive deletes |
| **Git** | `git push --force`, `git push -f`, `git push --force-with-lease` |
| **SQL** | `DROP TABLE`, `TRUNCATE TABLE`, `DELETE FROM ...;` (no WHERE clause), `DROP DATABASE` |
| **System** | `chmod -R 777 /`, `chown root:`, `dd` to block devices, `mkfs.*`, `shutdown`, `reboot`, `poweroff` |

## How It Works

1. Claude Code invokes the hook with a JSON payload on stdin before every tool call
2. The hook extracts the tool name and command from the JSON
3. If the tool is `Bash` and the command matches a dangerous pattern, execution is blocked
4. The blocked attempt is logged to `~/.claude/hooks/blocked.log`
5. A clear message is displayed explaining why the command was blocked

## Logging

All blocked attempts are saved to `~/.claude/hooks/blocked.log`:

```
[2026-07-06 21:15:00] BLOCKED: git-force-push | cmd: git push --force origin main | pwd: /path/to/project
[2026-07-06 21:16:00] BLOCKED: recursive-force-rm | cmd: rm -rf /tmp/cache | pwd: /path/to/project
```

## Customization

Edit `pre-tool-use.sh` and add your own patterns to the `DANGEROUS_PATTERNS` array:

```bash
DANGEROUS_PATTERNS+=(
    "my-custom-rule:my_dangerous_command_pattern"
)
```

## Testing

Run the provided test suite to verify the hook works correctly:

```bash
bash tests/test-hook.sh
```

## Uninstall

```bash
rm ~/.claude/hooks/pre-tool-use.sh
```

## License

MIT
