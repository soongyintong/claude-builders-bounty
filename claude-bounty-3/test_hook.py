#!/usr/bin/env python3
"""Tests for destructive bash command blocker hook."""

import json
import os
import subprocess
import sys
import tempfile

HOOK_PATH = os.path.join(os.path.dirname(__file__), "pre-tool-use")


def run_hook(command: str, tool_name: str = "Bash") -> dict:
    """Send a fake Claude Code hook payload to the hook and get the response."""
    payload = json.dumps({
        "tool_name": tool_name,
        "tool_input": {"command": command},
    })
    result = subprocess.run(
        [sys.executable, HOOK_PATH],
        input=payload,
        capture_output=True,
        text=True,
        timeout=5,
    )
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        # hook might output nothing for non-bash tools
        return {}


def test_blocks_rm_rf():
    resp = run_hook("rm -rf /important/data")
    decision = resp.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "deny", f"Expected deny, got {decision}"


def test_blocks_drop_table():
    resp = run_hook("mysql -e 'DROP TABLE users'")
    decision = resp.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "deny", f"Expected deny, got {decision}"


def test_blocks_git_push_force():
    resp = run_hook("git push --force origin main")
    decision = resp.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "deny", f"Expected deny, got {decision}"


def test_blocks_truncate():
    resp = run_hook("echo 'TRUNCATE TABLE logs' | mysql")
    decision = resp.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "deny", f"Expected deny, got {decision}"


def test_blocks_delete_without_where():
    resp = run_hook("DELETE FROM users")
    decision = resp.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "deny", f"Expected deny, got {decision}"


def test_allows_delete_with_where():
    resp = run_hook("DELETE FROM users WHERE id=5")
    decision = resp.get("hookSpecificOutput", {}).get("permissionDecision")
    assert decision == "allow", f"Expected allow, got {decision}"


def test_allows_normal_commands():
    for cmd in [
        "ls -la",
        "echo hello",
        "git status",
        "npm install express",
        "SELECT * FROM users",
        "cat README.md",
    ]:
        resp = run_hook(cmd)
        decision = resp.get("hookSpecificOutput", {}).get("permissionDecision")
        assert decision == "allow", f"Command '{cmd}' should be allowed, got {decision}"


def test_non_bash_tools_pass():
    resp = run_hook("rm -rf /", tool_name="Read")
    decision = resp.get("hookSpecificOutput", {}).get("permissionDecision")
    # non-bash tools should either allow or have no response
    assert decision != "deny", f"Non-bash tool should not be denied"


def test_block_logs():
    """Check that blocked attempts get logged."""
    log_path = os.path.expanduser("~/.claude/hooks/blocked.log")
    # run a block
    run_hook("rm -rf /tmp/logtest")
    assert os.path.exists(log_path), "blocked.log should exist after a blocked attempt"
    with open(log_path) as f:
        lines = f.readlines()
    assert len(lines) > 0, "blocked.log should have entries"
    last = json.loads(lines[-1])
    assert "timestamp" in last
    assert "command" in last
    assert "project_path" in last
    assert "reason" in last


if __name__ == "__main__":
    failed = 0
    passed = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            try:
                fn()
                print(f"✅ {name}")
                passed += 1
            except Exception as e:
                print(f"❌ {name}: {e}")
                failed += 1
    print(f"\n{passed} passed, {failed} failed")
    sys.exit(1 if failed else 0)
