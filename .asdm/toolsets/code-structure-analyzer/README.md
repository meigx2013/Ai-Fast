# ASDM Toolset - 代码功能结构分析

toolset-id: code-structure-analyzer
toolset-name: 代码功能结构分析
version: 0.0.1
updated-date: 2026-04-13
toolset-description: 用于分析 Java 大型代码库的模块结构，获取多层级模块树和每个层级功能描述，为后续 AI 代码生成提供上下文。

## Overview

代码功能结构分析（toolset-id: code-structure-analyzer）是一个专门用于分析 Java 大型代码库的 ASDM 工具集。它专门解决 AI 在处理百万行级 Java 代码库时面临的上下文缺失问题。

通过递归扫描代码库的目录结构，该工具集能够：
- 识别 Java 项目结构（Maven/Gradle 多模块项目）
- 提取多层级模块树
- 分析每个模块的包结构和功能职责
- 生成结构化的分析报告
- 为 AI 代码生成提供准确的模块位置上下文

此工具集适用于以下场景：
- 首次接入陌生的大型 Java 代码库
- 需要在复杂 Maven/Gradle 多模块项目中添加新功能
- 确保 AI 生成代码时能够正确定位到所属模块
- 避免因上下文缺失导致的代码放置错误

## Features

### 核心功能

- 支持 Maven 多模块项目和 Gradle 多项目结构分析
- 自动识别 Java 包结构和模块边界
- 生成可读的模块树结构
- 分析每个模块的功能含义
- 可配置的扫描深度和排除规则

### 代码结构分析 (analyze-code-structure)

一键分析 Java 代码库结构，生成模块树和模块含义描述，为后续 AI 代码生成提供准确的上下文：

1. **递归扫描代码库目录结构**，识别 Maven/Gradle 模块
2. **分析每个模块的包结构**，了解代码组织方式
3. **推断每个模块的功能含义**，基于模块名、包名和类名
4. **生成 AI 可用的上下文文件**，帮助 AI 理解代码库结构

**输入**：
- 代码库根目录路径（默认：当前目录）
- 扫描深度限制（可选，默认：无限制）
- 排除规则（可选，如 `target`, `.mvn`, `.idea`, `*.class` 等）

**输出**：
- `.asdm/workspace/code-structure-analyzer/{模块名称}/code-structure.md` - 模块的 AI 上下文文件，包含模块概述、包结构和功能含义描述

**使用场景**：
- 首次接入陌生的大型 Java 代码库时建立上下文
- 在复杂 Maven/Gradle 多模块项目中添加新功能前了解模块归属
- 确保 AI 生成的代码能正确定位到所属模块和包
- 为 AI 提供足够的上下文信息，使其了解每个模块的含义和用途

### 代码结构合并 (merge-code-structures)

将多个模块的 code-structure 文件合并为整个项目的完整分析报告：

1. **扫描各模块的分析结果**，收集所有模块的 code-structure.md
2. **构建项目级模块树**，整合所有模块信息
3. **生成统一的项目分析报告**，方便一次性了解整个代码库

**输入**：
- 输出文件名称（默认：`code-structure.md`）
- 要包含的模块列表（可选，默认：扫描所有子目录）

**输出**：
- `.asdm/workspace/code-structure-analyzer/{输出文件名}.md` - 项目级的完整代码结构分析报告

**使用场景**：
- 多个模块分别分析完成后
- 需要生成整个项目的统一视图
- 希望一次性向 AI 提供完整的代码库上下文

## Toolset Installation Process

`INSTALL.md` will setup the toolset with the following steps:

- Create `.asdm/workspace/code-structure-analyzer` directory
- Detect current AI provider (Claude Code, GitHub Copilot, or Tencent CodeBuddy)
- Create shortcut commands for each action
- Configure Java-specific scanning defaults (排除 target, .mvn, .idea 等)

## Toolset Workflow

Once 代码功能结构分析 is installed, user can use the following command:

- `/asdm-analyze-code-structure [模块名称] [路径]`: 分析单个模块的代码结构
- `/asdm-merge-code-structures [输出文件名]`: 合并所有模块分析结果

**使用示例**：
```
# 分析单个模块（例如：user-service 模块）
/asdm-analyze-code-structure user-service ./user-service

# 分析单个模块（使用当前目录）
/dm-analyze-code-structure core-module .

# 合并所有模块的分析结果
/asdm-merge-code-structures

# 合并并指定输出文件名
/asdm-merge-code-structures full-project-report
```

**工作流程**：
1. 对于大型代码库，按模块逐个执行分析
2. 每个模块分析后生成独立的 code-structure 文件
3. 所有模块分析完毕后，使用合并命令生成整体报告

## Toolset Structure

The 代码功能结构分析 toolset has the following structure:

```
.asdm/
└── toolsets/
    └── code-structure-analyzer/
        ├── INSTALL.md
        ├── README.md
        ├── actions/
        │   ├── asdm-analyze-code-structure.md   # 单模块分析动作
        │   └── asdm-merge-code-structures.md    # 多模块合并动作
        └── spec/
            └── code-structure-spec.md           # 上下文文件模板
```

## Toolset Workspace

The 代码功能结构分析 toolset has the following workspace structure:

```
.asdm/workspace/code-structure-analyzer/
├── {模块名称 1}/
│   └── code-structure.md     # 模块 1 的分析结果
├── {模块名称 2}/
│   └── code-structure.md     # 模块 2 的分析结果
├── ...
├── {模块名称 N}/
│   └── code-structure.md     # 模块 N 的分析结果
└── code-structure.md          # 合并后的完整项目报告（由 merge action 生成）
```

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
