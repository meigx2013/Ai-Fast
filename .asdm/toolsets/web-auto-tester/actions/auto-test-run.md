# ASDM Action: Auto Test Run

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
  "name": "auto-test-run",
  "displayName": "执行自动化测试",
  "description": "执行 YAML DSL 测试用例，支持 Playwright/Selenium 双框架，7 阶段执行流程（加载→上下文→执行→断言→截图→记录→输出），自动生成结果 JSON 和失败截图",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.1"
  },
  "scenario": "auto-test-execution"
}
```

## Purpose

本 action 是 Web Auto Tester 的核心命令。用户指定 YAML DSL 用例文件或用例目录，AI 按照 7 阶段执行规范自动加载用例、准备上下文、选择引擎、逐步执行、断言判定、截图采集、记录结果，并以表格形式输出测试摘要。

## ⛔ 用例数据保真原则（最高优先级 — 违反即为执行失败）

执行测试用例时，**必须严格提取并使用 YAML 用例文件中定义的数据，严禁自行解读、修改、替换或编造**。具体规则：

1. **URL 严格使用**：`metadata.targetUrl` 和 `navigate` 步骤中的 URL 必须原样使用，不得替换为其他 URL
2. **输入值严格使用**：`type`/`select` 步骤中的 `value` 必须原样使用，不得修改或替换为其他值
3. **选择器严格使用**：Step 中的 `target`（CSS 选择器）必须原样使用，不得自行修改或替换选择器
4. **参数严格解析**：`{{params.xxx}}` 必须从用例 `params` 字段精确查找替换，不得猜测或编造参数值
5. **断言数据严格使用**：`assert` 步骤中的 `target`/`expected`/`message` 必须原样使用，不得修改预期值或断言目标
6. **元数据严格使用**：`metadata` 中的 `timeout`/`browser`/`viewport` 等必须按用例定义使用，不得随意更改
7. **步骤顺序严格执行**：按用例定义的 stages/steps 顺序逐一执行，不得跳过、调换或合并步骤
8. **禁止智能替换**：不得因为"觉得更合理"而替换用例中的任何数据（如用例写的是 `.login-btn`，不得因为页面上看到的是 `#loginButton` 就自行替换）

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

**此案例表明：即使规则写了"禁止编造"，如果缺乏强制验证机制，Agent 仍可能绕过规则。因此本 Action 新增了"数据提取自检"强制步骤（见 Step 2.5）。**

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
   - Purpose: 加载并执行测试用例

## Steps

### Step 1: 用例加载与数据提取（Phase 1）

1. 根据用户输入参数 `case` 定位用例文件：
   - 指定文件路径 → 直接加载该 YAML 文件
   - 指定目录路径 → 加载目录下所有 `.yaml` 文件
   - 未指定 → 加载 `.asdm/workspace/auto-test/cases/` 下所有 `.yaml` 文件
2. **逐字读取** YAML 文件内容，**逐字段精确提取**所有用例数据：
   - 提取 `name`、`description`、`framework`、`capture`、`tags`、`source` — 原样保留
   - 提取 `params` — **逐键逐值**存入参数上下文，供后续 `{{params.xxx}}` 解析（**此步骤是数据保真的核心，必须确保提取的值与 YAML 原文完全一致**）
   - 提取 `metadata` — 存入执行上下文（targetUrl/timeout/browser/viewport/prerequisites）
   - 提取 `stages[].name` — 原样保留阶段名称
   - 提取 `stages[].steps[]` — **逐字段精确提取**每个 step 的 action/target/value/timeout/pageTransition/capture/assertions，不得遗漏或修改任何字段
   - 提取 `assertions[]` — 精确提取 type/target/expected/message，原样保留
3. 执行 Schema 校验（参照 `auto-test-dsl-spec.md` §10 校验规则）：
   - `name` 非空 ✅
   - `stages` 数组长度 ≥ 1 ✅
   - 每个 Stage: `name` 非空 + `steps` ≥ 1 ✅
   - 每个 Step: `action` 必填 + `target` 必填 ✅
   - type/select 操作: `value` 必填 ✅
   - assert 操作: `assertions` ≥ 1 ✅
