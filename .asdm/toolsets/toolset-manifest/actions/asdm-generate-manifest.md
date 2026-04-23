# Instructions for asdm-generate-manifest action

## Purpose

本指令引导 AI 模型为指定工具集目录生成 manifest.json 文件。它从 README.md 中提取元数据，扫描 actions/ 目录收集可用命令，引导用户输入场景信息，并生成完整的 manifest.json 文件。

## Context Injection

在执行操作之前，AI 模型应读取以下上下文文件：

### Context Files to Read

1. **index.md** (Recommended)
   - Path: `.asdm/contexts/index.md`
   - Purpose: 了解工作区概述

2. **工具集 README.md** (Required)
   - Path: `.asdm/toolsets/<toolset-id>/README.md`
   - Purpose: 提取工具集元数据（registry_id、name、description、version）

3. **Manifest Spec** (Recommended)
   - Path: `.asdm/toolsets/toolset-manifest/spec/manifest-spec.md`
   - Purpose: 了解 manifest.json 的结构规范

## Steps to Generate Manifest

### 1. 接收工具集目录路径

接收用户指定的工具集根目录路径：

- 如果用户未指定路径，提示用户输入
- 验证目录是否存在
- 验证目录是否为有效的工具集目录（包含 README.md）

### 2. 读取 README.md 提取元数据

从目标目录的 README.md 文件中提取以下信息：

- `registry_id`: 工具集唯一标识符（对应 README.md 中的 toolset-id）
- `name`: 工具集显示名称（对应 README.md 中的 toolset-name）
- `description`: 工具集描述（对应 README.md 中的 toolset-description）
- `version`: 版本号（如未找到，使用默认值 "0.0.1"）

### 3. 扫描 Actions 目录

扫描目标工具集的 `actions/` 目录：

- 列出所有 `.md` 文件（排除 `.gitkeep`）
- 提取每个 action 文件的命令名称
- 生成 commands 列表

### 4. 确认场景信息

向用户确认工具集的使用场景：

- 场景描述只需 6 个字以内
- 例如：需求分析、代码编写、工具集开发、文档整理等
- 如果 README.md 中已包含 scenario 信息，询问用户是否确认或修改

### 5. 检查现有 manifest.json

检查目标目录是否已存在 manifest.json 文件：

- 如果存在，提示用户确认是否覆盖
- 如果用户选择不覆盖，终止操作
- 如果不存在，继续生成

### 6. 生成 manifest.json

构建 manifest.json 文件：

```json
{
  "registry_id": "<toolset-id>",
  "name": "<toolset-name>",
  "description": "<toolset-description>",
  "scenario": "<toolset-scenario>",
  "version": "<version>",
  "configType": "toolset",
  "commands": ["<action-name-1>", "<action-name-2>", "..."]
}
```

### 7. 验证并保存

验证生成的 JSON 格式：

- 使用 JSON 解析器验证格式正确性
- 验证所有必需字段是否存在
- 保存到目标目录的 `manifest.json` 文件

### 8. 输出结果摘要

向用户展示生成结果：

- manifest.json 的完整内容
- 提取的元数据摘要
- 收集的命令列表
- 文件保存路径

## Execution Guidelines

### When to Use This Action

使用此 action 当：
- 需要为新创建的工具集快速生成 manifest.json
- 现有工具集缺少 manifest.json 文件
- 需要更新工具集的 manifest.json 信息
- 需要验证工具集元数据的完整性

### 输入参数指南

- **toolset-path** (必需): 目标工具集的根目录路径
- 可以是绝对路径或相对于工作区的路径

### 输出规范

manifest.json 必须包含以下字段：

| 字段 | 类型 | 描述 |
|------|------|------|
| registry_id | string | 工具集唯一标识符（注册ID） |
| name | string | 工具集显示名称 |
| description | string | 工具集功能描述 |
| scenario | string | 工具集使用场景 |
| version | string | 版本号 |
| configType | string | 配置类型，固定值为 "toolset" |
| commands | array | 可用命令列表 |

### 错误处理

- **目录不存在**: 提示用户检查路径并重试
- **README.md 不存在**: 提示用户该目录不是有效的工具集目录
- **JSON 格式错误**: 重新生成并验证
- **文件写入失败**: 检查权限并提示用户

## Usage

要使用此指令，AI 模型应：

1. 检测响应语言
2. 接收工具集目录路径
3. 读取并解析 README.md
4. 扫描 actions/ 目录
5. 引导用户输入/确认场景信息
6. 检查现有 manifest.json
7. 生成并验证 manifest.json
8. 保存文件并输出摘要

## Output Summary

完成此操作后，将生成以下文件：

- `manifest.json`: 包含完整工具集元数据的 JSON 文件

所有文件将保存在用户指定的目标工具集根目录。

生成的内容包括：

- 工具集基本信息（ID、名称、描述、版本）
- 使用场景描述
- 可用命令列表
