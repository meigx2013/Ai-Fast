# ASDM Action: Auto Test Generate

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456791",
  "name": "auto-test-generate",
  "displayName": "AI 生成测试用例",
  "description": "根据用户提供的测试用例描述自动生成 YAML DSL 测试用例，支持自然语言描述、结构化步骤描述、Markdown 测试文档三种输入方式，自动推断选择器和断言，支持正向/逆向/边界值场景生成，输出符合 DSL 规范的 YAML 用例文件",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.2"
  },
  "scenario": "auto-test-generation"
}
```

## Purpose

本 action 是 Web Auto Tester 的用例生成命令。用户可传入**单个测试用例描述**（自然语言描述、结构化操作步骤、或 Markdown 测试文档），或传入**包含多个 Markdown 测试用例文档的目录**。AI 自动解析操作步骤和验证点，根据 `scenarioType` 参数生成正向/逆向/边界值测试场景（默认仅生成正向场景），转换为 YAML DSL 用例格式，自动推断选择器和断言，输出可执行的测试用例文件。当传入目录时，自动扫描目录下所有 `.md` 文件并逐一解析生成。用例标记 `source: generate` 以追溯来源。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有生成的文件、注释和文档均使用中文。

## Context Injection

在生成用例前，AI Agent **必须**读取并理解以下规范文件：

### Required Context Files

1. **YAML DSL 规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
   - Purpose: 了解用例格式定义、Schema 校验规则、操作类型映射、断言类型 A1~A8、数据模型

2. **执行引擎规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
   - Purpose: 了解操作映射（9 种操作类型 API 对应）、断言判定规则、选择器约定

3. **测试用例描述** (Required)
   - Path: 用户通过 `description` 参数提供（文本内容或文件路径）
   - Purpose: 提取操作步骤、验证点和业务规则

## Steps

### Step 1: 读取与解析测试用例描述

1. 根据 `description` 参数获取测试用例描述内容：
   - 指定文件路径 → 读取该文件内容
   - 直接传入内容 → 使用传入的文本内容

2. 自动识别输入格式并解析：

   #### 1.1 结构化步骤描述格式（优先识别）

   识别特征：包含编号步骤列表（如 `1. 2. 3.` 或 `步骤1 步骤2`），每步包含明确的操作和目标。

   解析规则：
   - **步骤编号**：识别 `1.` `2.` `3.` 或 `步骤1` `Step 1` 等前缀
   - **操作类型**：从步骤描述中提取操作动词（输入/点击/导航/等待/选择等）
   - **操作目标**：提取步骤中的 UI 元素描述（按钮、输入框、链接等）
   - **操作值**：提取步骤中的具体输入值（用户名、密码、URL等）
   - **页面跳转**：识别"跳转"/"导航到"/"页面切换"等关键词
   - **验证点**：识别"验证"/"确认"/"应显示"/"应跳转"等关键词

   示例解析：
   ```
   输入描述：
   1. 浏览器地址栏输入： https://platform-dt02.asdm.ai/
      → action: navigate, target: https://platform-dt02.asdm.ai/

   2. portal页面右上角点击【登录】, 页面跳转到ASDM登录页面
      → action: click, target: .login-btn (推断), pageTransition: navigate

   3. 输入邮箱地址： super-admin@asdm.ai
      → action: type, target: input[name="email"] (推断), value: super-admin@asdm.ai

   4. 输入密码： superadmin@20260214
      → action: type, target: input[name="password"] (推断), value: superadmin@20260214

   5. 点击【登录】按钮，完成登录
      → action: click, target: .login-form .btn-primary (推断)
   ```

   #### 1.2 自然语言描述格式

   识别特征：无编号步骤，使用自然语言描述测试流程。

   解析规则：
   - 识别操作动词：打开/输入/点击/选择/等待/滚动/上传/悬停
   - 识别 UI 元素：按钮/输入框/下拉框/链接/标签/菜单
   - 识别页面元素标记：用【】或「」包裹的元素名称
   - 识别输入值：用冒号后的值或引号内的值
   - 识别 URL：以 http/https 开头的链接
   - 识别验证描述：应/应该/必须/确认/验证等关键词

   #### 1.3 Markdown 测试文档格式

   识别特征：包含 Markdown 标题层级（`#` ~ `####`），结构化的测试用例文档。

   解析规则：
   - **用例标题**：识别 `#` 级标题（如"# 用例名称： 系统登录"）→ 提取用例名称
   - **用例描述**：标题下方的描述段落
   - **操作步骤**：识别"## 操作步骤"/"步骤"/"Steps"关键词段落下的编号列表
   - **预期结果**：识别"## 预期结果"/"验证点"/"Expected"关键词段落下的编号列表
   - **前置条件**：识别"## 前置条件"/"前提"/"Prerequisite"关键词段落下的编号列表

   示例解析（Markdown 测试文档格式）：
   ```
   输入描述：
   # 用例名称： 系统登录
   本用例适用于用户进行ASDM平台登录。
   ## 操作步骤
   1. 浏览器地址栏输入： https://platform-dt02.asdm.ai/
   2. portal页面右上角点击【登录】, 页面跳转到ASDM登录页面
   3. 输入邮箱地址： super-admin@asdm.ai
   4. 输入密码： superadmin@20260214
   5. 点击【登录】按钮，完成登录
   ## 预期结果
   1. 页面跳转到 ASDM管理后台 首页面
   ## 前置条件
   1. 用户已注册

   解析结果：
   - caseName: "系统登录"
   - description: "本用例适用于用户进行ASDM平台登录"
   - steps: 5个操作步骤（navigate→click→type→type→click）
   - verificationPoints: ["页面跳转到ASDM管理后台首页面"]
   - prerequisites: ["用户已注册"]
   ```

