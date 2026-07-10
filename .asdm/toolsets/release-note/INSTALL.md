# Release Note Toolset Installation

**Toolset ID:** `release-note`

## Overview

本文档提供了 Release Note Toolset 工具集的安装和设置说明。该工具集根据 Git Tag 或时间段范围内的代码差异，结合用户提供的缺陷清单和用户故事清单，自动生成结构清晰、信息完整的 Release Note 说明文档。支持指定扫描分支（默认 `release`）。

## AI Guided Installation

要使用 AI 引导安装此工具集，请将以下提示复制并粘贴到 AI 编码工具的聊天窗口中：

```shell
Follow instructions in .asdm/toolsets/release-note/INSTALL.md
```

## Installation Steps

### 1. Create workspace directories

创建 Release Note 工具集的工作区目录：

```bash
mkdir -p .asdm/workspace/release-notes
```

### 2. Detect the current `Agentic Engine` provider

检测当前 AI 编码助手提供商（如 Claude Code、GitHub Copilot、Tencent CodeBuddy）。使用以下规则检测提供商：

- 如果 `.claude` 目录存在，使用 `Claude Code`
- 如果 `.github` 目录存在，使用 `GitHub Copilot`
- 如果 `.codebuddy` 目录存在，使用 `Tencent CodeBuddy`
- 如果当前工作区中未找到上述目录，提示用户手动选择提供商

### 3. Create shortcuts commands for Release Note Toolset (toolset ID: `release-note`) in provider's entry point

根据检测到的提供商，在对应位置创建快捷命令。所有提供商的安装流程一致 — Claude 和 GitHub 使用 `cat` 拼接提供商特定的 frontmatter 与实际指令内容：

#### For Claude Code (`.claude/commands/`)

Claude Code 使用带有 Frontmatter 元数据的 Markdown 文件作为斜杠命令。通过拼接 Claude 特定的 frontmatter 与指令内容来创建命令：

```bash
mkdir -p .claude/commands/

# 生成 Release Note 命令
cat > .claude/commands/asdm-generate-release-note.md << 'EOF'
---
description: "根据 Git 提交差异和用户提供的清单，生成 Release Note 文档"
argument-hint: "[from-tag] [to-tag] [--branch <branch>] [--since <date>] [--until <date>]"
---

EOF
cat .asdm/toolsets/release-note/actions/asdm-generate-release-note.md >> .claude/commands/asdm-generate-release-note.md
```

#### For GitHub Copilot (`.github/prompts/`)

GitHub Copilot 使用 `.prompt.md` 文件和 YAML frontmatter。通过拼接 GitHub 特定的 frontmatter 与指令内容来创建提示文件：

```bash
mkdir -p .github/prompts/

# 生成 Release Note 提示
cat > .github/prompts/asdm-generate-release-note.prompt.md << 'EOF'
---
agent: 'agent'
description: '根据 Git 提交差异和用户提供的清单，生成 Release Note 文档'
argument-hint: '[from-tag] [to-tag] [--branch <branch>] [--since <date>] [--until <date>]'
---

EOF
cat .asdm/toolsets/release-note/actions/asdm-generate-release-note.md >> .github/prompts/asdm-generate-release-note.prompt.md
```

#### For Tencent CodeBuddy (`.codebuddy/commands/`)

CodeBuddy 不支持 frontmatter，直接复制指令文件即可：

```bash
mkdir -p .codebuddy/commands/

# 直接复制指令文件（无需 frontmatter）
cp .asdm/toolsets/release-note/actions/asdm-generate-release-note.md .codebuddy/commands/
```

### 4. Manual Usage for Other Providers

如果您的 AI 编码助手提供商不在自动检测逻辑中（Claude Code、GitHub Copilot 或 Tencent CodeBuddy），您仍然可以手动使用 Release Note Toolset。请按以下步骤操作：

#### 直接使用指令文件

您可以直接复制指令文件的相对路径，粘贴到 AI 编码助手的聊天窗口中使用：

1. **导航到指令文件**：

   ```bash
   cd .asdm/toolsets/release-note/actions/
   ```

2. **右键点击所需的指令文件**，复制其相对路径：
   - 生成 Release Note：`asdm-generate-release-note.md`

3. **在 AI 编码助手中输入提示**：

   ```text
   Follow the instructions in {指令文件的相对路径}
   ```

## Initializing Release Note Toolset

### 生成 Release Note

安装完成后，您可以开始运行 action：

```shell
Follow the instructions in .asdm/toolsets/release-note/actions/asdm-generate-release-note.md
```

此操作将：

- 接收发版参数（Git 起始/目标提交引用、缺陷清单、用户故事清单等）
- 获取 Git 两次提交之间的代码差异（提交日志、文件变更、代码详情）
- 读取并解析缺陷和用户故事清单
- 分析和分类代码变更（新功能/缺陷修复/改进优化/破坏性变更/废弃）
- 将代码差异与缺陷/用户故事关联匹配
- 按 Release Note 规范模板生成文档（Markdown）
- 验证并展示生成摘要

### Available Commands

安装完成后，您可以使用以下命令：

1. **`/asdm-generate-release-note`** - 根据 Git 提交差异和用户提供的清单，生成 Release Note 文档

## Toolset Structure

工具集将在 `.asdm/workspace/release-notes/` 中创建以下结构：

```text
.asdm/workspace/release-notes/
└── release-note-<version>.md
```