4. 校验失败 → 报错并终止，提示用户修正用例
5. **【强制】输出数据提取摘要**：解析完成后，**必须**输出以下格式的数据提取摘要，供自检验证：

```
📋 数据提取摘要 — {用例名称}
┌─────────────────────────────────────────┐
│ params 参数表                            │
├──────────┬──────────────────────────────┤
│ 键名     │ 提取值（必须与YAML原文一致）    │
├──────────┼──────────────────────────────┤
│ email    │ super-admin@asdm.ai          │
│ password │ superadmin@20260214          │
└──────────┴──────────────────────────────┘
┌─────────────────────────────────────────┐
│ metadata 元数据                          │
├──────────┬──────────────────────────────┤
│ targetUrl│ https://platform-dt02.asdm.ai/│
│ timeout  │ 30                           │
│ browser  │ chromium                     │
└──────────┴──────────────────────────────┘
┌─────────────────────────────────────────┐
│ steps 参数解析结果                        │
├─────┬──────────────────────┬────────────┤
│ 步骤│ value（解析前）       │ value（解析后）│
├─────┼──────────────────────┼────────────┤
│ S2  │ {{params.email}}     │ super-admin@asdm.ai │
│ S3  │ {{params.password}}  │ superadmin@20260214 │
└─────┴──────────────────────┴────────────┘
```

### Step 2: 上下文准备与数据自检（Phase 2）

1. 读取用例 `metadata` 字段，初始化执行上下文（**所有值必须严格使用用例定义，禁止使用默认值替代用例已有值**）：
   - `targetUrl` → 测试目标 URL（**仅当用例未定义时**才使用默认 `http://localhost:3000`）
   - `timeout` → 全局超时秒数（**仅当用例未定义时**才使用默认 30）
   - `browser` → 浏览器类型（**仅当用例未定义时**才使用默认 chromium）
   - `viewport` → 视口尺寸（**仅当用例未定义时**才使用默认 1280×720）
2. **参数解析（核心步骤，决定执行成败）**：
   - 读取用例 `params` 字段中的**所有键值对**，存入参数映射表 `paramMap`
   - 遍历所有步骤的 `value` 字段，识别 `{{params.xxx}}` 占位符
   - **参数替换算法**：
     ```
     对每个 step.value:
       若包含 "{{params.xxx}}" 模式:
         1. 提取占位符中的参数名 xxx
         2. 在 paramMap 中查找 xxx
         3. 若找到 → 用 paramMap[x] 的值替换 "{{params.xxx}}"
         4. 若未找到 → 该步骤标记为 error，报错"参数 xxx 未在 params 中定义"，终止执行
     ```
   - **严格按 params 映射表替换**，若 `params` 中不存在对应键 → 报错并终止，不得猜测值
3. 确定执行框架：
   - 读取 `framework` 字段（默认 playwright）
   - 若 selenium → 检查 A5/A8 断言 → 降级判断
4. 处理认证配置（如有 `metadata.auth`）
5. **【强制】数据提取自检清单** — 执行前**必须逐项确认**，任何一项不通过则终止：

| # | 自检项 | 检查方法 | 通过条件 |
|---|--------|---------|---------|
| 1 | params 完整性 | 对照 YAML 原文 | 提取的 params 键值对数量和内容与 YAML 原文完全一致 |
| 2 | 无编造值 | 检查参数映射表中每个值 | 每个值都能在 YAML 原文中找到对应行，不存在 YAML 中未出现的值 |
| 3 | 占位符已替换 | 检查所有 step.value | 不存在残留的 `{{params.xxx}}` 未替换情况 |
| 4 | 替换值来源可追溯 | 检查每个替换后的值 | 每个替换值 = YAML params 中对应键的值（字符级完全一致） |
| 5 | 无默认值替代 | 检查 metadata 中的值 | metadata 中用例已定义的值未被默认值覆盖（如用例写了 targetUrl，不得使用 localhost） |
| 6 | 选择器未修改 | 对照 YAML 原文 | 所有 step.target 与 YAML 原文一致，未被"优化"或替换 |

