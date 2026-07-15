# ASDM Action: Auto Test Generate

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456791",
  "name": "auto-test-generate",
  "displayName": "AI 生成测试用例",
  "description": "从 Markdown 需求文档自动生成 YAML DSL 测试用例，支持正向/逆向/边界值场景覆盖，自动推断断言，输出符合 DSL 规范的 YAML 用例文件",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.1"
  },
  "scenario": "auto-test-generation"
}
```

## Purpose

本 action 是 Web Auto Tester 的用例生成命令。用户传入 Markdown 需求文档（PRD 或功能描述），AI 自动解析功能点和验收标准，生成正向/逆向/边界值测试场景，转换为 YAML DSL 用例格式，自动推断断言，输出可执行的测试用例文件。用例标记 `source: generate` 以追溯来源。

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

3. **需求文档** (Required)
   - Path: 用户通过 `document` 参数提供（Markdown 文档内容或文件路径）
   - Purpose: 提取功能描述段落和验收标准

## Steps

### Step 1: 读取与解析需求文档

1. 根据 `document` 参数获取 Markdown 内容：
   - 指定文件路径 → 读取该 Markdown 文件
   - 直接传入内容 → 使用传入的文本内容
2. 解析 Markdown 结构，提取以下关键信息：
   - **功能描述段落**：识别标题层级（`#` ~ `####`），提取每个功能点的描述文本
   - **验收标准**：识别"验收标准"/"Acceptance Criteria"/"AC" 关键词段落，提取每条验收条件
   - **用户交互流程**：识别包含步骤、操作、页面跳转的描述段落
   - **业务规则与约束**：识别包含"规则"/"约束"/"限制"/"验证"的描述段落
   - **数据要求**：识别包含字段名、数据类型、必填/可选、范围值的描述段落
3. 为每个功能点建立结构化摘要：

```json
{
  "featureId": "F01",
  "featureName": "用户登录",
  "description": "用户通过账号密码登录系统",
  "acceptanceCriteria": [
    "登录成功后跳转到首页",
    "登录失败显示错误提示",
    "密码错误超过5次锁定账号"
  ],
  "userFlows": [
    "输入用户名 → 输入密码 → 点击登录按钮 → 等待响应 → 跳转首页或显示错误"
  ],
  "businessRules": [
    "用户名长度 3~20 字符",
    "密码长度 6~20 字符",
    "连续错误5次锁定15分钟"
  ],
  "dataFields": [
    {"name": "username", "type": "string", "required": true, "min": 3, "max": 20},
    {"name": "password", "type": "string", "required": true, "min": 6, "max": 20}
  ]
}
```

### Step 2: 生成测试场景

为每个功能点生成覆盖三类场景的测试用例：

#### 2.1 正向场景（Happy Path）

- 按用户交互流程逐步生成操作步骤
- 每个正向场景验证一条验收标准
- 场景命名规则：`{功能名}-{正向场景描述}`
- 示例：`用户登录-正常登录成功`

#### 2.2 逆向场景（Negative Path）

- 基于业务规则和约束生成违反规则的测试
- 每条约束至少生成1个逆向场景
- 逆向场景类型：
  - 空值/缺失必填字段
  - 超出范围值（过长/过短/过大/过小）
  - 非法格式（非邮箱格式/非数字/特殊字符）
  - 权限不足/未认证
  - 错误操作顺序
- 场景命名规则：`{功能名}-{逆向场景描述}`
- 示例：`用户登录-空用户名登录失败`

#### 2.3 边界值场景（Boundary Value）

- 基于数据字段的 min/max 值生成边界测试
- 边界值测试类型：
  - 最小值（min）
  - 最小值-1（min-1，验证拒绝）
  - 最大值（max）
  - 最大值+1（max+1，验证拒绝）
  - 临界值（min+1, max-1）
- 场景命名规则：`{功能名}-{边界值描述}`
- 示例：`用户登录-用户名最小长度3字符`

#### 2.4 场景数量控制

- 每个功能点至少生成：1 个正向 + 1 个逆向 + 2 个边界值
- 如验收标准超过3条，正向场景按验收标准数量增加
- 如业务规则超过3条，逆向场景按规则数量增加
- 总场景数量建议控制在 5~15 个/功能点

