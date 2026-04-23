# Installation Instructions

本文档提供项目上下文分析工具集的安装指南，包含 AI 引导安装和手动安装两种方式。

## AI Guided Installation

### For CodeBuddy Users

只需将以下命令复制到 CodeBuddy 聊天窗口并执行：

```shell
按照 .asdm/toolsets/project-context-analysis/INSTALL.md 中的指令执行
```

AI 将自动完成所有安装步骤。

### For Claude Code Users

将以下命令复制到 Claude Code 聊天窗口：

```shell
Follow instructions in .asdm/toolsets/project-context-analysis/INSTALL.md
```

## Prerequisites

在安装前，请确保：

1. **工作区根目录**：当前目录应为项目根目录
2. **`.asdm` 目录存在**：如果不存在，将自动创建
3. **Git 已初始化**（可选）：用于版本控制

## Installation Steps

### Step 1: Create Context Directory

创建上下文存储目录：

```bash
mkdir -p .asdm/contexts
```

### Step 2: Register Commands

根据您使用的 AI 编码工具，选择对应的安装方式：

#### For Tencent CodeBuddy

```bash
mkdir -p .codebuddy/commands/

# Context Index Init 命令
cp .asdm/toolsets/project-context-analysis/actions/asdm-cpc-index-init.md .codebuddy/commands/

# Context Module Build 命令
cp .asdm/toolsets/project-context-analysis/actions/asdm-cpc-workspace-context-build.md .codebuddy/commands/

# asdm-cpc-all-build 命令
cp .asdm/toolsets/project-context-analysis/actions/asdm-cpc-all-build.md .codebuddy/commands/

# asdm-cpc-build-module-context-index 命令
cp .asdm/toolsets/project-context-analysis/actions/asdm-cpc-build-module-context-indext.md .codebuddy/commands/
```

#### For Claude Code

```bash
mkdir -p .claude/commands/

# Context Index Init 命令
cat > .claude/commands/asdm-cpc-index-init.md << 'EOF'
---
description: "Initialize/update context index for the workspace"
argument-hint: "[additional prompt]"
---

EOF
cat .asdm/toolsets/project-context-analysis/actions/asdm-cpc-index-init.md >> .claude/commands/asdm-cpc-index-init.md

# Context Workspace Build 命令
cat > .claude/commands/asdm-cpc-workspace-context-build.md << 'EOF'
---
description: "Build workspace context"
argument-hint: ""
---

EOF
cat .asdm/toolsets/project-context-analysis/actions/asdm-cpc-workspace-context-build.md >> .claude/commands/asdm-cpc-workspace-context-build.md

# asdm-cpc-all-build 命令
cat > .claude/commands/asdm-cpc-all-build.md << 'EOF'
---
description: "Full batch context build for all modules (Complex Project Context)"
argument-hint: "[all|selective|skip-generated]"
---

EOF
cat .asdm/toolsets/project-context-analysis/actions/asdm-cpc-all-build.md >> .claude/commands/asdm-cpc-all-build.md

# asdm-cpc-build-module-context-index 命令
cat > .claude/commands/asdm-cpc-build-module-context-index.md << 'EOF'
---
description: "Build module context index with sub-module breakdown"
argument-hint: ""
---

EOF
cat .asdm/toolsets/project-context-analysis/actions/asdm-cpc-build-module-context-indext.md >> .claude/commands/asdm-cpc-build-module-context-index.md
```

#### For GitHub Copilot

```bash
mkdir -p .github/prompts/

# Context Index Init 提示
cat > .github/prompts/asdm-cpc-index-init.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Initialize/update context index for the workspace'
argument-hint: 'additional prompt (optional)'
---

EOF
cat .asdm/toolsets/project-context-analysis/actions/asdm-cpc-index-init.md >> .github/prompts/asdm-cpc-index-init.prompt.md

# Context Workspace Build 提示
cat > .github/prompts/asdm-cpc-workspace-context-build.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Build workspace context'
argument-hint: ''
---

EOF
cat .asdm/toolsets/project-context-analysis/actions/asdm-cpc-workspace-context-build.md >> .github/prompts/asdm-cpc-workspace-context-build.prompt.md

# asdm-cpc-all-build 提示
cat > .github/prompts/asdm-cpc-all-build.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Full batch context build for all modules (Complex Project Context)'
argument-hint: 'all|selective|skip-generated'
---

EOF
cat .asdm/toolsets/project-context-analysis/actions/asdm-cpc-all-build.md >> .github/prompts/asdm-cpc-all-build.prompt.md

# asdm-cpc-build-module-context-index 提示
cat > .github/prompts/asdm-cpc-build-module-context-index.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Build module context index with sub-module breakdown'
argument-hint: ''
---

EOF
cat .asdm/toolsets/project-context-analysis/actions/asdm-cpc-build-module-context-indext.md >> .github/prompts/asdm-cpc-build-module-context-index.prompt.md
```

