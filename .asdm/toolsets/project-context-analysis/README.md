# ASDM Toolset - 项目上下文分析工具集

toolset-id: project-context-analysis
toolset-name: 项目上下文分析工具集
version: 0.2.0
updated-date: 2026-04-09
toolset-description: 基于模块化架构的上下文分析工具,专为大型复杂项目设计,通过模块化方式生成完整且可追溯的项目上下文。

## Overview

项目上下文分析工具集（toolset-id `project-context-analysis`）是一个专门为大型复杂项目设计的上下文生成工具集。它采用模块化的方式,先建立项目索引,再逐模块生成详细上下文,解决了传统上下文生成工具在大型项目中生成不完整的问题。

该工具集通过以下方式确保大型项目的上下文生成完整且可追溯:
- **模块化生成**: 按模块逐个生成上下文,避免一次性生成过多内容
- **索引管理**: 生成模块索引表,跟踪每个模块的生成状态
- **渐进式加载**: 支持按需生成和更新单个模块上下文
- **状态追踪**: 记录每个模块的上下文生成状态（已生成、未生成、生成中）
- **智能细化**: 根据模块复杂度自动细化到子模块级别

用户可以安装此 `toolset` 到工作区,并通过 `AI Guided Installation` 初始化工具集。只需将以下提示复制到您的 `AI Coding` 工具的聊天窗口并按回车:

```shell
按照 .asdm/toolsets/project-context-analysis/INSTALL.md 中的指令执行
```

## Features

### 核心功能

项目上下文分析工具集提供以下核心功能:

#### 功能一: 上下文索引初始化 (`/asdm-cpc-index-init`)

初始化项目上下文索引,建立模块化上下文管理的基础。

**主要功能**:
- 在 `.asdm/contexts/` 目录下生成 `index.md` 入口文件
- 分析工作区工程结构,识别所有模块
- 生成模块索引表,包含模块名称、代码量、上下文生成状态
- 创建 `modules-index.json` 存储模块索引数据
- 支持增量更新（检测新增/删除模块）

**输入**:
- 工作区根目录路径
- 可选: 自定义排除目录列表

**输出**:
- `.asdm/contexts/index.md` - 项目上下文入口索引
- `.asdm/contexts/modules-index.json` - 模块索引数据文件

**使用场景**:
- 首次在项目中进行上下文管理
- 项目结构发生变化（新增或删除模块）
- 需要查看所有模块的上下文生成状态

#### 功能二: 模块上下文索引构建 (`/asdm-cpc-build-module-context-index`)

根据已生成的模块索引文件,创建模块上下文索引文件,并根据模块复杂度决定是否需要细化到子目录级别。

**主要功能**:
- 分析模块复杂度,评估是否需要细化
- 为复杂模块自动创建子模块索引
- 调用 SubAgent `asdm-subagent-build-submodule-context-index` 进行异步处理
- 生成 `module-context-index.json` 文件

**输入**:
- module-index 文件路径（必需）

**输出**:
- `.asdm/contexts/module-context-index.json` - 包含模块及子模块的上下文索引信息

**使用场景**:
- 模块索引初始化后,准备生成模块上下文
- 需要了解模块的复杂度和子模块分布
- 优化上下文生成粒度

#### 功能四: 全量上下文批量构建 (`/asdm-cpc-all-module-context-build`)

批量为所有模块生成上下文,支持选择性生成、进度跟踪和错误恢复。

**主要功能**:
- 批量为所有未生成上下文的模块生成上下文
- 支持选择性生成（用户选择模块）
- 提供实时进度跟踪和错误处理
- 生成批量生成摘要报告

**输入**:
- 可选参数:
  - `all`: 生成所有模块（包括已生成的）
  - `selective`: 交互式选择要生成的模块
  - `skip-generated`（默认）: 只生成未生成的模块

**输出**:
- 为每个模块生成完整的上下文文件集
- 更新项目索引文件
- 生成错误日志（如有错误）

**使用场景**:
- 首次为项目生成完整上下文
- 项目结构发生大规模变化
- 需要批量更新多个模块的上下文

#### 功能五: 工作区上下文构建 (`/asdm-cpc-workspace-context-build`)

为整个工作区生成综合上下文文档,整合所有已生成的模块上下文。

**主要功能**:
- 整合所有模块上下文信息
- 生成工作区级别的上下文文件
- 提供整体架构和部署信息
- 创建工作区索引和导航

**输入**:
- 工作区根目录路径

