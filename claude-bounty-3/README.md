# Pre-Tool-Use Hook — Destructive Bash Command Blocker

Claude Code hook that intercepts dangerous bash commands before execution.

## What it blocks

| Pattern | Why |
|---------|-----|
| `rm -rf` / `rm -fr` | Recursive force remove — permanent data loss |
| `DROP TABLE` / `DROP DATABASE` | Database destruction |
| `TRUNCATE` | Wipes table contents without WHERE |
| `DELETE FROM` without WHERE | Deletes everything in the table |
| `git push --force` / `-f` / `+refspec` | Rewrites remote history |

## Install (2 commands)

```bash
mkdir -p ~/.claude/hooks
curl -sSL https://raw.githubusercontent.com/soongyintong/claude-builders-bounty/main/claude-bounty-3/pre-tool-use -o ~/.claude/hooks/pre-tool-use && chmod +x ~/.claude/hooks/pre-tool-use
```

Then add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/pre-tool-use"
          }
        ]
      }
    ]
  }
}
```

## How it works

1. Claude Code sends JSON via stdin before every Bash command
2. Hook checks the command against danger patterns
3. Safe commands pass through silently
4. Dangerous commands get blocked with a clear reason + logged to `~/.claude/hooks/blocked.log`

## Blocked attempt log format

```json
{
  "timestamp": "2026-05-25T02:30:00Z",
  "command": "rm -rf /important/data",
  "project_path": "/Users/dev/my-project",
  "reason": "rm -rf (recursive force remove)"
}
```

## Test

```bash
# Test blocked commands
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/test"}}' | python3 ~/.claude/hooks/pre-tool-use

# Test safe commands
echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | python3 ~/.claude/hooks/pre-tool-use
```