### Step 3: 转换为 YAML DSL 结构

将每个测试场景转换为 YAML DSL 的 `stages/steps` 结构：

#### 3.1 Stage 划分策略

- 每个场景按逻辑阶段划分 Stage：
  - **访问阶段**：导航到目标页面 + 页面可见断言
  - **操作阶段**：执行用户交互操作（输入/点击/选择等）
  - **验证阶段**：执行断言判定结果

- Stage 命名规则：使用中文描述（如"登录页面访问"/"输入凭证"/"登录验证"）

#### 3.2 Step 操作映射

按 `auto-test-dsl-spec.md` §4 操作类型映射表，将场景操作转换为 Step：

| 场景操作 | Step action | target | value |
|----------|------------|--------|-------|
| 打开页面 | navigate | URL路径 | — |
| 输入文本 | type | CSS选择器 | 输入值 |
| 点击按钮 | click | CSS选择器 | — |
| 选择下拉 | select | CSS选择器 | 选项值 |
| 等待加载 | wait | CSS选择器 | — |
| 鼠标悬停 | hover | CSS选择器 | — |
| 滚动页面 | scroll | 滚动位置 | — |
| 上传文件 | upload | CSS选择器 | 文件路径 |
| 拍照记录 | screenshot | CSS选择器 | — |

#### 3.3 选择器推断策略

- 优先使用语义化选择器：`[data-testid="XXX"]`
- 其次使用 CSS 类名：`.类名 .子类名`
- 避免使用绝对位置选择器（nth-child）除非必要
- 基于需求文档中的 UI 描述推断选择器：
  - 表单输入框 → `.类名 input` 或 `[name="字段名"]`
  - 按钮 → `.类名 .按钮类名` 或 `[data-testid="按钮名"]`
  - 列表项 → `.列表类名 .项类名`
  - 提示信息 → `.提示类名` 或 `.error-message`

### Step 4: 自动推断断言

为每个 Step 自动推断断言，基于验收标准和操作类型：

#### 4.1 断言推断规则

| 场景 | 推断断言 | 说明 |
|------|---------|------|
| navigate 操作后 | A1 页面可见 | 验证目标页面核心元素可见 |
| navigate 操作后 | A2 页面跳转 | 验证 URL 路径正确 |
| click 操作后（提交/确认类） | A4 内容匹配 | 验证操作结果文本 |
| 错误提示验证 | A1 + A4 | 验证错误提示元素可见 + 内容匹配 |
| 表单提交后 | A2 页面跳转 | 验证跳转到目标页面 |
| 数据范围验证 | A4 内容匹配 | 验证显示正确数据 |
| 列表/数量验证 | A7 元素数量 | 验证元素数量符合预期 |
| 表单值验证 | A6 表单值 | 验证输入框当前值 |

#### 4.2 正向场景断言

- 正向场景：验证操作成功的结果
- 使用 A1/A2/A4 组合断言
- 示例：
  ```yaml
  assertions:
    - type: A2
      target: current-url
      expected: /home
      message: 登录成功后应跳转到首页
    - type: A4
      target: .header-user .user-name
      expected: testuser
      message: 用户名应显示为 testuser
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
      expected: 用户名不能为空
      message: 错误提示内容应包含预期文字
  ```

#### 4.4 边界值场景断言

- 边界值场景：验证边界值处理结果
- 正边界（合法值）：验证成功结果
- 负边界（非法值）：验证拒绝或错误提示
- 示例：
  ```yaml
  assertions:
    - type: A1
      target: .error-message
      expected: visible
      message: 超长用户名应显示错误提示
  ```

### Step 5: 设置用例元数据与框架标记

1. **设置顶层字段**：
   - `name`：用例名称（基于功能点和场景类型）
   - `description`：用例描述（中文）
   - `framework`：使用 `framework` 参数值（默认 `playwright`）
   - `capture`：默认 `on-fail`
   - `tags`：自动推断标签（基于功能模块和场景类型）
   - `source`：固定为 `generate`
   - `metadata`：
     - `targetUrl`：从需求文档推断或使用用户指定
     - `timeout`：默认 30
     - `browser`：默认 chromium