**输出**:
- `.asdm/contexts/project_workspace/index.md` - 工作区索引
- `.asdm/contexts/project_workspace/architecture.md` - 系统架构
- `.asdm/contexts/project_workspace/api.md` - API 汇总
- `.asdm/contexts/project_workspace/data-models.md` - 数据模型汇总
- `.asdm/contexts/project_workspace/deployment.md` - 部署配置
- `.asdm/contexts/project_workspace/standard-project-structure.md` - 标准项目结构
- `.asdm/contexts/project_workspace/standard-coding-style.md` - 标准编码风格

**使用场景**:
- 所有模块上下文生成完成后
- 需要工作区整体概览
- 准备项目文档或知识库

### 模块上下文结构

每个模块生成以下标准文档:

| 文档 | 说明 | 是否必需 |
|------|------|---------|
| `index.md` | 模块上下文入口文件 | 必需 |
| `structure.md` | 模块目录结构和组件概览 | 必需 |
| `code-style.md` | 模块编码风格规范 | 必需 |
| `data-models.md` | 数据模型定义 | 可选 |
| `api.md` | API 定义（API 模块） | 可选 |
| `components.md` | 组件/类定义 | 可选 |
| `services.md` | 服务/业务逻辑 | 可选 |

### 高级特性

- **渐进式上下文加载**: 避免一次性加载过多上下文
- **上下文状态追踪**: 跟踪每个模块的上下文生成状态
- **智能增量更新**: 检测变化,只更新需要更新的部分
- **错误恢复机制**: 支持中断恢复和失败重试
- **批量操作优化**: 智能排序和并发控制
- **模块复杂度评估**: 自动评估模块复杂度,决定是否需要细化到子模块
- **SubAgent 异步处理**: 使用 SubAgent 处理复杂模块,减少主会话上下文占用

## Toolset Installation Process

`INSTALL.md` 将按以下步骤设置工具集:

1. **创建上下文目录**: 创建 `.asdm/contexts/` 目录用于存储生成的上下文
2. **检测当前提供商**: 识别当前使用的 AI 引擎（如 CodeBuddy）
3. **注册命令**: 在提供商的命令入口点创建快捷命令
   - CodeBuddy: `.codebuddy/commands/`
   - Claude Code: `.claude/commands/`
   - GitHub Copilot: `.github/prompts/`
4. **初始化索引**: 首次运行时自动初始化上下文索引

## Toolset Workflow

安装项目上下文分析工具集后,用户可以使用以下命令:

### 推荐工作流

```markdown
## 步骤 1: 初始化上下文索引
/asdm-cpc-index-init

## 步骤 2: 构建模块上下文索引（可选,用于复杂模块细化）
/asdm-cpc-build-module-context-index

## 步骤 3: 生成模块上下文
# 选项 A: 全量构建（所有模块）
/asdm-cpc-all-module-context-build

# 选项 B: 单模块构建
/asdm-cpc-all-module-context-build <模块名>

# 选项 C: 选择性构建
/asdm-cpc-all-build selective

## 步骤 4: 生成工作区上下文（可选）
/asdm-cpc-workspace-context-build

## 步骤 5: 更新上下文（当需要时）
/asdm-cpc-build-module-context-index  <模块路径>  # 如果项目结构变化,更新索引
/asdm-cpc-all-module-context-build <模块名>  # 更新特定模块
```

### 命令参考

| 命令 | 描述 | 参数 |
|------|------|------|
| `/context-index-init` | 初始化/更新上下文索引表 | 无 |
| `/asdm-cpc-build-module-context-index` | 构建模块上下文索引（细化到子模块） | module-index 文件路径 |
| `/asdm-module-context-build <模块名>` | 为指定模块生成上下文 | 模块名（必需） |
| `/asdm-cpc-all-build [选项]` | 批量生成所有模块的上下文 | all/selective/skip-generated |
| `/asdm-cpc-workspace-context-build` | 生成工作区综合上下文 | 无 |

### 快速开始

```shell
# 1. 首次使用: 初始化索引并生成所有上下文
/context-index-init
/asdm-cpc-all-build
/asdm-cpc-workspace-context-build

# 2. 后续更新: 更新特定模块的上下文
/asdm-module-context-build <变化的模块名>

# 3. 定期维护: 项目结构变化时更新索引
/context-index-init
```

## Toolset Structure

项目上下文分析工具集具有以下结构:

