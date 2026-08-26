# ASDM Action: Auto Test Run

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
  "name": "auto-test-run",
  "displayName": "执行自动化测试",
  "description": "读取全部 YAML DSL 测试用例后自动编排执行流水线：构建用例先后依赖关系（DAG）与参数依赖关系（outputs 引用链），拓扑分层生成 sh 执行脚本，按依赖顺序执行（Playwright/Selenium 双框架），失败自动 BLOCKED 下游用例，生成结果 JSON、参数上下文与失败截图",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.2"
  },
  "scenario": "auto-test-pipeline-execution"
}
```

## Purpose

本 action 是 Web Auto Tester 的核心命令。分为两大执行形态：

1. **流水线模式（默认，case 为目录或留空）**：读取目录下**所有** YAML DSL 用例 → 自动编排执行流水线（构建用例先后依赖关系 DAG + 用例间参数依赖关系）→ 生成 sh 执行脚本 → 按拓扑分层顺序逐用例执行（每用例走 7 阶段规范）→ 输出流水线级汇总
2. **单用例模式（case 为单个文件）**：跳过编排，直接对该用例执行 7 阶段规范流程（向后兼容）

## ⛔ 用例数据保真原则（最高优先级 — 违反即为执行失败）

执行测试用例时，**必须严格提取并使用 YAML 用例文件中定义的数据，严禁自行解读、修改、替换或编造**。具体规则：

1. **URL 严格使用**：`metadata.targetUrl` 和 `navigate` 步骤中的 URL 必须原样使用，不得替换为其他 URL
2. **输入值严格使用**：`type`/`select` 步骤中的 `value` 必须原样使用，不得修改或替换为其他值
3. **选择器严格使用**：Step 中的 `target`（CSS 选择器）必须原样使用，不得自行修改或替换选择器
4. **参数严格解析**：`{{params.xxx}}` 必须从用例 `params` 字段精确查找替换，不得猜测或编造参数值
5. **跨用例参数严格传递**：`{{outputs.X.y}}` 必须从上游用例 X 执行后的真实提取结果（参数上下文文件）读取，不得猜测、缓存旧值或编造
6. **断言数据严格使用**：`assert` 步骤中的 `target`/`expected`/`message` 必须原样使用，不得修改预期值或断言目标
7. **元数据严格使用**：`metadata` 中的 `timeout`/`browser`/`viewport` 等必须按用例定义使用，不得随意更改
8. **步骤顺序严格执行**：按用例定义的 stages/steps 顺序逐一执行，不得跳过、调换或合并步骤
9. **依赖关系不得虚构**：编排阶段的依赖图只能来自可追溯证据（`dependsOn` 声明、`{{outputs.X.y}}` 引用、明确的推断信号），不得凭"感觉"编造用例先后关系
10. **禁止智能替换**：不得因为"觉得更合理"而替换用例中的任何数据（如用例写的是 `.login-btn`，不得因为页面上看到的是 `#loginButton` 就自行替换）

### 🚨 典型失败案例（务必避免）

以下是一次**真实执行失败**的案例，展示了数据提取错误导致的后果：

> **YAML 用例定义**：
> ```yaml
> params:
>   email: super-admin@asdm.ai
>   password: superadmin@20260214
> ```
>
> **Agent 实际执行时使用了**：`admin / Admin@123`（完全编造的值，YAML 中根本不存在）
>
> **结果**：登录失败 → 10 个后续用例全部 BLOCKED → 通过率 0%
>
> **根因**：Agent 没有从 YAML `params` 字段提取数据，而是使用了自身"记忆"中的默认凭据

**此案例表明：即使规则写了"禁止编造"，如果缺乏强制验证机制，Agent 仍可能绕过规则。因此本 Action 新增了"数据提取自检"强制步骤（见 Step 3）。**

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有生成的文件、注释和文档均使用中文。

## Context Injection

在执行测试前，AI Agent **必须**读取并理解以下规范文件：

### Required Context Files

1. **YAML DSL 规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
   - Purpose: 了解用例格式定义、Schema 校验规则、操作类型映射、断言类型

2. **执行引擎规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
   - Purpose: 了解 7 阶段执行流程、操作映射、断言判定、截图策略、结果记录规则

3. **目标用例文件** (Required)
   - Path: 用户指定或 `.asdm/workspace/auto-test/cases/*.yaml`
   - Purpose: 加载并执行测试用例（流水线模式下加载目录下**全部**用例）

## 编排 DSL 扩展定义（本 Action 使用的用例级新字段）

编排引擎在标准 YAML DSL 基础上识别以下扩展字段（均放在 `metadata` 内，与现有 Schema 兼容，未声明时走自动推断规则）：

### 1. 用例级依赖声明 — `metadata.dependsOn`

```yaml
metadata:
  dependsOn:
    - user-login-test        # 本用例必须在 user-login-test 成功（pass）后才能执行
    - data-init-test         # 支持多个依赖（全部 pass 才执行本用例）
```

| 规则 | 说明 |
|------|------|
| 值类型 | 字符串数组，每项为被依赖用例的 `name` |
| 依赖强度 | **硬依赖**：上游 fail/error → 本用例 BLOCKED（skip） |
| 引用校验 | 依赖名必须存在于本次加载的用例集合中，否则报错终止 |

### 2. 输出声明 — `metadata.outputs`

声明本用例执行后向流水线暴露哪些输出值（供下游用例通过 `{{outputs.X.y}}` 引用）：

```yaml
metadata:
  outputs:
    auth_token:              # 输出名（[a-z_]+）
      from: step             # 提取来源（当前仅支持 step：从步骤结果提取）
      stepIndex: 5           # 全局步骤序号（1-based，跨 Stage 连续编号）
      field: actual          # 提取 StepResult 的字段（默认 actual）
    order_id:
      from: step
      stepIndex: 8
      field: actual
```

| 规则 | 说明 |
|------|------|
| 输出提取时机 | 本用例执行完成、AutoTestResult JSON 生成后（Step 7） |
| 提取来源 | `from: step` → 从 `stepResults[stepIndex-1][field]` 提取 |
| 提取失败 | 步骤不存在 / 字段为空 → 输出标记缺失，引用该输出的下游用例 BLOCKED |
| 声明必要性 | 下游引用 `{{outputs.X.y}}` 而 X 未声明 `outputs.y` → 报错终止（**禁止猜测输出值**） |

