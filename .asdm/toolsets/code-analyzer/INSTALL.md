# 代码分析工具集 安装指南

**工具集 ID：** `code-analyzer`

## 概述

本文档提供安装和设置代码分析工具集的说明。代码分析工具集是一个用于代码库分析和资产识别的 ASDM 工具集，帮助开发团队快速了解代码库的结构和规模，识别代码库中的核心资产（高引用类/方法）。

## AI 引导安装

要使用 AI 引导安装此工具集，请将以下提示复制粘贴到您的 AI 编程助手的聊天窗口：

```shell
Follow instructions in .asdm/toolsets/code-analyzer/INSTALL.md
```

## 安装步骤

### 1. 创建工作区目录

根据工具集工作区结构，创建以下目录：

```bash
mkdir -p .asdm/workspace/code-analyzer/analysis-reports/file-analysis
mkdir -p .asdm/workspace/code-analyzer/analysis-reports/core-assets
mkdir -p .asdm/workspace/code-analyzer/config
mkdir -p .asdm/workspace/code-analyzer/temp
```

**目录说明**：
- `analysis-reports/file-analysis/`：存储文件分析报告
- `analysis-reports/core-assets/`：存储核心资产分析报告
- `config/`：工具集配置文件
- `temp/`：临时缓存文件，分析完成后可清理

### 2. 检测当前的 `Agentic Engine` 提供商

检测当前 AI 编程助手提供商（如 Claude Code、GitHub Copilot、Tencent CodeBuddy）。使用以下指南进行检测：

- 如果存在 `.claude` 目录，使用 `Claude Code`
- 如果存在 `.github` 目录，使用 `GitHub Copilot`
- 如果存在 `.codebuddy` 目录，使用 `Tencent CodeBuddy`
- 如果在当前工作区中未找到此类文件夹，请手动选择提供商

### 3. 为代码分析工具集（工具集 ID：`code-analyzer`）创建快捷命令

根据检测到的提供商，在相应位置创建快捷命令。安装过程在所有提供商中一致——我们使用 `cat` 将提供商特定的前导内容与实际指令内容连接：

#### 对于 Claude Code（`.claude/commands/`）：

Claude Code 使用带有 Frontmatter 元数据的 Markdown 文件作为斜杠命令。创建命令时，将 Claude 特定的前导内容与指令内容连接：

```bash
mkdir -p .claude/commands/

# file-analyze 命令
cat > .claude/commands/file-analyze.md << 'EOF'
---
description: "分析指定目录下的所有代码文件，输出文件大小和含义描述"
argument-hint: "[分析路径]"
---

EOF
cat .asdm/toolsets/code-analyzer/actions/file-analyze.md >> .claude/commands/file-analyze.md

# core-asset-identify 命令
cat > .claude/commands/core-asset-identify.md << 'EOF'
---
description: "分析代码中的核心资产，识别高引用类/方法"
argument-hint: "[代码库路径]"
---

EOF
cat .asdm/toolsets/code-analyzer/actions/core-asset-identify.md >> .claude/commands/core-asset-identify.md

# code-summary 命令
cat > .claude/commands/code-summary.md << 'EOF'
---
description: "快速获取整个工作区的代码概览"
argument-hint: "[分析范围]"
---

EOF
cat .asdm/toolsets/code-analyzer/actions/code-summary.md >> .claude/commands/code-summary.md
```

#### 对于 GitHub Copilot（`.github/prompts/`）：

GitHub Copilot 使用带有 YAML 前导内容的 `.prompt.md` 文件。创建提示文件时，将 GitHub 特定的前导内容与指令内容连接：

