# Web Auto Tester - YAML DSL 用例格式规范

**Document Version**: 1.0
**Last Updated**: 2026-07-14
**Toolset ID**: web-auto-tester

## Overview

本文档定义 Web Auto Tester 工具集的 YAML DSL 用例格式规范，包括用例文件结构、顶层字段说明、Stage 与 Step 定义、断言定义、框架标记与捕获配置、数据模型，以及完整的用例示例。

YAML DSL 格式与 `web-smoke-tester` Pipeline YAML 风格一致，继承其数据模型骨架（ID 生成规则、断言分类），但扩展了用例驱动测试的能力：增加断言类型（A5~A8）、支持双框架标记（Playwright/Selenium）、增加截图策略配置（on-fail/full/always）。

---

## 1. 用例文件顶层结构

YAML DSL 用例文件遵循以下顶层结构：

```yaml
name: string               # 必填，用例名称，唯一标识
description: string         # 可选，用例描述
framework: string           # 可选，框架偏好：playwright（默认）或 selenium
capture: string             # 可选，截图策略：on-fail（默认）或 full
tags: string[]              # 可选，标签列表，用于分类和筛选
metadata: object            # 可选，自定义元数据（目标URL、超时等）
source: string              # 可选，用例来源：generate/record/manual
stages: Stage[]             # 必填，测试阶段列表
```

### 顶层字段说明

| 字段 | 类型 | 必填 | 说明 | 示例 |
|------|------|:----:|------|------|
| name | string | ✅ | 用例名称，唯一标识 | `user-login-test` |
| description | string | ❌ | 用例描述 | `验证用户端登录流程` |
| framework | string | ❌ | 框架偏好：`playwright`（默认）或 `selenium` | `playwright` |
| capture | string | ❌ | 截图策略：`on-fail`（默认）或 `full` | `on-fail` |
| tags | string[] | ❌ | 标签列表，用于分类和筛选 | `[auth, user, P1]` |
| metadata | object | ❌ | 自定义元数据 | `{targetUrl, timeout, browser}` |
| source | string | ❌ | 用例来源 | `generate` / `record` / `manual` |
| stages | Stage[] | ✅ | 测试阶段列表 | 见 Stage 定义 |

---

## 2. metadata 子字段

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| targetUrl | string | 测试目标基础 URL | `http://localhost:3000` |
| timeout | number | 全局超时秒数（默认 30） | `30` |
| browser | string | 浏览器类型 | `chromium`、`firefox`、`webkit`、`chrome` |
| viewport | object | 视口尺寸 | `{width: 1280, height: 720}` |
| auth | object | 认证配置 | `{type: login, username: admin, password: xxx}` |

**auth 子字段**：

| 字段 | 类型 | 说明 |
|------|------|------|
| type | string | 认证方式：`login`（表单登录）、`token`（令牌注入）、`basic`（HTTP Basic） |
| username | string | 用户名（login 类型） |
| password | string | 密码（login 类型） |
| token | string | 认证令牌（token 类型） |
| loginUrl | string | 登录页面路径（login 类型） |

---

## 3. Stage 定义

Stage 表示测试的一个逻辑阶段（如"登录"、"搜索"、"验证"）：

```yaml
stages:
  - name: string             # 必填，阶段名称
    steps: Step[]            # 必填，步骤列表
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| name | string | ✅ | 阶段名称（如"登录页面访问"、"输入凭证"、"登录验证"） |
| steps | Step[] | ✅ | 步骤列表 |

---

## 4. Step 定义

Step 是一个可执行的操作步骤：

```yaml
steps:
  - action: string          # 必填，操作类型
    target: string          # 必填，目标选择器或 URL
    value: string           # 可选，输入值（type/select 操作必填）
    capture: string         # 可选，步骤截图策略
    timeout: number         # 可选，步骤超时秒数
    frameworkOverride: string  # 可选，步骤级框架偏好覆盖
    assertions: Assertion[]    # 可选，断言列表（action: assert 时使用）
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| action | string | ✅ | 操作类型：navigate/click/type/wait/scroll/upload/hover/select/screenshot/assert |
| target | string | ✅ | 目标选择器或 URL |
| value | string | ❌ | 输入值（type/select 操作必填） |
| capture | string | ❌ | 步骤截图策略：`always` 强制截图，或继承用例/stage 配置 |
| timeout | number | ❌ | 步骤超时秒数，覆盖全局配置 |
| frameworkOverride | string | ❌ | 步骤级框架偏好覆盖（仅限 Selenium 用例中特定步骤降级为 playwright） |
| assertions | Assertion[] | ❌ | 断言列表（action: assert 时使用） |

### 操作类型映射