### 3. 跨用例参数引用 — `{{outputs.{caseName}.{outputName}}}`

```yaml
params:
  token: "{{outputs.user-login-test.auth_token}}"   # 引用上游用例的输出
  order_id: "{{outputs.order-create-test.order_id}}"
```

| 规则 | 说明 |
|------|------|
| 语法 | `{{outputs.{上游用例name}.{上游输出名}}}`，花括号内无空格 |
| 隐式依赖 | 出现该引用即自动建立**硬依赖**（等效 dependsOn，无需重复声明） |
| 解析时机 | 上游用例执行完毕、输出写入参数上下文文件后，本用例执行前 |
| 解析失败 | 上游未执行 / 输出缺失 → 本用例 BLOCKED，**不得用默认值或编造值替代** |

## Steps

```text
用例目录（全部 YAML）
    │
    ▼
[Step 1] 用例全量加载与数据提取 ──→ YAML 逐字解析 → Schema 校验 → 数据提取摘要
    │
    ▼
[Step 2] 流水线编排（核心） ──→ 依赖关系构建 → 参数依赖构建 → DAG+环检测
    │                            → 拓扑分层 → 编排图输出 → 生成 sh 执行脚本
    │
    ▼
[Step 3] 上下文准备与数据自检 ──→ metadata 读取 → 参数解析（本地+跨用例）→ 6项自检
    │
    ▼
[Step 4] 执行引擎 ──→ 按编排顺序逐用例：依赖检查（BLOCKED判定）→ 逐步骤执行
    │
    ▼
[Step 5] 断言判定 ──→ A1~A8 断言类型 → 结果映射 pass/fail/error/skip
    │
    ▼
[Step 6] 截图采集 ──→ on-fail/full/always 三策略 → 文件命名 → 存储路径
    │
    ▼
[Step 7] 结果记录与输出传递 ──→ AutoTestResult JSON → outputs 提取 → ctx 写入 → 状态回写
    │
    ▼
[Step 8] 报告输出 ──→ 流水线级汇总表格 + 结构化 JSON + sh 脚本/产物路径
```

### Step 1: 用例全量加载与数据提取（Phase 1）

1. 根据用户输入参数 `case` 定位用例：
   - 指定**单个文件**路径 → 进入**单用例模式**（跳过 Step 2 编排，直接从 Step 3 开始）
   - 指定**目录**路径 → 进入**流水线模式**，加载目录下所有 `.yaml` 文件
   - 未指定 → 进入**流水线模式**，加载 `.asdm/workspace/auto-test/cases/` 下所有 `.yaml` 文件
2. **逐字读取**每个 YAML 文件内容，**逐字段精确提取**所有用例数据：
   - 提取 `name`、`description`、`framework`、`capture`、`tags`、`source` — 原样保留
   - 提取 `params` — **逐键逐值**存入参数上下文，供后续 `{{params.xxx}}` / `{{outputs.X.y}}` 解析（**此步骤是数据保真的核心，必须确保提取的值与 YAML 原文完全一致**）
   - 提取 `metadata` — 存入执行上下文（targetUrl/timeout/browser/viewport/dependsOn/outputs/prerequisites）
   - 提取 `stages[].name` — 原样保留阶段名称
   - 提取 `stages[].steps[]` — **逐字段精确提取**每个 step 的 action/target/value/timeout/pageTransition/capture/assertions，不得遗漏或修改任何字段
   - 提取 `assertions[]` — 精确提取 type/target/expected/message，原样保留
3. 对每个用例执行 Schema 校验（参照 `auto-test-dsl-spec.md` §10 校验规则）：
   - `name` 非空 ✅
   - `stages` 数组长度 ≥ 1 ✅
   - 每个 Stage: `name` 非空 + `steps` ≥ 1 ✅
   - 每个 Step: `action` 必填 + `target` 必填 ✅
   - type/select 操作: `value` 必填 ✅
   - assert 操作: `assertions` ≥ 1 ✅
   - `metadata.dependsOn` 依赖名存在于用例集合 ✅（编排扩展校验）
   - `{{outputs.X.y}}` 引用的 X 已声明 `outputs.y` ✅（编排扩展校验）
4. 校验失败 → 报错并终止，提示用户修正用例
5. **用例名冲突检查**：多个 YAML 文件出现相同 `name` → 报错终止（依赖图以 name 为节点标识，必须唯一）
6. **【强制】输出数据提取摘要**：所有用例解析完成后，**必须**输出以下格式的数据提取摘要，供自检验证：

```
📋 用例清单与数据提取摘要 — 共 {N} 个用例
┌──────────────────────┬──────────┬──────────────────────────────┬─────────────────┐
│ 用例名称             │ 框架     │ params（必须与YAML原文一致）   │ metadata 摘要    │
├──────────────────────┼──────────┼──────────────────────────────┼─────────────────┤
│ user-login-test      │playwright│ email=super-admin@asdm.ai    │ url=…dt02.asdm  │
│                      │          │ password=superadmin@2026…    │ timeout=30      │
├──────────────────────┼──────────┼──────────────────────────────┼─────────────────┤
│ order-create-test    │playwright│ token={{outputs.user-login-  │ url=…dt02.asdm  │
│                      │          │ test.auth_token}}            │ dependsOn: 1    │
│                      │          │ remark=备注测试               │ outputs: 1      │
└──────────────────────┴──────────┴──────────────────────────────┴─────────────────┘
```

每个含 `{{params.xxx}}` 或 `{{outputs.X.y}}` 的用例，另需输出**步骤级参数解析预览**：

```
📋 步骤参数解析预览 — {用例名称}
┌─────┬──────────────────────────────┬────────────────────────────────────┐
│ 步骤│ value（解析前）               │ value（解析后）                     │
├─────┼──────────────────────────────┼────────────────────────────────────┤
│ S2  │ {{params.email}}             │ super-admin@asdm.ai（本地参数）      │
│ S5  │ {{outputs.X.auth_token}}     │ ⏳ 运行时解析（等上游执行后注入）     │
└─────┴──────────────────────────────┴────────────────────────────────────┘
```

