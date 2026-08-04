# Instructions for asdm-generate-release-note action

## Metadata

```json
{
  "guid": "c7d8e9f0-a1b2-3c4d-5e6f-7a8b9c0d1e2f",
  "name": "asdm-generate-release-note",
  "displayName": "生成 Release Note",
  "description": "根据输入的 Git Tag 或时间段范围，扫描指定分支上所有 submodule 的代码差异，结合功能模块列表，生成结构化的 Release Note 文档",
  "toolset": {
    "guid": "12f55022-ccab-46e0-8bb5-3ebb5fdaee0f",
    "id": "release-note",
    "name": "Release Note Toolset",
    "version": "0.0.1"
  },
  "scenario": "发版文档生成"
}
```

## Purpose

本指令引导 AI 模型根据输入的 Git Tag 或时间段范围，扫描所有 Git Submodule 的代码差异，
结合功能模块列表（`docs/planning/Modules/README.md`），自动归类和映射变更到对应功能模块，
生成结构清晰、信息完整的 Release Note 文档。它通过逐个 Submodule 分析代码变更内容，
将其映射到 ASDM 功能模块，按新功能、功能优化、Bug 修复、数据/配置变更、依赖变更等分类组织发版说明，
并提供上线影响评估与回滚策略。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有生成的文件、注释和文档均使用中文，并遵循中文写作规范。

如需切换语言，可在工作区根目录创建 `.asdm/config.json` 配置：

```json
{
  "language": "zh"
}
```

支持的语言：`zh`（中文，默认）、`en`（英文）。

## Context Injection

在生成 Release Note 之前，AI 模型**必须**读取并理解项目上下文：

### Context Files to Read (Required)

1. **功能模块列表** (Required)
   - Path: `docs/planning/Modules/README.md`
   - Purpose: 了解 ASDM 平台功能模块划分（15 个一级模块及其二级模块），用于将代码变更映射到对应功能模块

2. **项目上下文入口** (Recommended)
   - Path: `.asdm/contexts/index.md`
   - Purpose: 了解项目整体结构和模块划分

3. **渐进式上下文加载** (Optional - On-Demand)
   - 根据代码差异涉及的模块，按需加载相关上下文
   - 示例：`.asdm/contexts/architecture.md`、`.asdm/contexts/api.md`
   - AI 模型可根据 Git 差异涉及的文件路径，判断是否需要额外上下文

### Submodule 与技术栈映射

本工作区为 monorepo 结构，包含以下 Git Submodule：

| Submodule | 技术栈 | 构建工具 | 路径 | 说明 |
|-----------|--------|----------|------|------|
| asdm-admin | Java 17+ / Spring Boot | Maven | `./asdm-admin` | 后端主服务 |
| asdm-portal | Vue 3 / TypeScript / Vite | npm (vite build) | `./asdm-portal` | 用户门户前端 |
| asdm-agentorbit | TypeScript / Node.js 18+ | pnpm monorepo | `./asdm-agentorbit` | AgentOrbit 前端+后端 |
| asdm-cli | TypeScript / Node.js | npm (tsc) | `./asdm-cli/asdm-bootstrapper-cli` | CLI 工具 |
| asdm-mcp-server-hosted | TypeScript / Node.js 16+ (ESM) | npm (tsc) | `./asdm-mcp-server-hosted` | MCP 托管服务器 |
| asdm-docs | TypeScript / React 18 / Vite | npm (vite build) | `./asdm-docs` | 文档站 |

## Steps to Generate Release Note

### 1. 接收发版参数

从用户处接收以下参数：

**必填参数**（以下两种方式任选其一）：

方式 A：Git Tag 范围

- **起始 Tag**（from-tag）：发版起始的 Git Tag（如 `v1.0.0`）
- **目标 Tag**（to-tag）：发版目标的 Git Tag（如 `v1.1.0`）

方式 B：时间段范围

- **起始时间**（from-date）：发版起始时间，支持以下格式：
  - 相对时间：`2.weeks.ago`、`1.month.ago`、`3.days.ago`
  - 绝对时间：`2026-05-01`、`2026-05-01T00:00:00`
- **目标时间**（to-date）：发版目标时间，默认为 `now`（当前时间），支持与起始时间相同的格式

> **优先级**：如果同时提供了 Tag 和时间段，优先使用 Tag 范围。

**可选参数**：

- **目标分支**（branch）：扫描代码差异时使用的 Git 分支，默认为 `release`。所有 Submodule 的 Git 命令（log、diff 等）将基于此分支执行。若指定分支不存在于某个 Submodule，将跳过该 Submodule 并输出警告
- **系统名称**：发版系统或产品名称，默认为 "ASDM Platform"
- **版本号**：本次发版版本号（如 `v1.2.0`），默认从目标 Tag 推断；使用时间段时需手动提供
- **发布类型**：常规迭代 / 热修复 / 紧急上线，默认为"常规迭代"
- **发布日期**：发版日期，默认为当天
- **发布窗口**：发布的时间窗口
- **影响范围**：受影响的系统或端
- **缺陷清单**：缺陷 ID 和描述列表（文件路径或直接提供）
- **用户故事清单**：用户故事 ID 和描述列表（文件路径或直接提供）
- **输出路径**：Release Note 保存路径，默认为 `.asdm/workspace/release-notes/`
- **指定 Submodule**：仅扫描指定的 Submodule（逗号分隔），默认扫描全部

如果必填参数未提供（既无 Tag 范围也无时间段范围），提示用户输入。

### 2. 读取功能模块列表

