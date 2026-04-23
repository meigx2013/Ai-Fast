# ASDM Toolset - Database Design

toolset-id: database-design
toolset-name: Database Design
version: 0.0.1
updated-date: 2026-04-17
toolset-description: 基于需求PRD文档和当前的数据库结构，设计当前需求开发时需要进行的数据库变更内容，必须输出可执行的数据库变更脚本。

## Overview

Database Design (toolset-id: database-design) 是一款面向开发团队的 ASDM 工具集，用于根据需求文档和现有数据库结构，自动分析并生成数据库变更脚本。

该工具集帮助开发团队在需求开发过程中，快速完成数据库设计变更工作：
- **输入**：需求 PRD 文档 + 现有数据库结构（DDL/SQL 文件或数据库连接）
- **输出**：可直接执行的数据库变更脚本（DDL + DML）
- **价值**：减少人工分析工作量，确保变更脚本准确完整，支持数据库版本管理

用户可以通过 AI Guided Installation 安装此工具集到工作空间，安装后使用快捷命令启动数据库变更设计流程。

## Features

### Common features

- **智能需求分析**：自动从 PRD 文档中提取数据实体、属性和关系
- **结构差异对比**：对比需求模型与现有数据库结构的差异
- **脚本自动生成**：生成可直接执行的 SQL 变更脚本
- **版本管理支持**：支持生成版本化的变更脚本，便于回滚追踪
- **多数据库支持**：支持 MySQL、PostgreSQL、Oracle、SQL Server 等主流数据库

### Feature 1: 数据库结构分析 (analyze-existing-db)

分析现有数据库结构，提取表结构、字段、索引、外键等元信息。

**输入**：
- 现有数据库 DDL 文件路径
- 或数据库连接信息

**输出**：
- 数据库结构分析报告 (`.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md`)

**使用场景**：在开始需求开发前，了解现有数据库结构作为变更设计的基准

### Feature 2: 需求数据建模 (model-data-requirements)

从 PRD 文档中提取数据需求，构建需求数据模型。

**输入**：
- Feature PRD 文档路径
- 或需求描述文本

**输出**：
- 需求数据模型文档 (`.asdm/workspace/database-design/analysis/<feature-id>/data-model.md`)

**使用场景**：新功能开发时，将需求转化为数据实体定义

### Feature 3: 变更方案设计 (design-change-plan)

设计数据库变更方案，明确需要执行的变更操作。

**输入**：
- 需求数据模型
- 现有数据库结构

**输出**：
- 数据库变更方案文档 (`.asdm/workspace/database-design/analysis/<feature-id>/change-plan.md`)

**使用场景**：明确变更范围和影响，为脚本生成提供依据

### Feature 4: 变更脚本生成 (generate-change-script)

生成可执行的数据库变更脚本（DDL 和 DML）。

**输入**：
- 数据库变更方案

**输出**：
- DDL 变更脚本 (`.asdm/workspace/database-design/scripts/<feature-id>/ddl_<timestamp>.sql`)
- DML 变更脚本 (`.asdm/workspace/database-design/scripts/<feature-id>/dml_<timestamp>.sql`)
- 回滚脚本 (`.asdm/workspace/database-design/scripts/<feature-id>/rollback_<timestamp>.sql`)

**使用场景**：生成可直接执行的数据库变更脚本

## Toolset Installation Process

`INSTALL.md` will setup the toolset with the following steps:

- 创建 `.asdm/workspace/database-design` 目录结构
- 创建 `analysis/` 子目录存放分析文档
- 创建 `scripts/` 子目录存放变更脚本
- 检测当前 AI Provider（如 Claude Code、GitHub Copilot、Tencent CodeBuddy）
- 在对应目录创建快捷命令

## Toolset Workflow

Once Database Design is installed, user can use the following commands:

- `/asdm-db-analyze`：分析现有数据库结构
- `/asdm-db-model`：从 PRD 文档提取数据需求建模
- `/asdm-db-plan`：设计数据库变更方案
- `/asdm-db-generate`：生成数据库变更脚本
- `/asdm-db-full`：完整流程（分析 + 建模 + 方案 + 脚本）

## Toolset Structure

The Database Design toolset has the following structure:

```
.asdm/
└── toolsets/
    └── database-design/                    ## Database Design toolset
        ├── INSTALL.md                     ## Installation instructions
        ├── README.md                      ## Current document
        └── actions/                       ## Action instructions
            ├── asdm-db-analyze.md         ## Analyze existing database
            ├── asdm-db-model.md           ## Model data requirements
            ├── asdm-db-plan.md            ## Design change plan
            ├── asdm-db-generate.md        ## Generate change scripts
            └── asdm-db-full.md            ## Full workflow
        └── spec/                          ## Spec templates
            ├── db-structure-spec.md       ## Database structure analysis spec
            ├── data-model-spec.md         ## Data model spec
            ├── change-plan-spec.md        ## Change plan spec
            ├── script-template.md         ## SQL script template
            └── db-list-spec.md            ## DB change tracking list spec
```

## Spec Documents

The toolset uses the following spec documents as templates:

- **db-structure-spec.md**: Template for generating database structure analysis reports (`.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md`)
- **data-model-spec.md**: Template for generating data requirements model documents (`.asdm/workspace/database-design/analysis/<feature-id>/data-model.md`)
- **change-plan-spec.md**: Template for generating database change plan documents (`.asdm/workspace/database-design/analysis/<feature-id>/change-plan.md`)
- **script-template.md**: Template for generating SQL change scripts (DDL, DML, rollback, verify scripts)
- **db-list-spec.md**: Template for database change tracking list (`.asdm/workspace/database-design/db-list.md`)

## Toolset Workspace

The Database Design toolset has the following workspace structure:

```
.asdm/
└── workspace/
    └── database-design/                    ## Database Design workspace
        ├── analysis/                       ## Analysis documents
        │   └── <feature-id>/             ## Per-feature analysis
        │       ├── db-structure.md       ## Existing DB structure
        │       ├── data-model.md         ## Data requirements model
        │       └── change-plan.md        ## Change plan
        ├── scripts/                       ## Generated SQL scripts
        │   └── <feature-id>/             ## Per-feature scripts
        │       ├── ddl_<timestamp>.sql   ## DDL change script
        │       ├── dml_<timestamp>.sql   ## DML change script
        │       └── rollback_<timestamp>.sql ## Rollback script
        └── db-list.md                     ## Database change tracking list
```

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
