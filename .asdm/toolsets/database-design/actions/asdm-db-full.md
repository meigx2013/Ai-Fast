# Instructions for asdm-db-full action

## Purpose
本指令指导 AI 模型执行完整的数据库变更设计流程，包括：分析现有数据库结构、从 PRD 文档提取数据需求、设计变更方案、生成变更脚本。这是一个一站式 action，整合了 `asdm-db-analyze`、`asdm-db-model`、`asdm-db-plan` 和 `asdm-db-generate` 四个步骤。

## Language Detection

在执行任何步骤之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置确定主要语言
2. **应用语言一致性**：确保所有生成内容使用检测到的语言
3. **支持的语言**：中文 (zh)、英文 (en)

## Context Injection

在执行完整流程前，AI 模型应读取项目上下文：

### Context Files to Read (Required)

1. **index.md** (Required - MUST be read first)
   - Path: `.asdm/contexts/index.md`
   - Purpose: 了解工作空间整体结构

2. **Feature PRD 文档** (Required)
   - Path: `.asdm/workspace/features/<feature-id>/feature-prd.md`
   - Purpose: 获取功能需求详细描述

3. **数据库结构分析规范** (Required)
   - Path: `.asdm/toolsets/database-design/spec/db-structure-spec.md`
   - Purpose: 了解结构分析输出格式

4. **数据模型规范** (Required)
   - Path: `.asdm/toolsets/database-design/spec/data-model-spec.md`
   - Purpose: 了解数据模型输出格式

5. **变更方案规范** (Required)
   - Path: `.asdm/toolsets/database-design/spec/change-plan-spec.md`
   - Purpose: 了解变更方案输出格式

6. **SQL 脚本模板** (Required)
   - Path: `.asdm/toolsets/database-design/spec/script-template.md`
   - Purpose: 了解脚本输出格式

## Steps to Execute Full Database Design Workflow

### Phase 1: Database Structure Analysis

#### 1.1 Receive Parameters

接收以下参数：

- **Feature ID**：功能唯一标识
- **数据库结构输入**：
  - DDL 文件路径
  - 数据库连接信息
  - SQL 脚本文件路径
- **数据库类型**：MySQL、PostgreSQL、Oracle、SQL Server

如果参数不完整：
- 提示用户提供缺失的参数
- 显示可用选项
- 等待用户输入

#### 1.2 Analyze Existing Database Structure

按照 `asdm-db-analyze` action 执行结构分析：

1. 读取数据库结构（DDL 文件或连接数据库）
2. 提取表结构、字段、索引、外键
3. 生成结构分析报告
4. 保存到 `.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md`

### Phase 2: Data Requirements Modeling

#### 2.1 Load Feature PRD

读取 Feature PRD 文档：
- 路径：`.asdm/workspace/features/<feature-id>/feature-prd.md`
- 提取功能需求和业务规则

#### 2.2 Model Data Requirements

按照 `asdm-db-model` action 执行需求建模：

1. 从 PRD 文档中识别数据实体
2. 定义实体属性
3. 定义实体关系
4. 生成数据模型文档
5. 保存到 `.asdm/workspace/database-design/analysis/<feature-id>/data-model.md`

### Phase 3: Change Plan Design

#### 3.1 Load Documents

读取以下文档：
- 需求数据模型
- 现有数据库结构
- Feature PRD

#### 3.2 Analyze Differences

对比分析：
- 识别新增表
- 识别字段变更
- 识别索引变更
- 识别外键变更

#### 3.3 Design Change Plan

按照 `asdm-db-plan` action 设计变更方案：

1. 设计变更操作
2. 评估变更影响
3. 设计执行顺序
4. 制定回滚方案
5. 生成变更方案文档
6. 保存到 `.asdm/workspace/database-design/analysis/<feature-id>/change-plan.md`

### Phase 4: Script Generation

#### 4.1 Load Change Plan

读取变更方案文档：
- 提取变更操作清单
- 了解执行顺序

#### 4.2 Generate Scripts

按照 `asdm-db-generate` action 生成脚本：

1. 初始化脚本目录
2. 生成 DDL 变更脚本
3. 生成 DML 变更脚本
4. 生成回滚脚本（DDL + DML）
5. 生成验证脚本
6. 保存所有脚本到 `.asdm/workspace/database-design/scripts/<feature-id>/`

### Phase 5: Summary Report

#### 5.1 Generate Execution Summary

生成完整流程执行摘要：

