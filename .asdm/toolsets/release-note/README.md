# ASDM Toolset - Release Note Toolset

toolset-id: release-note
toolset-name: Release Note Toolset
version: 0.0.1
updated-date: 2026-06-04
toolset-description: 根据 Git Tag 或时间段范围内的代码差异，结合用户提供的缺陷清单和用户故事清单，生成结构化的 Release Note 说明文档

## Overview

Release Note Toolset（工具集ID：release-note）是一个用于自动生成发版说明文档的 ASDM 工具集。它通过分析 Git Tag 或时间段范围内的代码差异，结合用户提供的缺陷清单和用户故事清单，自动优化和补充内容，生成结构清晰、信息完整的 Release Note 文档。支持指定扫描分支（默认 `release`）。

该工具集适用于软件发版流程中需要编写版本说明的场景，能够有效减少人工整理发版内容的工作量，确保发版文档的准确性和完整性。用户只需提供两次提交的 Git 引用和相关信息，工具集即可自动完成差异分析、内容分类和文档生成。

## Features

### Common features

- 基于 Git Tag 或时间段范围自动分析代码变更内容
- 支持指定扫描分支（默认 `release`）
- 结合缺陷清单和用户故事清单优化发版说明
- 支持自定义 Release Note 文档模板
- 支持多种 AI 助手平台（Claude Code、GitHub Copilot、Tencent CodeBuddy）

### Feature 1: 生成 Release Note（generate-release-note）

根据 Git Tag 或时间段范围内的代码差异，结合用户提供的缺陷和用户故事清单，生成结构化的 Release Note 文档。

- 分析 Git Tag 或时间段范围内的代码差异（新增、修改、删除）
- 支持指定扫描分支（`--branch`，默认 `release`）
- 读取用户提供的缺陷清单和用户故事清单
- 将代码差异与缺陷/用户故事进行关联匹配
- 生成分类清晰的 Release Note 文档（新功能、缺陷修复、改进优化等）
- 支持自定义输出格式和模板

**输入**：Git Tag 范围或时间段范围、目标分支、缺陷清单、用户故事清单
**输出**：结构化的 Release Note 文档
**使用场景**：软件发版时需要生成版本说明文档

## Toolset Installation Process

`INSTALL.md` will setup the toolset with the following steps:

- 确认 `.asdm/toolsets` 目录存在
- 检测当前 AI 助手提供商（Claude Code、GitHub Copilot、Tencent CodeBuddy）
- 在对应提供商的命令目录中创建快捷命令
- 创建 `.asdm/workspace/release-notes` 工作区目录

## Toolset Workflow

Once Release Note Toolset is installed, user can use the following commands:

- `/asdm-generate-release-note`：根据 Git 提交差异和用户提供的清单，生成 Release Note 文档

### 使用方式

#### 基本用法：提供 Git Tag 范围

```shell
/asdm-generate-release-note <起始 Tag> <目标 Tag> [--branch <分支>]
```

- `<起始 Tag>`：发版起始的 Git Tag
- `<目标 Tag>`：发版目标的 Git Tag
- `--branch <分支>`：扫描分支（可选，默认 `release`）

**示例**：

```shell
# 使用 Git Tag（默认扫描 release 分支）
/asdm-generate-release-note v1.0.0 v1.1.0

# 指定扫描分支
/asdm-generate-release-note v1.0.0 v1.1.0 --branch main
```

#### 使用时间段范围

```shell
/asdm-generate-release-note --since <起始时间> [--until <目标时间>] [--branch <分支>]
```

**示例**：

```shell
# 使用相对时间
/asdm-generate-release-note --since 2.weeks.ago

# 使用绝对时间，指定分支
/asdm-generate-release-note --since 2026-05-01 --until 2026-06-01 --branch dev
```

#### 完整用法：同时提供缺陷清单和功能清单

在对话中输入命令后，补充缺陷和用户故事信息：

```markdown
/asdm-generate-release-note v1.0.0 v1.1.0

缺陷清单：
- BUG-1001: 用户登录页面在移动端布局异常
- BUG-1002: 搜索结果排序不正确

用户故事清单：
- US-2001: 支持多语言切换
- US-2002: 新增数据导出为 Excel 功能
```

#### 通过文件提供清单

将缺陷和用户故事保存为文件（如 `.asdm/workspace/release-notes/bugs.md`），在对话中引用：

```markdown
/asdm-generate-release-note v1.0.0 v1.1.0 --branch release

缺陷清单文件：.asdm/workspace/release-notes/bugs.md
用户故事清单文件：.asdm/workspace/release-notes/stories.md
```

> 更详细的使用说明请参考 [action 指令文件](actions/asdm-generate-release-note.md) 中的 Usage 部分

## Toolset Structure

The Release Note Toolset toolset has the following structure:

```text
.asdm/
└── toolsets/
    └── release-note/
        ├── INSTALL.md
        ├── README.md
        ├── actions/
        │   └── asdm-generate-release-note.md
        └── spec/
            └── release-note-spec.md
```

### Spec Documents

The toolset uses the following spec documents as templates:

- **release-note-spec.md**: Release Note 文档的规范模板，定义了文档结构、各章节编写指南和输出格式

## Toolset Workspace

The Release Note Toolset toolset has the following workspace structure:

```text
.asdm/workspace/release-notes/
└── release-note-<version>.md
```

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