| 操作类型 | 说明 | Playwright API | Selenium API |
|----------|------|----------------|--------------|
| navigate | 打开页面 | `page.goto(url)` | `driver.get(url)` |
| click | 点击元素 | `page.click(selector)` | `element.click()` |
| type | 输入文本 | `page.fill(selector, value)` | `element.sendKeys(value)` |
| wait | 等待元素或时间 | `page.waitForSelector/waitForTimeout` | `WebDriverWait(driver, timeout)` |
| scroll | 滚动页面 | `page.evaluate(scroll logic)` | `driver.executeScript(scroll)` |
| upload | 上传文件 | `page.setInputFiles(selector, files)` | `element.sendKeys(filepath)` |
| hover | 鼠标悬停 | `page.hover(selector)` | `ActionChains(driver).move_to_element()` |
| select | 下拉选择 | `page.selectOption(selector, value)` | `Select(element).select_by_value()` |
| screenshot | 截图 | `page.screenshot({path})` | `driver.save_screenshot(path)` |
| assert | 执行断言 | `expect(page).toHaveURL/toBeVisible/...` | 手动比对 + `driver.find_element` |

### 选择器约定

- **Playwright 用例**：直接使用 CSS 选择器或 Playwright 选择器语法
  - `.auth-form .el-button--primary`
  - `[data-testid="login-btn"]`
- **Selenium 用例**：使用 `css=` 前缀标记 CSS 选择器（SelectorStrategy 约定）
  - `css=.login-form .el-button--primary`
  - Selenium 也可使用 `id=`、`xpath=` 前缀

---

## 5. 断言定义

断言作为 Step 的 `action: assert` 类型，通过 `assertions` 字段定义多个断言：