**自检输出格式**：
```
✅ 自检通过 — 数据提取与解析验证
  [✓] params 完整性: 2/2 键值对已提取
  [✓] 无编造值: 所有值均来源于 YAML 原文
  [✓] 占位符已替换: 2/2 处 {{params.xxx}} 已解析
  [✓] 替换值来源可追溯: email=super-admin@asdm.ai ← params.email, password=superadmin@20260214 ← params.password
  [✓] 无默认值替代: targetUrl 使用用例定义值
  [✓] 选择器未修改: 所有 target 与 YAML 一致
```

若自检不通过，**禁止进入 Step 3 执行阶段**，必须回退到 Step 1 重新提取数据。

### Step 3: 执行引擎（Phase 3）

1. 根据 framework 选择引擎适配（参照 `auto-test-execution-spec.md` §3 操作映射表）
2. 逐阶段逐步骤执行（**严格按 Step 2 自检通过的数据执行，禁止自行修改任何参数**）：
   - `navigate` 步骤：使用用例 `target` 字段的 URL，不得替换
   - `type` 步骤：使用用例 `target` 字段的选择器 + **Step 2 解析后的** `value` 字段的输入值，不得修改
     - ⚠️ **type 操作的数据来源只有一种**：Step 2 参数解析后的 value 值。禁止使用"常见用户名"、"默认密码"、"上次记忆的凭据"等任何非用例来源的值
     - 正确：`type(target=".login-form input[name='email']", value="super-admin@asdm.ai")` ← 来自 params.email
     - ❌ 错误：`type(target=".login-form input[name='email']", value="admin")` ← 编造值，YAML 中不存在
     - ❌ 错误：`type(target=".login-form input[name='email']", value="admin@asdm.ai")` ← 猜测值，YAML 中不存在
   - `click` 步骤：使用用例 `target` 字段的选择器，不得替换
   - `select` 步骤：使用用例 `target` + `value`，不得修改
   - `wait` 步骤：使用用例 `target` + `timeout`（如有），不得修改
   - `assert` 步骤：使用用例 `assertions` 数组中的每个断言，逐项执行
   - Playwright: 按 API 映射执行操作
   - Selenium: 按 API 映射执行操作（css= 前缀选择器处理）
3. **参数解析规则（执行阶段二次确认）**：
   - 步骤 `value` 中的 `{{params.xxx}}` 必须从 Step 2 建立的参数映射表中精确查找
   - 若参数映射表中无对应键 → 该步骤标记为 error，不得猜测或使用默认值
   - **【关键】执行每个 type/select 步骤前，必须确认 value 值来自 Step 1 提取的 YAML 数据，而非自行编造**
4. 每步执行后收集结果：
   - `actual`：实际观察到的结果
   - `duration`：步骤耗时估算
   - 异常捕获并记录

### Step 4: 断言判定（Phase 4）

1. 对 `action: assert` 步骤执行断言判定（参照 `auto-test-execution-spec.md` §4）
2. 8 种断言类型（A1~A8）按类型映射执行
3. 结果映射：完全匹配→pass，不匹配→fail，异常→error，前置失败→skip
4. 记录断言详情（target/expected/actual/message）

### Step 5: 截图采集（Phase 5）

1. 根据 capture 策略采集截图（参照 `auto-test-execution-spec.md` §5）：
   - `on-fail` → 仅失败步骤截图
   - `full` → 全步骤截图
   - `always` → 标记步骤强制截图
2. 截图命名规则：`ATR-{resultId}-S{stepIndex}-{strategy}.png`
3. 保存到 `.asdm/workspace/auto-test/screenshots/`

### Step 6: 结果记录（Phase 6）

1. 生成 `AutoTestResult` JSON（参照 `auto-test-execution-spec.md` §6）
2. 生成结果 ID：`ATR-{YYYYMMDD}-{NNN}`
3. 计算整体状态：pass/fail/error/skip
4. 持久化到 `.asdm/workspace/auto-test/results/ATR-{YYYYMMDD}-{NNN}.json`

### Step 7: 报告输出（Phase 7）

