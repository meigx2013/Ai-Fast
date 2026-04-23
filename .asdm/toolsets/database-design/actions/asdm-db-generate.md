# Instructions for asdm-db-generate action

## Purpose
本指令指导 AI 模型根据数据库变更方案，生成可直接执行的数据库变更脚本（DDL 和 DML）。脚本应包含完整的变更 SQL、验证 SQL 和回滚 SQL，确保变更可追溯、可回滚。

## Language Detection

在生成任何内容之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置确定主要语言
2. **应用语言一致性**：确保所有生成内容使用检测到的语言
3. **支持的语言**：中文 (zh)、英文 (en)

## Context Injection

在生成变更脚本前，AI 模型应读取以下上下文：

### Context Files to Read (Required)

1. **index.md** (Required)
   - Path: `.asdm/contexts/index.md`
   - Purpose: 了解工作空间整体结构

2. **数据库变更方案** (Required)
   - Path: `.asdm/workspace/database-design/analysis/<feature-id>/change-plan.md`
   - Purpose: 获取变更方案详情

3. **需求数据模型** (Optional)
   - Path: `.asdm/workspace/database-design/analysis/<feature-id>/data-model.md`
   - Purpose: 获取完整的数据定义

4. **数据库结构** (Optional)
   - Path: `.asdm/workspace/database-design/analysis/<feature-id>/db-structure.md`
   - Purpose: 获取现有结构参考

5. **SQL 脚本模板** (Required)
   - Path: `.asdm/toolsets/database-design/spec/script-template.md`
   - Purpose: 遵循模板格式生成脚本

## Steps to Generate Change Scripts

### 1. Receive Script Generation Parameters

接收以下参数：

- **Feature ID**：功能唯一标识
- **数据库类型**：MySQL、PostgreSQL、Oracle、SQL Server
- **脚本前缀**：可选，用于标识脚本（如版本号）

如果参数不完整：
- 提示用户提供缺失的参数
- 列出可用的 Feature ID 供选择
- 等待用户输入

### 2. Load Change Plan Document

读取变更方案文档：

使用 `read_file` 工具读取：
- 路径：`.asdm/workspace/database-design/analysis/<feature-id>/change-plan.md`
- 提取：
  - 变更操作清单
  - 执行顺序
  - 影响评估
  - 回滚方案
  - 验收标准

### 3. Initialize Script Files

创建脚本目录结构：

```
.asdm/workspace/database-design/scripts/<feature-id>/
├── ddl_<timestamp>.sql          # DDL 变更脚本
├── dml_<timestamp>.sql          # DML 变更脚本
├── rollback_ddl_<timestamp>.sql # DDL 回滚脚本
├── rollback_dml_<timestamp>.sql # DML 回滚脚本
└── verify_<timestamp>.sql       # 验证脚本
```

### 4. Generate DDL Change Script

生成 DDL（数据定义语言）变更脚本：

#### 4.1 脚本头部

```sql
-- ================================================
-- Database Change Script
-- Feature ID: <feature-id>
-- Database Type: <db-type>
-- Generated: <timestamp>
-- ================================================

-- !!! IMPORTANT: Execute this script in a transaction or with backup !!!
-- !!! Please review all statements before execution !!!

SET SESSION sql_mode = '';

-- ================================================
-- Section 1: Pre-checks
-- ================================================
-- Verify database state before changes
-- [Add verification queries here]

-- ================================================
-- Section 2: Create New Tables
-- ================================================
```

#### 4.2 CREATE TABLE 语句

对于每个新增表，生成 CREATE TABLE 语句：

```sql
-- Create table: <table_name>
-- Description: <table_description>

CREATE TABLE `<table_name>` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    <field_definitions>,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='<table_comment>';
```

#### 4.3 ALTER TABLE 语句

对于每个字段变更，生成 ALTER TABLE 语句：

