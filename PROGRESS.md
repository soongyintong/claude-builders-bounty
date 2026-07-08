# PROGRESS.md — claude-builders-bounty (Issue #1)

> 墨子 Harness · 2026-07-08

---

## ✅ 已完成

- [x] Harness 脚手架初始化（AGENTS.md / PROGRESS.md / setup.sh）
- [x] 分析 issue #1 需求：从 git history 生成 CHANGELOG 的 bash 脚本/SKILL.md
- [x] 实现 `changelog.sh` — 获取 commits + 自动分类 + 格式化输出
  - 支持: no args（自动检测 tag）/ single arg（从 tag 到 HEAD）/ two args（范围）
  - 分类: Added / Fixed / Changed / Removed
  - 自动降级到第一个 commit 当无 tag
- [x] 创建测试脚本 `tests/test-changelog.sh` — 17/17 全部通过
- [x] 创建 `SKILL.md`（Claude Code skill 格式）
- [x] 四条 Harness 命令全绿通过：
  - ✅ type-check: `bash -n changelog.sh` → exit 0
  - ✅ test: `bash tests/test-changelog.sh` → 17 passed
  - ⬜ lint: shellcheck not installed (skip)
  - ✅ build: `echo "OK"` → exit 0
- [x] 验证：在本仓库上运行生成 sample changelog 成功
- [x] 编写 README 使用说明

---

## 🔄 进行中

- [ ] git add + commit + push
- [ ] 在 GitHub issue #1 中 comment `/opire try`
- [ ] 提交 PR

---

## 📋 待办

- [ ] PR 描述：改了什么、为什么、怎么测的

---

## ⚠️ 已知问题

- ShellCheck 未安装 → lint 跳过
- 如果 commit message 不遵循 conventional commit 格式，会归入 Changed