```
.asdm/toolsets/project-context-analysis/
├── INSTALL.md                                    # 安装指南
├── README.md                                     # 当前文档
├── LICENSE                                       # 许可证文件
├── actions/                                      # Action 指令文件
│   ├── asdm-cpc-index-init.md                    # 初始化上下文索引
│   ├── asdm-cpc-build-module-context-indext.md   # 构建模块上下文索引
│   ├── asdm-cpc-all-build.md                     # 全量上下文构建
│   └── asdm-cpc-workspace-context-build.md       # 工作区上下文构建
└── spec/                                         # 模板和规范文件
    ├── index.md                                  # 工作区索引模板
    ├── architecture.md                           # 架构概述模板
    ├── api.md                                    # API 定义模板
    ├── data-models.md                            # 数据模型模板
    ├── deployment.md                             # 部署配置模板
    ├── standard-coding-style.md                  # 编码风格模板
    └── standard-project-structure.md             # 项目结构模板
```

### Actions 目录

| Action 文件 | 用途 |
|------------|------|
| `asdm-cpc-index-init.md` | 初始化上下文索引表,分析项目结构 |
| `asdm-cpc-build-module-context-indext.md` | 构建模块上下文索引,根据复杂度细化到子模块 |
| `asdm-cpc-all-build.md` | 批量生成所有模块的上下文 |
| `asdm-cpc-workspace-context-build.md` | 生成工作区综合上下文文档 |

### Spec 目录

| Spec 文件 | 用途 |
|----------|------|
| `index.md` | 工作区索引模板 |
| `architecture.md` | 系统架构概述模板 |
| `api.md` | API 定义和文档模板 |
| `data-models.md` | 数据模型和关系模板 |
| `deployment.md` | 部署配置模板 |
| `standard-coding-style.md` | 编码风格规范模板 |
| `standard-project-structure.md` | 项目结构模板 |

## Toolset Workspace

项目上下文分析工具集的工作区结构如下:

```
.asdm/contexts/
├── index.md                             # 项目上下文入口索引
├── modules-index.json                   # 模块索引数据
├── module-context-index.json            # 模块上下文索引（含子模块信息）
│
├── project_workspace/                   # 工作区上下文目录
│   ├── index.md                         # 工作区索引
│   ├── architecture.md                  # 系统架构
│   ├── api.md                           # API 汇总
│   ├── data-models.md                   # 数据模型汇总
│   ├── deployment.md                    # 部署配置
│   ├── standard-project-structure.md    # 标准项目结构
│   └── standard-coding-style.md         # 标准编码风格
│
├── <module-1>/                          # 模块上下文目录
│   ├── index.md                         # 模块入口
│   ├── structure.md                     # 模块结构
│   ├── code-style.md                    # 编码风格
│   ├── data-models.md                   # 数据模型
│   ├── api.md                           # API 定义
│   ├── components.md                    # 组件定义
│   └── services.md                      # 服务逻辑
│
├── <module-2>/
│   └── ...
│
└── [其他模块...]
```

### 文件说明

