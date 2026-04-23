# Database Design 安装指南

**Toolset ID:** `database-design`

## 概述

本指南提供 Database Design 工具集的安装和设置说明。Database Design 是一款面向开发团队的 ASDM 工具集，用于根据需求文档和现有数据库结构，自动分析并生成数据库变更脚本。

## AI 引导安装

要使用 AI 引导安装此工具集，请将以下提示复制到 AI 编码工具的聊天窗口：

```shell
Follow instructions in .asdm/toolsets/database-design/INSTALL.md
```

## 安装步骤

### 1. 创建工作空间目录

根据 Toolset Workspace 部分，创建以下目录结构：

```bash
mkdir -p .asdm/workspace/database-design/analysis
mkdir -p .asdm/workspace/database-design/scripts
```

### 2. 检测当前 Agentic Engine 提供商

检测当前 AI 编码助手提供商（如 Claude Code、GitHub Copilot、Tencent CodeBuddy）。使用以下指南进行检测：

- 如果存在 `.claude` 目录，使用 `Claude Code`
- 如果存在 `.github` 目录，使用 `GitHub Copilot`
- 如果存在 `.codebuddy` 目录，使用 `Tencent CodeBuddy`
- 如果当前工作空间未找到上述文件夹，请手动选择提供商

### 3. 为 Database Design (Toolset ID: `database-design`) 创建快捷命令

根据检测到的提供商，在相应位置创建快捷命令。安装过程在所有提供商间保持一致——使用 `cat` 将提供商特定的前置内容与实际指令内容连接：

#### 对于 Claude Code (`.claude/commands/`)

Claude Code 使用带有 Frontmatter 元数据的 Markdown 文件作为斜杠命令。通过连接 Claude 特定的前置内容与指令内容来创建命令：

```bash
mkdir -p .claude/commands/

# 动作 1：分析现有数据库结构
cat > .claude/commands/asdm-db-analyze.md << 'EOF'
---
description: "分析现有数据库结构，提取表结构、字段、索引、外键等元信息"
argument-hint: "[<输入源类型> <输入源路径/信息> <feature-id> <数据库类型>]"
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-analyze.md >> .claude/commands/asdm-db-analyze.md

# 动作 2：需求数据建模
cat > .claude/commands/asdm-db-model.md << 'EOF'
---
description: "从 PRD 文档中提取数据需求，构建需求数据模型"
argument-hint: "[<feature-id> <PRD文档路径>]"
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-model.md >> .claude/commands/asdm-db-model.md

# 动作 3：变更方案设计
cat > .claude/commands/asdm-db-plan.md << 'EOF'
---
description: "设计数据库变更方案，明确需要执行的变更操作"
argument-hint: "[<feature-id> <数据库类型>]"
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-plan.md >> .claude/commands/asdm-db-plan.md

# 动作 4：变更脚本生成
cat > .claude/commands/asdm-db-generate.md << 'EOF'
---
description: "生成可执行的数据库变更脚本（DDL 和 DML）"
argument-hint: "[<feature-id> <数据库类型> <脚本前缀>]"
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-generate.md >> .claude/commands/asdm-db-generate.md

# 动作 5：完整流程
cat > .claude/commands/asdm-db-full.md << 'EOF'
---
description: "完整流程（分析 + 建模 + 方案 + 脚本）"
argument-hint: "[<feature-id> <数据库结构输入> <数据库类型>]"
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-full.md >> .claude/commands/asdm-db-full.md
```

#### 对于 GitHub Copilot (`.github/prompts/`)

GitHub Copilot 使用带有 YAML Frontmatter 的 `.prompt.md` 文件。通过连接 GitHub 特定的前置内容与指令内容来创建提示文件：

```bash
mkdir -p .github/prompts/

# 动作 1：分析现有数据库结构
cat > .github/prompts/asdm-db-analyze.prompt.md << 'EOF'
---
agent: 'agent'
description: '分析现有数据库结构，提取表结构、字段、索引、外键等元信息'
argument-hint: '[<输入源类型> <输入源路径/信息> <feature-id> <数据库类型>]'
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-analyze.md >> .github/prompts/asdm-db-analyze.prompt.md

# 动作 2：需求数据建模
cat > .github/prompts/asdm-db-model.prompt.md << 'EOF'
---
agent: 'agent'
description: '从 PRD 文档中提取数据需求，构建需求数据模型'
argument-hint: '[<feature-id> <PRD文档路径>]'
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-model.md >> .github/prompts/asdm-db-model.prompt.md

# 动作 3：变更方案设计
cat > .github/prompts/asdm-db-plan.prompt.md << 'EOF'
---
agent: 'agent'
description: '设计数据库变更方案，明确需要执行的变更操作'
argument-hint: '[<feature-id> <数据库类型>]'
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-plan.md >> .github/prompts/asdm-db-plan.prompt.md

# 动作 4：变更脚本生成
cat > .github/prompts/asdm-db-generate.prompt.md << 'EOF'
---
agent: 'agent'
description: '生成可执行的数据库变更脚本（DDL 和 DML）'
argument-hint: '[<feature-id> <数据库类型> <脚本前缀>]'
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-generate.md >> .github/prompts/asdm-db-generate.prompt.md

# 动作 5：完整流程
cat > .github/prompts/asdm-db-full.prompt.md << 'EOF'
---
agent: 'agent'
description: '完整流程（分析 + 建模 + 方案 + 脚本）'
argument-hint: '[<feature-id> <数据库结构输入> <数据库类型>]'
---

EOF
cat .asdm/toolsets/database-design/actions/asdm-db-full.md >> .github/prompts/asdm-db-full.prompt.md
```