### Step 2: 流水线编排与 sh 脚本生成（Phase 1.5 — 核心编排阶段）

> 单用例模式跳过本步骤。流水线模式**必须**完整执行本步骤后再进入执行。

#### 2.1 用例先后依赖关系构建

对每个用例依次扫描依赖信号，按以下 **5 级优先级规则**构建依赖边：

| 优先级 | 依赖信号 | 依赖强度 | 可追溯性 | 判定规则 |
|:------:|---------|:--------:|---------|---------|
| D1 | `metadata.dependsOn` 显式声明 | **硬依赖** | YAML 原文 | 本用例 → 依赖所列全部用例 |
| D2 | params 含 `{{outputs.X.y}}` 引用 | **硬依赖** | YAML 原文 | 本用例 → X（隐式依赖，与 D1 等效） |
| D3 | 文件名数字前缀 `NN-name.yaml` | 软依赖（推断） | 文件名 | 前缀序号小者优先；仅对**同一系统**（同 targetUrl）且均无硬依赖的相邻序号用例建立 |
| D4 | tags 语义推断 | 软依赖（推断） | tags 字段 | ① 含 `auth`/`login`/`登录` 且无任何硬依赖 → 编排为根节点（Layer 1）；② 含 `create`/`add`/`new`/`创建` 的用例先于同系统含 `query`/`delete`/`查询`/`删除` 的用例 |
| D5 | 同系统分组 | 软依赖（分组） | metadata | 同 `targetUrl` 的用例归入同一执行组；不同系统的用例组之间**可并行** |

**硬依赖与软依赖的处理差异**：

| 维度 | 硬依赖（D1/D2） | 软依赖（D3/D4/D5） |
|------|----------------|-------------------|
| 失败传播 | 上游 fail/error → 下游 **BLOCKED（skip）** | 上游失败**不阻塞**下游正常执行 |
| 环检测 | 参与环检测，成环 → 报错终止 | 不参与环检测，成环 → 降级为同层并行 |
| 编排图标注 | 实线箭头 `──▶` | 虚线箭头 `┈┈▶`（标注"推断"及推断依据） |
| 参数传递 | 允许（outputs 引用仅存在于硬依赖链） | 不涉及 |
| 用户覆盖 | — | 用户补充 `dependsOn` 后升级为硬依赖 |

**依赖构建算法**：

```
初始化: G = (V, E_hard, E_soft)，V = 全部用例节点
for 每个用例 C in V:
  # D1: 显式声明
  for dep in C.metadata.dependsOn:
    assert dep ∈ V（否则报错终止）
    E_hard.add(dep → C)
  # D2: 参数引用扫描
  for (k, v) in C.params:
    for match in regex_findall("{{outputs\.([a-z0-9-]+)\.[a-z_]+}}", v):
      assert match ∈ V 且 match.metadata.outputs 含对应输出名（否则报错终止）
      E_hard.add(match → C)
  # D3: 文件名前缀（仅当 C 无硬依赖入边）
  ...
  # D4: tags 语义（仅当 C 无硬依赖入边）
  ...
# D5: 按 targetUrl 分组 → 并行组划分
```

#### 2.2 参数依赖关系构建

扫描所有用例 `params` 中的 `{{outputs.X.y}}` 引用，构建**参数依赖关系表**：

| 下游用例 | 参数名 | 引用语法 | 来源用例 | 来源输出 | 提取规则 | ctx 变量名 |
|---------|--------|---------|:-------:|:-------:|---------|-----------|
| order-create-test | token | `{{outputs.user-login-test.auth_token}}` | user-login-test | auth_token | step[5].actual | OUTPUT_USER_LOGIN_TEST__AUTH_TOKEN |
| order-query-test | order_id | `{{outputs.order-create-test.order_id}}` | order-create-test | order_id | step[8].actual | OUTPUT_ORDER_CREATE_TEST__ORDER_ID |

**ctx 变量名命名规则**：`OUTPUT_` + 用例名大写（`-` 转 `_`）+ `__` + 输出名大写（`_` 保留）。

**参数依赖校验**（任一失败 → 报错终止，禁止进入执行）：

1. 引用的上游用例 X 必须存在于本次用例集合
2. X 必须在 `metadata.outputs` 中声明了该输出名（**未声明不得猜测提取规则**）
3. X 必须是本用例的硬依赖（2.1 中 D2 已自动建立）
4. 同一参数不得同时引用多个不同来源（一个参数仅允许一个 `{{outputs.X.y}}` 引用）

#### 2.3 DAG 构建与环检测

1. 以用例 `name` 为节点，硬依赖边 + 软依赖边构成混合图
2. **硬依赖环检测**（Kahn 拓扑排序检测）：
   - 发现硬依赖环 → **报错终止**，输出环路径：`❌ 依赖闭环检测失败：A → B → C → A，请修正 metadata.dependsOn 或 outputs 引用`
   - 仅软依赖成环 → 软依赖边失效，相关用例归入同层并行，输出提示：`⚠️ 推断依赖成环（A ⇄ B），已降级为同层并行执行`
3. 孤立用例（无任何依赖边）→ 根节点，归入 Layer 1

#### 2.4 拓扑排序与执行分层

1. 对 DAG 执行 Kahn 拓扑排序，得到合法执行序列
2. **分层规则**：用例的层号 = 其全部硬依赖的最大层号 + 1（无硬依赖 → Layer 1）
3. 同层内排序：按文件名字典序（稳定、可复现）
4. 执行模式（`mode` 参数）：
   - `sequence`（默认）：严格按拓扑序列串行执行（含同层）
   - `parallel`：同层无相互依赖的用例并行执行（Agent 逐用例调度或后台并发），层间等待

#### 2.5 编排图与依赖表输出

**【强制】输出以下编排产物**（三件套：编排图 + 依赖表 + 参数依赖表）：

