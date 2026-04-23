# Instructions for asdm-db-analyze action

## Purpose
本指令指导 AI 模型分析现有数据库结构，提取表结构、字段、索引、外键等元信息，并生成结构化分析报告。分析结果将作为后续数据库变更设计的基础参考。

## Language Detection

在生成任何内容之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置确定主要语言
2. **应用语言一致性**：确保所有生成内容使用检测到的语言
3. **支持的语言**：中文 (zh)、英文 (en)

## Context Injection

在执行数据库结构分析前，AI 模型应读取项目上下文：

### Context Files to Read (Optional)

1. **index.md** (Recommended)
   - Path: `.asdm/contexts/index.md`
   - Purpose: 了解工作空间整体结构

2. **Progressive Context Reading** (Optional)
   - 根据需要读取架构文档、数据模型文档

### Database Context Sources

根据用户提供的输入类型，确定需要读取的数据库上下文：

| 输入类型 | 读取内容 |
|----------|----------|
| DDL 文件路径 | 解析 DDL 文件内容 |
| 数据库连接信息 | 使用 MCP 连接数据库获取结构 |
| SQL 脚本文件 | 解析 SQL 脚本中的建表语句 |

## Steps to Analyze Existing Database Structure

### 1. Receive Analysis Parameters

接收以下参数：

- **输入源类型**：
  - `ddl-file`：DDL 文件路径
  - `connection`：数据库连接信息
  - `sql-script`：SQL 脚本文件路径
- **输入源路径/信息**：具体的文件路径或连接参数
- **Feature ID**：关联的功能 ID（用于组织输出）
- **数据库类型**：MySQL、PostgreSQL、Oracle、SQL Server 等

如果参数不完整：
- 提示用户提供缺失的参数
- 显示可用选项
- 等待用户输入

### 2. Read Database Context

根据输入源类型，读取数据库结构：

#### 2.1 如果是 DDL 文件

使用 `read_file` 工具读取 DDL 文件：
- 解析 CREATE TABLE 语句
- 提取表名、字段定义、主键、索引、外键
- 识别注释和字段说明

#### 2.2 如果是数据库连接

使用 `mcp__database` 连接数据库：
- 查询系统表获取表结构
- 查询索引信息
- 查询外键关系

#### 2.3 如果是 SQL 脚本

解析 SQL 脚本文件：
- 识别所有 CREATE TABLE 语句
- 提取建表语句中的完整定义

### 3. Extract Database Elements

提取以下数据库元素：

#### 3.1 表结构 (Tables)
```
- 表名 (table_name)
- 表注释 (table_comment)
- 字段列表 (columns)
```

#### 3.2 字段定义 (Columns)
```
- 字段名 (column_name)
- 数据类型 (data_type)
- 是否可空 (nullable)
- 默认值 (default_value)
- 字段注释 (column_comment)
- 是否主键 (is_primary_key)
```

#### 3.3 索引信息 (Indexes)
```
- 索引名 (index_name)
- 索引类型 (index_type)
- 索引字段 (index_columns)
- 是否唯一 (is_unique)
```

#### 3.4 外键关系 (Foreign Keys)
```
- 外键名 (fk_name)
- 来源表 (source_table)
- 来源字段 (source_column)
- 目标表 (target_table)
- 目标字段 (target_column)
```

### 4. Generate Structure Analysis Report

按照 `spec/db-structure-spec.md` 模板生成分析报告：

报告内容应包括：
1. **概述**：数据库整体结构摘要
2. **表清单**：所有表的列表及说明
3. **详细表结构**：每个表的完整字段定义
4. **索引清单**：所有索引及其覆盖字段
5. **外键关系图**：表之间的关联关系

### 5. Save Analysis Report

保存分析报告：

- **路径**：`.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md`
- **格式**：Markdown
- **时间戳**：在文件头部添加分析时间

### 6. Update Tracking List

更新数据库变更追踪列表：

- 读取 `.asdm/workspace/database-design/db-list.md`
- 添加本次分析的表数量、索引数量等统计信息

## Execution Guidelines

### When to Use This Action

使用此 action 的场景：
- 开始新功能开发前，需要了解现有数据库结构
- 需要为数据库变更设计提供基准参考
- PRD 文档评审时需要了解现有数据支撑能力
- 数据库重构前的结构调研

### Analysis Guidelines

分析数据库结构时：
1. **完整性**：确保提取所有表、字段、索引、外键
2. **准确性**：数据类型的解析要准确反映原始定义
3. **可读性**：使用清晰的结构化格式输出
4. **追溯性**：保留原始 DDL 或 SQL 以便追溯

### Database Type Handling

不同数据库类型的处理：

| 数据库类型 | 特殊处理 |
|------------|----------|
| MySQL | 处理 `AUTO_INCREMENT`、`ENGINE`、`CHARSET` |
| PostgreSQL | 处理 `SERIAL`、`OWNED BY`、`USING INDEX` |
| Oracle | 处理 `NUMBER`、`CLOB`、`BLOB` 类型 |
| SQL Server | 处理 `IDENTITY`、`NVARCHAR` |

## Usage

使用本指令，AI 模型应：
1. 检测响应语言
2. 接收分析参数
3. 读取数据库上下文（DDL 文件或连接数据库）
4. 提取数据库元素
5. 生成结构分析报告
6. 保存报告到指定路径
7. 更新追踪列表

## Output Summary

完成分析后，将生成以下文件：
- **数据库结构分析报告**：`.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md`

报告包含：
- 数据库概述
- 完整表清单及字段定义
- 索引列表
- 外键关系

所有文件保存在 `.asdm/workspace/database-design/analysis/<feature-id>/` 目录。