2. **标签自动推断规则**：
   - 功能模块标签：基于需求文档标题提取（如 auth/search/product）
   - 场景类型标签：正向→`happy-path`，逆向→`negative`，边界值→`boundary`
   - 优先级标签：基于功能重要性推断（P1/P2/P3）

3. **验证用例符合 DSL Schema**：
   - `name` 非空 ✅
   - `stages` 数组长度 ≥ 1 ✅
   - 每个 Stage: `name` 非空 + `steps` ≥ 1 ✅
   - 每个 Step: `action` 必填 + `target` 必填 ✅
   - assert 操作: `assertions` ≥ 1 ✅
   - `source: generate` ✅

### Step 6: 输出 YAML 文件与审核提示

1. 将生成的用例保存为 YAML 文件：
   - 输出目录：`outputDir` 参数指定（默认 `.asdm/workspace/auto-test/cases/`）
   - 文件命名：`{name}.yaml`
   - 文件编码：UTF-8

2. 输出生成摘要：

```markdown
### ✅ AI 用例生成完成

> 从需求文档生成了 {totalCases} 个测试用例 | 正向: {positiveCount} | 逆向: {negativeCount} | 边界值: {boundaryCount}

| # | 用例名称 | 类型 | 功能点 | 阶段数 | 步骤数 | 断言数 | 标签 |
|:-:|---------|:----:|--------|:------:|:------:|:------:|------|
| 1 | user-login-happy-path | 正向 | 用户登录 | 3 | 7 | 4 | auth, happy-path, P1 |
| 2 | user-login-empty-username | 逆向 | 用户登录 | 2 | 4 | 2 | auth, negative, P1 |
| 3 | user-login-min-username | 边界值 | 用户登录 | 2 | 5 | 2 | auth, boundary, P1 |

**⚠️ 审核提示**：
- 选择器推断基于需求描述，请验证是否符合实际 UI 结构
- 断言推断基于验收标准，请补充遗漏的验证点
- 建议执行 `/auto-test-run` 验证用例可执行性
- 可使用 `/auto-test-record` 录制补充选择器

**文件路径**：`.asdm/workspace/auto-test/cases/{name}.yaml`
```

3. 结构化输出：

```json
{
  "phase": "auto-test-generate",
  "status": "success",
  "total_cases": 5,
  "positive_cases": 1,
  "negative_cases": 2,
  "boundary_cases": 2,
  "cases": [
    {
      "name": "user-login-happy-path",
      "type": "positive",
      "feature": "用户登录",
      "stages_count": 3,
      "steps_count": 7,
      "assertions_count": 4,
      "tags": ["auth", "happy-path", "P1"],
      "file_path": ".asdm/workspace/auto-test/cases/user-login-happy-path.yaml"
    }
  ],
  "timestamp": "ISO 8601 datetime"
}
```

## Execution Guidelines

### 需求文档解析优先级

1. 有明确"验收标准"段落的 → 直接提取为断言依据
2. 无明确"验收标准"但有"功能描述" → 从描述推断预期结果
3. 有 UI 线框图或截图引用 → 优先推断视觉相关断言（A1/A8）
4. 有 API 接口描述 → 推断 API 相关断言（A5）

### 场景覆盖策略

- **最小覆盖**：1 正向 + 1 逆向（最基础验证）
- **标准覆盖**：1 正向 + N 逆向（按约束数）+ 2 边界值
- **深度覆盖**：多条验收标准 → 多个正向场景 + 全约束逆向 + 全边界值
- 用户可通过参数 `coverage=min/standard/deep` 控制覆盖深度（默认 standard）

### 选择器推断保守策略

- 当需求文档未明确 UI 结构时，使用通用选择器模式
- 通用选择器模板：
  - 登录表单：`.auth-form` 或 `.login-form`
  - 表单输入框：`.form-class input` 或 `[name="field-name"]`
  - 提交按钮：`.form-class .submit-btn` 或 `.btn-primary`
  - 错误提示：`.error-message` 或 `.alert-danger`
  - 导航菜单：`.nav-menu` 或 `.sidebar`