```
📐 用例执行流水线编排图 — PIPE-{YYYYMMDD}-{NNN}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
系统① https://platform-dt02.asdm.ai/
Layer 1:  [user-login-test]        [home-smoke-test]
              │
              │ 硬依赖: outputs.auth_token
              ▼
Layer 2:  [order-create-test]
              │
              │ 硬依赖: outputs.order_id        ┈┈▶ [order-list-test]
              ▼                                    （推断: create 先于 list）
Layer 3:  [order-query-test]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
系统② http://localhost:3001/
Layer 1:  [admin-login-selenium]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
统计: 用例 6 | 硬依赖边 2 | 推断依赖边 1 | 层数 3 | 并行组 2
```

（同时输出 Mermaid 版本，`graph TD`，硬依赖实线、软依赖虚线，供报告引用）

**用例依赖关系表**：

| 用例 | 层级 | 硬依赖 | 软依赖（推断依据） | 输出声明 | 执行模式 |
|------|:----:|--------|------------------|:-------:|:-------:|
| user-login-test | L1 | — | 根节点（tags: auth） | auth_token | 并行 |
| order-create-test | L2 | user-login-test | — | order_id | 串行 |
| order-query-test | L3 | order-create-test | — | — | 串行 |

#### 2.6 生成 sh 执行脚本

按以下规范生成 Bash 脚本，持久化到 `.asdm/workspace/auto-test/pipelines/pipeline-{YYYYMMDD}-{NNN}.sh`：

**脚本结构规范**（8 个区块，按序生成）：

```bash
#!/usr/bin/env bash
# ================================================================
# Web Auto Tester — 自动编排执行流水线脚本
# Pipeline ID : PIPE-20260826-001
# 生成时间    : 2026-08-26T10:30:00+08:00
# 用例总数    : 6 | 硬依赖边: 2 | 推断依赖边: 1 | 执行层数: 3
# 执行模式    : sequence
# 用法        :
#   bash pipeline-20260826-001.sh                    # 实际执行
#   bash pipeline-20260826-001.sh --dry-run          # 只打印执行计划
#   bash pipeline-20260826-001.sh --only order-query-test  # 只执行该用例及其依赖链
# 说明: 本脚本为编排产物，AI Agent 按脚本顺序解释执行每个
#       run_case 调用（执行体见函数内注释）；未来接入真实
#       Runner 后可将执行体替换为 CLI 调用。
# ================================================================
set -uo pipefail

# ---------- [区块1] 全局变量 ----------
PIPE_ID="PIPE-20260826-001"
MODE="sequence"
WS=".asdm/workspace/auto-test"
CASES_DIR="$WS/cases"
RESULTS_DIR="$WS/results"
PIPE_DIR="$WS/pipelines"
CTX_FILE="$PIPE_DIR/$PIPE_ID.ctx.env"        # 参数上下文（上游输出）
STATUS_FILE="$PIPE_DIR/$PIPE_ID.status"      # 流水线状态（KEY=VALUE）

# ---------- [区块2] 基础函数 ----------
log()  { echo "[$(date '+%H:%M:%S')] $*"; }
pass() { log "✅ $*"; }
fail() { log "❌ $*"; }
skip() { log "⏭️  $*"; }

init_pipeline() {
  mkdir -p "$RESULTS_DIR" "$PIPE_DIR"
  : > "$STATUS_FILE"
  cat > "$CTX_FILE" <<'EOF'
# Pipeline 参数上下文（上游用例输出自动注入，禁止手改）
EOF
}

# 依赖状态检查：上游全部 pass 才放行；否则本用例 BLOCKED
check_deps() {
  local case_name="$1"; shift
  for dep in "$@"; do
    local status
    status=$(grep -E "^${dep}=" "$STATUS_FILE" 2>/dev/null | tail -1 | cut -d= -f2-)
    status="${status:-pending}"
    if [ "$status" != "pass" ]; then
      skip "用例 ${case_name} BLOCKED：硬依赖 ${dep} 状态为 ${status}"
      echo "${case_name}=skip:BLOCKED_BY:${dep}" >> "$STATUS_FILE"
      return 1
    fi
  done
  return 0
}

# 状态回写：pass | fail | error | skip:BLOCKED_BY:{dep}
update_status() {
  echo "$1=$2" >> "$STATUS_FILE"
}

# 单用例执行封装（AI Agent 解释执行体）
run_case() {
  local case_name="$1"
  local layer="${2:-?}"
  local case_file="$CASES_DIR/${case_name}.yaml"
  log "▶ [L${layer}] 执行用例: ${case_name} (${case_file})"
  # >>> AI Agent 执行体（按 auto-test-run.md Step 3~7 执行该用例）<<<
  # 1. 单用例 7 阶段执行（上下文准备→执行引擎→断言→截图→结果记录）
  # 2. 结果写入:   $RESULTS_DIR/ATR-{YYYYMMDD}-{NNN}.json
  # 3. 输出提取:   按该用例 metadata.outputs 从结果 JSON 提取 → 追加 $CTX_FILE
  # 4. 状态回写:   update_status "${case_name}" "{pass|fail|error}"
  # >>> 未来接入真实 Runner 后可替换为: npx @asdm/auto-test-runner "$case_file" <<<
}

# 流水线汇总
summary() {
  log "────────── 流水线汇总 ──────────"
  cat "$STATUS_FILE"
  local total p f s
  total=$(wc -l < "$STATUS_FILE"); p=$(grep -c "=pass" "$STATUS_FILE" || true)
  f=$(grep -cE "=fail|=error" "$STATUS_FILE" || true)
  s=$(grep -c "=skip" "$STATUS_FILE" || true)
  log "总计 ${total} | ✅ ${p} | ❌ ${f} | ⏭️ ${s}"
  [ "$f" -eq 0 ] && pass "PIPELINE PASS" || fail "PIPELINE FAIL"
}

# ---------- [区块3] 初始化 ----------
init_pipeline

# ================================================================
# [区块4] Layer 1 — 无硬依赖用例（并行组: 系统①/系统②）
# 依赖: 无 | 推断: 根节点（tags: auth / 无依赖声明）
# ================================================================
run_case user-login-test 1        # 输出: auth_token(step5.actual) → ctx
run_case home-smoke-test 1        # 本地参数 2 个，无跨用例依赖
run_case admin-login-selenium 1   # 系统② 独立执行

# ================================================================
# [区块5] Layer 2 — 硬依赖: user-login-test
# 参数注入: token ← {{outputs.user-login-test.auth_token}}
#          ← $OUTPUT_USER_LOGIN_TEST__AUTH_TOKEN（执行时 source ctx）
# ================================================================
if check_deps order-create-test user-login-test; then
  source "$CTX_FILE"
  run_case order-create-test 2    # 输出: order_id(step8.actual) → ctx
fi

# ================================================================
# [区块6] Layer 3 — 硬依赖: order-create-test
# 参数注入: order_id ← {{outputs.order-create-test.order_id}}
# ================================================================
if check_deps order-query-test order-create-test; then
  source "$CTX_FILE"
  run_case order-query-test 3
fi

# ---------- [区块7]（parallel 模式专用）----------
# parallel 模式下，同层无依赖用例采用后台并发:
#   run_case user-login-test 1 &
#   run_case home-smoke-test 1 &
#   wait
# 注意: 并发用例不得操作同一数据实体（编排时已按系统/实体分组）

# ---------- [区块8] 汇总 ----------
summary
```