## Spec Documents

工具集使用以下规范文档作为模板：

1. **`release-note-spec.md`** - Release Note 文档的规范模板，定义了文档结构、各章节编写指南和输出格式

## Verification

安装完成后，请验证：

1. `.asdm/workspace/release-notes` 目录已创建用于存放 Release Note Toolset 的输出文件
2. Release Note Toolset（toolset ID: `release-note`）的快捷命令已在对应的提供商目录中创建（如果使用 Claude Code、GitHub Copilot 或 Tencent CodeBuddy）
3. Release Note Toolset 工具集文件位于 `.asdm/toolsets/release-note`（toolset ID: `release-note`）

**对于其他提供商**：请验证您可以访问以下指令文件：

- `.asdm/toolsets/release-note/actions/asdm-generate-release-note.md`

## Usage Examples

### Example 1: 基于 Git Tag 生成 Release Note

```shell
# 使用两次 Git Tag 作为参数（默认扫描 release 分支）
/asdm-generate-release-note v1.0.0 v1.1.0

# 指定扫描分支
/asdm-generate-release-note v1.0.0 v1.1.0 --branch main
```

### Example 2: 使用时间段范围生成 Release Note

```shell
# 使用相对时间（默认扫描 release 分支）
/asdm-generate-release-note --since 2.weeks.ago

# 使用绝对时间，指定扫描分支
/asdm-generate-release-note --since 2026-05-01 --until 2026-06-01 --branch dev
```

### Example 3: 同时提供缺陷清单和功能清单

在对话中输入命令后，补充缺陷和用户故事信息：

```markdown
/asdm-generate-release-note v1.0.0 v1.1.0

缺陷清单：
- BUG-1001: 用户登录页面在移动端布局异常
- BUG-1002: 搜索结果排序不正确
- BUG-1003: 导出功能在数据量超过1000条时超时

用户故事清单：
- US-2001: 支持多语言切换
- US-2002: 新增数据导出为 Excel 功能
- US-2003: 支持批量删除操作
```

### Example 4: 通过文件提供缺陷和用户故事清单

先将清单保存为文件，然后在对话中引用文件路径：

```markdown
/asdm-generate-release-note v1.0.0 v1.1.0

缺陷清单文件：.asdm/workspace/release-notes/bugs.md
用户故事清单文件：.asdm/workspace/release-notes/stories.md
```

缺陷清单文件示例（`bugs.md`）：

```markdown
| 缺陷ID | 标题 | 状态 |
|--------|------|------|
| BUG-1001 | 用户登录页面在移动端布局异常 | 已修复 |
| BUG-1002 | 搜索结果排序不正确 | 已修复 |
```

用户故事清单文件示例（`stories.md`）：

```markdown
| 用户故事ID | 标题 | 状态 |
|-----------|------|------|
| US-2001 | 支持多语言切换 | 已完成 |
| US-2002 | 数据导出为 Excel | 已完成 |
```

### Example 5: 仅基于 Git 差异生成（不提供清单）

```shell
# 不提供缺陷和用户故事清单，仅根据代码差异自动生成
/asdm-generate-release-note v1.0.0 v1.1.0
```

> **提示**：Git 提交引用支持 Tag 名称和 Commit Hash 格式。可用 `git log --oneline -10` 查看 commit hash，`git tag -l` 查看 tag 列表。时间段范围支持相对时间（`2.weeks.ago`）和绝对时间（`2026-05-01`）。使用 `--branch` 指定扫描分支，默认为 `release`。

## Usage

### For Supported Providers (Claude Code, GitHub Copilot, Tencent CodeBuddy)

安装完成后，您可以使用以下命令：

- `/asdm-generate-release-note`：根据 Git 提交差异和用户提供的清单，生成 Release Note 文档

### For Other Providers (Manual Usage)

如果您的提供商不在自动检测范围内，您可以按照上方"Manual Usage for Other Providers"部分的步骤手动使用指令文件。

## Notes

- 此安装过程假设您具有创建目录和文件的必要权限
- 命令的实际执行将由 AI 模型使用 Release Note Toolset（toolset ID: `release-note`）中提供的模板和指令来完成
- 请根据您实际使用的 AI 编码助手自定义提供商特定设置
- 工具集 ID `release-note` 应在命令和文档中一致使用以指代 Release Note Toolset
- **对于不在检测逻辑中的提供商**：用户可以手动使用指令文件，复制其相对路径并输入类似"Follow the instructions in .asdm/toolsets/release-note/actions/asdm-generate-release-note.md"的提示
- 生成 Release Note 前请确保 Git 仓库中有有效的提交记录

## Integration with Other Toolsets

Release Note Toolset 可以与其他 ASDM 工具集和上下文文件集成。Context Builder 的上下文文件可以被引用，使生成的文档基于实际项目内容。例如，项目上下文入口文件（`.asdm/contexts/index.md`）可帮助 AI 模型更好地理解项目结构和模块划分，从而生成更准确的 Release Note。

### Getting Help

如需 Release Note Toolset 相关帮助，请参考：

- [ASDM Documentation](https://asdm.ai/docs)
- 工具集 README：`.asdm/toolsets/release-note/README.md`
- 规范文档：`.asdm/toolsets/release-note/spec/`

## License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.

---

*This installation document is part of the Release Note Toolset toolset. 如需帮助，请参考 README.md 或 ASDM 文档。*
