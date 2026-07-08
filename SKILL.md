---
name: generate-changelog
description: "Generate a structured CHANGELOG.md from the project's git history"
---

# Generate Changelog

A Claude Code skill that generates a structured `CHANGELOG.md` from git history.

## Usage

In Claude Code, say:

> `/generate-changelog`

Or with a specific tag range:

> `/generate-changelog v1.0.0`
> `/generate-changelog v1.0.0 v2.0.0`

## What it does

1. Fetches all commits from the last git tag (or specified range) to HEAD
2. Auto-categorizes each commit by conventional commit prefix:
   - **Added**: `feat:`, `feature:`, `add:`, `new:`
   - **Fixed**: `fix:`, `bugfix:`, `hotfix:`, `patch:`
   - **Changed**: `refactor:`, `chore:`, `update:`, `bump:`, `migrate:`
   - **Removed**: `remove:`, `drop:`, `delete:`
3. Outputs a well-formatted `CHANGELOG.md` in the project root

## Output example

```markdown
# Changelog

## [v1.0.0 → HEAD] - 2026-07-08

### 🚀 Added
- `a1b2c3d` feat: add user authentication module
- `e4f5g6h` add rate limiting middleware

### 🐛 Fixed
- `i7j8k9l` fix: prevent XSS in profile form
- `m0n1o2p` hotfix: resolve database connection leak

### 🔄 Changed
- `q3r4s5t` refactor: extract payment service
- `u6v7w8x` bump dependencies to latest versions

---

_自动生成于 2026-07-08 由 changelog.sh_
```

## Requirements

- `git`
- `bash` 4.0+