```bash
mkdir -p .github/prompts/

# file-analyze 提示
cat > .github/prompts/file-analyze.prompt.md << 'EOF'
---
agent: 'agent'
description: '分析指定目录下的所有代码文件，输出文件大小和含义描述'
argument-hint: '<分析路径>'
---

EOF
cat .asdm/toolsets/code-analyzer/actions/file-analyze.md >> .github/prompts/file-analyze.prompt.md

# core-asset-identify 提示
cat > .github/prompts/core-asset-identify.prompt.md << 'EOF'
---
agent: 'agent'
description: '分析代码中的核心资产，识别高引用类/方法'
argument-hint: '<代码库路径>'
---

EOF
cat .asdm/toolsets/code-analyzer/actions/core-asset-identify.md >> .github/prompts/core-asset-identify.prompt.md

# code-summary 提示
cat > .github/prompts/code-summary.prompt.md << 'EOF'
---
agent: 'agent'
description: '快速获取整个工作区的代码概览'
argument-hint: '<分析范围>'
---

EOF
cat .asdm/toolsets/code-analyzer/actions/code-summary.md >> .github/prompts/code-summary.prompt.md
```

#### 对于 Tencent CodeBuddy（`.codebuddy/commands/`）：

CodeBuddy 不支持前导内容，因此直接复制指令文件：

```bash
mkdir -p .codebuddy/commands/

# 复制指令文件（无需前导内容）
cp .asdm/toolsets/code-analyzer/actions/file-analyze.md .codebuddy/commands/
cp .asdm/toolsets/code-analyzer/actions/core-asset-identify.md .codebuddy/commands/
cp .asdm/toolsets/code-analyzer/actions/code-summary.md .codebuddy/commands/
```

### 4. 其他提供商的手动使用

如果您的 AI 编程助手提供商未被自动检测逻辑覆盖（Claude Code、GitHub Copilot 或 Tencent CodeBuddy），您仍然可以手动使用代码分析工具集。请按照以下步骤操作：

#### 直接使用指令

您可以通过复制相对路径并将其粘贴到 AI 编程助手的聊天窗口来直接使用指令文件：

1. **导航到指令文件**：
   ```bash
   cd .asdm/toolsets/code-analyzer/actions/
   ```

2. **右键点击所需的指令文件**并复制其相对路径：
   - 文件分析：`file-analyze.md`
   - 核心资产识别：`core-asset-identify.md`
   - 代码概览：`code-summary.md`

3. **在 AI 编程助手中输入提示**：
   ```
   Follow the instructions in .asdm/toolsets/code-analyzer/actions/file-analyze.md
   ```

## 初始化代码分析工具集

### 文件分析

安装完成后，您可以通过运行以下命令开始：

```shell
Follow the instructions in .asdm/toolsets/code-analyzer/actions/file-analyze.md
```

此命令将：
- 扫描指定目录下的所有代码文件
- 统计每个文件的大小和代码行数
- 生成简洁的中文含义描述
- 生成 Markdown 格式的分析报告

### 核心资产识别

完成文件分析后，您可以运行：

```shell
Follow the instructions in .asdm/toolsets/code-analyzer/actions/core-asset-identify.md
```

此命令将：
- 分析代码中的引用关系
- 识别被引用 3 次及以上的类和方法
- 生成核心资产列表和依赖关系分析

### 代码概览

如果您需要快速了解整个工作区：

```shell
Follow the instructions in .asdm/toolsets/code-analyzer/actions/code-summary.md
```

此命令将：
- 结合文件分析和核心资产识别
- 生成综合性的代码库摘要报告
- 提供关键发现和建议

### 可用命令

安装完成后，您可以使用以下命令：

1. **`/file-analyze`** - 分析指定路径下的所有代码文件，输出文件大小和含义描述
2. **`/core-asset-identify`** - 分析代码中的核心资产，识别高引用类/方法
3. **`/code-summary`** - 快速获取整个工作区的代码概览

## 工具集结构

工具集将在 `.asdm/workspace/code-analyzer/` 中创建以下结构：

```
.asdm/workspace/code-analyzer/
├── analysis-reports/
│   ├── file-analysis/
│   │   └── <时间戳>-file-analysis.md
│   └── core-assets/
│       └── <时间戳>-core-assets.md
├── config/
│   └── analyzer-config.json
└── temp/
    └── <临时分析缓存文件>
```

## 规格文档

工具集使用以下规格文档作为模板：

