# FT-003 Code Research — codebuddy-commands

> 代码库路径：`.codebuddy/commands/`
> 扫描日期：2026-07-13

---

## 1. 目录结构与关键文件

`.codebuddy/commands/` 目录下共有 **21 个 .md 命令文件**，分为两大类：

| 分类 | 文件名 | 数量 |
|------|--------|------|
| smoke-test 系列 | smoke-test-run, smoke-test-list, smoke-test-report, smoke-test-clear | 4 |
| asdm 系列 | asdm-feature-askme, asdm-feature-breakdown, asdm-feature-idea, asdm-feature-planning(lite/lite-overall/lite-detailed), asdm-feature-progress, asdm-feature-review, asdm-docs-manual-update, asdm-docs-module-update, asdm-stats, asdm-start-project, asdm-git-commit, asdm-git-commit-message, asdm-toolset-showcase-generator | 15 |
| 独立工具 | awesome-pptx | 1 |

---

## 2. 现有实现分析

### 2.1 命令文件结构

所有命令文件极其简洁，**仅包含一行 `Follow` 指引**，没有 YAML frontmatter：

```
Follow .asdm/toolsets/<toolset-id>/actions/<action-name>.md
```

具体映射：

| Toolset ID | 指向的 Actions | 命令数 |
|------------|---------------|--------|
| web-smoke-tester | smoke-test-run/list/report/clear | 4 |
| asdm-planner | asdm-feature-askme/breakdown/idea/planning/planning-lite*/progress/review/stats/docs-manual-update/docs-module-update/toolset-showcase-generator | 13 |
| basic-tools | asdm-git-commit/asdm-git-commit-message/asdm-start-project | 3 |
| awesome-pptx | awesome-pptx | 1 |

### 2.2 注册机制

采用**"快捷方式 → Action 定义"** 的两层架构：

- **层级1**：`.codebuddy/commands/{command-name}.md` — 纯指针/快捷方式
- **层级2**：`.asdm/toolsets/{toolset-id}/actions/{action-name}.md` — 真正命令逻辑

AI 每次执行斜杠命令时实时读取 action 文件，确保使用最新版本。

### 2.3 多平台适配差异

| 平台 | 命令目录 | 命令文件格式 |
|------|----------|-------------|
| Claude Code | `.claude/commands/` | YAML frontmatter(description+argument-hint) + Follow |
| GitHub Copilot | `.github/prompts/` | YAML frontmatter(agent+description+argument-hint) + Follow |
| CodeBuddy | `.codebuddy/commands/` | 仅一行 Follow，无 frontmatter |

本项目使用 **CodeBuddy 格式**。

---

## 3. 关键发现与缺失项

| 编号 | 发现/缺失项 | 说明 |
|------|------------|------|
| cmd-G1 | **命令注册需新增7个** | auto-test-generate/record/run/list/report/ci/clean |
| cmd-G2 | **命名规则统一** | 所有命令以功能短语命名，如 smoke-test-run |
| cmd-G3 | **Follow路径一致性** | 命令文件名必须与 action 文件名对应 |

---

## 4. auto-tester 需注册的7个命令

| 命令文件名 | Follow 指向 |
|-----------|------------|
| auto-test-generate.md | `.asdm/toolsets/web-auto-tester/actions/auto-test-generate.md` |
| auto-test-record.md | `.asdm/toolsets/web-auto-tester/actions/auto-test-record.md` |
| auto-test-run.md | `.asdm/toolsets/web-auto-tester/actions/auto-test-run.md` |
| auto-test-list.md | `.asdm/toolsets/web-auto-tester/actions/auto-test-list.md` |
| auto-test-report.md | `.asdm/toolsets/web-auto-tester/actions/auto-test-report.md` |
| auto-test-clean.md | `.asdm/toolsets/web-auto-tester/actions/auto-test-clean.md` |

---

## 5. 与其他代码库的交互接口

- **`.asdm/toolsets/`**：命令 Follow 指向对应 toolset 的 action 文件
- **无跨代码库 API 调用**：命令文件是纯指针，不包含逻辑