### Step 3: Register Agents (CodeBuddy Only)

**注意**：此步骤仅适用于 CodeBuddy 用户。其他 AI 工具不需要此步骤。

为 CodeBuddy 注册 SubAgent：

```bash
mkdir -p .codebuddy/agents/

# 复制 SubAgent 配置文件
cp .asdm/toolsets/project-context-analysis/subagents/asdm-subagent-build-submodule-context-index.md .codebuddy/agents/
cp .asdm/toolsets/project-context-analysis/subagents/asdm-subagent-module-context-build.md .codebuddy/agents/
```

**SubAgent 说明**：

1. **asdm-subagent-build-submodule-context-index**
   - 用途：独立生成子模块的上下文创建索引
   - 功能：根据模块复杂度自动细化到子模块级别
   - 调用场景：由 `/asdm-cpc-build-module-context-index` 命令调用

2. **asdm-subagent-module-context-build**
   - 用途：独立生成指定模块的上下文
   - 功能：为单个模块生成详细的上下文文档
   - 调用场景：由 `/asdm-cpc-all-build` 命令批量调用

### Step 4: Verify Installation

验证命令和 agents 是否正确安装：

```bash
# For CodeBuddy
echo "=== 验证命令 ==="
ls -la .codebuddy/commands/ | grep -E "context|asdm"

echo "=== 验证 Agents ==="
ls -la .codebuddy/agents/ | grep asdm

# For Claude Code
ls -la .claude/commands/ | grep context

# For GitHub Copilot
ls -la .github/prompts/ | grep context
```

应该看到以下文件：

**命令文件**：
- asdm-cpc-index-init.md（或 .prompt.md）
- asdm-cpc-workspace-context-build.md（或 .prompt.md）
- asdm-cpc-all-build.md（或 .prompt.md）
- asdm-cpc-build-module-context-indext.md（或 .prompt.md）

**Agent 文件**（仅 CodeBuddy）：
- asdm-subagent-build-submodule-context-index.md
- asdm-subagent-module-context-build.md

### Step 5: Initialize Context Index（可选）

安装完成后，建议立即初始化上下文索引：

```bash
/context-index-init
```

这将创建项目的模块索引表，为后续的上下文生成做好准备。

## Available Commands

安装完成后，您可以使用以下命令：

### 核心命令

| 命令 | 描述 | 示例 |
|------|------|------|
| `/asdm-cpc-index-init` | 初始化/更新上下文索引表 | `/asdm-cpc-index-init` |
| `/asdm-cpc-build-module-context-index` | 构建模块上下文索引（细化到子模块） | `/asdm-cpc-build-module-context-index` |
| `/asdm-module-context-build <模块名>` | 为指定模块生成上下文 | `/asdm-module-context-build aise-api` |
| `/asdm-cpc-all-build [选项]` | 批量生成所有模块的上下文 | `/asdm-cpc-all-build` |
| `/asdm-cpc-workspace-context-build` | 生成工作区综合上下文 | `/asdm-cpc-workspace-context-build` |

### 命令详解

#### /asdm-cpc-index-init

初始化项目上下文索引，分析项目结构并生成模块索引表。

**用法**：
```bash
/asdm-cpc-index-init
```

**输出**：
- `.asdm/contexts/index.md` - 项目上下文入口
- `.asdm/contexts/modules-index.json` - 模块索引数据

**何时使用**：
- 首次使用工具集
- 项目结构发生变化
- 需要查看所有模块的状态

#### /asdm-cpc-build-module-context-index

根据模块复杂度构建模块上下文索引，自动细化到子模块级别。

**用法**：
```bash
/asdm-cpc-build-module-context-index
```

**输出**：
- `.asdm/contexts/module-context-index.json` - 模块上下文索引（含子模块信息）

**何时使用**：
- 模块索引初始化后，准备生成模块上下文
- 需要了解模块的复杂度和子模块分布
- 优化上下文生成粒度

#### /asdm-module-context-build

为单个模块生成详细的上下文文档。

**用法**：
```bash
/asdm-module-context-build <模块名>
```

**示例**：
```bash
/asdm-module-context-build aise-api
/asdm-module-context-build aise-auth
```

**输出**：
- 模块上下文目录：`.asdm/contexts/<模块名>/`
- 包含多个标准文档（如适用）