- 在审核提示中标记推断选择器，提醒用户验证

### 用例命名规范

- 用例名称使用英文小写 + 连字符
- 命名格式：`{feature}-{scenario-type}-{detail}`
- 示例：`user-login-happy-path`、`user-login-empty-username`、`user-login-min-username`

### 输出目录处理

- 如 `outputDir` 目录不存在 → 自动创建
- 如同名 YAML 文件已存在 → 覆盖（重新生成）
- 文件编码 UTF-8，确保中文内容正确保存

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| document | string | ✅ | Markdown 文档内容或文件路径 |
| framework | string | ❌ | 框架偏好，默认 playwright |
| outputDir | string | ❌ | 输出目录，默认 .asdm/workspace/auto-test/cases/ |
| coverage | string | ❌ | 覆盖深度：min/standard/deep，默认 standard |

### 命令示例

```
/auto-test-generate document=docs/prd/user-login.md
/auto-test-generate document=docs/prd/user-login.md framework=playwright
/auto-test-generate document=docs/prd/user-login.md outputDir=cases/ coverage=deep
/auto-test-generate document="## 用户登录功能\n### 验收标准\n1. 登录成功跳转首页"
```

## Output

### YAML 用例文件示例

```yaml
name: user-login-happy-path
description: 验证用户正常登录成功流程（正向场景）
framework: playwright
capture: on-fail
tags: [auth, user, happy-path, P1]
source: generate
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
  browser: chromium
stages:
  - name: 登录页面访问
    steps:
      - action: navigate
        target: /login
      - action: assert
        assertions:
          - type: A1
            target: .auth-form
            expected: visible
            message: 登录表单应可见
  - name: 输入凭证
    steps:
      - action: type
        target: .auth-form [name="username"]
        value: testuser
      - action: type
        target: .auth-form [name="password"]
        value: password123
      - action: click
        target: .auth-form .btn-primary
        capture: always
  - name: 登录验证
    steps:
      - action: wait
        target: .header-user
        timeout: 5
      - action: assert
        assertions:
          - type: A2
            target: current-url
            expected: /home
            message: 登录成功后应跳转到首页
          - type: A4
            target: .header-user .user-name
            expected: testuser
            message: 用户名应显示为 testuser
```

### 逆向场景示例

```yaml
name: user-login-empty-username
description: 验证空用户名登录失败（逆向场景）
framework: playwright
capture: on-fail
tags: [auth, user, negative, P1]
source: generate
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
  browser: chromium
stages:
  - name: 登录页面访问
    steps:
      - action: navigate
        target: /login
      - action: assert
        assertions:
          - type: A1
            target: .auth-form
            expected: visible
            message: 登录表单应可见
  - name: 空用户名登录
    steps:
      - action: type
        target: .auth-form [name="password"]
        value: password123
      - action: click
        target: .auth-form .btn-primary
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
            expected: 用户名不能为空
            message: 错误提示内容应为"用户名不能为空"
```

### 边界值场景示例

```yaml
name: user-login-min-username
description: 验证用户名最小长度3字符登录成功（边界值场景）
framework: playwright
capture: on-fail
tags: [auth, user, boundary, P2]
source: generate
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
  browser: chromium
stages:
  - name: 登录页面访问
    steps:
      - action: navigate
        target: /login
      - action: assert
        assertions:
          - type: A1
            target: .auth-form
            expected: visible
            message: 登录表单应可见
  - name: 最小长度用户名登录
    steps:
      - action: type
        target: .auth-form [name="username"]
        value: abc
      - action: type
        target: .auth-form [name="password"]
        value: password123
      - action: click
        target: .auth-form .btn-primary
      - action: wait
        target: .header-user
        timeout: 5
      - action: assert
        assertions:
          - type: A2
            target: current-url
            expected: /home
            message: 最小长度用户名应能正常登录
```

## Configuration

Refer to:
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — YAML DSL 用例格式定义、Schema 校验、操作类型映射、断言类型 A1~A8
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 7 阶段执行规范、操作映射、断言判定、选择器约定