**必须**读取功能模块列表文件作为变更归类的基础：

```bash
# 读取功能模块列表
cat docs/planning/Modules/README.md
```

从文件中提取以下信息用于变更映射：

- 一级模块编号与名称（1-15）
- 二级模块编号、名称与状态
- 模块功能说明

该模块列表将用于：

- 将 Submodule 代码变更映射到功能模块
- 在 Release Note 中按功能模块组织变更内容
- 识别变更影响的功能范围

### 3. 扫描所有 Submodule 的 Git 差异

对每个 Submodule 执行 Git 差异分析，获取版本范围（Tag 或时间段）之间的代码变更。

#### 3.1 确定范围引用方式

根据用户输入的参数，确定 Git 查询使用的范围引用：

- **Tag 范围**：使用 `<from-tag>..<to-tag>` 作为 git log/diff 的范围
- **时间段范围**：使用 `--since=<from-date> --until=<to-date>` 作为 git log/diff 的过滤条件

将确定的范围信息保存为变量，后续步骤统一使用。

#### 3.2 获取 Submodule 列表

执行命令获取所有 Submodule 路径：

```bash
git submodule status
```

或直接使用以下 Submodule 列表（从 `.gitmodules` 获取）：

- `asdm-admin`
- `asdm-portal`
- `asdm-agentorbit`
- `asdm-cli`
- `asdm-mcp-server-hosted`
- `asdm-docs`

如果用户指定了特定 Submodule，仅扫描指定的。

#### 3.2b 检查 Submodule 初始化状态与数据源确定

在执行步骤 3.3-3.5 之前，**必须**检查每个 Submodule 的本地初始化状态。对于未初始化的 Submodule，使用 `git clone --no-checkout` 克隆完整 Git 历史到子模块路径，使所有 Submodule 统一可用。

**检查命令**（逐个 Submodule 执行）：

```bash
test -d <workspace-root>/<submodule-path>/.git && echo "INITIALIZED" || echo "NOT_INITIALIZED"
```

**遍历检查所有 Submodule**：

```bash
for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  if test -d <workspace-root>/${submodule}/.git; then
    echo "${submodule}: INITIALIZED"
  else
    echo "${submodule}: NOT_INITIALIZED"
  fi
done
```

**数据源策略**：

| Submodule 状态 | 处理方式 | 命令前缀 | 说明 |
|---------------|---------|---------|------|
| 已初始化（有 `.git`） | 直接使用本地仓库 | `cd <workspace-root>/<submodule-path>` | 本地已有完整 Git 历史 |
| 未初始化（无 `.git`） | `git clone --no-checkout` 克隆到子模块路径 | `cd <workspace-root>/<submodule-path>` | 克隆完整历史但不检出工作区，克隆后命令与已初始化完全一致 |

> **`--no-checkout` 的优势**：克隆完整 Git 历史但不检出工作区文件，既节省时间和磁盘空间（无需写入工作区文件），又保留了完整的 Git 命令兼容性。克隆完成后，`git log`、`git diff`、`git show` 等只读命令与已初始化的 Submodule 完全一致，后续步骤 3.3-3.5 无需区分数据来源。

**获取远程仓库 URL**（从 `.gitmodules` 提取）：

```bash
# 获取指定 Submodule 的远程 URL
git config --file <workspace-root>/.gitmodules --get submodule.<submodule-path>.url
```

**远程 Submodule 克隆**（仅对未初始化的 Submodule 执行）：

```bash
# 逐个克隆未初始化的 Submodule
for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  if [ ! -d <workspace-root>/${submodule}/.git ]; then
    remote_url=$(git config --file <workspace-root>/.gitmodules --get submodule.${submodule}.url)
    echo "Cloning ${submodule} from ${remote_url} ..."
    git clone --no-checkout ${remote_url} <workspace-root>/${submodule}
  fi
done

# 克隆后，所有 Submodule 均可在子模块路径下执行 Git 命令
cd <workspace-root>/<submodule-path> && git log --oneline --no-merges <from-tag>..<to-tag>
```

> **注意**：`--no-checkout` 克隆完整 Git 历史到子模块路径，但不检出工作区文件，显著节省时间和磁盘空间。克隆完成后，该 Submodule 的命令与已初始化的完全一致，步骤 3.3-3.5 无需区分来源。
> 对于大型仓库且使用时间段范围时，可追加 `--shallow-since=<from-date>` 限制克隆深度以加速。如果远程仓库需要认证（SSH Key / HTTPS Token），需确保 Git 凭证已配置。步骤 8.3 可选择清理克隆的 `.git` 目录，或保留以便后续使用。

**`--no-checkout` vs `--bare` 对比**：

| 特性 | `--no-checkout` | `--bare` |
|------|----------------|----------|
| Git 历史 | ✅ 完整 | ✅ 完整 |
| 工作区文件 | ❌ 不检出 | ❌ 无工作区概念 |
| `git log` | ✅ | ✅ |
| `git diff <from>..<to>` | ✅ | ✅ |
| `git checkout` 后续可用 | ✅ 可补充检出 | ❌ 不可 |
| `.git` 位置 | `<path>/.git`（标准） | `<path>` 本身就是 `.git` |
| 与子模块路径一致 | ✅ 克隆到子模块路径 | ❌ 需要额外临时目录 |
| 后续步骤命令是否统一 | ✅ 统一 | ❌ 需区分路径 |

**Submodule 远程 URL 参考**（从当前 `.gitmodules` 提取）：