**sh 脚本生成规则**：

| 规则 | 说明 |
|------|------|
| 脚本命名 | `pipeline-{YYYYMMDD}-{NNN}.sh`，NNN 检查 `pipelines/` 已有编号递增 |
| 编码与换行 | UTF-8，**LF 换行**（确保 Git Bash / WSL / Linux 可执行） |
| 每个 run_case 调用注释 | 必须注明：层级、硬依赖列表、参数注入链（含 ctx 变量名）、输出声明 |
| 依赖保护 | 每个含硬依赖的用例调用必须包裹 `if check_deps ...; then ... fi` |
| 参数注入 | 含 `{{outputs.X.y}}` 的用例执行前必须 `source "$CTX_FILE"` |
| parallel 模式 | 同层用例 `&` 后台 + `wait` 收口；跨系统分组天然可并行 |
| dryRun | `dryRun=true` 时仅生成脚本 + 编排图，不执行；脚本自身支持 `--dry-run` 参数打印计划 |
| 幂等性 | 重复生成会创建新 NNN 编号，不覆盖已有脚本 |

**相关产物文件**：

| 文件 | 路径 | 生成时机 | 格式 |
|------|------|---------|------|
| 执行脚本 | `pipelines/pipeline-{YYYYMMDD}-{NNN}.sh` | Step 2.6 | Bash |
| 参数上下文 | `pipelines/PIPE-{YYYYMMDD}-{NNN}.ctx.env` | 运行时逐用例追加 | `OUTPUT_{CASE}__{NAME}=值` |
| 流水线状态 | `pipelines/PIPE-{YYYYMMDD}-{NNN}.status` | 运行时逐用例追加 | `{case}={pass\|fail\|error\|skip:BLOCKED_BY:{dep}}` |

### Step 3: 上下文准备与数据自检（Phase 2）

> 流水线模式下，本步骤在**每个用例执行前**按序执行（含运行时跨用例参数解析）。

1. 读取用例 `metadata` 字段，初始化执行上下文（**所有值必须严格使用用例定义，禁止使用默认值替代用例已有值**）：
   - `targetUrl` → 测试目标 URL（**仅当用例未定义时**才使用默认 `http://localhost:3000`）
   - `timeout` → 全局超时秒数（**仅当用例未定义时**才使用默认 30）
   - `browser` → 浏览器类型（**仅当用例未定义时**才使用默认 chromium）
   - `viewport` → 视口尺寸（**仅当用例未定义时**才使用默认 1280×720）
2. **参数解析（核心步骤，决定执行成败）**：
   - 读取用例 `params` 字段中的**所有键值对**，存入参数映射表 `paramMap`
   - 遍历所有步骤的 `value` 字段，识别 `{{params.xxx}}` 与 `{{outputs.X.y}}` 占位符
   - **参数替换算法**：
     ```
     对每个 step.value:
       若包含 "{{params.xxx}}" 模式:
         1. 提取占位符中的参数名 xxx
         2. 在 paramMap 中查找 xxx
         3. 若找到 → 用 paramMap[x] 的值替换 "{{params.xxx}}"
         4. 若未找到 → 该步骤标记为 error，报错"参数 xxx 未在 params 中定义"，终止执行
       若包含 "{{outputs.X.y}}" 模式:
         1. 在参数上下文文件（CTX_FILE）中查找变量 OUTPUT_{X大写}__{Y大写}
         2. 若找到且上游状态为 pass → 用 ctx 值替换
         3. 若未找到 → 本用例标记为 skip（BLOCKED），报错
            "上游输出 {X}.{y} 尚未产生（上游未执行或输出提取失败）"
         4. 【禁止】使用默认值、旧值、猜测值替代
     ```
   - **严格按 params 映射表替换**，若 `params` 中不存在对应键 → 报错并终止，不得猜测值
3. 确定执行框架：
   - 读取 `framework` 字段（默认 playwright）
   - 若 selenium → 检查 A5/A8 断言 → 降级判断
4. 处理认证配置（如有 `metadata.auth`）
5. **【强制】数据提取自检清单** — 每个用例执行前**必须逐项确认**，任何一项不通过则该用例终止（流水线模式下终止该用例并回写状态，不中断整个流水线）：

| # | 自检项 | 检查方法 | 通过条件 |
|---|--------|---------|---------|
| 1 | params 完整性 | 对照 YAML 原文 | 提取的 params 键值对数量和内容与 YAML 原文完全一致 |
| 2 | 无编造值 | 检查参数映射表中每个值 | 每个值都能在 YAML 原文或 ctx 文件中找到对应来源，不存在两处均未出现的值 |
| 3 | 占位符已替换 | 检查所有 step.value | 不存在残留的 `{{params.xxx}}` / `{{outputs.X.y}}` 未替换情况 |
| 4 | 替换值来源可追溯 | 检查每个替换后的值 | 每个替换值 = YAML params 对应键值（字符级一致）或 ctx 文件中上游输出值 |
| 5 | 无默认值替代 | 检查 metadata 中的值 | metadata 中用例已定义的值未被默认值覆盖（如用例写了 targetUrl，不得使用 localhost） |
| 6 | 选择器未修改 | 对照 YAML 原文 | 所有 step.target 与 YAML 原文一致，未被"优化"或替换 |

