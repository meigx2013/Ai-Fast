# 数据库变更脚本模板规范

## Language Guidelines

本文档必须使用环境中检测到的响应语言。确保所有内容遵循：

1. **语言一致性**：整个文档使用同一种语言
2. **书写惯例**：遵循检测语言的书写风格和格式
3. **清晰性**：确保内容清晰易懂

**支持的语言**:
- 中文 (zh)
- 英文 (en)

---

## Overview

本规范定义了数据库变更脚本（DDL、DML、回滚脚本）的结构和格式要求。此类脚本用于记录和应用数据库变更操作，必须可直接执行并支持回滚。

**主要用途**:
- 生成可直接执行的数据库变更脚本
- 记录数据库变更历史
- 支持变更回滚
- 版本化管理数据库变更

---

## Document Structure

### DDL 变更脚本结构

```sql
-- ================================================
-- Database DDL Change Script
-- Feature ID: <feature-id>
-- Database Type: <MySQL/PostgreSQL/Oracle/SQL Server>
-- Generated: <YYYY-MM-DD HH:mm:ss>
-- Version: <v1.0>
-- ================================================

-- !!! IMPORTANT: Please review all statements before execution !!!
-- !!! Execute this script in a transaction or with backup !!!
-- !!! Backup your database before running this script !!!

-- ================================================
-- Pre-checks Section
-- ================================================
-- Verify database state before changes
-- [Add verification queries here]

-- Check if tables exist before creating
SELECT COUNT(*) 
FROM information_schema.tables 
WHERE table_schema = '<database>' AND table_name = '<table_name>';

-- ================================================
-- Create New Tables Section
-- ================================================
-- Description: <description>

-- Create table: <table_name>
-- Description: <table_description>

CREATE TABLE `<table_name>` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    <field_definitions>,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='<table_comment>';

-- ================================================
-- Add Columns Section
-- ================================================
-- Description: Add new columns to existing tables

-- Add column: <table_name>.<column_name>
ALTER TABLE `<table_name>` 
ADD COLUMN `<column_name>` <data_type> <nullable> <default> COMMENT '<comment>'
AFTER `<previous_column>`;

-- ================================================
-- Modify Columns Section
-- ================================================
-- Description: Modify existing column definitions

-- Modify column: <table_name>.<column_name>
ALTER TABLE `<table_name>` 
MODIFY COLUMN `<column_name>` <new_data_type> <nullable> <default> COMMENT '<comment>';

-- ================================================
-- Drop Columns Section
-- ================================================
-- Description: Drop unused columns

-- Drop column: <table_name>.<column_name>
ALTER TABLE `<table_name>` 
DROP COLUMN `<column_name>`;

-- ================================================
-- Create Indexes Section
-- ================================================
-- Description: Create new indexes

-- Create index: <index_name>
CREATE <UNIQUE> INDEX `<index_name>` 
ON `<table_name>` (`<column_list>`)
<USING BTREE/HASH>;

-- ================================================
-- Drop Indexes Section
-- ================================================
-- Description: Drop unused indexes

-- Drop index: <index_name>
DROP INDEX `<index_name>` ON `<table_name>`;

-- ================================================
-- Add Foreign Keys Section
-- ================================================
-- Description: Add foreign key constraints

-- Add foreign key: <fk_name>
ALTER TABLE `<table_name>` 
ADD CONSTRAINT `<fk_name>` 
FOREIGN KEY (`<column>`) REFERENCES `<ref_table>`(`<ref_column>`)
ON DELETE <action> ON UPDATE <action>;

-- ================================================
-- Drop Foreign Keys Section
-- ================================================
-- Description: Drop foreign key constraints

-- Drop foreign key: <fk_name>
ALTER TABLE `<table_name>` 
DROP FOREIGN KEY `<fk_name>`;

-- ================================================
-- Post-checks Section
-- ================================================
-- Verify changes were applied correctly

-- Check new tables exist
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = '<database>' AND table_name = '<new_table>';

-- Check new columns exist
SELECT COUNT(*) FROM information_schema.columns 
WHERE table_schema = '<database>' AND table_name = '<table>' 
AND column_name = '<new_column>';

-- ================================================
-- End of Script
-- ================================================
```

