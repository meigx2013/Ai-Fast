# Hibernate to MyBatis Converter - Installation Guide

## Overview

本工具集帮助将 Hibernate/JPA 项目迁移到 MyBatis 框架。

## Prerequisites

- Java 项目使用 Hibernate/JPA
- IDE 或编辑器支持 ASDM 工具集
- 建议先备份项目代码

## Installation Steps

### Step 1: Setup ASDM Structure

确保项目包含 `.asdm/` 目录：

```bash
mkdir -p .asdm/workspace
```

### Step 2: Copy Toolset Files

将 `hibernate-to-mybatis` 工具集复制到项目中：

```bash
cp -r .asdm/toolsets/hibernate-to-mybatis /path/to/your/project/.asdm/toolsets/
```

### Step 3: Register Shortcuts

根据你的 AI 助手，在对应的命令目录创建快捷方式：

**For CodeBuddy:**
```bash
mkdir -p .codebuddy/commands
```

创建以下命令文件：
- `.codebuddy/commands/hibernate-analyze.md`
- `.codebuddy/commands/hibernate-convert-entity.md`
- `.codebuddy/commands/hibernate-convert-repo.md`
- `.codebuddy/commands/hibernate-convert-config.md`
- `.codebuddy/commands/hibernate-migrate.md`

**For Claude Code:**
```bash
mkdir -p .claude/commands
```

**For GitHub Copilot:**
```bash
mkdir -p .github/prompts
```

## Usage

安装完成后，可使用以下命令：

| Command | Description |
|---------|-------------|
| `/hibernate-analyze` | 分析 Hibernate 项目结构 |
| `/hibernate-convert-entity` | 转换 Entity 实体类 |
| `/hibernate-convert-repo` | 转换 Repository |
| `/hibernate-convert-config` | 转换配置文件 |
| `/hibernate-migrate` | 执行完整项目迁移 |

## Recommended Workflow

1. **分析项目**: 先运行 `/hibernate-analyze` 了解项目结构
2. **测试转换**: 使用 `/hibernate-convert-entity` 转换一个 Entity
3. **批量转换**: 确认无误后使用 `/hibernate-migrate` 批量转换
4. **验证结果**: 运行测试确保功能正常

## Troubleshooting

- 确保源文件是 UTF-8 编码
- 复杂关联关系可能需要手动调整
- 建议在版本控制下操作以便回退