3. 为每个用例建立结构化摘要：

```json
{
  "caseId": "TC01",
  "caseName": "系统登录",
  "description": "本用例适用于用户进行ASDM平台登录",
  "steps": [
    {
      "index": 1,
      "action": "navigate",
      "target": "https://platform-dt02.asdm.ai/",
      "value": null,
      "pageTransition": "navigate",
      "uiElement": "浏览器地址栏"
    },
    {
      "index": 2,
      "action": "click",
      "target": "推断: .login-btn 或 .header .login-link",
      "value": null,
      "uiElement": "portal页面右上角【登录】按钮",
      "pageTransition": "navigate"
    },
    {
      "index": 3,
      "action": "type",
      "target": "推断: input[name=\"email\"] 或 .login-form input:first-child",
      "value": "super-admin@asdm.ai",
      "uiElement": "邮箱地址输入框"
    },
    {
      "index": 4,
      "action": "type",
      "target": "推断: input[name=\"password\"] 或 .login-form input:nth-child(2)",
      "value": "superadmin@20260214",
      "uiElement": "密码输入框"
    },
    {
      "index": 5,
      "action": "click",
      "target": "推断: .login-form .btn-primary 或 button[type=\"submit\"]",
      "value": null,
      "uiElement": "【登录】按钮"
    }
  ],
  "verificationPoints": [
    "页面跳转到ASDM管理后台首页面"
  ],
  "prerequisites": [
    "用户已注册"
  ],
  "targetUrl": "https://platform-dt02.asdm.ai/",
  "dataFields": [
    {"name": "email", "type": "string", "required": true, "value": "super-admin@asdm.ai"},
    {"name": "password", "type": "string", "required": true, "value": "superadmin@20260214"}
  ]
}
```

### Step 2: 生成测试场景

基于解析出的操作步骤，根据 `scenarioType` 参数为每个用例生成测试用例：

#### 2.1 正向场景（Happy Path）— 默认且必选

- **严格按用户描述的步骤生成**：将用户描述的每个步骤逐一转换为 YAML DSL Step
- 保留用户提供的所有操作细节（URL、输入值、点击目标等）
- 补充必要的断言验证（如页面跳转、元素可见）
- **预期结果**：将用户描述中的"预期结果"部分直接转换为断言
- **前置条件**：将用户描述中的"前置条件"记录到用例 metadata 的 `prerequisites` 字段
- 场景命名规则：`{用例名}-{正向场景描述}`
- 示例：`asdm-login-happy-path`