### DML 变更脚本结构

```sql
-- ================================================
-- Database DML Change Script
-- Feature ID: <feature-id>
-- Database Type: <MySQL/PostgreSQL/Oracle/SQL Server>
-- Generated: <YYYY-MM-DD HH:mm:ss>
-- Version: <v1.0>
-- ================================================

-- !!! IMPORTANT: Backup data before execution !!!
-- !!! Execute DDL first, then DML !!!
-- !!! This script modifies data, please review carefully !!!

-- ================================================
-- Pre-checks Section
-- ================================================
-- Check data before migration

SELECT COUNT(*) FROM `<table_name>`;

-- ================================================
-- Data Migration Section
-- ================================================
-- Description: <migration_description>

-- Migrate data: <source> to <target>
-- Logic: <transformation_logic>

INSERT INTO `<target_table>` (<target_columns>)
SELECT <source_columns>
FROM `<source_table>`
WHERE <conditions>;

-- ================================================
-- Initial Data Section
-- ================================================
-- Description: Insert initial/seed data

-- Insert initial data: <table_name>

INSERT INTO `<table_name>` (<columns>) VALUES
(<values1>),
(<values2>),
(<values3>);

-- ================================================
-- Data Cleanup Section
-- ================================================
-- Description: Clean up old/unused data

-- Delete old data: <table_name>
DELETE FROM `<table_name>` 
WHERE <conditions>;

-- ================================================
-- Update Data Section
-- ================================================
-- Description: Update existing data

-- Update data: <table_name>
UPDATE `<table_name>` 
SET <column> = <value>
WHERE <conditions>;

-- ================================================
-- Post-checks Section
-- ================================================
-- Verify data changes

SELECT COUNT(*) FROM `<table_name>`;

-- ================================================
-- End of Script
-- ================================================
```

### DDL 回滚脚本结构

```sql
-- ================================================
-- DDL Rollback Script
-- Feature ID: <feature-id>
-- Generated: <YYYY-MM-DD HH:mm:ss>
-- Version: <v1.0>
-- ================================================

-- !!! IMPORTANT: Execute ONLY if you need to rollback the changes !!!
-- !!! This script will reverse the DDL changes made by ddl_<timestamp>.sql !!!
-- !!! Please backup your database before executing !!!

-- ================================================
-- Drop Foreign Keys (Reverse Order)
-- ================================================
-- Reverse: Add foreign key: <fk_name>

ALTER TABLE `<table_name>` 
DROP FOREIGN KEY `<fk_name>`;

-- ================================================
-- Drop Indexes (Reverse Order)
-- ================================================
-- Reverse: Create index: <index_name>

DROP INDEX `<index_name>` ON `<table_name>`;

-- ================================================
-- Drop Columns (Reverse Order)
-- ================================================
-- Reverse: Add column: <table_name>.<column_name>
-- Note: This will lose data!

ALTER TABLE `<table_name>` 
DROP COLUMN `<column_name>`;

-- ================================================
-- Drop Tables (Reverse Order)
-- ================================================
-- Reverse: Create table: <table_name>
-- Note: This will delete all data!

DROP TABLE IF EXISTS `<table_name>`;

-- ================================================
-- End of Rollback Script
-- ================================================
```

### DML 回滚脚本结构