1. 输出简要摘要表格（P4 阶段实现完整 HTML 报告）
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
| 修改断言的预期值 | 严格使用用例定义的 expected | 用例写 `expected: /dashboard` → 必须断言 URL 包含 `/dashboard`，不得改为 `/home` |
| 跳过或调换步骤顺序 | 严格按 stages/steps 顺序执行 | 用例定义5个步骤 → 必须1→2→3→4→5执行，不得跳过或调换 |
| 自行增加操作步骤 | 只执行用例定义的步骤 | 用例未定义"检查Cookie" → 不得自行添加此操作 |
| 使用"常见默认值"作为输入 | 仅使用 YAML params 中定义的值 | YAML 写了 `super-admin@asdm.ai`，不得使用 `admin`、`admin@asdm.ai`、`root` 等常见用户名 |

**唯一例外**：选择器定位失败（元素未找到）时，可以在结果中记录实际 DOM 结构供用户修正用例，但不得在执行过程中自行替换选择器。

### 🔒 数据防篡改三道防线

为确保用例数据不被篡改，建立了三道防线：

| 防线 | 阶段 | 机制 | 说明 |
|------|------|------|------|
| **第一道：提取即验证** | Step 1 | 数据提取摘要输出 | 解析 YAML 后立即输出所有提取的数据，使数据可见化 |
| **第二道：执行前自检** | Step 2 | 6 项自检清单 | 逐项确认 params 完整性、无编造值、占位符已替换等 |
| **第三道：执行时回溯** | Step 3 | 每步数据来源确认 | 执行 type/select 时确认 value 来自 Step 1 提取值 |

**任何一道防线不通过，禁止继续执行。**

### 快速失败策略

- 某步骤 fail/error → 后续步骤标记为 skip
- Stage 间不中断（即使某 Stage 失败，下个 Stage 继续执行）

### 超时控制

- 每个步骤使用 `timeout` 字段或全局超时
- 超时 → 步骤标记为 error

### 框架降级

- Selenium 用例含 A5/A8 → 降级为 Playwright 并提示
- 降级提示：`"⚠️ 框架降级提示：用例 {name} 指定 selenium 框架，但包含 Playwright 专有特性（A5/A8），已自动降级为 Playwright 执行引擎"`

### 环境检测

- 执行前检测目标系统是否可访问
- 不可访问 → 用例标记为 error，提示用户

### 凭据数据二次确认（防止凭据篡改）

当用例包含登录/认证相关步骤时，**在执行输入操作前必须进行凭据二次确认**：

1. 识别所有 `type` 步骤中涉及认证字段（如 email/username/password/token/secret 等）的 value
2. 逐个确认：该 value 是否来源于 YAML `params` 字段的精确提取
3. 输出确认信息：`🔐 凭据确认: {字段名} = {值} ← params.{键名}（来源: YAML 行 {行号}）`
4. 若任何凭据值无法追溯到 YAML 原文 → **终止执行**，输出错误：`❌ 凭据数据异常：{字段名} 的值 "{值}" 在 YAML 中未找到定义，疑似编造`

**典型错误模式识别**（发现以下模式立即终止）：
- 输入了 `admin` / `root` / `test` 等常见用户名 → YAML 中 params 未定义这些值
- 输入了 `Admin@123` / `123456` / `password` 等常见密码 → YAML 中 params 未定义这些值
- 输入了与 YAML params 值不同的邮箱地址 → 篡改了 params.email 的值

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| case | string | ✅ | 用例文件路径、目录路径，或留空使用默认 cases/ 目录 |
| framework | string | ❌ | 框架偏好，覆盖用例设置（playwright/selenium） |
| capture | string | ❌ | 截图策略，覆盖用例设置（on-fail/full） |

### 命令示例

```
/auto-test-run case=user-login-test.yaml
/auto-test-run case=.asdm/workspace/auto-test/cases/
/auto-test-run
/auto-test-run case=admin-login-test.yaml framework=playwright capture=full
```

## Output

### 简要摘要输出

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
  "status": "success",
  "result_id": "ATR-20260714-001",
  "test_case_name": "user-login-test",
  "test_case_status": "pass",
  "total_steps": 7,
  "passed_steps": 7,
  "failed_steps": 0,
  "duration_ms": 8500,
  "framework": "playwright",
  "result_path": ".asdm/workspace/auto-test/results/ATR-20260714-001.json",
  "timestamp": "ISO 8601 datetime"
}
```

## Configuration

Refer to:
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — YAML DSL 用例格式定义、Schema 校验、操作映射
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 7 阶段执行规范、断言判定、截图策略、结果记录