**自检输出格式**：
```
✅ 自检通过 — 数据提取与解析验证（{用例名称}）
  [✓] params 完整性: 2/2 键值对已提取
  [✓] 无编造值: 所有值均来源于 YAML 原文或上游 ctx 输出
  [✓] 占位符已替换: 1/1 处本地参数 + 1/1 处跨用例参数已解析
  [✓] 替换值来源可追溯: email=super-admin@asdm.ai ← params.email;
      token=eyJhbGciOi... ← OUTPUT_USER_LOGIN_TEST__AUTH_TOKEN（上游 step5.actual）
  [✓] 无默认值替代: targetUrl 使用用例定义值
  [✓] 选择器未修改: 所有 target 与 YAML 一致
```

若自检不通过，**该用例禁止进入 Step 4 执行阶段**，必须回退到 Step 1 重新提取数据（流水线模式下该用例回写 fail 状态，下游按依赖规则传播）。

### Step 4: 执行引擎（Phase 3）

1. **流水线模式下按编排顺序执行**：严格按 Step 2.4 拓扑分层顺序逐用例调度；每个用例执行前先做**依赖检查**：
   - 硬依赖用例状态非 pass → 本用例标记 skip（BLOCKED），回写状态文件，跳到下个用例
   - 全部硬依赖 pass → 进入该用例的 7 阶段执行（Step 3~7）
2. 根据 framework 选择引擎适配（参照 `auto-test-execution-spec.md` §3 操作映射表）
3. 逐阶段逐步骤执行（**严格按 Step 3 自检通过的数据执行，禁止自行修改任何参数**）：
   - `navigate` 步骤：使用用例 `target` 字段的 URL，不得替换
   - `type` 步骤：使用用例 `target` 字段的选择器 + **Step 3 解析后的** `value` 字段的输入值，不得修改
     - ⚠️ **type 操作的数据来源只有两种**：Step 3 参数解析后的本地参数值，或 ctx 文件中的上游输出值。禁止使用"常见用户名"、"默认密码"、"上次记忆的凭据"等任何非用例来源的值
     - 正确：`type(target=".login-form input[name='email']", value="super-admin@asdm.ai")` ← 来自 params.email
     - 正确：`type(target=".order-form input[name='token']", value="eyJhbGciOi...")` ← 来自 ctx 上游输出
     - ❌ 错误：`type(target=".login-form input[name='email']", value="admin")` ← 编造值，YAML 中不存在
     - ❌ 错误：`type(target=".order-form input[name='token']", value="fake-token-123")` ← 编造值，ctx 中不存在
   - `click` 步骤：使用用例 `target` 字段的选择器，不得替换
   - `select` 步骤：使用用例 `target` + `value`，不得修改
   - `wait` 步骤：使用用例 `target` + `timeout`（如有），不得修改
   - `assert` 步骤：使用用例 `assertions` 数组中的每个断言，逐项执行
   - Playwright: 按 API 映射执行操作
   - Selenium: 按 API 映射执行操作（css= 前缀选择器处理）
4. **参数解析规则（执行阶段二次确认）**：
   - 步骤 `value` 中的 `{{params.xxx}}` 必须从 Step 3 建立的参数映射表中精确查找
   - 步骤 `value` 中的 `{{outputs.X.y}}` 必须从 ctx 文件精确查找
   - 若两处均无对应值 → 该步骤标记为 error，不得猜测或使用默认值
   - **【关键】执行每个 type/select 步骤前，必须确认 value 值来自 Step 1 提取的 YAML 数据或 ctx 上游输出，而非自行编造**
5. 每步执行后收集结果：
   - `actual`：实际观察到的结果
   - `duration`：步骤耗时估算
   - 异常捕获并记录

### Step 5: 断言判定（Phase 4）

1. 对 `action: assert` 步骤执行断言判定（参照 `auto-test-execution-spec.md` §4）
2. 8 种断言类型（A1~A8）按类型映射执行
3. 结果映射：完全匹配→pass，不匹配→fail，异常→error，前置失败→skip
4. 记录断言详情（target/expected/actual/message）

### Step 6: 截图采集（Phase 5）

1. 根据 capture 策略采集截图（参照 `auto-test-execution-spec.md` §5）：
   - `on-fail` → 仅失败步骤截图
   - `full` → 全步骤截图
   - `always` → 标记步骤强制截图
2. 截图命名规则：`ATR-{resultId}-S{stepIndex}-{strategy}.png`
3. 保存到 `.asdm/workspace/auto-test/screenshots/`

### Step 7: 结果记录与输出传递（Phase 6）

1. 生成 `AutoTestResult` JSON（参照 `auto-test-execution-spec.md` §6）
2. 生成结果 ID：`ATR-{YYYYMMDD}-{NNN}`
3. 计算整体状态：pass/fail/error/skip
4. 持久化到 `.asdm/workspace/auto-test/results/ATR-{YYYYMMDD}-{NNN}.json`
5. **【编排新增】输出提取与 ctx 写入**（流水线模式下，本用例声明了 `metadata.outputs` 时执行）：
   ```
   对每个输出 (name, rule) in metadata.outputs:
     1. 定位 stepResults[rule.stepIndex - 1]
     2. 读取 rule.field 字段值（默认 actual）
     3. 值非空且本用例状态为 pass → 追加写入 ctx 文件:
        OUTPUT_{用例名大写下划线}__{输出名大写}={值}
     4. 值为空 / 步骤不存在 / 用例非 pass → 不写入，并输出提示:
        ⚠️ 输出提取失败: {用例}.{name}（下游引用该输出的用例将 BLOCKED）
   ```