| Submodule | 远程 URL |
|-----------|---------|
| asdm-admin | `git@ssh.dev.azure.com:v3/leansoftx/ASDM/asdm-admin` |
| asdm-portal | `git@ssh.dev.azure.com:v3/leansoftx/ASDM/asdm-portal` |
| asdm-agentorbit | `git@ssh.dev.azure.com:v3/leansoftx/ASDM/asdm-agentorbit` |
| asdm-cli | `git@ssh.dev.azure.com:v3/leansoftx/ASDM/asdm-cli` |
| asdm-mcp-server-hosted | `git@ssh.dev.azure.com:v3/leansoftx/ASDM/asdm-mcp-server-hosted` |
| asdm-docs | `git@ssh.dev.azure.com:v3/leansoftx/ASDM/asdm-docs` |

> **重要**：上表为当前快照，AI 模型应优先通过 `git config --file .gitmodules` 动态获取最新 URL，仅当命令不可用时才使用此表作为回退。

#### 3.2c 检查与切换目标分支

在执行步骤 3.3-3.5 之前，**必须**对每个已初始化或已克隆的 Submodule 检查目标分支是否存在，并确保后续 Git 命令在该分支上执行。

**目标分支**默认为 `release`，可通过 `--branch` 参数指定其他分支。

##### 分支存在性检查

对每个 Submodule 逐一检查目标分支是否存在：

```bash
# 检查本地分支
cd <workspace-root>/<submodule-path> && git branch --list <target-branch>

# 若本地不存在，检查远程分支
cd <workspace-root>/<submodule-path> && git branch -r --list origin/<target-branch>
```

##### 完整遍历检查脚本

```bash
TARGET_BRANCH="${target-branch:-release}"  # 默认 release

for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  SUBMODULE_PATH="<workspace-root>/${submodule}"

  if [ ! -d "${SUBMODULE_PATH}/.git" ]; then
    echo "${submodule}: SKIP (未初始化或克隆失败)"
    continue
  fi

  cd "${SUBMODULE_PATH}"

  # 1. 先检查本地分支
  LOCAL_BRANCH=$(git branch --list "${TARGET_BRANCH}")
  if [ -n "${LOCAL_BRANCH}" ]; then
    echo "${submodule}: LOCAL_BRANCH_EXISTS (${TARGET_BRANCH})"
    continue
  fi

  # 2. 获取远程引用并检查远程分支
  git fetch origin --quiet 2>/dev/null || true
  REMOTE_BRANCH=$(git branch -r --list "origin/${TARGET_BRANCH}")
  if [ -n "${REMOTE_BRANCH}" ]; then
    echo "${submodule}: REMOTE_BRANCH_EXISTS (origin/${TARGET_BRANCH})"
  else
    echo "${submodule}: BRANCH_NOT_FOUND (${TARGET_BRANCH})"
  fi
done
```

##### 分支切换策略

根据分支检查结果，采取以下策略：

| 分支状态 | 处理方式 | 说明 |
|---------|---------|------|
| 本地分支已存在 | 直接使用，无需切换 | `git log`、`git diff` 等只读命令可直接引用该分支 |
| 仅远程分支存在 | 创建本地跟踪分支 | `git branch <target-branch> origin/<target-branch>` |
| 本地和远程均不存在 | 跳过该 Submodule 并输出警告 | 在最终报告中标注该 Submodule 因分支不存在而跳过 |

**创建本地跟踪分支**（仅对仅存在于远程的分支执行）：

```bash
cd <workspace-root>/<submodule-path> && git branch <target-branch> origin/<target-branch>
```

> **注意**：此操作仅创建本地分支引用，不检出工作区文件，不影响当前工作区状态。后续 `git log <target-branch>`（时间段范围）等命令可直接引用该分支名。Tag 范围的 `git log` 和所有 `git diff` 命令**不需要**分支前缀。

##### Tag 与分支的关系

Tag 范围和时间段范围对分支的依赖不同：

- **Tag 范围**：`git log <from-tag>..<to-tag>` / `git diff <from-tag>..<to-tag>` — Tag 是全局引用，直接标识具体 commit，**不需要**分支前缀。分支仅在步骤 3.2c 中用于判断该 Submodule 是否存在目标分支（决定是否跳过），不影响 Tag 范围的命令本身
- **时间段范围**：`git log <target-branch> --since --until` — 时间段模式下**必须**指定分支，限定扫描范围仅为该分支上的提交。`git diff` 则先通过 `git log <target-branch>` 在该分支上定位起止 commit，再进行 diff，diff 本身不加分支前缀

**关键规则**：后续步骤 3.3-3.5 中 Git 命令的分支使用规则：

| 命令类型 | Tag 范围 | 时间段范围 |
|---------|---------|-----------|
| `git log` | `git log --oneline --no-merges <from-tag>..<to-tag>`（无分支前缀） | `git log <target-branch> --oneline --no-merges --since=... --until=...`（需分支前缀） |
| `git diff --stat` | `git diff --stat <from-tag>..<to-tag>`（无分支前缀） | `git diff --stat $(git log...)..$(git log...)`（分支仅在子命令中） |
| `git diff` | `git diff <from-tag>..<to-tag>`（无分支前缀） | `git diff $(git log...)..$(git log...)`（分支仅在子命令中） |

时间段范围 `git diff` 的完整命令：

```bash
# diff --stat
git diff --stat $(git log -1 --format=%H --before="<from-date>" <target-branch>)..$(git log -1 --format=%H --before="<to-date>" <target-branch>)

# diff 详情
git diff $(git log -1 --format=%H --before="<from-date>" <target-branch>)..$(git log -1 --format=%H --before="<to-date>" <target-branch>)
```