**何时使用**：
- 为特定模块生成上下文
- 更新已变化的模块上下文

#### /asdm-cpc-all-build

批量为所有模块生成上下文。

**用法**：
```bash
/asdm-cpc-all-build [选项]
```

**选项**：
- `all`：生成所有模块（包括已生成的）
- `selective`：交互式选择模块
- `skip-generated`（默认）：只生成未生成的模块

**示例**：
```bash
/asdm-cpc-all-build                    # 默认：跳过已生成的
/asdm-cpc-all-build skip-generated     # 明确指定跳过已生成的
/asdm-cpc-all-build all                # 重新生成所有模块
/asdm-cpc-all-build selective          # 交互式选择模块
```

**输出**：
- 所有模块的上下文文件
- 更新的项目索引
- 生成摘要报告

**何时使用**：
- 首次生成完整上下文
- 批量更新多个模块

## Quick Start Guide

### 首次使用

```bash
# 1. 初始化索引
/asdm-cpc-index-init

# 2. （可选）构建模块上下文索引，细化到子模块
/asdm-cpc-build-module-context-index

# 3. 查看模块列表
# （AI 会显示所有模块及其状态）

# 4. 生成所有模块上下文
/asdm-cpc-all-build

# 5. （可选）生成工作区综合上下文
/asdm-cpc-workspace-context-build

# 或者只生成特定模块
/asdm-module-context-build <模块名>
```

### 日常使用

```bash
# 当某个模块代码变化时
/asdm-module-context-build <变化的模块名>

# 当项目结构变化时
/asdm-cpc-index-init
```

## Context Files Structure

工具集将创建以下上下文文件结构：

```
.asdm/contexts/
├── index.md                             # 项目上下文入口
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
└── [其他模块...]
```

## Troubleshooting

### 问题：命令未找到

**原因**：命令文件未正确复制到命令目录

**解决方案**：
```bash
# 检查命令文件是否存在
ls .codebuddy/commands/  # 或 .claude/commands/ 或 .github/prompts/

# 检查 agent 文件是否存在（仅 CodeBuddy）
ls .codebuddy/agents/

# 如果文件不存在，重新执行安装步骤 2 和步骤 3
```

### 问题：上下文索引生成失败

**原因**：`.asdm/contexts` 目录不存在或权限不足

**解决方案**：
```bash
# 创建目录
mkdir -p .asdm/contexts

# 检查权限
ls -la .asdm/
```

### 问题：模块上下文生成不完整

**原因**：生成过程中被中断或资源不足

**解决方案**：
```bash
# 检查生成状态
cat .asdm/contexts/modules-index.json

# 重新生成失败的模块
/asdm-module-context-build <失败的模块名>
```

### 问题：如何重新生成所有上下文

**解决方案**：
```bash
# 方案 1：删除所有上下文后重新生成
rm -rf .asdm/contexts/*
/asdm-cpc-index-init
/asdm-cpc-all-build

# 方案 2：使用 all 参数强制重新生成
/asdm-cpc-all-build all
```

## Advanced Configuration

### 自定义排除目录

在首次运行 `/asdm-cpc-index-init` 时，可以指定要排除的目录：

```bash
# 向 AI 提供自定义排除列表
/asdm-cpc-index-init
排除以下目录：[自定义目录1, 自定义目录2]
```

### 调整生成顺序

在批量生成时，可以自定义模块生成顺序：

```bash
# 向 AI 提供自定义顺序
/asdm-cpc-all-build
按以下顺序生成：[模块1, 模块2, 模块3, ...]
```

### 选择性生成特定文件

对于单模块生成，可以选择只生成特定文件：

```bash
# 向 AI 提供文件选择
/asdm-module-context-build <模块名>
只生成以下文件：[index.md, structure.md, api.md]
```

## Uninstallation

如需卸载工具集：

```bash
# 删除命令文件
rm .codebuddy/commands/asdm-*.md  # 或 .claude/commands/ 或 .github/prompts/

# 删除 agent 文件（仅 CodeBuddy）
rm .codebuddy/agents/asdm-subagent-*.md

# 删除上下文文件（可选）
rm -rf .asdm/contexts/

# 保留工具集目录（供将来使用）
# 或删除整个工具集
# rm -rf .asdm/toolsets/project-context-analysis/
```

## Support

如有问题或建议，请：

1. 查看工具集文档：`.asdm/toolsets/project-context-analysis/README.md`
2. 查看上下文模板：`.asdm/toolsets/project-context-analysis/spec/`
3. 联系工具集维护团队

---

*此安装指南由 project-context-analysis 工具集提供。*