```yaml
- action: assert
  assertions:
    - type: string          # 必填，断言类型 A1~A8
      target: string        # 必填，断言目标选择器
      expected: string      # 必填，预期值
      message: string       # 可选，断言失败时的自定义消息
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| type | string | ✅ | 断言类型：A1~A8 |
| target | string | ✅ | 断言目标选择器或 URL |
| expected | string | ✅ | 预期值 |
| message | string | ❌ | 断言失败时的自定义消息 |

### 8 种断言类型

| 编号 | 断言类型 | 适用框架 | 说明 | target 示例 | expected 示例 |
|:----:|----------|:--------:|------|------------|--------------|
| A1 | 页面可见 | PW/SEL | 验证页面/元素是否可见 | `.auth-form` | `visible` / `hidden` |
| A2 | 页面跳转 | PW/SEL | 验证 URL 跳转到预期路径 | — | `/home` |
| A3 | 元素状态 | PW/SEL | 验证元素属性（enabled/disabled/visible/hidden） | `.submit-btn` | `enabled` |
| A4 | 内容匹配 | PW/SEL | 验证页面/元素文本包含预期内容 | `.user-name` | `testuser` |
| A5 | API 响应 | PW | 验证接口返回数据（仅 Playwright 支持 `page.route`拦截） | `api:/api/user` | `{status: 200}` |
| A6 | 表单值 | PW/SEL | 验证表单输入框的当前值 | `input[name="email"]` | `user@example.com` |
| A7 | 元素数量 | PW/SEL | 验证匹配选择器的元素数量 | `.list-item` | `5` |
| A8 | 截图比对 | PW | 视觉回归断言（仅 Playwright 支持 `toHaveScreenshot`） | `.dashboard` | `baseline/dashboard.png` |

### 断言结果映射

| 实际 vs 预期 | 结果 |
|:------------:|------|
| 完全匹配 | **pass** |
| 不匹配 | **fail** |
| 执行异常（超时/元素未找到） | **error** |
| 条件不满足跳过 | **skip** |

### Selenium 断言限制

- A1~A4、A6、A7：完全支持（通过 `driver.find_element` + 手动比对）
- A5（API 响应）：不支持（Selenium 无 `page.route` 拦截能力）
- A8（截图比对）：不支持（Selenium 无 `toHaveScreenshot` 能力）

---

## 6. 框架标记与捕获配置

### 框架标记

- 用例顶层 `framework` 字段设置全局框架偏好：`playwright`（默认）或 `selenium`
- 单个 Step 可通过 `frameworkOverride` 临时切换框架（仅限 Selenium 用例中的特定步骤降级为 playwright）
- 执行时根据 framework 字段选择对应引擎适配
- Selenium 用例仅支持基础操作类型和断言（A1~A4、A6、A7）
- 如 Selenium 用例含 Playwright 专有操作（A5/A8/tracing/codegen），执行时降级为 playwright 并提示用户

### 捕获配置

- 用例顶层 `capture: on-fail | full` 设置全局截图策略
  - `on-fail`（默认）：仅失败步骤截图
  - `full`：每个步骤执行后截图
- 单个 Step 通过 `capture: always` 强制该步骤截图（不受全局策略限制）
- Selenium 用例仅支持全页截图（`driver.save_screenshot()`），不支持元素级截图

### 截图文件命名规则

| 截图策略 | 触发条件 | 文件命名 |
|----------|----------|----------|
| on-fail（默认） | 断言结果为 fail/error | `ATR-{id}-S{stepIndex}-fail.png` |
| full | 每个步骤执行后 | `ATR-{id}-S{stepIndex}-{status}.png` |
| 标记步骤（capture: always） | 用户标记的关键步骤 | `ATR-{id}-S{stepIndex}-marked.png` |

### 截图存储路径

所有截图保存到 `.asdm/workspace/auto-test/screenshots/`

---

## 7. 数据模型

### 7.1 AutoTestCase 数据模型（ATC）

| 字段ID | 字段 | 类型 | 说明 |
|--------|------|------|------|
| ATC-01 | id | string | 用例 ID：`ATC-{YYYYMMDD}-{NNN}` |
| ATC-02 | name | string | 用例名称 |
| ATC-03 | description | string | 用例描述 |
| ATC-04 | framework | string | 框架偏好：playwright/selenium |
| ATC-05 | capture | string | 截图策略：on-fail/full |
| ATC-06 | tags | string[] | 标签列表 |
| ATC-07 | metadata | object | 元数据配置 |
| ATC-08 | stages | Stage[] | 阶段列表 |
| ATC-09 | source | string | 用例来源：generate/record/manual |
| ATC-10 | createdAt | string | 创建时间（ISO 8601） |
| ATC-11 | updatedAt | string | 更新时间（ISO 8601） |

**Stage 子模型**：

| 字段 | 类型 | 说明 |
|------|------|------|
| name | string | 阶段名称 |
| steps | Step[] | 步骤列表 |

**Step 子模型**：

| 字段 | 类型 | 说明 |
|------|------|------|
| action | string | 操作类型 |
| target | string | 目标选择器 |
| value | string | 输入值 |
| capture | string | 截图策略 |
| timeout | number | 步骤超时 |
| frameworkOverride | string | 步骤级框架覆盖 |
| assertions | Assertion[] | 断言列表 |

**Assertion 子模型**：

| 字段 | 类型 | 说明 |
|------|------|------|
| type | string | 断言类型（A1~A8） |
| target | string | 断言目标 |
| expected | string | 预期值 |
| message | string | 失败消息 |

### 7.2 AutoTestResult 数据模型（ATR）

| 字段ID | 字段 | 类型 | 说明 |
|--------|------|------|------|
| ATR-01 | id | string | 结果 ID：`ATR-{YYYYMMDD}-{NNN}` |
| ATR-02 | testCaseId | string | 关联用例 ID |
| ATR-03 | testCaseName | string | 用例名称 |
| ATR-04 | status | string | 整体状态：pass/fail/error/skip |
| ATR-05 | totalSteps | number | 总步骤数 |
| ATR-06 | passedSteps | number | 通过步骤数 |
| ATR-07 | failedSteps | number | 失败步骤数 |
| ATR-08 | skippedSteps | number | 跳过步骤数 |
| ATR-09 | duration | number | 执行耗时（毫秒） |
| ATR-10 | startTime | string | 开始时间（ISO 8601） |
| ATR-11 | endTime | string | 结束时间（ISO 8601） |
| ATR-12 | framework | string | 实际执行框架 |
| ATR-13 | stepResults | StepResult[] | 步骤结果列表 |
| ATR-14 | environment | object | 执行环境信息 |

**StepResult 子模型**：

| 字段 | 类型 | 说明 |
|------|------|------|
| stepIndex | number | 步骤序号 |
| action | string | 操作类型 |
| target | string | 目标 |
| expected | string | 预期值 |
| actual | string | 实际值 |
| status | string | 状态：pass/fail/error/skip |
| duration | number | 步骤耗时（毫秒） |
| errorMessage | string | 错误信息 |
| screenshotPath | string | 截图路径（如有） |

### 7.3 AutoTestReport 数据模型

| 字段 | 类型 | 说明 |
|------|------|------|
| title | string | 报告标题 |
| generatedAt | string | 生成时间（ISO 8601） |
| totalCases | number | 总用例数 |
| passedCases | number | 通过用例数 |
| failedCases | number | 失败用例数 |
| skippedCases | number | 跳过用例数 |
| passRate | string | 通过率（百分比） |
| totalDuration | number | 总耗时（毫秒） |
| results | AutoTestResult[] | 结果列表 |

---

## 8. 与 smoke-tester Pipeline YAML 的风格一致性

Web Auto Tester 的 YAML DSL 格式继承 `web-smoke-tester` Pipeline YAML 的设计风格：

### 一致性说明

| 维度 | smoke-tester Pipeline YAML | web-auto-tester YAML DSL |
|------|---------------------------|--------------------------|
| 结构 | stages + steps | stages + steps（相同） |
| 阶段概念 | Stage（逻辑阶段） | Stage（逻辑阶段，相同） |
| 步骤定义 | action/target/value | action/target/value（相同骨架） |
| 断言分类 | B1~B5（5种Browser断言） | A1~A8（8种断言，扩展） |
| ID 规则 | STR-{YYYYMMDD}-{NNN} | ATC-/ATR-{YYYYMMDD}-{NNN}（延续规则） |
| 数据模型 | SmokeTestRecord | AutoTestCase/AutoTestResult（延续骨架） |
| 捕获配置 | capture（失败截图） | capture: on-fail/full/always（扩展） |

### 差异说明

- **断言类型扩展**：smoke-tester 定义 B1~B5（5 种 Browser 断言），web-auto-tester 定义 A1~A8（8 种断言），新增 A5（API 响应）、A8（截图比对）
- **框架标记**：web-auto-tester 新增 `framework` 字段支持双框架，smoke-tester 仅支持 Playwright
- **截图策略**：web-auto-tester 新增 `capture: full/always` 策略，smoke-tester 仅失败截图
- **用例来源标记**：web-auto-tester 新增 `source` 字段追踪用例来源（generate/record/manual）

---

## 9. 用例示例

### 9.1 Playwright 用例示例 — 登录测试

```yaml
name: user-login-test
description: 验证用户端登录流程
framework: playwright
capture: on-fail
tags: [auth, user, P1]
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
        target: .auth-form .el-form-item:first-child input
        value: testuser
      - action: type
        target: .auth-form .el-form-item:nth-child(2) input
        value: password123
      - action: click
        target: .auth-form .el-button--primary
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