> **Tag 范围**：Tag 已标识具体 commit，`git log` 和 `git diff` 均不需要分支前缀。若加了分支前缀，`git log <branch> <rev1>..<rev2>` 会取交集（可能过滤掉预期结果），`git diff <branch> <rev1>..<rev2>` 中 `<branch>` 会被当作第一个 commit 参数，导致 diff 对象完全错误。
>
> **时间段范围**：`git log` 必须加分支前缀以限定扫描范围。`git diff` 不加分支前缀，通过子命令 `git log <target-branch>` 定位起止 commit 后再 diff。

##### 跳过 Submodule 记录

对于目标分支不存在的 Submodule，**必须**在变更统计汇总表（步骤 3.6）中标注为"分支不存在，已跳过"，而非省略。示例：

| Submodule | 提交数 | 变更文件数 | 新增行数 | 删除行数 | 是否有变更 |
|-----------|--------|-----------|---------|---------|-----------|
| asdm-admin | 15 | 23 | +320 | -45 | ✅ |
| asdm-docs | — | — | — | — | ⚠️ 分支 `release` 不存在，已跳过 |

**必须遍历步骤 3.2 中列出的每一个 Submodule**，逐一执行以下命令，不可遗漏任何一个子模块。如果用户指定了特定 Submodule，则仅遍历指定的子集。对于步骤 3.2c 中判定目标分支不存在的 Submodule，**跳过**该 Submodule 并在步骤 3.6 中标注。

完整的 Submodule 遍历列表（与步骤 3.2 一致）：

```text
asdm-admin, asdm-portal, asdm-agentorbit, asdm-cli, asdm-mcp-server-hosted, asdm-docs
```

根据步骤 3.2b 的处理结果，所有 Submodule（无论是本地已初始化还是通过 `--no-checkout` 克隆）均已在子模块路径下可用，命令统一。根据步骤 3.2c 的分支检查结果，对于目标分支不存在的 Submodule，**跳过**该 Submodule 并在步骤 3.6 中标注。

**Tag 范围**（无分支前缀，Tag 已标识具体 commit）：

```bash
cd <workspace-root>/<submodule-path> && git log --oneline --no-merges <from-tag>..<to-tag>
```

**时间段范围**（需分支前缀，限定扫描范围）：

```bash
cd <workspace-root>/<submodule-path> && git log <target-branch> --oneline --no-merges --since="<from-date>" --until="<to-date>"
```

**遍历示例**：

```bash
# Tag 范围
for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  echo "=== ${submodule} ==="
  cd <workspace-root>/${submodule} && git log --oneline --no-merges <from-tag>..<to-tag>
done

# 时间段范围
TARGET_BRANCH="${target-branch:-release}"

for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  echo "=== ${submodule} ==="
  cd <workspace-root>/${submodule} && git log ${TARGET_BRANCH} --oneline --no-merges --since="<from-date>" --until="<to-date>"
done
```

收集以下信息（每个 Submodule 均需记录，包括无变更的）：

- 每个 Submodule 的提交数量
- 每次提交的 hash 和消息
- 记录无变更的 Submodule（提交数量为 0）

#### 3.4 逐 Submodule 获取文件变更概览

**必须遍历步骤 3.2 中列出的每一个 Submodule**，逐一执行以下命令，不可遗漏。如果用户指定了特定 Submodule，则仅遍历指定的子集。

根据步骤 3.2b 的处理结果，所有 Submodule 均已在子模块路径下可用，命令统一。对于步骤 3.2c 中判定目标分支不存在的 Submodule，**跳过**。`git diff` 命令**不加**分支前缀（分支前缀会被误认为第一个 commit 参数，导致 diff 对象错误），时间段范围通过子命令 `git log <target-branch>` 定位起止 commit。

**Tag 范围**（无分支前缀）：

```bash
cd <workspace-root>/<submodule-path> && git diff --stat <from-tag>..<to-tag>
```

**时间段范围**（分支仅在子命令中，diff 本身不加分支前缀）：

```bash
cd <workspace-root>/<submodule-path> && git diff --stat $(git log -1 --format=%H --before="<from-date>" <target-branch>)..$(git log -1 --format=%H --before="<to-date>" <target-branch>)
```

**遍历示例**：

```bash
# Tag 范围
for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  echo "=== ${submodule} ==="
  cd <workspace-root>/${submodule} && git diff --stat <from-tag>..<to-tag>
done

# 时间段范围
TARGET_BRANCH="${target-branch:-release}"

for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  echo "=== ${submodule} ==="
  cd <workspace-root>/${submodule} && git diff --stat $(git log -1 --format=%H --before="<from-date>" ${TARGET_BRANCH})..$(git log -1 --format=%H --before="<to-date>" ${TARGET_BRANCH})
done
```

> **时间段 diff 说明**：时间段模式下的 diff 需要先通过 `git log <target-branch>` 在目标分支上定位起止时间点的提交，再进行差异比较。如果无法精确定位时间点提交，可改用 `git log <target-branch> --stat --since="<from-date>" --until="<to-date>"` 获取提交级别的变更概览。

收集以下信息（每个 Submodule 均需记录，包括无变更的）：

- 变更文件数量
- 新增/修改/删除的文件列表
- 各文件变更行数统计

#### 3.5 逐 Submodule 获取代码差异详情

**必须遍历步骤 3.2 中列出的每一个 Submodule**，逐一执行以下命令，不可遗漏。如果用户指定了特定 Submodule，则仅遍历指定的子集。