```markdown
# Database Design Execution Summary

## Feature Information
- Feature ID: <feature-id>
- Feature Name: <feature-name>
- Execution Time: <timestamp>

## Phase 1: Structure Analysis
- Status: ✓ Completed
- Output: db-structure.md
- Tables Found: <n>
- Indexes Found: <n>
- Foreign Keys Found: <n>

## Phase 2: Data Modeling
- Status: ✓ Completed
- Output: data-model.md
- Entities Identified: <n>
- Attributes Defined: <n>
- Relationships Defined: <n>

## Phase 3: Change Planning
- Status: ✓ Completed
- Output: change-plan.md
- New Tables: <n>
- Modified Tables: <n>
- Field Changes: <n>

## Phase 4: Script Generation
- Status: ✓ Completed
- Scripts Generated:
  - ddl_<timestamp>.sql
  - dml_<timestamp>.sql
  - rollback_ddl_<timestamp>.sql
  - rollback_dml_<timestamp>.sql
  - verify_<timestamp>.sql

## Next Steps
1. Review generated documents and scripts
2. Conduct code review for the changes
3. Execute DDL script in staging environment
4. Execute DML script in staging environment
5. Run verification script
6. Execute in production environment (if tests pass)
```

#### 5.2 Save Summary

保存执行摘要：
- **路径**：`.asdm/workspace/database-design/analysis/<feature-id>/execution-summary.md`

### Phase 6: User Review

#### 6.1 Display Summary

向用户展示执行摘要：

```
===============================================
Database Design Workflow Completed
===============================================

Feature: <feature-name> (<feature-id>)

Phases Completed:
✓ Phase 1: Database Structure Analysis
✓ Phase 2: Data Requirements Modeling
✓ Phase 3: Change Plan Design
✓ Phase 4: Script Generation

Generated Files:
- Analysis: .asdm/workspace/database-design/analysis/<feature-id>/
- Scripts:  .asdm/workspace/database-design/scripts/<feature-id>/

===============================================
```

#### 6.2 Prompt Next Actions

提示用户下一步操作：

```
Next Steps:
1. Review the generated change plan (change-plan.md)
2. Review the generated scripts
3. Execute scripts in staging environment
4. Verify changes with verification script
5. Proceed with production deployment
```

## Execution Guidelines

### When to Use This Action

使用此 action 的场景：
- 需要完整走查数据库变更设计全流程
- 新功能开发需要完整的数据库变更方案
- 需要一站式完成从需求到脚本的所有工作
- 变更评审前的完整准备

### When to Use Individual Actions

在以下情况下，考虑使用单个 action：
- 只做结构分析：使用 `asdm-db-analyze`
- 只做需求建模：使用 `asdm-db-model`
- 只做方案设计：使用 `asdm-db-plan`
- 只生成脚本：使用 `asdm-db-generate`

### Workflow Guidelines

执行完整流程时：
1. **顺序执行**：按 Phase 顺序执行，确保每个阶段的输出正确
2. **及时保存**：每个阶段完成后及时保存输出
3. **错误处理**：某阶段失败时，提示用户并允许重试该阶段
4. **保持上下文**：记住之前阶段的输入和输出

### Quality Checks

每个阶段结束时应进行质量检查：

| 阶段 | 检查项 |
|------|--------|
| 结构分析 | 是否完整提取所有表/字段 |
| 需求建模 | 是否覆盖所有功能点 |
| 变更方案 | 是否无遗漏变更 |
| 脚本生成 | SQL 语法是否正确 |

## Usage

使用本指令，AI 模型应：
1. 检测响应语言
2. 接收完整流程参数
3. 按顺序执行 6 个 Phase
4. 每个 Phase 完成后进行质量检查
5. 生成执行摘要
6. 提示用户下一步操作

## Output Summary

完成完整流程后，将生成以下文件：

### Analysis Documents

| 文档 | 路径 |
|------|------|
| 结构分析报告 | `.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md` |
| 数据需求模型 | `.asdm/workspace/database-design/analysis/<feature-id>/data-model.md` |
| 变更方案 | `.asdm/workspace/database-design/analysis/<feature-id>/change-plan.md` |
| 执行摘要 | `.asdm/workspace/database-design/analysis/<feature-id>/execution-summary.md` |

### Generated Scripts

| 脚本 | 路径 |
|------|------|
| DDL 变更 | `.asdm/workspace/database-design/scripts/<feature-id>/ddl_<timestamp>.sql` |
| DML 变更 | `.asdm/workspace/database-design/scripts/<feature-id>/dml_<timestamp>.sql` |
| DDL 回滚 | `.asdm/workspace/database-design/scripts/<feature-id>/rollback_ddl_<timestamp>.sql` |
| DML 回滚 | `.asdm/workspace/database-design/scripts/<feature-id>/rollback_dml_<timestamp>.sql` |
| 验证脚本 | `.asdm/workspace/database-design/scripts/<feature-id>/verify_<timestamp>.sql` |

所有文件保存在 `.asdm/workspace/database-design/` 目录下的相应子目录。
