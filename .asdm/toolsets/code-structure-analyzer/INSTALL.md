# 代码功能结构分析 安装指南

**Toolset ID:** `code-structure-analyzer`

## 概述

本安装指南提供代码功能结构分析工具集的安装和设置说明。该工具集用于分析 Java 大型代码库的模块结构，获取多层级模块树和每个层级功能描述，为后续 AI 代码生成提供上下文。

## AI 引导安装

要使用 AI 引导安装，请将以下提示复制到 AI 编码工具的聊天窗口中：

```shell
Follow instructions in .asdm/toolsets/code-structure-analyzer/INSTALL.md
```

## 安装步骤

### 1. 创建工作区目录

代码功能结构分析工具集需要在工作区中创建以下目录结构：

```bash
mkdir -p .asdm/workspace/code-structure-analyzer
```

### 2. 检测当前的 `Agentic Engine` 提供商

检测当前 AI 编码助手提供商（例如 Claude Code、GitHub Copilot、Tencent CodeBuddy）。使用以下指南进行检测：

- 如果存在 `.claude` 目录，使用 `Claude Code`
- 如果存在 `.github` 目录，使用 `GitHub Copilot`
- 如果存在 `.codebuddy` 目录，使用 `Tencent CodeBuddy`
- 如果在当前工作区中未找到此类文件夹，请手动选择提供商

### 3. 为代码功能结构分析（Toolset ID: `code-structure-analyzer`）创建快捷命令

根据检测到的提供商，在适当的位置创建快捷命令。安装过程在所有提供商中一致——我们使用 `cat` 将提供商特定的前置配置与实际指令内容连接：

#### 对于 Claude Code (`.claude/commands/`):

Claude Code 使用带有 Frontmatter 元数据的 Markdown 文件作为斜杠命令。通过将 Claude 特定的前置配置与指令内容连接来创建命令：

```bash
mkdir -p .claude/commands/

# 代码结构分析命令
cat > .claude/commands/asdm-analyze-code-structure.md << 'EOF'
---
description: "分析 Java 代码库的模块结构，生成模块树和功能描述"
argument-hint: "[代码库路径]"
---

EOF
cat .asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md >> .claude/commands/asdm-analyze-code-structure.md
```

#### 对于 GitHub Copilot (`.github/prompts/`):

GitHub Copilot 使用带有 YAML 前置配置的 `.prompt.md` 文件。通过将 GitHub 特定的前置配置与指令内容连接来创建提示文件：

```bash
mkdir -p .github/prompts/

# 代码结构分析提示
cat > .github/prompts/asdm-analyze-code-structure.prompt.md << 'EOF'
---
agent: 'agent'
description: '分析 Java 代码库的模块结构，生成模块树和功能描述'
argument-hint: '<代码库路径>'
---

EOF
cat .asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md >> .github/prompts/asdm-analyze-code-structure.prompt.md
```

#### 对于腾讯 CodeBuddy (`.codebuddy/commands/`):

CodeBuddy 不支持前置配置，因此直接复制指令文件：

```bash
mkdir -p .codebuddy/commands/

# 复制指令文件（无需前置配置）
cp .asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md .codebuddy/commands/
```

### 4. 其他提供商的通用使用方式

如果您的 AI 编码助手提供商未被自动检测逻辑识别（Claude Code、GitHub Copilot 或 Tencent CodeBuddy），您仍可以手动使用此工具集。请按照以下步骤操作：

#### 直接使用指令

您可以通过复制相对路径并将其粘贴到 AI 编码助手的聊天窗口中来直接使用指令文件：

1. **导航到指令文件目录**：
   ```bash
   cd .asdm/toolsets/code-structure-analyzer/actions/
   ```

2. **右键点击所需的指令文件**并复制其相对路径：
   - 代码结构分析：`asdm-analyze-code-structure.md`

3. **在 AI 编码助手中输入提示**：
   ```
   Follow the instructions in .asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md
   ```