> **注意**：对于有变更的 Submodule 必须获取代码差异详情；对于无变更的 Submodule 可跳过此步骤。

根据步骤 3.2b 的处理结果，所有 Submodule 均已在子模块路径下可用，命令统一。对于步骤 3.2c 中判定目标分支不存在的 Submodule，**跳过**。`git diff` 命令**不加**分支前缀，时间段范围通过子命令 `git log <target-branch>` 定位起止 commit。

**Tag 范围**（无分支前缀）：

```bash
cd <workspace-root>/<submodule-path> && git diff <from-tag>..<to-tag>
```

**时间段范围**（分支仅在子命令中，diff 本身不加分支前缀）：

```bash
cd <workspace-root>/<submodule-path> && git diff $(git log -1 --format=%H --before="<from-date>" <target-branch>)..$(git log -1 --format=%H --before="<to-date>" <target-branch>)
```

**遍历示例**：

```bash
# Tag 范围
for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  echo "=== ${submodule} ==="
  cd <workspace-root>/${submodule} && git diff <from-tag>..<to-tag>
done

# 时间段范围
TARGET_BRANCH="${target-branch:-release}"

for submodule in asdm-admin asdm-portal asdm-agentorbit asdm-cli asdm-mcp-server-hosted asdm-docs; do
  echo "=== ${submodule} ==="
  cd <workspace-root>/${submodule} && git diff $(git log -1 --format=%H --before="<from-date>" ${TARGET_BRANCH})..$(git log -1 --format=%H --before="<to-date>" ${TARGET_BRANCH})
done
```

> **时间段 diff 说明**：与文件变更概览相同，时间段模式下需先通过 `git log <target-branch>` 在目标分支上定位起止时间点提交再 diff。如果无法精确定位，可改用 `git log -p <target-branch> --since="<from-date>" --until="<to-date>"` 逐提交查看差异详情。

对每个有变更的 Submodule，分析差异内容，重点关注：

- 新增的函数/方法/类
- 修改的函数/方法/类
- 删除的函数/方法/类
- 配置文件变更
- 数据库迁移变更
- 依赖版本变更

#### 3.6 汇总变更统计

汇总**所有** Submodule 的变更统计（必须包含步骤 3.2 中列出的全部子模块，无论是否有变更）：

| Submodule | 提交数 | 变更文件数 | 新增行数 | 删除行数 | 是否有变更 |
|-----------|--------|-----------|---------|---------|-----------|
| asdm-admin | <数量> | <数量> | <数量> | <数量> | ✅/— |
| asdm-portal | <数量> | <数量> | <数量> | <数量> | ✅/— |
| asdm-agentorbit | <数量> | <数量> | <数量> | <数量> | ✅/— |
| asdm-cli | <数量> | <数量> | <数量> | <数量> | ✅/— |
| asdm-mcp-server-hosted | <数量> | <数量> | <数量> | <数量> | ✅/— |
| asdm-docs | <数量> | <数量> | <数量> | <数量> | ✅/— |

### 4. 读取缺陷和用户故事清单

#### 4.1 读取缺陷清单

如果用户提供了缺陷清单：

- 如果是文件路径，读取文件内容
- 如果是直接提供的列表，直接使用
- 解析缺陷 ID、标题、描述、状态等信息

#### 4.2 读取用户故事清单

如果用户提供了用户故事清单：

- 如果是文件路径，读取文件内容
- 如果是直接提供的列表，直接使用
- 解析用户故事 ID、标题、描述、DoD、状态等信息

**注意**：如果用户未提供缺陷或用户故事清单，跳过关联匹配步骤，仅基于代码差异生成 Release Note。

### 5. 分析和分类代码变更

根据收集的信息，对代码变更进行分类分析。

#### 5.1 Submodule 到功能模块的映射

根据代码变更涉及的 Submodule 和文件路径，将变更映射到功能模块列表中的对应模块。

**映射规则**：

| Submodule | 主要关联功能模块 | 映射依据 |
|-----------|-----------------|----------|
| asdm-admin | 认证与用户管理(1)、组织管理(2)、项目管理(3)、资源库管理(4)、工作区管理(5)、流水线集成(6)、制品与历史记录(7)、集成与工具链(8)、系统设置(9)、API集成能力(10)、仪表盘(11)、MCP Hosting(13)、AgentOrbit集成(15) | 后端服务覆盖大部分业务模块 |
| asdm-portal | 认证与用户管理(1)、仪表盘(11) | 用户门户前端 |
| asdm-agentorbit | AgentOrbit集成(15)、工作区管理(5) | AgentOrbit 前端+后端 |
| asdm-cli | CLI工具(12) | CLI 命令行工具 |
| asdm-mcp-server-hosted | ASDM MCP服务器(14)、API集成能力(10) | MCP 托管服务器 |
| asdm-docs | — | 文档站，非核心功能模块 |

**注意**：以上映射仅为初始参考，AI 模型应结合实际代码变更内容和功能模块列表进行智能映射。具体变更可能涉及多个模块，例如：

- `asdm-admin` 中认证相关代码变更 → 认证与用户管理(1)
- `asdm-admin` 中组织相关代码变更 → 组织管理(2)
- `asdm-admin` 中项目相关代码变更 → 项目管理(3)
- `asdm-admin` 中上下文空间相关代码变更 → 资源库管理(4)

#### 5.2 按变更类型分类

将变更分为以下类别：

