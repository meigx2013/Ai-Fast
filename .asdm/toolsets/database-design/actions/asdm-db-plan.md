# Instructions for asdm-db-plan action

## Purpose
本指令指导 AI 模型设计数据库变更方案。通过对比需求数据模型与现有数据库结构，分析差异点，明确需要执行的变更操作，生成结构化的变更方案文档。

## Language Detection

在生成任何内容之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置确定主要语言
2. **应用语言一致性**：确保所有生成内容使用检测到的语言
3. **支持的语言**：中文 (zh)、英文 (en)

## Context Injection

在设计变更方案前，AI 模型应读取以下上下文：

### Context Files to Read (Required)

1. **index.md** (Required)
   - Path: `.asdm/contexts/index.md`
   - Purpose: 了解工作空间整体结构

2. **Feature PRD 文档** (Required)
   - Path: `.asdm/workspace/features/<feature-id>/feature-prd.md`
   - Purpose: 了解功能需求背景

3. **需求数据模型** (Required)
   - Path: `.asdm/workspace/database-design/analysis/<feature-id>/data-model.md`
   - Purpose: 获取需求数据模型定义

4. **现有数据库结构** (Required)
   - Path: `.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md`
   - Purpose: 获取现有数据库结构

5. **变更方案规范模板** (Required)
   - Path: `.asdm/toolsets/database-design/spec/change-plan-spec.md`
   - Purpose: 遵循规范模板生成变更方案

## Steps to Design Change Plan

### 1. Receive Planning Parameters

接收以下参数：

- **Feature ID**：功能唯一标识
- **数据库类型**：MySQL、PostgreSQL、Oracle、SQL Server

如果参数不完整：
- 提示用户提供缺失的参数
- 列出可用的 Feature ID 供选择
- 等待用户输入

### 2. Load Required Documents

读取所有必需的上下文文档：

#### 2.1 读取需求数据模型

使用 `read_file` 工具读取：
- 路径：`.asdm/workspace/database-design/analysis/<feature-id>/data-model.md`
- 提取：
  - 数据实体清单
  - 实体属性定义
  - 实体关系定义

#### 2.2 读取现有数据库结构

使用 `read_file` 工具读取：
- 路径：`.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md`
- 提取：
  - 现有表清单
  - 表字段定义
  - 索引定义
  - 外键关系

#### 2.3 读取 Feature PRD

使用 `read_file` 工具读取：
- 路径：`.asdm/workspace/features/<feature-id>/feature-prd.md`
- 了解功能需求背景和业务规则

### 3. Analyze Differences

对比需求模型与现有结构，分析差异：

#### 3.1 差异类型分类

| 差异类型 | 说明 | 处理方式 |
|----------|------|----------|
| 新增表 | 需求中有但现有结构无 | CREATE TABLE |
| 删除表 | 现有结构中有但需求无 | DROP TABLE |
| 新增字段 | 表中有新属性需求 | ALTER TABLE ADD COLUMN |
| 删除字段 | 现有字段不再需要 | ALTER TABLE DROP COLUMN |
| 修改字段 | 字段定义变更 | ALTER TABLE MODIFY COLUMN |
| 新增索引 | 需要新增索引 | CREATE INDEX |
| 删除索引 | 索引不再需要 | DROP INDEX |
| 新增外键 | 表关系变更 | ALTER TABLE ADD FK |
| 删除外键 | 关系不再需要 | ALTER TABLE DROP FK |

#### 3.2 逐表对比分析

```
对于每个需求实体：
1. 检查现有结构中是否存在对应表
2. 如果存在：对比字段定义差异
3. 如果不存在：标记为新增表
4. 记录所有差异点

对于每个现有表：
1. 检查需求模型中是否引用该表
2. 如果需求中无引用：标记为可能删除（需确认）
3. 记录未使用的表
```

### 4. Design Change Operations

根据差异分析结果，设计变更操作：

#### 4.1 新增表设计

```
对于每个新增表：
- 表名：<table_name>
- 字段列表：[字段定义]
- 主键：<primary_key>
- 索引：[索引定义]
- 外键：[外键定义]
- 说明：[业务含义]
```

#### 4.2 字段变更设计