#### 2.2 逆向场景（Negative Path）— 仅当 scenarioType=all 时生成

- 基于正向场景中的输入字段和业务规则生成逆向测试
- 从用户描述中推断可测试的逆向场景：
  - 必填字段为空（如空邮箱、空密码）
  - 格式错误（如非法邮箱格式）
  - 错误凭证（如错误密码）
  - 权限不足
- 场景命名规则：`{用例名}-{逆向场景描述}`
- 示例：`asdm-login-wrong-password`、`asdm-login-empty-email`

#### 2.3 边界值场景（Boundary Value）— 仅当 scenarioType=all 时生成

- 基于输入字段的特征推断边界值
- 边界值测试类型：
  - 邮箱：最大长度、最小长度、特殊字符
  - 密码：最大长度、最小长度、特殊字符
  - 如无明确边界信息，则跳过边界值场景
- 场景命名规则：`{用例名}-{边界值描述}`
- 示例：`asdm-login-max-email-length`

#### 2.4 场景数量控制

- **scenarioType=positive-only（默认）**：每个用例仅生成 1 个正向场景
  - 严格按用户描述的步骤和预期结果生成
  - 不生成逆向和边界值场景
  - 适用于冒烟测试、回归测试等快速验证场景
- **scenarioType=all**：生成完整场景覆盖
  - 每个用例至少生成：1 个正向 + 1 个逆向
  - 如用户描述中包含多个输入字段，逆向场景按字段数量增加
  - 总场景数量建议控制在 3~10 个/用例
- 用户可通过参数 `coverage=min/standard/deep` 控制覆盖深度（默认 standard，仅在 scenarioType=all 时生效）

### Step 3: 转换为 YAML DSL 结构

将每个测试场景转换为 YAML DSL 的 `stages/steps` 结构：

#### 3.1 Stage 划分策略

- **按用户描述的步骤逻辑划分**，优先遵循用户的步骤分组：
  - 如果用户描述中包含"阶段"/"Phase"等关键词 → 按用户指定划分
  - 否则按操作类型自动划分：
    - **访问阶段**：navigate 操作 + 页面可见断言
    - **操作阶段**：type/click/select 等交互操作
    - **验证阶段**：assert 断言判定

- Stage 命名规则：使用中文描述（如"访问ASDM平台"/"点击登录按钮"/"输入凭证"/"完成登录"）

#### 3.2 Step 操作映射

按 `auto-test-dsl-spec.md` §4 操作类型映射表，将用户描述的操作转换为 Step：

| 用户描述中的操作 | Step action | target | value |
|-----------------|------------|--------|-------|
| 浏览器地址栏输入/打开/访问 URL | navigate | 完整URL | — |
| 输入/填写/键入 | type | CSS选择器 | 输入值 |
| 点击/按下/选择（按钮） | click | CSS选择器 | — |
| 选择下拉选项 | select | CSS选择器 | 选项值 |
| 等待/加载 | wait | CSS选择器 | — |
| 鼠标悬停/移到 | hover | CSS选择器 | — |
| 滚动页面 | scroll | 滚动位置 | — |
| 上传文件 | upload | CSS选择器 | 文件路径 |
| 拍照/截图 | screenshot | CSS选择器 | — |

#### 3.3 选择器推断策略

基于用户描述中的 UI 元素信息推断选择器：

- **用户描述中的元素标记**（用【】或「」包裹）→ 优先推断语义化选择器
  - 【登录】按钮 → `[data-testid="login-btn"]` 或 `.login-btn` 或 `button:has-text("登录")`
  - 【提交】按钮 → `[data-testid="submit-btn"]` 或 `.submit-btn` 或 `button:has-text("提交")`

- **用户描述中的位置信息** → 辅助推断选择器
  - "右上角" → 结合 `.header` 或 `.navbar` 等容器
  - "页面顶部" → 结合 `.top-bar` 或 `.header`
  - "左侧菜单" → 结合 `.sidebar` 或 `.nav-menu`