### 9.2 Selenium 用例示例 — 简化版登录测试

```yaml
name: admin-login-selenium
description: 验证管理端登录流程（Selenium框架）
framework: selenium
capture: on-fail
tags: [auth, admin, selenium]
metadata:
  targetUrl: http://localhost:3001
  timeout: 30
  browser: chrome
stages:
  - name: 登录
    steps:
      - action: navigate
        target: /login
      - action: type
        target: css=.login-form .el-form-item:first-child input
        value: admin
      - action: type
        target: css=.login-form .el-form-item:nth-child(2) input
        value: admin123
      - action: click
        target: css=.login-form .el-button--primary
      - action: wait
        target: css=.sidebar
        timeout: 5
      - action: assert
        assertions:
          - type: A1
            target: css=.sidebar
            expected: visible
            message: 侧边栏应可见
          - type: A4
            target: css=.sidebar .admin-name
            expected: admin
            message: 管理员名称应显示为 admin
```

### 9.3 AI 生成用例示例 — 带 source 标记

```yaml
name: search-product-test
description: 验证商品搜索和筛选功能
framework: playwright
capture: on-fail
tags: [search, product, P2]
source: generate
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
  browser: chromium
stages:
  - name: 搜索页面访问
    steps:
      - action: navigate
        target: /products
      - action: assert
        assertions:
          - type: A1
            target: .search-bar
            expected: visible
  - name: 搜索商品
    steps:
      - action: type
        target: .search-bar input
        value: 手机
      - action: click
        target: .search-bar .search-btn
      - action: wait
        target: .product-list
        timeout: 5
  - name: 验证搜索结果
    steps:
      - action: assert
        assertions:
          - type: A7
            target: .product-list .product-item
            expected: 3
            message: 搜索"手机"应至少返回3个结果
          - type: A4
            target: .product-list .product-item:first-child .product-name
            expected: 手机
```

---

## 10. Schema 校验规则

### 必填字段校验

- `name`：非空字符串，建议使用小写英文字母 + 连字符（如 `user-login-test`）
- `stages`：数组类型，长度 ≥ 1
- 每个 Stage：`name` 非空 + `steps` 数组长度 ≥ 1
- 每个 Step：`action` 必填 + `target` 必填
- `type` / `select` 操作的 Step：`value` 必填
- `assert` 操作的 Step：`assertions` 数组必填且长度 ≥ 1

### 框架校验

- `framework` 只接受 `playwright` 或 `selenium`
- Selenium 用例的 `target` 应使用 `css=` / `id=` / `xpath=` 前缀
- Selenium 用例不应包含 A5/A8 断言（如包含则降级为 playwright）

### 命名规范

- 用例文件命名：`{name}.yaml`（与用例 `name` 字段一致）
- 用例 ID 格式：`ATC-{YYYYMMDD}-{NNN}`
- 结果 ID 格式：`ATR-{YYYYMMDD}-{NNN}`
- 截图命名：`ATR-{id}-S{stepIndex}-{strategy}.png`