```sql
-- ================================================
-- DML Rollback Script
-- Feature ID: <feature-id>
-- Generated: <YYYY-MM-DD HH:mm:ss>
-- Version: <v1.0>
-- ================================================

-- !!! IMPORTANT: Execute ONLY if you need to rollback the data changes !!!
-- !!! This script will reverse the DML changes made by dml_<timestamp>.sql !!!
-- !!! Please backup your data before executing !!!

-- ================================================
-- Restore Data (Reverse Order)
-- ================================================
-- Reverse: Update data: <table_name>

UPDATE `<table_name>` 
SET <column> = <original_value>
WHERE <conditions>;

-- ================================================
-- Delete Migrated Data (Reverse Order)
-- ================================================
-- Reverse: Migrate data: <source> to <target>

DELETE FROM `<target_table>` 
WHERE <migration_identifier>;

-- ================================================
-- Delete Initial Data (Reverse Order)
-- ================================================
-- Reverse: Insert initial data: <table_name>

DELETE FROM `<table_name>` 
WHERE <initial_data_identifier>;

-- ================================================
-- End of Rollback Script
-- ================================================
```

### 验证脚本结构

```sql
-- ================================================
-- Verification Script
-- Feature ID: <feature-id>
-- Generated: <YYYY-MM-DD HH:mm:ss>
-- ================================================

-- Use this script to verify changes were applied correctly

-- ================================================
-- 1. Check New Tables Exist
-- ================================================
SELECT 
    table_name,
    table_comment,
    table_rows
FROM information_schema.tables 
WHERE table_schema = '<database>' 
AND table_name IN ('<table1>', '<table2>');

-- ================================================
-- 2. Check New Columns Exist
-- ================================================
SELECT 
    table_name,
    column_name,
    data_type,
    column_comment
FROM information_schema.columns 
WHERE table_schema = '<database>' 
AND table_name = '<table_name>'
AND column_name IN ('<column1>', '<column2>');

-- ================================================
-- 3. Check Indexes
-- ================================================
SELECT 
    table_name,
    index_name,
    column_name,
    non_unique
FROM information_schema.statistics 
WHERE table_schema = '<database>' 
AND table_name = '<table_name>'
ORDER BY index_name, seq_in_index;

-- ================================================
-- 4. Check Foreign Keys
-- ================================================
SELECT 
    table_name,
    constraint_name,
    column_name,
    referenced_table_name,
    referenced_column_name
FROM information_schema.key_column_usage 
WHERE table_schema = '<database>'
AND referenced_table_name IS NOT NULL;

-- ================================================
-- 5. Check Data Count
-- ================================================
SELECT COUNT(*) AS row_count FROM `<table_name>`;

-- ================================================
-- 6. Sample Data Verification
-- ================================================
SELECT * FROM `<table_name>` LIMIT 10;

-- ================================================
-- End of Verification Script
-- ================================================
```

---

## SQL 语法规范

### MySQL 语法