```sql
-- Add column: <table_name>.<column_name>
ALTER TABLE `<table_name>` 
ADD COLUMN `<column_name>` <data_type> <nullable> <default> COMMENT '<comment>'
AFTER `<previous_column>`;

-- Modify column: <table_name>.<column_name>
ALTER TABLE `<table_name>` 
MODIFY COLUMN `<column_name>` <new_data_type> <nullable> <default> COMMENT '<comment>';
```

#### 4.4 INDEX 语句

对于索引变更：

```sql
-- Create index: <index_name>
CREATE <UNIQUE> INDEX `<index_name>` 
ON `<table_name>` (`<column_list>`)
<USING BTREE/HASH>;
```

#### 4.5 FOREIGN KEY 语句

对于外键变更：

```sql
-- Add foreign key: <fk_name>
ALTER TABLE `<table_name>` 
ADD CONSTRAINT `<fk_name>` 
FOREIGN KEY (`<column>`) REFERENCES `<ref_table>`(`<ref_column>`)
ON DELETE <action> ON UPDATE <action>;
```

### 5. Generate DML Change Script

生成 DML（数据操作语言）变更脚本：

#### 5.1 脚本头部

```sql
-- ================================================
-- Data Migration Script
-- Feature ID: <feature-id>
-- Database Type: <db-type>
-- Generated: <timestamp>
-- ================================================

-- !!! IMPORTANT: Backup data before execution !!!
-- !!! Execute DDL first, then DML !!!
```

#### 5.2 数据迁移语句

对于数据迁移需求：

```sql
-- Migrate data: <source> to <target>
-- Description: <migration_description>

INSERT INTO `<target_table>` (<target_columns>)
SELECT <source_columns>
FROM `<source_table>`
WHERE <conditions>;
```

#### 5.3 初始数据

对于初始数据需求：

```sql
-- Insert initial data: <table_name>

INSERT INTO `<table_name>` (<columns>) VALUES
(<values1>),
(<values2>);
```

### 6. Generate Rollback Scripts

生成回滚脚本：

#### 6.1 DDL 回滚脚本

```sql
-- ================================================
-- DDL Rollback Script
-- Feature ID: <feature-id>
-- Generated: <timestamp>
-- ================================================

-- This script reverses the DDL changes made by ddl_<timestamp>.sql
-- Execute ONLY if you need to rollback the changes

-- Drop new tables (if safe to do so)
-- [Generated DROP statements]

-- Remove added columns
-- [Generated ALTER statements to drop columns]

-- Remove created indexes
-- [Generated DROP INDEX statements]

-- Remove foreign keys
-- [Generated ALTER statements to drop foreign keys]
```

#### 6.2 DML 回滚脚本

```sql
-- ================================================
-- DML Rollback Script
-- Feature ID: <feature-id>
-- Generated: <timestamp>
-- ================================================

-- This script reverses the DML changes made by dml_<timestamp>.sql
-- Execute ONLY if you need to rollback the data changes

-- Delete migrated data
-- [Generated DELETE statements]

-- Restore original data values
-- [Generated UPDATE statements]
```

### 7. Generate Verification Script

生成验证脚本：

```sql
-- ================================================
-- Verification Script
-- Feature ID: <feature-id>
-- Generated: <timestamp>
-- ================================================

-- Use this script to verify changes were applied correctly

-- 1. Check new tables exist
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = '<database>' AND table_name = '<new_table>';

-- 2. Check new columns exist
SELECT COUNT(*) FROM information_schema.columns 
WHERE table_schema = '<database>' AND table_name = '<table>' 
AND column_name = '<new_column>';

-- 3. Check data count
SELECT COUNT(*) FROM `<table_name>`;

-- 4. Sample data verification
SELECT * FROM `<table_name>` LIMIT 10;
```

### 8. Save All Scripts

保存所有脚本文件：

