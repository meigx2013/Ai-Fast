# Instructions for asdm-merge-code-structures action

## Purpose
此指令指导 AI 模型将多个模块的 code-structure 文件合并为整个项目的完整分析报告。当大型代码库的各个模块分别分析完成后，使用此 action 汇总生成统一的项目级 code-structure 报告。

## Context Injection

在执行合并之前，AI 模型应读取并理解项目上下文：

### Context Files to Read (Optional)

1. **index.md** (可选)
   - 路径：`.asdm/contexts/index.md`
   - 目的：提供工作区结构概述

**重要**：如果存在，在执行步骤之前始终读取 `.asdm/contexts/index.md`。

## Steps to Merge Code Structures

### 1. 接收合并参数

从用户处接收以下参数：
- **输出文件名称**：合并后的报告文件名称（默认：`code-structure.md`）
- **要包含的模块列表**：需要合并的模块目录列表（如果为空，则扫描所有子目录）

### 2. 扫描模块目录

扫描 `.asdm/workspace/code-structure-analyzer/` 目录：
- 查找所有包含 `code-structure.md` 文件的模块目录
- 收集每个模块的分析结果

### 3. 读取模块结构文件

对于每个找到的模块目录：
- 读取 `{模块目录}/code-structure.md`
- 提取模块名称、路径、包结构和功能描述

### 4. 构建项目级报告

生成统一的代码结构分析报告：
- **路径**：`.asdm/workspace/code-structure-analyzer/{输出文件名}.md`
- **格式**：具有清晰结构的 Markdown

### 5. 报告结构

合并后的报告应包含：

1. **项目概述**
   - 总模块数
   - 分析时间
   - 项目类型（Maven/Gradle/普通目录）

2. **模块树结构**
   - 层次化的模块视图
   - 模块依赖关系（如果有）

3. **各模块详情**
   - 链接到各模块的 code-structure.md 文件
   - 简要的功能描述摘要

### 6. 呈现合并摘要

向用户呈现摘要：
- 合并的模块数量
- 生成的报告位置
- 各模块的主要功能概述

## Execution Guidelines

### 何时使用此动作

在以下情况下使用此动作：
- 多个模块分别分析完成后
- 需要生成整个项目的统一视图
- 希望一次性向 AI 提供完整的代码库上下文

### 合并指南

合并 code-structures 时：
- 保持各模块信息完整性
- 生成清晰的模块树结构
- 突出显示模块间的功能差异
- 确保文件路径链接正确

## 使用方式

要使用此指令，AI 模型应：
1. 检测响应语言
2. 从用户处接收合并参数
3. 如果可用，读取项目上下文
4. 扫描模块目录
5. 读取各模块的 code-structure.md 文件
6. 构建项目级报告
7. 呈现合并摘要

## 输出摘要

完成合并后，将生成以下文件：
- **.asdm/workspace/code-structure-analyzer/{输出文件名}.md**：项目级的完整代码结构分析报告，包含所有模块的概述和详细信息

所有文件将保存在 `.asdm/workspace/code-structure-analyzer/` 目录中。
