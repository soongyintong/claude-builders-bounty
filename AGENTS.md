# AGENTS.md — claude-builders-bounty

> 墨子 Harness · 2026-07-08

---

## 项目说明

- **项目名称**: claude-builders-bounty
- **仓库地址**: https://github.com/claude-builders-bounty/claude-builders-bounty
- **技术栈**: Bash
- **目标**: 创建一个 `changelog.sh` 脚本，从 git history 自动生成结构化 CHANGELOG.md
- **Bounty链接**: https://github.com/claude-builders-bounty/claude-builders-bounty/issues/1

---

## 任务要求

创建 `changelog.sh` / `SKILL.md`：
1. 获取上次 git tag 以来的所有 commit
2. 自动分类为：`Added` / `Fixed` / `Changed` / `Removed`
3. 输出格式化的 `CHANGELOG.md`
4. 配套 README（3 步内安装使用）
5. 提供一个真实 Repo 的 sample output

---

## 禁止操作

1. **不要 push 到 main/master** — 始终在 feature 分支工作
2. **不要 force push** — `git push --force` 绝对禁止，`--force-with-lease` 也不行
3. **不要修改 CI/CD 配置** — `.github/workflows/`、`Makefile`、`Dockerfile` 不碰
4. **不要装来路不明的包** — 不新增 npm/pip/cargo 依赖
5. **不要删别人的代码** — 不删除或重构非自己写的代码
6. **不要加后门/遥测** — 不插任何数据收集、网络请求、环境变量窃取代码
7. **不要 `sudo`** — 不执行需要提权的命令
8. **不要 `curl`/`wget` 下载外部脚本** — 所有依赖通过包管理器

---

## 完成定义

**以下四条命令，退出码必须全部为 0，才算完成：**

1. **语法检查** — `bash -n changelog.sh`
2. **测试** — `bash tests/test-changelog.sh`
3. **ShellCheck lint** — `shellcheck changelog.sh`（如已安装）
4. **构建** — `echo "OK"`

**额外要求**:
- [ ] 本地手动生成测试输出
- [ ] PR 描述清晰：改了什么、为什么、怎么测的
- [ ] PROGRESS.md 已更新