- **用户描述中的输入字段** → 推断表单选择器
  - "邮箱地址" → `input[name="email"]` 或 `input[type="email"]`
  - "密码" → `input[name="password"]` 或 `input[type="password"]`
  - "用户名" → `input[name="username"]` 或 `input[name="user"]`

- **URL 中的线索** → 推断页面结构
  - 包含 `/login` → 登录页面，使用 `.login-form` 或 `.auth-form`
  - 包含 `/dashboard` → 仪表盘页面，使用 `.dashboard`
  - 包含 `/admin` → 管理页面，使用 `.admin-panel`

- **选择器推断优先级**：
  1. `[data-testid="XXX"]` — 最稳定
  2. `[name="字段名"]` — 表单字段常用
  3. `button:has-text("按钮文本")` — 文本匹配
  4. `.语义类名 .子类名` — CSS 类名
  5. `input[type="类型"]` — 输入类型

### Step 4: 自动推断断言

为关键步骤自动推断断言，基于操作类型和用户描述中的验证点：

#### 4.1 断言推断规则

| 场景 | 推断断言 | 说明 |
|------|---------|------|
| navigate 操作后 | A1 页面可见 | 验证目标页面核心元素可见 |
| navigate 操作后（页面跳转描述） | A2 页面跳转 | 验证 URL 路径正确 |
| click 操作后（页面跳转描述） | A2 页面跳转 | 验证跳转到目标页面 |
| click 操作后（提交/确认类） | A4 内容匹配 | 验证操作结果文本 |
| 错误提示验证 | A1 + A4 | 验证错误提示元素可见 + 内容匹配 |
| 表单提交后 | A2 页面跳转 | 验证跳转到目标页面 |
| 用户描述中包含"验证"/"确认"/"应" | 对应断言 | 根据验证描述推断断言类型 |

#### 4.2 正向场景断言

- 正向场景：验证操作成功的结果
- **优先基于用户描述中的"预期结果"生成断言**：
  - "页面跳转到 XXX" → A2 页面跳转断言
  - "应显示 XXX" → A1 页面可见断言
  - "内容包含 XXX" → A4 内容匹配断言
- 如用户描述中无明确验证点，基于操作类型自动推断
- 示例（用户预期结果："页面跳转到 ASDM管理后台 首页面"）：
  ```yaml
  assertions:
    - type: A2
      target: current-url
      expected: /dashboard
      message: 页面应跳转到ASDM管理后台首页面
    - type: A1
      target: .dashboard
      expected: visible
      message: ASDM管理后台首页面应可见
  ```

#### 4.3 逆向场景断言

- 逆向场景：验证操作失败的结果
- 使用 A1（错误提示可见）+ A4（错误提示内容）断言
- 示例：
  ```yaml
  assertions:
    - type: A1
      target: .error-message
      expected: visible
      message: 错误提示应可见
    - type: A4
      target: .error-message
      expected: 邮箱格式不正确
      message: 错误提示内容应为"邮箱格式不正确"
  ```

#### 4.4 边界值场景断言

- 边界值场景：验证边界值处理结果
- 正边界（合法值）：验证成功结果
- 负边界（非法值）：验证拒绝或错误提示

### Step 5: 设置用例元数据与框架标记

1. **设置顶层字段**：
   - `name`：用例名称（基于用例描述和场景类型）
   - `description`：用例描述（中文，来自用户描述）
   - `framework`：使用 `framework` 参数值（默认 `playwright`）
   - `capture`：默认 `on-fail`
   - `tags`：自动推断标签（基于功能模块和场景类型）
   - `source`：固定为 `generate`
   - `metadata`：
     - `targetUrl`：从用户描述中提取的 URL（如 navigate 步骤中的 URL）
     - `timeout`：默认 30
     - `browser`：默认 chromium
     - `prerequisites`：从用户描述中提取的"前置条件"（如有）