- **新功能（New Features）**：新增的功能、API、模块
- **功能优化（Enhancements）**：性能优化、重构、用户体验改进
- **Bug 修复（Bug Fixes）**：修复的问题
- **数据/配置变更（Data & Config Changes）**：数据库迁移、配置项变更
- **依赖变更（Dependencies）**：第三方依赖版本变更
- **上线影响与回滚（Impact & Rollback）**：上线影响评估及回滚策略

#### 5.3 将代码差异与功能模块、缺陷/用户故事关联

**与功能模块关联**：

- 根据代码变更涉及的 Submodule 和文件路径，映射到功能模块列表中的对应模块
- 根据提交消息中的关键词（如模块名、功能名）进行关联
- 根据代码变更涉及的业务逻辑进行推断关联
- 无法映射到具体功能模块的变更归类为"其他"

**与缺陷/用户故事关联**（如果提供了清单）：

- 根据提交消息中的关键词（如缺陷 ID、用户故事 ID）进行关联
- 根据代码变更涉及的模块和功能进行推断关联
- 无法关联的变更归类为"其他"

### 6. 生成 Release Note 文档

根据分类结果，按照 Release Note 规范模板生成文档。

#### 6.1 文档模板

完整模板结构参见 `release-note-spec.md`（`.asdm/toolsets/release-note/spec/release-note-spec.md`）的 Document Structure 章节。

#### 6.2 内容编写要求

- 新功能以表格形式展示，包含功能模块、Submodule、功能点、说明、相关需求
- 功能优化以表格形式展示，包含功能模块、Submodule、优化点、效果
- Bug 修复以表格形式展示，包含功能模块、Issue ID、问题描述、影响范围
- 数据/配置变更和依赖变更以表格形式展示，包含 Submodule 信息
- 关联用户故事时以 DoD 表格形式展示，包含用户故事 ID、标题、DoD 条件和完成状态
- 上线影响与回滚策略为必填章节
- 功能模块列使用"编号+名称"格式（如"1 认证与用户管理"），便于对照功能模块列表
- 描述应面向最终用户，避免技术细节
- 使用简洁、专业的语言
- 变更概览表格汇总所有 Submodule 的变更统计

### 7. 保存 Release Note 文档

将生成的 Release Note 保存到工作区：

- **Markdown 文件**：`.asdm/workspace/release-notes/release-note-<version>.md`

确保 `.asdm/workspace/release-notes/` 目录存在，不存在则创建。

### 8. 验证和展示

#### 8.1 验证 Release Note

验证生成结果：

- Markdown 文件格式正确
- 所有分类条目均有描述
- 功能模块映射正确（与 `docs/planning/Modules/README.md` 对照）
- 关联的缺陷/用户故事 ID 正确
- 上线影响与回滚策略已提供
- 无空章节（若某分类无内容则不展示该章节）
- 变更概览表格包含所有已扫描的 Submodule

#### 8.2 展示摘要

向用户展示 Release Note 摘要：

- 系统名称、版本号和发布类型
- 变更概览（各 Submodule 变更统计）
- 各分类条目数量
- 上线影响与回滚策略要点
- 文件保存路径

#### 8.3 清理克隆的 Submodule 目录（可选）

如果在步骤 3.2b 中使用了 `git clone --no-checkout` 克隆了未初始化的 Submodule，Release Note 生成完成后可选择清理或保留：

**方案一：保留（推荐）** — 克隆的 Submodule 包含完整 Git 历史，保留后可直接用于后续开发或再次生成 Release Note，无需重新克隆。

**方案二：清理** — 如需释放磁盘空间，逐个删除通过 `--no-checkout` 克隆的 Submodule 目录：

```bash
# 仅删除步骤 3.2b 中通过 --no-checkout 克隆的 Submodule 目录
# 已初始化的 Submodule 不受影响
for submodule in <通过克隆创建的子模块列表>; do
  rm -rf <workspace-root>/${submodule}
done
```

> **注意**：`--no-checkout` 克隆的目录仅含 `.git` 和少量元数据，不包含工作区文件，磁盘占用相对较小。保留这些目录可避免后续重复克隆的开销。

## Execution Guidelines

### When to Use This Action

- ASDM Platform 发版时需要生成版本说明文档
- 需要扫描多个 Submodule 的代码变更并汇总
- 需要将代码变更按功能模块归类到发版说明
- 需要规范化发版文档的格式和内容

### Git 范围选择

| 场景 | 推荐方式 | 原因 |
|------|----------|------|
| 正式发版 | Tag | Tag 标识了明确的发布版本，范围精确 |
| 开发中迭代 | 时间段 | 尚未打 Tag，需要查看阶段性进展 |
| 热修复验证 | Tag | 热修复通常有明确的版本标记 |
| 日常变更汇总 | 时间段 | 适合周期性汇总最近变更 |

### 提交消息分类规则

| 前缀 | 分类 |
|------|------|
| `feat:` / `feature:` | 新功能 |
| `fix:` / `bugfix:` | Bug 修复 |
| `refactor:` / `perf:` / `enhance:` | 功能优化 |
| `data:` / `config:` / `migration:` | 数据/配置变更 |
| `chore:` / `deps:` | 依赖变更 |
| `breaking:` / `BREAKING CHANGE` | 上线影响 |
| `docs:` | 备注 |

### Submodule 扫描注意