#### 对于 Tencent CodeBuddy (`.codebuddy/commands/`)

CodeBuddy 不支持 frontmatter，因此直接复制指令文件：

```bash
mkdir -p .codebuddy/commands/

# 复制所有指令文件
cp .asdm/toolsets/database-design/actions/asdm-db-analyze.md .codebuddy/commands/
cp .asdm/toolsets/database-design/actions/asdm-db-model.md .codebuddy/commands/
cp .asdm/toolsets/database-design/actions/asdm-db-plan.md .codebuddy/commands/
cp .asdm/toolsets/database-design/actions/asdm-db-generate.md .codebuddy/commands/
cp .asdm/toolsets/database-design/actions/asdm-db-full.md .codebuddy/commands/
```

### 4. 其他提供商的上手使用

如果您的 AI 编码助手提供商未被自动检测逻辑识别（Claude Code、GitHub Copilot 或 Tencent CodeBuddy），您仍然可以手动使用 Database Design。请按以下步骤操作：

#### 直接使用指令

您可以通过复制指令文件的相对路径并将其粘贴到 AI 编码助手的聊天窗口来直接使用指令文件：

1. **导航到指令文件**：
   ```bash
   cd .asdm/toolsets/database-design/actions/
   ```

2. **右键点击所需的指令文件**并复制其相对路径：
   - 分析现有数据库：`asdm-db-analyze.md`
   - 需求数据建模：`asdm-db-model.md`
   - 变更方案设计：`asdm-db-plan.md`
   - 变更脚本生成：`asdm-db-generate.md`
   - 完整流程：`asdm-db-full.md`

3. **在 AI 编码助手中输入提示**：
   ```
   Follow the instructions in {指令文件的相对路径}
   ```

## 初始化 Database Design

### 分析现有数据库结构

安装完成后，您可以通过运行第一个动作来开始：

```shell
Follow the instructions in .asdm/toolsets/database-design/actions/asdm-db-analyze.md
```

这将：
- 读取 DDL 文件或连接数据库获取结构信息
- 提取表结构、字段、索引、外键
- 生成结构分析报告

### 需求数据建模

完成结构分析后，您可以运行需求建模：

```shell
Follow the instructions in .asdm/toolsets/database-design/actions/asdm-db-model.md
```

这将：
- 从 PRD 文档中识别数据实体
- 定义实体属性和关系
- 生成数据需求模型文档

### 变更方案设计

完成需求建模后，您可以设计变更方案：

```shell
Follow the instructions in .asdm/toolsets/database-design/actions/asdm-db-plan.md
```

这将：
- 对比需求模型与现有结构差异
- 设计变更操作
- 生成变更方案文档

### 变更脚本生成

完成方案设计后，您可以生成变更脚本：

```shell
Follow the instructions in .asdm/toolsets/database-design/actions/asdm-db-generate.md
```

这将：
- 生成 DDL 变更脚本
- 生成 DML 变更脚本
- 生成回滚脚本
- 生成验证脚本

### 完整流程

如果需要完整走查数据库变更设计全流程：

```shell
Follow the instructions in .asdm/toolsets/database-design/actions/asdm-db-full.md
```

这将一站式完成从需求分析到脚本生成的所有工作。

### 可用命令

安装后，您可以使用以下命令：

1. **`/asdm-db-analyze`** - 分析现有数据库结构
2. **`/asdm-db-model`** - 从 PRD 文档提取数据需求建模
3. **`/asdm-db-plan`** - 设计数据库变更方案
4. **`/asdm-db-generate`** - 生成数据库变更脚本
5. **`/asdm-db-full`** - 完整流程（分析 + 建模 + 方案 + 脚本）

## 工具集结构

该工具集将在 `.asdm/workspace/database-design/` 中创建以下结构：