| 脚本类型 | 路径 |
|----------|------|
| DDL 变更 | `.asdm/workspace/database-design/scripts/<feature-id>/ddl_<timestamp>.sql` |
| DML 变更 | `.asdm/workspace/database-design/scripts/<feature-id>/dml_<timestamp>.sql` |
| DDL 回滚 | `.asdm/workspace/database-design/scripts/<feature-id>/rollback_ddl_<timestamp>.sql` |
| DML 回滚 | `.asdm/workspace/database-design/scripts/<feature-id>/rollback_dml_<timestamp>.sql` |
| 验证脚本 | `.asdm/workspace/database-design/scripts/<feature-id>/verify_<timestamp>.sql` |

### 9. Update Change Plan

更新变更方案文档，添加生成的脚本引用：

```markdown
## Generated Scripts

| 脚本类型 | 文件路径 | 生成时间 |
|----------|----------|----------|
| DDL 变更 | `scripts/<feature-id>/ddl_<timestamp>.sql` | <time> |
| DML 变更 | `scripts/<feature-id>/dml_<timestamp>.sql` | <time> |
| DDL 回滚 | `scripts/<feature-id>/rollback_ddl_<timestamp>.sql` | <time> |
| DML 回滚 | `scripts/<feature-id>/rollback_dml_<timestamp>.sql` | <time> |
| 验证脚本 | `scripts/<feature-id>/verify_<timestamp>.sql` | <time> |
```

## Execution Guidelines

### When to Use This Action

使用此 action 的场景：
- 变更方案评审通过后，需要生成实际执行的脚本
- 数据库变更实施前的最终脚本准备
- 需要生成可回滚的变更脚本
- 需要验证脚本正确性

### Generation Guidelines

生成变更脚本时：
1. **语法正确**：确保 SQL 语法符合目标数据库规范
2. **可执行性**：脚本可直接在数据库中执行
3. **完整性**：包含所有必要的变更操作
4. **可回滚**：每个变更都有对应的回滚语句

### Safety Guidelines

确保脚本安全：
1. **添加注释**：每个重要操作都添加说明注释
2. **风险提示**：对高风险操作添加警告
3. **验证设计**：包含验证步骤确保变更正确
4. **事务考虑**：必要时使用事务包裹

### Database-Specific Guidelines

| 数据库 | 注意事项 |
|--------|----------|
| MySQL | 使用 `ENGINE=InnoDB`，注意 `AUTO_INCREMENT` |
| PostgreSQL | 使用 `SERIAL` 或 `GENERATED`，注意 `USING INDEX` |
| Oracle | 使用 `NUMBER`，注意 `CLOB`/`BLOB` 处理 |
| SQL Server | 使用 `IDENTITY`，注意 `NVARCHAR` |

## Usage

使用本指令，AI 模型应：
1. 检测响应语言
2. 接收脚本生成参数
3. 读取变更方案文档
4. 初始化脚本目录
5. 生成 DDL 变更脚本
6. 生成 DML 变更脚本
7. 生成回滚脚本
8. 生成验证脚本
9. 保存所有脚本
10. 更新变更方案文档

## Output Summary

完成脚本生成后，将生成以下文件：

| 脚本类型 | 路径 |
|----------|------|
| DDL 变更脚本 | `.asdm/workspace/database-design/scripts/<feature-id>/ddl_<timestamp>.sql` |
| DML 变更脚本 | `.asdm/workspace/database-design/scripts/<feature-id>/dml_<timestamp>.sql` |
| DDL 回滚脚本 | `.asdm/workspace/database-design/scripts/<feature-id>/rollback_ddl_<timestamp>.sql` |
| DML 回滚脚本 | `.asdm/workspace/database-design/scripts/<feature-id>/rollback_dml_<timestamp>.sql` |
| 验证脚本 | `.asdm/workspace/database-design/scripts/<feature-id>/verify_<timestamp>.sql` |

所有文件保存在 `.asdm/workspace/database-design/scripts/<feature-id>/` 目录。