2. **标签自动推断规则**：
   - 功能模块标签：基于用例描述标题提取（如 auth/login/dashboard）
   - 场景类型标签：正向→`happy-path`，逆向→`negative`，边界值→`boundary`
   - 优先级标签：基于功能重要性推断（P1/P2/P3）

3. **数据参数化**（当 `dataParam=true` 时）：
   - 将 type 步骤中的 value 提取为 params 变量
   - 参数名推断优先级：name 属性 > 字段语义 > 序号
   - 步骤 value 使用 `{{params.xxx}}` 引用

4. **验证用例符合 DSL Schema**：
   - `name` 非空 ✅
   - `stages` 数组长度 ≥ 1 ✅
   - 每个 Stage: `name` 非空 + `steps` ≥ 1 ✅
   - 每个 Step: `action` 必填 + `target` 必填 ✅
   - assert 操作: `assertions` ≥ 1 ✅
   - `source: generate` ✅

### Step 6: 输出 YAML 文件与审核提示

1. 将生成的用例保存为 YAML 文件：
   - 输出目录：`outputDir` 参数指定（默认 `.asdm/workspace/auto-test/cases/`）
   - 文件命名：`{用例名称}.yaml`（用例名称取自用户描述中的用例标题，如"系统登录"→`系统登录.yaml`）
   - 完整路径：`{outputDir}/{用例名称}.yaml`
   - 文件编码：UTF-8

2. 输出生成摘要：

```markdown
### ✅ AI 用例生成完成

> 从测试用例描述生成了 {totalCases} 个测试用例 | 正向: {positiveCount} | 逆向: {negativeCount} | 边界值: {boundaryCount}

| # | 用例名称 | 文件名 | 类型 | 功能点 | 阶段数 | 步骤数 | 断言数 | 标签 |
|:-:|---------|--------|:----:|--------|:------:|:------:|:------:|------|
| 1 | 001_system-login | 系统登录.yaml | 正向 | 系统登录 | 4 | 7 | 3 | auth, login, P1 |

**⚠️ 审核提示**：
- 选择器推断基于用例描述，请验证是否符合实际 UI 结构
- 断言推断基于操作步骤和验证点，请补充遗漏的验证点
- 建议执行 `/auto-test-run` 验证用例可执行性
- 可使用 `/auto-test-record` 录制补充选择器
- 如需生成逆向/边界值场景，请使用 `scenarioType=all` 参数

**文件路径**：`.asdm/workspace/auto-test/cases/{用例名称}.yaml`
```

3. 结构化输出：

```json
{
  "phase": "auto-test-generate",
  "status": "success",
  "scenario_type": "positive-only",
  "total_cases": 1,
  "positive_cases": 1,
  "negative_cases": 0,
  "boundary_cases": 0,
  "cases": [
    {
      "name": "001_system-login",
      "type": "positive",
      "feature": "系统登录",
      "stages_count": 4,
      "steps_count": 7,
      "assertions_count": 3,
      "tags": ["auth", "login", "P1"],
      "file_path": ".asdm/workspace/auto-test/cases/系统登录.yaml"
    }
  ],
  "timestamp": "ISO 8601 datetime"
}
```

## Execution Guidelines

### 测试用例描述解析优先级

1. 有明确编号步骤列表的 → 按步骤逐一解析
2. 有【】或「」标记 UI 元素的 → 优先提取元素名称和操作
3. 有 URL 的 → 识别为 navigate 操作，提取 targetUrl
4. 有"跳转"/"切换"描述的 → 识别为页面跳转，添加 pageTransition
5. 有"验证"/"确认"/"应"描述的 → 识别为验证点，添加断言

### 场景覆盖策略

- **scenarioType=positive-only（默认）**：仅生成 1 个正向场景，严格按用户描述的步骤和预期结果生成
  - 适用于冒烟测试、快速验证、回归测试等场景
  - 生成速度快，用例数量少，易于维护
- **scenarioType=all**：生成完整场景覆盖
  - **最小覆盖**：1 正向（仅用户描述的步骤）+ 1 逆向（最基础验证）
  - **标准覆盖**：1 正向 + N 逆向（按输入字段数量）+ 可选边界值
  - **深度覆盖**：多条验证点 → 多个正向场景 + 全字段逆向 + 全边界值
  - 用户可通过参数 `coverage=min/standard/deep` 控制覆盖深度（默认 standard）