- 对于大型 Submodule（如 `asdm-admin`），重点关注业务逻辑变更而非纯重构
- 对于 `asdm-cli`，实际代码在 `asdm-cli/asdm-bootstrapper-cli` 子目录中
- 时间段模式下，建议先通过 `git log --oneline --since="<from>" --until="<to>"` 确认提交情况
- 如果某个 Submodule 的 Tag 不存在，建议用户改用时间段范围
- **远程克隆模式**：当 Submodule 未本地初始化时，使用 `git clone --no-checkout` 克隆完整 Git 历史到子模块路径。不检出工作区文件，克隆后命令与已初始化 Submodule 完全一致
- **远程克隆凭证**：Azure DevOps 仓库使用 SSH（`git@ssh.dev.azure.com`），GitHub 仓库也使用 SSH，需确保本机 SSH Key 已配置且有权访问
- **远程克隆故障回退**：若克隆失败（权限不足、网络不通），提示用户执行 `git submodule update --init` 或手动克隆
- **克隆目录清理**：步骤 8.3 可选择清理通过 `--no-checkout` 克隆的子模块目录，或保留以便后续使用

### 内容编写规范

详细编写规范参见 `release-note-spec.md` 的 Section Guidelines 和 Best Practices 章节。核心原则：

- 面向最终用户，使用用户能理解的语言
- 模块列使用"编号+名称"格式（如"1 认证与用户管理"）
- 上线影响与回滚策略为必填章节
- 数据/配置变更、依赖变更必须明确列出
- 无内容的章节应从文档中移除

### 错误处理

| 错误场景 | 处理方式 |
|----------|----------|
| Tag 不存在 | 提示用户检查 Tag 是否正确，并列出可用的 Tag（`git tag -l`） |
| 时间段格式无效 | 提示用户使用正确格式：相对时间（`2.weeks.ago`）或绝对时间（`2026-05-01`） |
| 时间段内无提交 | 提示用户指定的时间段内无代码变更，建议调整时间范围 |
| Submodule 未初始化 | 自动从 `.gitmodules` 读取远程 URL，使用 `git clone --no-checkout` 克隆到子模块路径后执行 Git 命令；若克隆失败（无权限/网络不通），提示用户执行 `git submodule update --init` 或检查 SSH/HTTPS 凭证 |
| Submodule 中 Tag 不存在 | 跳过该 Submodule 并记录警告，继续扫描其他 Submodule；或建议用户改用时间段范围 |
| 目标分支不存在（本地和远程均无） | 跳过该 Submodule 并在变更统计表中标注 `⚠️ 分支 '<branch>' 不存在，已跳过`；列出该 Submodule 所有可用分支（`git branch -r`）供用户参考；若所有 Submodule 的目标分支均不存在，提示用户检查分支名称是否正确，并建议使用 `--branch` 指定正确的分支 |
| 目标分支仅存在于远程 | 自动创建本地跟踪分支（`git branch <branch> origin/<branch>`），继续执行扫描 |
| `git fetch` 失败（网络/权限） | 记录警告，仅依赖本地分支检查；若本地也不存在则按"目标分支不存在"处理 |
| 无代码差异 | 提示用户检查两次 Tag 或时间段之间是否有变更 |
| 缺陷/用户故事清单格式错误 | 提示用户修正格式或跳过关联步骤 |
| 输出目录不存在 | 自动创建目录 |
| 权限不足 | 提示用户检查文件系统权限 |
| 功能模块列表文件不存在 | 提示用户检查 `docs/planning/Modules/README.md` 是否存在 |

## Usage

要使用此指令，AI 模型应：

1. 读取功能模块列表（`docs/planning/Modules/README.md`）
2. 接收用户提供的发版参数（详见 Step 1 参数定义）
3. 扫描所有 Submodule 的 Git 差异
4. 读取并解析缺陷和用户故事清单
5. 分析代码变更并映射到功能模块
6. 按 Release Note 规范模板生成文档
7. 保存文件到工作区
8. 验证并向用户展示摘要

### 参数输入方式

用户可以通过以下方式提供参数：

#### 方式一：在斜杠命令中直接提供参数

```shell
/asdm-generate-release-note <from-tag> <to-tag> [--branch <branch-name>]
```

**参数说明**：

- `<from-tag>`：Git 起始 Tag（必填）— 发版起始版本的 Git Tag
- `<to-tag>`：Git 目标 Tag（必填）— 发版目标版本的 Git Tag
- `--branch <branch-name>`：目标分支（可选）— 扫描代码差异时使用的 Git 分支，默认为 `release`

**示例**：

```shell
# 使用 Git Tag（默认扫描 release 分支）
/asdm-generate-release-note v1.0.0 v1.1.0

# 使用带前缀的 Tag，指定 main 分支
/asdm-generate-release-note release-r03 release-r04 --branch main

# 使用 Git Tag，指定 feat/xxx 分支
/asdm-generate-release-note v1.0.0 v1.1.0 --branch feat/xxx
```

#### 方式一（备选）：使用时间段范围

```shell
/asdm-generate-release-note --since <from-date> [--until <to-date>] [--branch <branch-name>]
```

**参数说明**：

- `--since <from-date>`：起始时间（必填）— 支持相对时间或绝对时间
- `--until <to-date>`：目标时间（可选）— 默认为 `now`
- `--branch <branch-name>`：目标分支（可选）— 扫描代码差异时使用的 Git 分支，默认为 `release`

**示例**：

```shell
# 使用相对时间（默认扫描 release 分支）
/asdm-generate-release-note --since 2.weeks.ago

# 使用绝对时间，指定 dev 分支
/asdm-generate-release-note --since 2026-05-01 --branch dev

# 指定起止时间和分支
/asdm-generate-release-note --since 2026-05-01 --until 2026-06-01 --branch main
```

#### 方式二：在对话中提供完整参数

