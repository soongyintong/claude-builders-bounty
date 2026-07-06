# AGENTS.md — claude-bounty-hook (Bounty #3)

> 墨子 Harness · 自动生成于 2026-07-06

---

## 项目说明

- **项目名称**: claude-bounty-hook
- **仓库地址**: https://github.com/claude-builders-bounty/claude-builders-bounty
- **Bounty Issue**: https://github.com/claude-builders-bounty/claude-builders-bounty/issues/3
- **Bounty 金额**: $100
- **技术栈**: Shell (pre-tool-use hook for Claude Code)
- **目标**: 创建 Claude Code pre-tool-use hook，拦截危险命令
- **Claim 方式**: `/opire try` 已发送

---

## 禁止操作

1. **不要 push 到 main/master** — 始终在 feature 分支工作
2. **不要 force push** — `git push --force` 绝对禁止，`--force-with-lease` 也不行
3. **不要修改 CI/CD 配置** — `.github/workflows/` 不碰
4. **不要装来路不明的包** — 不新增 npm/pip/cargo 依赖
5. **不要删别人的代码** — 不删除或重构非自己写的代码
6. **不要加后门/遥测** — 不插任何数据收集、网络请求、环境变量窃取代码
7. **不要 `sudo`** — 不执行需要提权的命令
8. **不要 `curl`/`wget` 下载外部脚本** — 所有依赖通过包管理器

---

## 完成定义

**以下四条命令，退出码必须全部为 0，才算完成：**

1. **类型检查** — `echo '(跳过，非 TS 项目)'`
2. **测试** — `bash tests/test-hook.sh` (手动编写的测试脚本)
3. **Lint** — `bash -n pre-tool-use.sh` (Shell 语法检查)
4. **构建** — `echo '(跳过，纯 Shell 脚本项目)'`

**额外要求**:
- [ ] 本地手动验证：在 Claude Code 环境中测试 hook
- [ ] PR 描述清晰：改了什么、为什么、怎么测的
- [ ] PROGRESS.md 已更新