- **index.md**: 项目级别的上下文入口,提供整体概览和模块导航
- **modules-index.json**: 模块索引数据,包含所有模块的状态和统计信息
- **module-context-index.json**: 模块上下文索引,包含子模块信息和复杂度评估
- **project_workspace/**: 工作区上下文目录,包含整体架构和汇总信息
- **模块目录**: 每个模块的独立上下文目录,包含该模块的详细文档

## SubAgent 集成

工具集使用以下 SubAgent 进行异步处理:

### asdm-subagent-build-submodule-context-index

用于创建单个模块的子模块上下文索引,支持复杂模块的细化分析。

**主要功能**:
- 分析模块代码结构和复杂度
- 评估是否需要细化到子模块
- 创建子模块索引信息
- 返回复杂度评分和建议

**调用场景**:
- 由 `/asdm-cpc-build-module-context-index` 命令调用
- 处理大型模块时自动触发
- 减少主会话的上下文占用

### asdm-module-context-build

用于生成单个模块的详细上下文文档。

**主要功能**:
- 分析模块代码和结构
- 生成标准化的上下文文档
- 支持多种文件类型识别
- 提供上下文生成状态反馈

**调用场景**:
- 由 `/asdm-cpc-all-build` 命令批量调用
- 由 `/asdm-module-context-build` 命令单独调用
- 支持错误恢复和重试

## 与 Context Builder 的关系

项目上下文分析工具集是对原有 Context Builder 工具集的增强和扩展:

### 改进点

1. **模块化设计**:
   - Context Builder: 一次性生成整个项目的上下文
   - Project Context Analysis: 按模块逐个生成,更适合大型项目

2. **状态管理**:
   - Context Builder: 无状态追踪
   - Project Context Analysis: 完整的生成状态追踪和管理

3. **渐进式加载**:
   - Context Builder: 全量加载
   - Project Context Analysis: 支持按需加载单个模块

4. **错误恢复**:
   - Context Builder: 生成失败需要重新开始
   - Project Context Analysis: 支持中断恢复和失败重试

5. **复杂度感知**:
   - Context Builder: 统一粒度处理
   - Project Context Analysis: 根据模块复杂度自动细化

6. **工作区级别上下文**:
   - Context Builder: 仅生成模块上下文
   - Project Context Analysis: 额外生成工作区综合上下文

### 兼容性

- 两个工具集可以共存
- 复用 Context Builder 的 spec 模板
- 调用 Context Builder 的 `asdm-context-build` 命令
- 输出格式保持一致,便于 AI 模型理解

## 使用示例

### 示例 1: 首次为大型项目生成上下文

```bash
# 1. 初始化索引
/asdm-cpc-index-init

# 查看输出:
# 上下文索引初始化完成！
# 项目统计:
# - 模块总数: 25 个
# - 已生成上下文: 0 个
# - 未生成上下文: 25 个
# - 总代码量: 150,000 行

# 2. 构建模块上下文索引（可选,用于复杂模块）
/asdm-cpc-build-module-context-index .asdm/contexts/modules-index.json

# 3. 批量生成所有模块上下文
/asdm-cpc-all-build

# 查看进度:
# 处理模块 1/25: fineract-provider
# 处理模块 2/25: fineract-accounting
# ...

# 4. 生成工作区上下文
/asdm-cpc-workspace-context-build
```

### 示例 2: 更新单个模块的上下文

```bash
# 当 fineract-accounting 模块代码发生变化时
/asdm-module-context-build fineract-accounting

# 查看输出:
# 模块上下文生成完成！
# 模块: fineract-accounting
# 生成的文件:
# - .asdm/contexts/fineract-accounting/index.md
# - .asdm/contexts/fineract-accounting/structure.md
# - .asdm/contexts/fineract-accounting/api.md
# ...
```

### 示例 3: 选择性生成模块上下文

```bash
# 只生成特定模块的上下文
/asdm-cpc-all-build module1,module2...

# AI 会显示模块列表供选择:
# 可用模块:
# 1. fineract-provider (未生成)
# 2. fineract-accounting (已生成)
# 3. fineract-branch (未生成)
# ...
# 请选择要生成的模块编号: 1,3,5
```

## 故障排除

### 问题: 命令未找到

**原因**: 命令文件未正确复制到命令目录

**解决方案**:
```bash
# 检查命令文件是否存在
ls .codebuddy/commands/  # 或 .claude/commands/ 或 .github/prompts/

# 如果文件不存在,重新执行安装步骤
```

### 问题: 上下文索引生成失败

**原因**: `.asdm/contexts` 目录不存在或权限不足

**解决方案**:
```bash
# 创建目录
mkdir -p .asdm/contexts

# 检查权限
ls -la .asdm/
```

### 问题: 模块上下文生成不完整

**原因**: 生成过程中被中断或资源不足

**解决方案**:
```bash
# 检查生成状态
cat .asdm/contexts/module-context-index.json

# 重新生成失败的模块
/asdm-module-context-build <失败的模块名>
```

### 问题: SubAgent 执行超时

**原因**: 模块过大或复杂度过高

**解决方案**:
```bash
# 检查模块复杂度评分
cat .asdm/contexts/module-context-index.json | grep "complexityScore"

# 如果评分 > 50,建议先细化模块
# 或使用工作区上下文生成命令
/asdm-cpc-workspace-context-build
```

## 最佳实践

1. **首次使用**:
   - 先运行 `/context-index-init` 了解项目结构
   - 使用 `/asdm-cpc-all-build` 批量生成上下文
   - 最后运行 `/asdm-cpc-workspace-context-build` 生成工作区上下文

2. **日常使用**:
   - 当模块代码变化时,只更新该模块上下文
   - 当项目结构变化时,重新初始化索引
   - 定期检查和更新工作区上下文

3. **大型项目**:
   - 使用 `/asdm-cpc-build-module-context-index` 评估模块复杂度
   - 对于复杂模块,使用子模块级别的上下文
   - 采用渐进式生成,避免一次性生成过多内容

4. **团队协作**:
   - 将 `.asdm/contexts/` 目录纳入版本控制
   - 在代码审查时同步更新上下文
   - 使用工作区上下文作为项目文档基础

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