1. **`file-analyze-spec.md`** - 用于生成包含代码统计和中文描述的文件分析报告
2. **`core-asset-identify-spec.md`** - 用于生成包含引用次数和依赖分析的核心资产识别报告
3. **`code-summary-spec.md`** - 用于生成结合文件分析和核心资产识别的综合代码摘要报告

## 验证

安装完成后，请验证以下内容：

1. ✅ `.asdm/workspace/code-analyzer/` 目录已创建，包含 `analysis-reports/`、`config/` 和 `temp/` 子目录
2. ✅ 代码分析工具集（工具集 ID：`code-analyzer`）的快捷命令已创建在相应提供商的目录中（如果使用 Claude Code、GitHub Copilot 或 Tencent CodeBuddy）
3. ✅ 代码分析工具集文件位于 `.asdm/toolsets/code-analyzer/`（工具集 ID：`code-analyzer`）

**对于其他提供商**：验证您可以访问以下指令文件：
- `.asdm/toolsets/code-analyzer/actions/file-analyze.md`
- `.asdm/toolsets/code-analyzer/actions/core-asset-identify.md`
- `.asdm/toolsets/code-analyzer/actions/code-summary.md`

## 使用示例

### 示例 1：快速分析项目结构

```shell
# 首先使用 AI 引导安装工具集
Follow instructions in .asdm/toolsets/code-analyzer/INSTALL.md

# 然后运行文件分析
Follow the instructions in .asdm/toolsets/code-analyzer/actions/file-analyze.md

# 使用斜杠命令时的示例：
/file-analyze ./src
```

### 示例 2：识别核心资产

```shell
# 运行核心资产识别
Follow the instructions in .asdm/toolsets/code-analyzer/actions/core-asset-identify.md

# 使用斜杠命令时的示例：
/core-asset-identify ./src
```

### 示例 3：获取完整代码概览

```shell
# 运行代码概览分析
Follow the instructions in .asdm/toolsets/code-analyzer/actions/code-summary.md

# 使用斜杠命令时的示例：
/code-summary
```

## 使用方法

### 对于支持的提供商（Claude Code、GitHub Copilot、Tencent CodeBuddy）

安装后，您可以使用以下命令：

- `/file-analyze`：分析指定目录下的所有代码文件，输出文件大小和含义描述
- `/core-asset-identify`：分析代码中的核心资产，识别高引用类/方法
- `/code-summary`：快速获取整个工作区的代码概览

### 对于其他提供商（手动使用）

如果您的提供商未被自动检测，您可以通过以下方式手动使用指令：
1. 导航到 `.asdm/toolsets/code-analyzer/actions/` 目录
2. 复制所需的指令文件路径
3. 输入提示："Follow the instructions in {相对路径}"

## 注意事项

- 此安装过程假设您具有创建目录和文件的必要权限
- 命令的实际实现将由 AI 模型使用工具集提供的模板和指令来完成
- 根据您的实际 AI 编程助手自定义提供商特定的设置
- 工具集 ID `code-analyzer` 应在命令和文档中一致使用
- **对于不在检测逻辑中的提供商**：用户可以通过复制相对路径并输入类似 "Follow the instructions in .asdm/toolsets/code-analyzer/actions/file-analyze.md" 的提示来手动使用指令文件
- 建议在首次分析前配置 `analyzer-config.json` 文件以自定义分析选项

## 与其他工具集成

代码分析工具集可以与 ASDM 的其他工具集和上下文文件集成。来自上下文构建器的上下文文件可用于将生成的文档锚定到实际项目。

### 获取帮助

如遇到代码分析工具集的问题，请参阅：
- [ASDM 文档](https://asdm.ai/docs)
- 工具集 README：`.asdm/toolsets/code-analyzer/README.md`
- 规格文档：`.asdm/toolsets/code-analyzer/spec/`

## 版权与许可

Copyright (c) 2026 LeansoftX.com & iSoftStone. 保留所有权利。

根据 PROPRIETARY SOFTWARE LICENSE授权。详见项目根目录中的 [LICENSE](LICENSE)。

---

*本安装文档是代码分析工具集的一部分。*