```
对于每个字段变更：
- 表名：<table_name>
- 字段名：<column_name>
- 变更类型：ADD / MODIFY / DROP
- 原定义：[变更前定义，如有]
- 新定义：[变更后定义，如有]
- SQL 语句：<对应的 ALTER 语句>
- 影响分析：[对现有数据的影响]
```

#### 4.3 数据迁移设计

如果有数据迁移需求：

```
迁移需求：
- 源表/字段：[迁移来源]
- 目标表/字段：[迁移目标]
- 迁移逻辑：[转换规则]
- 迁移顺序：[执行顺序]
- 回滚方案：[回滚逻辑]
```

### 5. Assess Change Impact

评估变更影响：

#### 5.1 影响范围分析

```
- 影响表数量：<n>
- 影响数据量：<估算>
- 影响服务：<受影响的服务列表>
- 停机窗口：<需要的维护窗口>
```

#### 5.2 风险评估

| 风险类型 | 风险描述 | 影响等级 | 缓解措施 |
|----------|----------|----------|----------|
| 数据丢失 | 删除字段可能丢失数据 | 高 | 提前备份 |
| 服务中断 | 表结构变更可能短暂影响 | 中 | 选择低峰期执行 |
| 外键约束 | 关联数据可能导致失败 | 中 | 先迁移数据后建约束 |

### 6. Design Execution Order

设计变更执行顺序：

```
Phase 1: 准备阶段
  1.1 数据备份
  1.2 创建变更脚本备份点

Phase 2: 新增操作（无依赖）
  2.1 新增表
  2.2 新增字段
  2.3 新增索引

Phase 3: 数据迁移
  3.1 迁移数据
  3.2 验证数据

Phase 4: 约束操作
  4.1 新增外键
  4.2 创建唯一索引

Phase 5: 清理操作
  5.1 删除废弃字段
  5.2 删除废弃索引
  5.3 删除废弃表
```

### 7. Generate Change Plan Document

按照 `spec/change-plan-spec.md` 模板生成变更方案文档：

#### 7.1 文档结构

```
# 数据库变更方案

## 变更概述
[变更背景和目标]

## 变更范围
[涉及的表和变更类型]

## 差异分析
[需求模型与现有结构的差异]

## 变更操作清单
[所有变更操作的详细描述]

## 执行计划
[变更执行顺序和时间安排]

## 影响评估
[变更对系统的影响]

## 回滚方案
[如果变更失败的回滚措施]

## 验收标准
[如何验证变更成功]
```

### 8. Save Change Plan

保存变更方案：

- **路径**：`.asdm/workspace/database-design/analysis/<feature-id>/change-plan.md`
- **格式**：Markdown
- **时间戳**：在文件头部添加方案生成时间

## Execution Guidelines

### When to Use This Action

使用此 action 的场景：
- 完成数据建模后，需要设计具体变更
- PRD 评审时需要明确数据库变更范围
- 数据库变更实施前的方案评审
- 需要多方确认数据库变更计划

### Planning Guidelines

设计变更方案时：
1. **完整性**：覆盖所有数据变更需求
2. **可逆性**：每个变更都应可回滚
3. **最小化影响**：减少对线上服务的影响
4. **可执行性**：确保变更脚本可正确执行

### Safety Guidelines

确保变更安全：
1. **先读后写**：充分理解现有结构再设计变更
2. **影响评估**：明确每个变更的影响范围
3. **回滚准备**：每个变更都要有回滚方案
4. **顺序合理**：按照依赖关系安排执行顺序

## Usage

使用本指令，AI 模型应：
1. 检测响应语言
2. 接收变更规划参数
3. 读取需求数据模型和现有数据库结构
4. 分析两者差异
5. 设计变更操作
6. 评估变更影响
7. 设计执行顺序
8. 生成变更方案文档
9. 保存文档到指定路径

## Output Summary

完成变更方案设计后，将生成以下文件：
- **数据库变更方案文档**：`.asdm/workspace/database-design/analysis/<feature-id>/change-plan.md`

方案包含：
- 变更概述和范围
- 差异分析详情
- 变更操作清单（含 SQL 语句）
- 执行计划和顺序
- 影响评估
- 回滚方案
- 验收标准

所有文件保存在 `.asdm/workspace/database-design/analysis/<feature-id>/` 目录。