### 选择器推断保守策略

- 当用户描述中未明确 UI 结构时，使用通用选择器模式
- 通用选择器模板：
  - 登录表单：`.login-form` 或 `.auth-form`
  - 表单输入框：`.form-class input[name="field-name"]` 或 `input[type="类型"]`
  - 提交按钮：`.form-class .submit-btn` 或 `button[type="submit"]` 或 `.btn-primary`
  - 错误提示：`.error-message` 或 `.alert-danger`
  - 导航菜单：`.nav-menu` 或 `.sidebar`
  - 头部区域：`.header` 或 `.navbar`
- 在审核提示中标记推断选择器，提醒用户验证

### 用例命名规范

- YAML 文件命名：使用用户描述中的用例名称（中文），格式为 `{用例名称}.yaml`
  - 示例：用例名称为"系统登录"→ 文件名 `系统登录.yaml`
  - 用例名称取自 Markdown 标题中的 `# 用例名称：XXX` 或用户描述的标题
  - 同一用例描述生成多个场景时，文件名规则：`{用例名称}-{场景描述}.yaml`（如 `系统登录-错误密码.yaml`、`系统登录-空邮箱.yaml`）
- YAML 内部 `name` 字段：使用英文小写 + 连字符，格式为 `{feature}-{scenario-type}-{detail}`
  - 示例：`001_system-login-succ`、`001_system-login-wrong-password`、`001_system-login-empty-email`

### 输出目录处理

- 如 `outputDir` 目录不存在 → 自动创建
- 如 `outputDir` 目录存在 → 检查是否有同名 YAML 文件
  - 用例名规则：从用例描述标题提取，中文转英文小写+连字符（如 系统登录→system-login）
  - 同一用例描述生成的多个场景文件（正向/逆向/边界值）放入同一子目录
- 如同名 YAML 文件已存在 → 覆盖（重新生成）
- 文件编码 UTF-8，确保中文内容正确保存

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| description | string | ✅ | 测试用例描述内容或文件路径（支持自然语言描述、结构化步骤、Markdown 测试文档） |
| framework | string | ❌ | 框架偏好，默认 playwright |
| outputDir | string | ❌ | 输出目录，默认 .asdm/workspace/auto-test/cases/ |
| scenarioType | string | ❌ | 场景类型：positive-only（仅正向，默认）/ all（正向+逆向+边界值） |
| coverage | string | ❌ | 覆盖深度：min/standard/deep，默认 standard（仅在 scenarioType=all 时生效） |
| dataParam | string | ❌ | 数据参数化开关：true/false，默认 false |

### 命令示例

```
# 结构化步骤描述（仅正向场景）
/auto-test-generate description="1. 浏览器地址栏输入：https://platform-dt02.asdm.ai/ 2. 点击【登录】 3. 输入邮箱：admin@test.com 4. 输入密码：pass123 5. 点击【登录】按钮"

# Markdown 文件路径（仅正向场景）
/auto-test-generate description=docs/test-cases/login-test.md

# 自然语言描述（仅正向场景）
/auto-test-generate description="打开ASDM平台，点击右上角登录按钮，输入邮箱和密码，点击登录"

# 生成完整场景（正向+逆向+边界值）
/auto-test-generate description="1. 打开 https://example.com 2. 输入用户名 3. 输入密码 4. 点击登录" scenarioType=all coverage=deep dataParam=true

# 带参数（仅正向场景 + 数据参数化）
/auto-test-generate description="1. 打开 https://example.com 2. 输入用户名 3. 输入密码 4. 点击登录" dataParam=true
```

## Output

### YAML 用例文件示例 — ASDM 平台登录（仅正向场景）