如果需要同时提供系统信息和缺陷/用户故事清单，建议在对话中按以下格式提供：

**使用 Tag 范围**：

```markdown
/asdm-generate-release-note

起始 Tag：v1.0.0
目标 Tag：v1.1.0
目标分支：release
系统名称：ASDM Platform
发布类型：常规迭代
影响范围：Web 端 / 后台服务 / CLI

缺陷清单：
- BUG-1001: 用户登录页面在移动端布局异常
- BUG-1002: 搜索结果排序不正确

用户故事清单：
- US-2001: 支持多语言切换
- US-2002: 新增数据导出为 Excel 功能

指定 Submodule：asdm-admin,asdm-agentorbit
```

**使用时间段范围**：

```markdown
/asdm-generate-release-note

起始时间：2026-05-01
目标时间：2026-06-01
目标分支：main
版本号：v1.2.0
系统名称：ASDM Platform
发布类型：常规迭代
影响范围：Web 端 / 后台服务 / CLI

缺陷清单：
- BUG-1001: 用户登录页面在移动端布局异常

指定 Submodule：asdm-admin,asdm-agentorbit
```

#### 方式三：通过文件提供缺陷和用户故事清单

如果缺陷或用户故事清单内容较多，可以提前保存为文件，然后引用文件路径：

**1. 创建缺陷清单文件**（如 `.asdm/workspace/release-notes/bugs.md`）：

```markdown
# 缺陷清单

| 缺陷ID | 标题 | 描述 | 状态 |
|--------|------|------|------|
| BUG-1001 | 用户登录页面在移动端布局异常 | 移动端登录页面元素重叠导致无法正常登录 | 已修复 |
| BUG-1002 | 搜索结果排序不正确 | 按日期排序时结果顺序颠倒 | 已修复 |
```

**2. 创建用户故事清单文件**（如 `.asdm/workspace/release-notes/stories.md`）：

```markdown
# 用户故事清单

| 用户故事ID | 标题 | 描述 | 状态 |
|-----------|------|------|------|
| US-2001 | 支持多语言切换 | 用户可以在设置中切换界面语言（中/英/日） | 已完成 |
| US-2002 | 数据导出为 Excel | 支持将列表数据导出为 .xlsx 格式文件 | 已完成 |
```

**3. 在对话中引用文件**：

```markdown
/asdm-generate-release-note v1.0.0 v1.1.0

缺陷清单文件：.asdm/workspace/release-notes/bugs.md
用户故事清单文件：.asdm/workspace/release-notes/stories.md
```

#### 方式四：仅提供范围（不提供清单）

如果不需要关联缺陷和用户故事，仅基于代码差异生成 Release Note：

**Tag 范围**：

```shell
# 默认扫描 release 分支
/asdm-generate-release-note v1.0.0 v1.1.0

# 指定分支
/asdm-generate-release-note v1.0.0 v1.1.0 --branch main
```

**时间段范围**：

```shell
# 默认扫描 release 分支
/asdm-generate-release-note --since 2.weeks.ago

# 指定分支
/asdm-generate-release-note --since 2.weeks.ago --branch dev
```

AI 模型将扫描所有 Submodule，根据 Git 提交记录和代码差异自动分析、映射功能模块并分类变更内容。

### Git 范围参考

Git Tag 和时间段两种范围方式的技术参考（选择建议见 Execution Guidelines > Git 范围选择）。

**Tag 相关命令**：

```bash
git tag -l                                          # 查看所有 tag
git tag --sort=-creatordate | head -10               # 查看最近 tag
cd <submodule-path> && git tag -l                    # 查看 Submodule 的 tag
```

**分支相关命令**：

```bash
cd <submodule-path> && git branch -r                 # 查看 Submodule 的所有远程分支
cd <submodule-path> && git branch --list release      # 检查本地是否有 release 分支
cd <submodule-path> && git branch -r --list origin/release  # 检查远程是否有 release 分支
cd <submodule-path> && git fetch origin               # 获取远程分支引用
```

**Tag 命名规范**：语义版本（`v1.0.0`）、发布版本（`release-r03`）、日期版本（`2026.06.01`）

**时间段格式**：

| 格式 | 示例 | 说明 |
|------|------|------|
| 相对时间 | `2.weeks.ago`、`1.month.ago` | 适合快速查看近期变更 |
| 绝对日期 | `2026-05-01` | 指定具体日期 |
| 绝对时间 | `2026-05-01T00:00:00` | 精确到时分秒 |

**时间段相关命令**：

```bash
git log --oneline --since="2026-05-01" --until="2026-06-01"   # 指定时间段
git log --oneline --since="2.weeks.ago"                        # 最近 2 周
```

### 缺陷和用户故事清单格式

无论以何种方式提供，清单内容应包含以下信息：

**缺陷清单**：

- **缺陷 ID**：如 `BUG-1001`、`DEF-2001`
- **标题**：缺陷的简要描述
- **描述**（可选）：缺陷的详细说明
- **状态**（可选）：如"已修复"、"已关闭"

**用户故事清单**：

- **用户故事 ID**：如 `US-2001`、`STORY-100`
- **标题**：用户故事的简要描述
- **描述**（可选）：用户故事的详细说明
- **DoD**（可选）：完成的定义/条件
- **状态**（可选）：如"已完成"、"已实现"

## Output Summary

完成此 action 后，将生成以下内容：

- Release Note Markdown 文档：`.asdm/workspace/release-notes/release-note-<version>.md`

文件保存于 `.asdm/workspace/release-notes/` 目录中。
