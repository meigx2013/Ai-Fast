# ASDM Toolset - 代码分析工具集

toolset-id: code-analyzer
toolset-name: 代码分析工具集
version: 0.0.1
updated-date: 2026-04-09
toolset-description: 这是一个用于代码库分析的工具集，主要用来分析当前工作区或工作区某个子目录（子模块）下的代码，达成两个目标：a. 分析输出每个代码文件的大小和简要中文含义描述。b.分析类/方法被引用3次以上的识别为核心类/方法资产。

## Overview

代码分析工具集是一个用于代码库分析和资产识别的 ASDM 工具集。它帮助开发团队快速了解代码库的结构和规模，识别代码库中的核心资产（高引用类/方法）。

该工具集通过两种核心分析能力为开发者提供代码库的全局视图：**文件分析**功能将遍历指定目录下的所有代码文件，统计每个文件的大小，并生成简洁的中文含义描述，帮助开发者快速把握代码库的整体结构和各模块的用途；**核心资产识别**功能则通过分析代码中的引用关系，识别出被引用次数达到阈值（默认3次及以上）的类和方法，这些高引用代码通常是项目的核心资产，在进行代码重构或架构调整时需要特别关注。

此工具集特别适用于以下场景：新项目接手时快速了解代码库结构、新人培训时概览项目全貌、代码重构前识别核心依赖、以及项目代码质量评估。

## Features

### Common features

- **灵活的分析范围**：支持分析整个工作区或指定子目录（子模块）
- **多语言支持**：支持 JavaScript/TypeScript、Python、Java、C# 等主流编程语言
- **友好的输出格式**：生成结构化的 Markdown 报告，便于阅读和存档
- **时间戳记录**：每次分析结果都带有时间戳，方便追溯和对比

### Feature 1: 文件分析 (file-analyze)

分析指定目录下所有代码文件的大小和简要含义描述，帮助快速了解代码库结构。

**输入**：
- 分析路径（工作区根目录或子目录，默认当前目录）

**输出**：
- Markdown 格式报告，包含文件路径、代码行数、文件大小估算、中文含义描述

**使用场景**：
- 新项目接手时快速了解代码库结构
- 识别项目中的主要模块和职责
- 评估各代码文件的复杂度和规模

### Feature 2: 核心资产识别 (core-asset-identify)

分析代码中被引用3次以上的类/方法，识别为核心代码资产，便于重点保护和重构规划。

**输入**：
- 代码库路径（支持整个工作区或指定模块）
- 引用阈值（默认值为3次）

**输出**：
- 核心资产列表，包含类名/方法名、引用次数、所在文件路径、首次定义位置

**使用场景**：
- 识别代码库核心依赖，避免破坏性修改
- 重构前评估影响范围
- 发现潜在的耦合问题和循环依赖

## Toolset Installation Process

`INSTALL.md` will setup the toolset with the following steps:

- 创建 `.asdm/workspace/code-analyzer/analysis-reports` 目录用于存储分析报告
- 创建 `.asdm/workspace/code-analyzer/temp` 目录用于临时文件
- 初始化工作区配置文件
- 注册工具集命令到系统

安装完成后，用户可通过 AI Guided Installation 方式运行 `INSTALL.md` 来初始化工具集。

## Toolset Workflow

Once 代码分析工具集 is installed, user can use the following commands:

- `/file-analyze [path]`: 分析指定路径下的所有代码文件，输出文件大小和含义描述
- `/core-asset-identify [path]`: 分析代码中的核心资产，识别高引用类/方法
- `/code-summary`: 快速获取整个工作区的代码概览

**典型工作流程**：

1. 进入新的代码工作区
2. 使用 `/file-analyze` 了解代码结构
3. 使用 `/core-asset-identify` 识别核心资产
4. 根据分析报告规划后续开发或重构工作

## Toolset Structure

The 代码分析工具集 toolset has the following structure:

```
.asdm/
└── toolsets/
    └── code-analyzer/
        ├── INSTALL.md
        ├── README.md
        ├── actions/
        │   ├── file-analyze.md
        │   ├── core-asset-identify.md
        │   └── code-summary.md
        └── spec/
            ├── file-analyze-spec.md
            ├── core-asset-identify-spec.md
            └── code-summary-spec.md
```

### Spec Documents

The toolset uses the following spec documents as templates:

- **file-analyze-spec.md**: Template for generating file analysis reports with code statistics and Chinese descriptions
- **core-asset-identify-spec.md**: Template for generating core asset identification reports with reference counts and dependency analysis
- **code-summary-spec.md**: Template for generating comprehensive code summary reports combining file analysis and core asset identification

## Toolset Workspace

The 代码分析工具集 toolset has the following workspace structure:

```
.asdm/workspace/code-analyzer/
├── analysis-reports/
│   ├── file-analysis/
│   │   └── <timestamp>-file-analysis.md
│   └── core-assets/
│       └── <timestamp>-core-assets.md
├── config/
│   └── analyzer-config.json
└── temp/
    └── <临时分析缓存文件>
```

**目录说明**：
- `analysis-reports/`: 存储所有分析报告
  - `file-analysis/`: 文件分析报告
  - `core-assets/`: 核心资产分析报告
- `config/`: 工具集配置文件
- `temp/`: 临时缓存文件，分析完成后可清理

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