## 初始化代码功能结构分析

### 分析代码结构

安装完成后，您可以通过运行以下命令开始使用：

```shell
Follow the instructions in .asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md
```

此操作将：
- 递归扫描代码库目录结构，识别 Maven/Gradle 模块
- 分析每个模块的包结构，了解代码组织方式
- 推断每个模块的功能含义
- 生成 AI 可用的上下文文件

### 可用命令

安装完成后，您可以使用以下命令：

1. **`/asdm-analyze-code-structure`** - 分析 Java 代码库的模块结构，生成模块树和功能描述

## 工具集结构

该工具集将在 `.asdm/workspace/code-structure-analyzer/` 中创建以下结构：

```
.asdm/workspace/code-structure-analyzer/
├── code-structure.md     # AI 上下文文件（主要输出）
└── module-tree.json      # 模块树数据（可选）
```

## 规范文档

该工具集使用以下规范文档作为模板：

1. **`code-structure-spec.md`** - 代码结构分析输出格式规范

## 验证

安装后，请验证以下内容：

1. `.asdm/workspace/code-structure-analyzer` 目录存在
2. 代码功能结构分析（Toolset ID: `code-structure-analyzer`）的快捷命令已创建在相应提供商的目录中（如果您使用的是 Claude Code、GitHub Copilot 或 Tencent CodeBuddy）
3. 代码功能结构分析工具集文件位于 `.asdm/toolsets/code-structure-analyzer` 中

**对于其他提供商**：验证您可以访问以下指令文件：
- `.asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md`

## 使用示例

### 示例 1：分析当前目录的 Java 项目

```shell
# 首先，使用 AI 引导安装
Follow instructions in .asdm/toolsets/code-structure-analyzer/INSTALL.md

# 然后运行分析动作
Follow the instructions in .asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md

# 使用斜杠命令时的示例：
/asdm-analyze-code-structure
```

### 示例 2：分析指定目录的 Java 项目

```shell
# 运行分析动作
Follow the instructions in .asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md

# 使用斜杠命令时的示例：
/asdm-analyze-code-structure ./my-java-project

# 或者分析包含 pom.xml 的 Maven 项目
/asdm-analyze-code-structure ./
```

## 使用方法

### 对于支持的提供商（Claude Code、GitHub Copilot、Tencent CodeBuddy）

安装后，您可以使用以下命令：

- `/asdm-analyze-code-structure [路径]`：分析 Java 代码库的模块结构，生成模块树和功能描述

### 对于其他提供商（手动使用）

如果您的提供商未被自动检测，您可以按照上述"其他提供商的通用使用方式"部分中的步骤手动使用指令。

## 注意事项

- 此安装过程假设您具有创建目录和文件的必要权限
- 命令的实际实现将由 AI 模型使用工具集中提供的模板和指令来处理
- 请根据您的实际 AI 编码助手自定义提供商特定设置
- 工具集 ID `code-structure-analyzer` 应在命令和文档中一致使用
- **对于检测逻辑中未列出的提供商**：用户可以通过复制指令文件的相对路径并输入类似 "follow the instructions in .asdm/toolsets/code-structure-analyzer/actions/asdm-analyze-code-structure.md" 的提示来手动使用指令文件
- 此工具集专门用于分析 Java 代码库，会自动排除 `target`、`node_modules`、`.mvn`、`.idea` 等目录

## 与其他工具集成

代码功能结构分析可以与 ASDM 其他工具集和上下文文件集成。Context Builder 的上下文文件可以被引用，以将生成的文档锚定到实际项目中。

### 获取帮助

有关代码功能结构分析工具集的问题，请参阅：
- [ASDM 文档](https://asdm.ai/docs)
- 工具集 README：`.asdm/toolsets/code-structure-analyzer/README.md`
- 规范文档：`.asdm/toolsets/code-structure-analyzer/spec/`

## 许可证

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.

---

*本安装文档是代码功能结构分析工具集的一部分。*
