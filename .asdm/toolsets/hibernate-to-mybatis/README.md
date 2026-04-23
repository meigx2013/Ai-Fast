# ASDM Toolset - Hibernate to MyBatis Converter

toolset-id: hibernate-to-mybatis
toolset-name: Hibernate to MyBatis Converter
version: 0.0.1
updated-date: 2026-04-15
toolset-description: 将 Hibernate/JPA 代码转换为 MyBatis 代码的工具集

## Overview

Hibernate to MyBatis Converter 帮助开发者将基于 Hibernate/JPA 的项目迁移到 MyBatis 框架。提供完整的转换工作流，涵盖代码分析、Entity 转换、Repository 转换、配置文件转换等。

## Features

### Common features

- 标准化 Hibernate 到 MyBatis 转换流程
- Entity 实体类到 Mapper XML 转换
- JPA Repository 到 MyBatis DAO 转换
- 配置文件转换
- 代码质量验证

### Feature 1: analyze-hibernate - 分析项目结构

分析 Hibernate/JPA 项目结构：
- 扫描 Entity 实体类
- 识别 Repository/DAO 层
- 分析配置文件
- 生成结构报告

### Feature 2: convert-entities - 转换 Entity

将 Hibernate Entity 转换为 MyBatis：
- JPA 注解转 MyBatis 注解
- 字段类型映射
- 关联关系处理
- 生成 Mapper XML

### Feature 3: convert-repositories - 转换 Repository

转换 JPA Repository 为 MyBatis DAO：
- 接口方法转换
- @Query 注解转 XML SQL
- 分页支持转换
- 生成 DAO 接口

### Feature 4: convert-config - 转换配置文件

转换项目配置文件：
- persistence.xml 转 mybatis-config.xml
- application.properties 转 mybatis-config.xml
- 数据源配置转换
- 事务管理配置

### Feature 5: migrate-project - 完整项目迁移

执行完整项目迁移：
- 批量转换所有文件
- 依赖配置更新
- 测试代码调整
- 生成迁移报告

## Toolset Workflow

使用以下命令进行迁移：

```
/hibernate-analyze      - 分析项目结构
/hibernate-convert-entity    - 转换单个 Entity
/hibernate-convert-repo      - 转换 Repository
/hibernate-convert-config    - 转换配置文件
/hibernate-migrate           - 完整迁移
```

## Toolset Structure

```
.asdm/toolsets/hibernate-to-mybatis/
├── README.md
├── INSTALL.md
├── actions/
│   ├── analyze-hibernate.md
│   ├── convert-entity.md
│   ├── convert-repository.md
│   ├── convert-config.md
│   └── migrate-project.md
├── spec/
│   ├── entity-mapping-spec.md
│   ├── repository-mapping-spec.md
│   └── migration-report-spec.md
└── contexts/
    └── hibernate-mybatis-mapping.md
```

## Copyright & License

Copyright (c) 2026. All rights reserved.