```
.asdm/workspace/database-design/
├── analysis/                       ## 分析文档
│   └── <feature-id>/             ## 按功能分析
│       ├── db-structure.md       ## 现有数据库结构
│       ├── data-model.md         ## 数据需求模型
│       └── change-plan.md        ## 变更方案
├── scripts/                       ## 生成的 SQL 脚本
│   └── <feature-id>/             ## 按功能脚本
│       ├── ddl_<timestamp>.sql   ## DDL 变更脚本
│       ├── dml_<timestamp>.sql   ## DML 变更脚本
│       └── rollback_<timestamp>.sql ## 回滚脚本
└── db-list.md                     ## 数据库变更追踪列表
```

## 规范文档

该工具集使用以下规范文档作为模板：

1. **db-structure-spec.md** - 数据库结构分析报告模板
2. **data-model-spec.md** - 数据需求模型文档模板
3. **change-plan-spec.md** - 数据库变更方案文档模板
4. **script-template.md** - SQL 变更脚本模板
5. **db-list-spec.md** - 数据库变更追踪列表模板

## 验证

安装后，请验证：

1. `.asdm/workspace/database-design/` 目录已创建
2. Database Design 工具集文件位于 `.asdm/toolsets/database-design/`（工具集 ID：`database-design`）
3. 如果使用支持的提供商，快捷命令已在相应目录中创建：
   - Claude Code: `.claude/commands/`
   - GitHub Copilot: `.github/prompts/`
   - Tencent CodeBuddy: `.codebuddy/commands/`

**对于其他提供商**：验证您可以访问以下指令文件：
- `.asdm/toolsets/database-design/actions/asdm-db-analyze.md`
- `.asdm/toolsets/database-design/actions/asdm-db-model.md`
- `.asdm/toolsets/database-design/actions/asdm-db-plan.md`
- `.asdm/toolsets/database-design/actions/asdm-db-generate.md`
- `.asdm/toolsets/database-design/actions/asdm-db-full.md`

## 使用示例

### 示例 1：分析现有数据库结构

```shell
# 首先，使用 AI 引导安装工具集
Follow instructions in .asdm/toolsets/database-design/INSTALL.md

# 然后运行分析动作
Follow the instructions in .asdm/toolsets/database-design/actions/asdm-db-analyze.md

# 使用斜杠命令时：
/asdm-db-analyze <输入源类型> <输入源路径> <feature-id> <数据库类型>
```

### 示例 2：完整数据库变更设计流程

```shell
# 运行完整流程
Follow the instructions in .asdm/toolsets/database-design/actions/asdm-db-full.md

# 使用斜杠命令时：
/asdm-db-full <feature-id> <数据库结构输入> <数据库类型>
```

## 使用说明

### 对于支持的提供商（Claude Code、GitHub Copilot、Tencent CodeBuddy）

安装后，您可以使用以下命令：

- `/asdm-db-analyze`：分析现有数据库结构
- `/asdm-db-model`：从 PRD 文档提取数据需求建模
- `/asdm-db-plan`：设计数据库变更方案
- `/asdm-db-generate`：生成数据库变更脚本
- `/asdm-db-full`：完整流程（分析 + 建模 + 方案 + 脚本）

### 对于其他提供商（手动使用）

如果您的提供商未自动检测，您可以通过以下步骤手动使用指令：

1. 导航到 `.asdm/toolsets/database-design/actions/` 目录
2. 右键点击所需的指令文件并复制其相对路径
3. 在 AI 编码助手中输入："Follow the instructions in {相对路径}"

## 注意事项

- 此安装过程假设您具有创建目录和文件的必要权限
- 命令的实际实现将由 AI 模型使用工具集中提供的模板和指令来处理
- 请根据您的实际 AI 编码助手定制提供商特定设置
- 工具集 ID `database-design` 应在引用 Database Design 时一致使用
- **对于不在检测逻辑中的提供商**：用户可以通过复制指令文件的相对路径并输入类似 "follow the instructions in .asdm/toolsets/database-design/actions/asdm-db-analyze.md" 的提示来手动使用指令文件
- 支持多种数据库类型：MySQL、PostgreSQL、Oracle、SQL Server
- 所有生成的脚本都包含回滚脚本，确保变更可追溯、可回滚

## 与其他工具集成

Database Design 可与 ASDM 其他工具集和上下文文件集成。Context Builder 的上下文文件可用于将生成的文档基于实际项目。

### 获取帮助

有关 Database Design 工具集的问题，请参阅：
- [ASDM 文档](https://asdm.ai/docs)
- 工具集 README：`.asdm/toolsets/database-design/README.md`
- 规范文档：`.asdm/toolsets/database-design/spec/`

## 许可证

版权所有 (c) 2026 LeansoftX.com & iSoftStone。保留所有权利。

根据 PROPRIETARY SOFTWARE LICENSE 获得许可。有关许可证信息，请参阅项目根目录中的 [LICENSE](LICENSE)。

---

*本安装文档是 Database Design 工具集的一部分。