6. **【编排新增】流水线状态回写**：将本用例状态追加写入状态文件（`{case}={pass|fail|error}`），供后续用例的依赖检查使用

### Step 8: 报告输出（Phase 7）

1. 输出流水线级汇总表格（单用例模式输出原单用例摘要）
2. 输出结构化结果摘要 JSON

## Execution Guidelines

### ⛔ 用例数据保真红线（违反即失败）

执行用例时，以下行为**严格禁止**：

| 禁止行为 | 正确做法 | 示例 |
|---------|---------|------|
| 替换用例中的 URL | 严格使用用例定义的 URL | 用例写 `https://platform-dt02.asdm.ai/` → 必须导航到此 URL，不得改为 `http://localhost:3000` |
| 修改用例中的输入值 | 严格使用用例定义的 value | 用例写 `value: super-admin@asdm.ai` → 必须输入此值，不得改为 `admin@test.com` |
| 替换用例中的选择器 | 严格使用用例定义的 target | 用例写 `.login-form input[name="email"]` → 必须用此选择器，不得改为 `#email` |
| 猜测 params 参数值 | 严格从 params 字段查找 | `{{params.email}}` → 必须从 `params.email` 取值，若不存在则报错，不得猜测 |
| 猜测跨用例参数值 | 严格从 ctx 文件读取 | `{{outputs.X.auth_token}}` → 必须从 ctx 变量取值，上游未产出则 BLOCKED，不得编造 token |
| 修改断言的预期值 | 严格使用用例定义的 expected | 用例写 `expected: /dashboard` → 必须断言 URL 包含 `/dashboard`，不得改为 `/home` |
| 跳过或调换步骤顺序 | 严格按 stages/steps 顺序执行 | 用例定义5个步骤 → 必须1→2→3→4→5执行，不得跳过或调换 |
| 自行增加操作步骤 | 只执行用例定义的步骤 | 用例未定义"检查Cookie" → 不得自行添加此操作 |
| 使用"常见默认值"作为输入 | 仅使用 YAML params 或 ctx 中定义的值 | YAML 写了 `super-admin@asdm.ai`，不得使用 `admin`、`admin@asdm.ai`、`root` 等常见用户名 |

**唯一例外**：选择器定位失败（元素未找到）时，可以在结果中记录实际 DOM 结构供用户修正用例，但不得在执行过程中自行替换选择器。

### ⛔ 流水线编排红线（违反即失败）

| 禁止行为 | 正确做法 |
|---------|---------|
| 凭直觉编造用例先后关系 | 依赖边必须有可追溯证据（dependsOn / outputs 引用 / 明确推断信号），并在依赖表标注依据 |
| 猜测上游输出值填充下游参数 | 上游未产出输出 → 下游 BLOCKED（skip），绝不编造 |
| 使用上次执行的旧输出值 | ctx 文件由本次流水线重新生成，禁止引用历史 ATR 中的旧值 |
| 硬依赖失败仍执行下游用例 | 硬依赖状态非 pass → 下游必须 BLOCKED 并回写状态 |
| 隐瞒推断依赖 | 软依赖必须在编排图中虚线标注并输出推断依据，用户可用 dependsOn 固化 |
| 跳过环检测直接执行 | 硬依赖环 → 报错终止；软依赖环 → 降级同层并行并提示 |
| 并行执行相互依赖的用例 | 仅同层且无硬/软依赖边的用例可并行（parallel 模式） |
| 修改生成的 sh 脚本以"修复"依赖 | 依赖问题必须回源修改 YAML（dependsOn/outputs），再重新编排生成 |

### 🔒 数据防篡改三道防线

为确保用例数据不被篡改，建立了三道防线：

| 防线 | 阶段 | 机制 | 说明 |
|------|------|------|------|
| **第一道：提取即验证** | Step 1 | 数据提取摘要输出 | 解析 YAML 后立即输出所有提取的数据，使数据可见化 |
| **第二道：执行前自检** | Step 3 | 6 项自检清单 | 逐项确认 params 完整性、无编造值、占位符已替换等 |
| **第三道：执行时回溯** | Step 4 | 每步数据来源确认 | 执行 type/select 时确认 value 来自 Step 1 提取值或 ctx 上游输出 |

**任何一道防线不通过，对应用例禁止执行。**（流水线模式下阻塞该用例及其下游，不中断其他独立分支）

### 快速失败策略

- **用例内**：某步骤 fail/error → 后续步骤标记为 skip；Stage 间不中断（即使某 Stage 失败，下个 Stage 继续执行）
- **用例间（流水线）**：用例 fail/error → 硬依赖它的下游用例标记为 skip（BLOCKED），软依赖的下游用例正常执行；无依赖关系的用例不受影响

### 超时控制

- 每个步骤使用 `timeout` 字段或全局超时
- 超时 → 步骤标记为 error

### 框架降级

- Selenium 用例含 A5/A8 → 降级为 Playwright 并提示
- 降级提示：`"⚠️ 框架降级提示：用例 {name} 指定 selenium 框架，但包含 Playwright 专有特性（A5/A8），已自动降级为 Playwright 执行引擎"`

### 环境检测

- 执行前检测目标系统是否可访问（每个用例的 targetUrl 分别检测）
- 不可访问 → 用例标记为 error，提示用户（流水线模式下不影响其他系统的用例）

### 凭据数据二次确认（防止凭据篡改）

当用例包含登录/认证相关步骤时，**在执行输入操作前必须进行凭据二次确认**：

1. 识别所有 `type` 步骤中涉及认证字段（如 email/username/password/token/secret 等）的 value
2. 逐个确认：该 value 是否来源于 YAML `params` 字段的精确提取，或 ctx 文件中上游输出
3. 输出确认信息：`🔐 凭据确认: {字段名} = {值} ← params.{键名}（来源: YAML 行 {行号}）` 或 `🔐 凭据确认: {字段名} = {值} ← ctx:OUTPUT_{CASE}__{NAME}（来源: 上游 {用例} step{N}.actual）`
4. 若任何凭据值无法追溯到 YAML 原文或 ctx 文件 → **终止该用例执行**，输出错误：`❌ 凭据数据异常：{字段名} 的值 "{值}" 在 YAML 与 ctx 中均未找到定义，疑似编造`