```sql
-- CREATE TABLE
CREATE TABLE `<table_name>` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '名称',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0-禁用，1-正常',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_name` (`name`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='<table_comment>';

-- ADD COLUMN
ALTER TABLE `<table_name>` 
ADD COLUMN `<column_name>` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '<comment>'
AFTER `<previous_column_name>`;

-- MODIFY COLUMN
ALTER TABLE `<table_name>` 
MODIFY COLUMN `<column_name>` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '<new_comment>';

-- DROP COLUMN
ALTER TABLE `<table_name>` 
DROP COLUMN `<column_name>`;

-- CREATE INDEX
CREATE INDEX `idx_<table>_<column>` ON `<table_name>` (`<column>`);
CREATE UNIQUE INDEX `uk_<table>_<column>` ON `<table_name>` (`<column>`);

-- ADD FOREIGN KEY
ALTER TABLE `<table_name>` 
ADD CONSTRAINT `fk_<table>_<ref_table>` 
FOREIGN KEY (`<column>`) REFERENCES `<ref_table>`(`<ref_column>`)
ON DELETE CASCADE ON UPDATE CASCADE;
```

### PostgreSQL 语法

```sql
-- CREATE TABLE
CREATE TABLE <table_name> (
    id BIGINT NOT NULL DEFAULT nextval('<sequence>'),
    name VARCHAR(100) NOT NULL DEFAULT '',
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE SEQUENCE <table_name>_id_seq;

-- ADD COLUMN
ALTER TABLE <table_name> 
ADD COLUMN <column_name> VARCHAR(50) NOT NULL DEFAULT '';

-- CREATE INDEX
CREATE INDEX idx_<table>_<column> ON <table_name> (<column>);
CREATE UNIQUE INDEX uk_<table>_<column> ON <table_name> (<column>);

-- ADD FOREIGN KEY
ALTER TABLE <table_name> 
ADD CONSTRAINT fk_<table>_<ref_table> 
FOREIGN KEY (<column>) REFERENCES <ref_table>(<ref_column>)
ON DELETE CASCADE ON UPDATE CASCADE;
```

---

## Output Format

数据库变更脚本应输出为：

**DDL 变更脚本**:
- **Format**: SQL (.sql)
- **Location**: `.asdm/workspace/database-design/scripts/<feature-id>/ddl_<timestamp>.sql`
- **Naming**: `ddl_<YYYYMMDDHHMMSS>.sql`

**DML 变更脚本**:
- **Format**: SQL (.sql)
- **Location**: `.asdm/workspace/database-design/scripts/<feature-id>/dml_<timestamp>.sql`
- **Naming**: `dml_<YYYYMMDDHHMMSS>.sql`

**DDL 回滚脚本**:
- **Format**: SQL (.sql)
- **Location**: `.asdm/workspace/database-design/scripts/<feature-id>/rollback_ddl_<timestamp>.sql`
- **Naming**: `rollback_ddl_<YYYYMMDDHHMMSS>.sql`

**DML 回滚脚本**:
- **Format**: SQL (.sql)
- **Location**: `.asdm/workspace/database-design/scripts/<feature-id>/rollback_dml_<timestamp>.sql`
- **Naming**: `rollback_dml_<YYYYMMDDHHMMSS>.sql`

**验证脚本**:
- **Format**: SQL (.sql)
- **Location**: `.asdm/workspace/database-design/scripts/<feature-id>/verify_<timestamp>.sql`
- **Naming**: `verify_<YYYYMMDDHHMMSS>.sql`

---

## Best Practices

### 脚本编写规范

1. **注释清晰**: 每个重要操作都添加说明注释
2. **分段组织**: 使用分隔符组织不同类型的操作
3. **前后检查**: 包含验证查询确保变更正确
4. **安全警告**: 对高风险操作添加警告注释

### 常见注意事项

| 数据库 | 注意事项 |
|--------|----------|
| MySQL | 使用 `ENGINE=InnoDB`，注意 `AUTO_INCREMENT` |
| PostgreSQL | 使用 `SERIAL` 或 `GENERATED`，注意 `USING INDEX` |
| Oracle | 使用 `NUMBER`，注意 `CLOB`/`BLOB` 处理 |
| SQL Server | 使用 `IDENTITY`，注意 `NVARCHAR` |

### Common Pitfalls to Avoid

- **语法错误**: 确保 SQL 语法符合目标数据库规范
- **遗漏语句**: 变更内容要完整，无遗漏
- **顺序错误**: 按照依赖关系排序（先创建后引用）
- **回滚遗漏**: 每个变更都要有对应的回滚语句

---

## Related Documents

This spec template works with:

- **spec/change-plan-spec.md**: 变更方案规范（脚本基于变更方案生成）
- **spec/db-structure-spec.md**: 数据库结构分析规范（参考现有结构）

This spec is used by:

- **Action: asdm-db-generate**: 生成数据库变更脚本
- **Action: asdm-db-full**: 完整流程中的脚本生成阶段

---

## Checklist

生成数据库变更脚本前，检查：

- [ ] 脚本头部信息完整（Feature ID、数据库类型、时间戳）
- [ ] 所有 SQL 语句语法正确
- [ ] 语句顺序符合依赖关系
- [ ] 包含前后验证语句
- [ ] 高风险操作有警告注释
- [ ] 回滚脚本与正向脚本对应
- [ ] 验证脚本包含必要的检查项
- [ ] 数据库类型选择正确