```yaml
name: 001_system-login-succ
description: 验证用户通过ASDM平台登录流程（正向场景）
framework: playwright
capture: on-fail
tags: [auth, login, happy-path, P1]
source: generate
params:
  email: super-admin@asdm.ai
  password: superadmin@20260214
metadata:
  targetUrl: https://platform-dt02.asdm.ai/
  timeout: 30
  browser: chromium
  prerequisites:
    - 用户已注册
stages:
  - name: 访问ASDM平台
    steps:
      - action: navigate
        target: https://platform-dt02.asdm.ai/
      - action: assert
        assertions:
          - type: A1
            target: .header
            expected: visible
            message: ASDM平台页面应可见
  - name: 点击登录入口
    steps:
      - action: click
        target: .header .login-btn
        pageTransition: navigate
      - action: assert
        assertions:
          - type: A1
            target: .login-form
            expected: visible
            message: ASDM登录页面应可见
  - name: 输入凭证并登录
    steps:
      - action: type
        target: .login-form input[name="email"]
        value: "{{params.email}}"
      - action: type
        target: .login-form input[name="password"]
        value: "{{params.password}}"
      - action: click
        target: .login-form .btn-primary
        capture: always
  - name: 登录验证
    steps:
      - action: wait
        target: .dashboard
        timeout: 5
      - action: assert
        assertions:
          - type: A2
            target: current-url
            expected: /dashboard
            message: 页面应跳转到ASDM管理后台首页面
          - type: A1
            target: .dashboard
            expected: visible
            message: ASDM管理后台首页面应可见
```

### 逆向场景示例 — 错误密码登录（仅当 scenarioType=all 时生成）

```yaml
name: 001_system-login-wrong-password
description: 验证错误密码登录失败（逆向场景）
framework: playwright
capture: on-fail
tags: [auth, login, negative, P1]
source: generate
metadata:
  targetUrl: https://platform-dt02.asdm.ai/
  timeout: 30
  browser: chromium
  prerequisites:
    - 用户已注册
stages:
  - name: 访问ASDM平台
    steps:
      - action: navigate
        target: https://platform-dt02.asdm.ai/
      - action: click
        target: .header .login-btn
        pageTransition: navigate
      - action: assert
        assertions:
          - type: A1
            target: .login-form
            expected: visible
            message: 登录表单应可见
  - name: 输入错误凭证
    steps:
      - action: type
        target: .login-form input[name="email"]
        value: super-admin@asdm.ai
      - action: type
        target: .login-form input[name="password"]
        value: wrong-password
      - action: click
        target: .login-form .btn-primary
      - action: wait
        target: .error-message
        timeout: 3
      - action: assert
        assertions:
          - type: A1
            target: .error-message
            expected: visible
            message: 错误提示应可见
          - type: A4
            target: .error-message
            expected: 密码错误
            message: 错误提示内容应为"密码错误"
```

### 逆向场景示例 — 空邮箱登录（仅当 scenarioType=all 时生成）

```yaml
name: 001_system-login-empty-email
description: 验证空邮箱登录失败（逆向场景）
framework: playwright
capture: on-fail
tags: [auth, login, negative, P2]
source: generate
metadata:
  targetUrl: https://platform-dt02.asdm.ai/
  timeout: 30
  browser: chromium
  prerequisites:
    - 用户已注册
stages:
  - name: 访问ASDM平台
    steps:
      - action: navigate
        target: https://platform-dt02.asdm.ai/
      - action: click
        target: .header .login-btn
        pageTransition: navigate
      - action: assert
        assertions:
          - type: A1
            target: .login-form
            expected: visible
            message: 登录表单应可见
  - name: 空邮箱登录
    steps:
      - action: type
        target: .login-form input[name="password"]
        value: superadmin@20260214
      - action: click
        target: .login-form .btn-primary
      - action: assert
        assertions:
          - type: A1
            target: .error-message
            expected: visible
            message: 错误提示应可见
          - type: A4
            target: .error-message
            expected: 邮箱不能为空
            message: 错误提示内容应为"邮箱不能为空"
```

## Configuration

Refer to:
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — YAML DSL 用例格式定义、Schema 校验、操作类型映射、断言类型 A1~A8
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 7 阶段执行规范、操作映射、断言判定、选择器约定