**典型错误模式识别**（发现以下模式立即终止该用例）：
- 输入了 `admin` / `root` / `test` 等常见用户名 → YAML params 与 ctx 中均未定义这些值
- 输入了 `Admin@123` / `123456` / `password` 等常见密码 → YAML params 与 ctx 中均未定义这些值
- 输入了与 YAML params 值不同的邮箱地址 → 篡改了 params.email 的值
- 输入了形似 JWT 但 ctx 中不存在的 token → 编造了 outputs.X.auth_token 的值

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| case | string | ✅ | 用例文件路径（单用例模式）、目录路径（流水线模式），或留空使用默认 cases/ 目录（流水线模式） |
| framework | string | ❌ | 框架偏好，覆盖用例设置（playwright/selenium） |
| capture | string | ❌ | 截图策略，覆盖用例设置（on-fail/full） |
| mode | string | ❌ | 编排执行模式：`sequence`（默认，按拓扑序全串行）/ `parallel`（同层无依赖用例并行） |
| dryRun | boolean | ❌ | `true` 时仅执行 Step 1~2（加载 + 编排 + 生成 sh 脚本与编排图），不实际执行用例；默认 `false` |

### 命令示例

```
# 流水线模式：加载全部用例 → 自动编排 → 生成 sh → 顺序执行
/auto-test-run
/auto-test-run case=.asdm/workspace/auto-test/cases/

# 流水线模式：同层并行执行
/auto-test-run case=cases/ mode=parallel

# 编排预演：只生成编排图与 sh 脚本，不执行
/auto-test-run dryRun=true

# 单用例模式：跳过编排，直接 7 阶段执行（向后兼容）
/auto-test-run case=user-login-test.yaml

# 覆盖框架与截图策略
/auto-test-run case=cases/ framework=playwright capture=full
```

### 生成脚本的手动用法

```bash
# 实际执行（由 AI Agent 解释执行或未来 Runner 直执行）
bash .asdm/workspace/auto-test/pipelines/pipeline-20260826-001.sh

# 只打印执行计划
bash .asdm/workspace/auto-test/pipelines/pipeline-20260826-001.sh --dry-run

# 只执行指定用例及其依赖链
bash .asdm/workspace/auto-test/pipelines/pipeline-20260826-001.sh --only order-query-test
```

## Output

### 流水线编排输出（Step 2 产物）

```markdown
### 📐 用例执行流水线编排 — PIPE-20260826-001

**用例总数**：6 | **硬依赖边**：2 | **推断依赖边**：1 | **执行层数**：3 | **执行模式**：sequence

（编排图 ASCII + Mermaid，见 Step 2.5 格式）

**用例依赖关系表**：见 Step 2.5 表格格式
**参数依赖关系表**：见 Step 2.2 表格格式

**sh 执行脚本**：`.asdm/workspace/auto-test/pipelines/pipeline-20260826-001.sh`
```

### 流水线执行汇总输出（Step 8）

```markdown
### 🧪 自动化测试流水线执行结果：PIPE-20260826-001

| 用例 | 层级 | 硬依赖 | 状态 | 步骤 | 耗时 | 结果文件 |
|------|:----:|--------|:----:|------|:----:|---------|
| user-login-test | L1 | — | ✅ pass | 7/7 | 8.5s | ATR-20260826-001.json |
| home-smoke-test | L1 | — | ✅ pass | 4/4 | 3.2s | ATR-20260826-002.json |
| order-create-test | L2 | user-login-test | ❌ fail | 3/6 | 5.2s | ATR-20260826-003.json |
| order-query-test | L3 | order-create-test | ⏭️ skip | 0/5 | — | —（BLOCKED_BY: order-create-test） |

**流水线状态**：❌ 失败 | **用例**：2 通过 / 1 失败 / 1 跳过 | **总耗时**：23.4s
**执行脚本**：pipelines/pipeline-20260826-001.sh | **状态文件**：pipelines/PIPE-20260826-001.status
**参数传递**：1 条输出链（auth_token: user-login-test → order-create-test）
```

### 单用例摘要输出（单用例模式 / 流水线内每用例）

```markdown
### 🧪 自动化测试结果：{testCaseName}

| 步骤 | 操作 | 目标 | 预期结果 | 实际结果 | 状态 |
|:----:|------|------|---------|---------|:----:|
| 1 | navigate | /login | 登录页面正常加载 | 登录页面正常加载 | ✅ |
| 2 | assert | .auth-form | visible | visible | ✅ |
| ... | ... | ... | ... | ... | ... |

**用例状态**：✅ 通过 | **步骤**：7/7 通过 | **耗时**：8.5s
**执行框架**：playwright | **结果文件**：ATR-20260714-001.json
```

### 结构化输出

```json
{
  "phase": "auto-test-run",
  "mode": "pipeline",
  "pipeline_id": "PIPE-20260826-001",
  "status": "fail",
  "total_cases": 4,
  "passed_cases": 2,
  "failed_cases": 1,
  "skipped_cases": 1,
  "layers": 3,
  "hard_dependencies": 2,
  "inferred_dependencies": 1,
  "param_dependencies": [
    {"consumer": "order-create-test", "param": "token", "producer": "user-login-test", "output": "auth_token", "resolved": true}
  ],
  "script_path": ".asdm/workspace/auto-test/pipelines/pipeline-20260826-001.sh",
  "ctx_path": ".asdm/workspace/auto-test/pipelines/PIPE-20260826-001.ctx.env",
  "cases": [
    {"name": "user-login-test", "layer": 1, "status": "pass", "result_id": "ATR-20260826-001", "total_steps": 7, "passed_steps": 7, "duration_ms": 8500, "framework": "playwright"},
    {"name": "order-query-test", "layer": 3, "status": "skip", "blocked_by": ["order-create-test"], "result_id": null}
  ],
  "timestamp": "ISO 8601 datetime"
}
```

## Configuration

Refer to:
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — YAML DSL 用例格式定义、Schema 校验、操作映射
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 7 阶段执行规范、断言判定、截图策略、结果记录
