# Web Auto Tester 执行引擎规范

**Document Version**: 1.0
**Last Updated**: 2026-07-14
**Toolset ID**: web-auto-tester

## Overview

本文档定义 Web Auto Tester 执行引擎的完整规范，包括 7 阶段执行流程、操作映射、断言引擎、截图采集、结果记录和报告输出。所有引擎功能由 AI Agent 按本规范执行，无实际编译代码。

---

## Pipeline 总览

```
YAML DSL 用例文件
    │
    ▼
[Phase 1: 用例加载] ──→ YAML 解析 → Schema 校验 → AutoTestCase 结构化
    │
    ▼
[Phase 2: 上下文准备] ──→ 读取 metadata → 初始化浏览器选项 → 确定执行框架
    │
    ▼
[Phase 3: 执行引擎] ──→ Playwright/Selenium 适配 → Step 逐个执行 → 异常捕获
    │
    ▼
[Phase 4: 断言判定] ──→ A1~A8 断言类型 → 结果映射 pass/fail/error/skip
    │
    ▼
[Phase 5: 截图采集] ──→ on-fail/full/always 三策略 → 文件命名 → 存储路径
    │
    ▼
[Phase 6: 结果记录] ──→ AutoTestResult JSON → ATR-{YYYYMMDD}-{NNN} ID → 持久化到 results/
    │
    ▼
[Phase 7: 报告输出] ──→ 简要摘要输出（详细 HTML 报告在 P4 实现）
```

---

## Phase 1: 用例加载

### 1.1 加载流程

1. **读取 YAML 文件**：从 `.asdm/workspace/auto-test/cases/` 目录或用户指定路径读取 YAML DSL 用例文件
2. **YAML 解析**：将 YAML 内容解析为结构化对象
3. **Schema 校验**：按照以下规则校验用例结构完整性
4. **结构化输出**：生成 `AutoTestCase` 结构

### 1.2 Schema 校验规则

| 校验项 | 规则 | 失败处理 |
|--------|------|----------|
| name | 非空字符串，建议小写+连字符 | 报错并终止 |
| stages | 数组类型，长度 ≥ 1 | 报错并终止 |
| Stage.name | 非空字符串 | 报错并跳过该 Stage |
| Stage.steps | 数组类型，长度 ≥ 1 | 报错并跳过该 Stage |
| Step.action | 必填，值在操作类型映射表中 | 报错并标记该 Step 为 error |
| Step.target | 必填 | 报错并标记该 Step 为 error |
| Step.value | type/select 操作必填 | 报错并标记该 Step 为 error |
| Step.assertions | assert 操作必填且长度 ≥ 1 | 报错并标记该 Step 为 error |
| framework | 值为 playwright 或 selenium | 默认 playwright |
| capture | 值为 on-fail 或 full | 默认 on-fail |

### 1.3 用例 ID 生成

- 格式：`ATC-{YYYYMMDD}-{NNN}`
- YYYYMMDD：用例创建或加载日期
- NNN：当天三位序号，从 001 开始递增
- 全局唯一：检查 `.asdm/workspace/auto-test/results/` 目录已有的 ID，避免冲突

---

## Phase 2: 上下文准备

### 2.1 Metadata 读取

从用例的 `metadata` 字段读取以下配置：

| 配置项 | 字段 | 默认值 | 说明 |
|--------|------|--------|------|
| 目标 URL | targetUrl | `http://localhost:3000` | 测试目标基础 URL |
| 全局超时 | timeout | 30 | 全局超时秒数 |
| 浏览器类型 | browser | chromium | chromium/firefox/webkit/chrome |
| 视口尺寸 | viewport | {width:1280, height:720} | 浏览器视口配置 |
| 认证配置 | auth | null | 认证方式及凭证 |

### 2.2 浏览器选项初始化

**Playwright 初始化**：

```typescript
// 等价配置（AI Agent 按此逻辑执行）
{
  browser: metadata.browser || 'chromium',  // chromium/firefox/webkit
  viewport: metadata.viewport || { width: 1280, height: 720 },
  timeout: (metadata.timeout || 30) * 1000,  // 毫秒
  headless: true,  // 默认无头模式
}
```

**Selenium 初始化**：

```typescript
// 等价配置（AI Agent 按此逻辑执行）
{
  browser: metadata.browser || 'chrome',  // chrome/firefox/edge
  viewport: metadata.viewport || { width: 1280, height: 720 },
  timeout: (metadata.timeout || 30) * 1000,  // 毫秒
  implicitWait: 5000,  // Selenium 隐式等待 5 秒
}
```

### 2.3 框架选择策略

1. 读取用例顶层 `framework` 字段（默认 `playwright`）
2. 如指定 `selenium`，检查用例中是否包含 Playwright 专有操作（A5/A8/tracing/codegen）
3. 如包含专有操作，**降级为 playwright** 并提示用户：`"用例包含 Playwright 专有特性（A5/API拦截 或 A8/截图比对），已自动降级为 Playwright 执行引擎"`
4. Step 级 `frameworkOverride` 字段可临时切换框架（仅限 Selenium→Playwright 降级）

### 2.4 认证处理

如 metadata.auth 存在，在执行测试步骤前先完成认证：

| 认证方式 | 执行逻辑 |
|----------|----------|
| login | 先访问 auth.loginUrl，执行登录步骤（输入用户名+密码+点击登录），获取登录态 |
| token | 在浏览器中注入 localStorage 或 cookie（`{tokenName: auth.token}`） |
| basic | 设置 HTTP Basic Auth 头（Playwright: `page.setExtraHTTPHeaders`） |

---

## Phase 3: 执行引擎

### 3.1 Playwright 主引擎操作映射

| 操作类型 | Playwright API | 参数映射 | 说明 |
|----------|---------------|----------|------|
| navigate | `page.goto(targetUrl)` | target → URL（拼接 metadata.targetUrl + target） | 打开页面 |
| click | `page.click(target)` | target → CSS 选择器或 Playwright 选择器 | 点击元素 |
| type | `page.fill(target, value)` | target → 选择器, value → 输入值 | 输入文本（清空后输入） |
| wait | `page.waitForSelector(target, {timeout})` | target → 选择器, timeout → 步骤超时或全局超时 | 等待元素出现 |
| scroll | `page.evaluate(() => window.scrollTo(x, y))` | target → 滚动目标位置 | 滚动页面 |
| upload | `page.setInputFiles(target, value)` | target → 文件输入框选择器, value → 文件路径 | 上传文件 |
| hover | `page.hover(target)` | target → 选择器 | 鼠标悬停 |
| select | `page.selectOption(target, value)` | target → 下拉框选择器, value → 选项值 | 下拉选择 |
| screenshot | `page.screenshot({path, fullPage})` | path → 截图保存路径 | 截图 |
| assert | 内置断言（见 Phase 4） | — | 断言判定 |

### 3.2 Selenium 辅引擎操作映射

| 操作类型 | Selenium API | 参数映射 | 说明 |
|----------|-------------|----------|------|
| navigate | `driver.get(targetUrl)` | target → URL（拼接 metadata.targetUrl + target） | 打开页面 |
| click | `driver.find_element(By.CSS_SELECTOR, sel).click()` | target → `css=` 前缀去除后作为 CSS 选择器 | 点击元素 |
| type | `driver.find_element(By.CSS_SELECTOR, sel).send_keys(value)` | target → 选择器, value → 输入值 | 输入文本 |
| wait | `WebDriverWait(driver, timeout).until(EC.presence_of_element_located((By.CSS_SELECTOR, sel)))` | target → 选择器, timeout → 步骤超时 | 等待元素 |
| scroll | `driver.execute_script("window.scrollTo(x, y)")` | target → 滚动目标 | 滚动页面 |
| screenshot | `driver.save_screenshot(path)` | path → 截图保存路径 | 全页截图 |
| hover | `ActionChains(driver).move_to_element(element).perform()` | target → 选择器 | 鼠标悬停 |
| select | `Select(element).select_by_value(value)` | target → 下拉框选择器, value → 选项值 | 下拉选择 |
| assert | 手动比对 + `driver.find_element` | — | 无内置 expect |

### 3.3 选择器策略

**Playwright 选择器**：
- 直接使用 CSS 选择器：`.auth-form .el-button--primary`
- 支持数据属性选择器：`[data-testid="login-btn"]`
- 支持文本选择器：`text=登录`

**Selenium 选择器（css= 前缀约定）**：
- `css=.login-form .el-button--primary` → 去除 `css=` 前缀，使用 CSS_SELECTOR 定位
- `id=username` → 使用 By.ID 定位
- `xpath=//div[@class='form']` → 使用 By.XPATH 定位

### 3.4 Step 逐个执行规则

1. **顺序执行**：Step 按序号依次执行，不跳步
2. **快速失败**：某步骤 fail/error 后，后续步骤标记为 `skip`
3. **超时控制**：每个步骤使用 `timeout` 字段或全局超时，超时视为 error
4. **异常捕获**：
   - 元素未找到 → Step 状态 error，记录 errorMessage
   - 超时 → Step 状态 error，记录 "操作超时"
   - 网络异常 → Step 状态 error，记录 "网络请求异常"
   - 断言失败 → Step 状态 fail，记录断言详情
5. **跨 Stage 执行**：Stage 间顺序执行，不中断（即使某 Stage 有失败步骤，下个 Stage 继续执行直至快速失败规则触发）

---

## Phase 4: 断言判定

### 4.1 断言类型定义

| 编号 | 断言类型 | 适用框架 | Playwright 实现 | Selenium 实现 | target | expected |
|:----:|----------|:--------:|-----------------|--------------|--------|----------|
| A1 | 页面可见 | PW/SEL | `expect(locator).toBeVisible()` | `element.is_displayed()` | CSS 选择器 | `visible` / `hidden` |
| A2 | 页面跳转 | PW/SEL | `expect(page).toHaveURL(expected)` | `driver.current_url.contains(expected)` | `current-url` | URL 路径 |
| A3 | 元素状态 | PW/SEL | `expect(locator).toBeEnabled/Disabled()` | `element.is_enabled()` | CSS 选择器 | `enabled` / `disabled` / `visible` / `hidden` |
| A4 | 内容匹配 | PW/SEL | `expect(locator).toHaveText(expected)` | `element.text.contains(expected)` | CSS 选择器 | 预期文本 |
| A5 | API 响应 | PW | `page.route()` 拦截 + `expect(response).Status()` | ❌ 不支持 | `api:{path}` | `{status: N}` 或 JSON 片段 |
| A6 | 表单值 | PW/SEL | `expect(locator).toHaveValue(expected)` | `element.get_attribute('value')` | CSS 选择器 | 预期输入值 |
| A7 | 元素数量 | PW/SEL | `expect(locator).toHaveCount(expected)` | `len(driver.find_elements(selector))` | CSS 选择器 | 预期数量 |
| A8 | 截图比对 | PW | `expect(locator).toHaveScreenshot(baseline)` | ❌ 不支持 | CSS 选择器 | 基准图路径 |

### 4.2 断言结果映射

| 实际 vs 预期 | 结果 | 说明 |
|:------------:|------|------|
| 完全匹配 | **pass** | 实际值与预期值一致 |
| 不匹配 | **fail** | 实际值与预期值不一致 |
| 执行异常（超时/元素未找到） | **error** | 断言执行过程中发生异常 |
| 条件不满足跳过 | **skip** | 前置步骤失败导致断言无法执行 |

### 4.3 Selenium 断言限制

| 断言类型 | Selenium 支持度 | 说明 |
|----------|:---------------:|------|
| A1 页面可见 | ✅ | 通过 `element.is_displayed()` 实现 |
| A2 页面跳转 | ✅ | 通过 `driver.current_url` 比对实现 |
| A3 元素状态 | ✅ | 通过 `element.is_enabled()` 实现 |
| A4 内容匹配 | ✅ | 通过 `element.text` 比对实现 |
| A5 API 响应 | ❌ | Selenium 无 `page.route` 拦截能力，如出现则降级为 Playwright |
| A6 表单值 | ✅ | 通过 `element.get_attribute('value')` 实现 |
| A7 元素数量 | ✅ | 通过 `len(driver.find_elements())` 实现 |
| A8 截图比对 | ❌ | Selenium 无 `toHaveScreenshot` 能力，如出现则降级为 Playwright |

### 4.4 断言失败消息格式

```
断言 {type} 失败：目标 {target}，预期 {expected}，实际 {actual}
```

如 Step 定义了 `message` 字段，使用自定义消息替代默认格式。

---

## Phase 5: 截图采集

### 5.1 截图策略

| 截图策略 | 触发条件 | 优先级 | 说明 |
|----------|----------|:------:|------|
| **on-fail（默认）** | 断言结果为 fail/error | 最低 | 仅失败步骤截图 |
| **full** | 每个步骤执行后 | 中等 | 全步骤截图 |
| **标记步骤（capture: always）** | 用例中标记的步骤 | 最高 | 用户标记的关键步骤强制截图，不受全局策略限制 |

**优先级规则**：`always > full > on-fail`

- 全局 `capture: on-fail` + Step `capture: always` → 该 Step 截图
- 全局 `capture: full` → 所有 Step 截图
- 全局 `capture: on-fail` → 仅失败 Step 截图

### 5.2 文件命名规则

| 截图策略 | 文件命名格式 | 示例 |
|----------|-------------|------|
| on-fail | `ATR-{resultId}-S{stepIndex}-fail.png` | `ATR-20260714-001-S03-fail.png` |
| full | `ATR-{resultId}-S{stepIndex}-{status}.png` | `ATR-20260714-001-S05-pass.png` |
| always | `ATR-{resultId}-S{stepIndex}-marked.png` | `ATR-20260714-001-S02-marked.png` |

### 5.3 截图存储路径

所有截图保存到 `.asdm/workspace/auto-test/screenshots/`

### 5.4 Playwright 截图特性

- 支持 `page.screenshot({fullPage: true})` 全页截图
- 支持 `locator.screenshot()` 元素级截图
- 支持 tracing（完整操作序列录制），作为高级可选功能

### 5.5 Selenium 截图特性

- 仅支持 `driver.save_screenshot()` 全页截图
- 不支持元素级截图和 tracing

---

## Phase 6: 结果记录

### 6.1 AutoTestResult JSON 生成

每个用例执行完成后，生成一个 `AutoTestResult` JSON 文件：

```json
{
  "id": "ATR-20260714-001",
  "testCaseId": "ATC-20260714-001",
  "testCaseName": "user-login-test",
  "status": "pass",
  "totalSteps": 7,
  "passedSteps": 7,
  "failedSteps": 0,
  "skippedSteps": 0,
  "duration": 8500,
  "startTime": "2026-07-14T10:30:00+08:00",
  "endTime": "2026-07-14T10:30:08.500+08:00",
  "framework": "playwright",
  "stepResults": [
    {
      "stepIndex": 1,
      "action": "navigate",
      "target": "/login",
      "expected": "登录页面正常加载",
      "actual": "登录页面正常加载，表单元素可见",
      "status": "pass",
      "duration": 2000,
      "errorMessage": null,
      "screenshotPath": null
    },
    {
      "stepIndex": 2,
      "action": "assert",
      "target": ".auth-form",
      "expected": "visible",
      "actual": "visible",
      "status": "pass",
      "duration": 500,
      "errorMessage": null,
      "screenshotPath": null
    }
  ],
  "environment": {
    "browser": "chromium",
    "viewport": { "width": 1280, "height": 720 },
    "nodeVersion": "18.x",
    "os": "windows",
    "targetUrl": "http://localhost:3000"
  }
}
```

### 6.2 结果 ID 生成规则

- 格式：`ATR-{YYYYMMDD}-{NNN}`
- YYYYMMDD：执行日期
- NNN：当天三位序号，从已有结果文件的最大序号+1 开始
- 检查 `.asdm/workspace/auto-test/results/` 目录下已有文件，避免 ID 冲突

### 6.3 持久化规则

- 存储路径：`.asdm/workspace/auto-test/results/ATR-{YYYYMMDD}-{NNN}.json`
- 每个用例执行生成一个独立的 JSON 文件
- 文件编码：UTF-8
- 不覆盖已有结果文件（幂等性保证）

### 6.4 整体状态计算规则

| 规则 | 条件 | 结果 |
|------|------|------|
| 全通过 | 所有 stepResults.status 为 pass | **pass** |
| 有失败 | 有 stepResults.status 为 fail | **fail** |
| 有异常 | 有 stepResults.status 为 error | **error** |
| 全跳过 | 所有 stepResults.status 为 skip | **skip** |
| 混合失败+异常 | 有 fail 和 error | **fail**（fail 优先级高于 error） |

---

## Phase 7: 报告输出（简要摘要）

### 7.1 简要摘要格式

P2 阶段仅输出简要摘要，详细 HTML 报告在 P4 实现：

```markdown
### 🧪 自动化测试结果：{testCaseName}

| 步骤 | 操作 | 目标 | 预期结果 | 实际结果 | 状态 |
|:----:|------|------|---------|---------|:----:|
| 1 | {action} | {target} | {expected} | {actual} | ✅/❌/⚠️ |
| 2 | {action} | {target} | {expected} | {actual} | ✅/❌/⚠️ |
| ... | ... | ... | ... | ... | ... |

**用例状态**：✅ 通过 / ❌ 失败 / ⚠️ 异常 | **步骤**：{passedSteps}/{totalSteps} 通过 | **耗时**：{duration}s
**执行框架**：{framework} | **结果文件**：`.asdm/workspace/auto-test/results/ATR-{id}.json`
**失败原因**：{errorMessage}（仅失败时显示）
```

### 7.2 结构化输出

```json
{
  "phase": "auto-test-run",
  "status": "success",
  "result_id": "ATR-20260714-001",
  "test_case_name": "user-login-test",
  "test_case_status": "pass|fail|error|skip",
  "total_steps": 7,
  "passed_steps": 7,
  "failed_steps": 0,
  "duration_ms": 8500,
  "framework": "playwright",
  "result_path": ".asdm/workspace/auto-test/results/ATR-20260714-001.json",
  "screenshots": [],
  "timestamp": "ISO 8601 datetime"
}
```

---

## Selenium 辅框架适配专章

### S1. 定位与边界

Selenium 作为 Web Auto Tester 的辅框架，定位为：

- **主框架**：Playwright（优先支持、完整功能）
- **辅框架**：Selenium（兼容适配、基础功能）
- **降级策略**：Selenium 用例含 Playwright 专有特性时自动降级为 Playwright

**功能边界对比**：

| 能力维度 | Playwright（主） | Selenium（辅） |
|----------|:----------------:|:--------------:|
| 操作类型 | 全部 9 种 + upload + screenshot | 全部 9 种（基础操作） |
| 断言类型 | A1~A8（8种全覆盖） | A1~A4、A6、A7（6种） |
| 截图能力 | 全页 + 元素级 + tracing | 仅全页截图 |
| 选择器语法 | Playwright 选择器 + CSS | css= / id= / xpath= 前缀 |
| API 拦截 | page.route() 支持 | ❌ 不支持 |
| 视觉回归 | toHaveScreenshot 支持 | ❌ 不支持 |
| 隐式等待 | 自动等待机制 | 需手动 WebDriverWait |

### S2. Selenium 操作映射总表

| 操作类型 | Selenium WebDriver API | 选择器处理 | 说明 |
|----------|----------------------|------------|------|
| navigate | `driver.get(url)` | URL 拼接 metadata.targetUrl + target | 打开页面 |
| click | `driver.find_element(By.CSS_SELECTOR, sel).click()` | 去除 `css=` 前缀 → CSS_SELECTOR | 点击元素 |
| type | `driver.find_element(By.CSS_SELECTOR, sel).clear(); element.send_keys(value)` | 去除 `css=` 前缀 → CSS_SELECTOR | 清空后输入 |
| wait | `WebDriverWait(driver, timeout).until(EC.presence_of_element_located((By.CSS_SELECTOR, sel)))` | 去除 `css=` 前缀 → CSS_SELECTOR | 显式等待元素 |
| scroll | `driver.execute_script("window.scrollTo({x}, {y})")` | target → 滚动位置 | JavaScript 滚动 |
| hover | `ActionChains(driver).move_to_element(element).perform()` | 去除 `css=` 前缀 → 先定位元素 | 鼠标悬停 |
| select | `Select(driver.find_element(By.CSS_SELECTOR, sel)).select_by_value(value)` | 去除 `css=` 前缀 → CSS_SELECTOR | 下拉选择 |
| screenshot | `driver.save_screenshot(path)` | path → 截图保存路径 | 仅全页截图 |
| assert | 手动比对 + `driver.find_element` | 见 S3 断言适配 | 无内置 expect |

### S3. Selenium 断言适配

#### 支持的断言类型

| 断言类型 | Selenium 实现方式 | 说明 |
|----------|------------------|------|
| A1 页面可见 | `element.is_displayed()` → 比对 expected | 返回 True/False 映射 visible/hidden |
| A2 页面跳转 | `driver.current_url` → contains(expected) | 检查当前 URL 是否包含预期路径 |
| A3 元素状态 | `element.is_enabled()` / `element.is_displayed()` | 映射 enabled/disabled/visible/hidden |
| A4 内容匹配 | `element.text` → contains(expected) | 检查元素文本是否包含预期内容 |
| A6 表单值 | `element.get_attribute('value')` → 比对 expected | 获取输入框当前值 |
| A7 元素数量 | `len(driver.find_elements(By.CSS_SELECTOR, sel))` → 比对 expected | 计算匹配元素数量 |

#### 不支持的断言类型

| 断言类型 | 不支持原因 | 降级策略 |
|----------|-----------|----------|
| A5 API 响应 | Selenium 无 `page.route()` 拦截能力 | 降级为 Playwright + 提示 |
| A8 截图比对 | Selenium 无 `toHaveScreenshot` 视觉回归能力 | 降级为 Playwright + 提示 |

#### Selenium 断言执行模式

由于 Selenium 无内置 expect/assertion 机制，所有断言采用**手动比对模式**：

```python
# 等价逻辑（AI Agent 按此规则执行）
actual_value = get_actual_value(driver, assertion_type, target)
if actual_value matches expected_value:
    result = "pass"
else:
    result = "fail"
    message = f"断言 {type} 失败：目标 {target}，预期 {expected}，实际 {actual_value}"
```

### S4. Selenium 截图限制

| 截图能力 | Playwright | Selenium |
|----------|:----------:|:--------:|
| 全页截图 | ✅ page.screenshot({fullPage: true}) | ✅ driver.save_screenshot(path) |
| 元素级截图 | ✅ locator.screenshot() | ❌ 不支持 |
| 操作录制 tracing | ✅ page.context.tracing | ❌ 不支持 |
| 视觉回归基准图 | ✅ toHaveScreenshot(baseline) | ❌ 不支持 |

**Selenium 用例截图策略适配**：

| 用例 capture 策略 | Selenium 实际行为 |
|-------------------|------------------|
| on-fail（默认） | 失败步骤 → driver.save_screenshot() 全页截图 |
| full | 每步骤 → driver.save_screenshot() 全页截图 |
| always（步骤标记） | 标记步骤 → driver.save_screenshot() 全页截图 |

所有 Selenium 截图均为全页截图，截图命名规则与 Playwright 一致。

### S5. CSS 选择器前缀约定

Selenium 用例的选择器使用前缀约定来区分定位策略：

| 前缀 | By 定位方式 | 示例 | 转换规则 |
|------|-----------|------|----------|
| `css=` | By.CSS_SELECTOR | `css=.login-form .btn-primary` | 去除 `css=` → `.login-form .btn-primary` |
| `id=` | By.ID | `id=username` | 去除 `id=` → `username` |
| `xpath=` | By.XPATH | `xpath=//div[@class='form']` | 去除 `xpath=` → `//div[@class='form']` |
| 无前缀 | By.CSS_SELECTOR | `.auth-form .el-button` | 直接使用 CSS 选择器 |

**前缀处理逻辑**：

```python
# 等价逻辑（AI Agent 按此规则执行）
def resolve_selector(target):
    if target.startswith("css="):
        return (By.CSS_SELECTOR, target[4:])
    elif target.startswith("id="):
        return (By.ID, target[3:])
    elif target.startswith("xpath="):
        return (By.XPATH, target[6:])
    else:
        return (By.CSS_SELECTOR, target)  # 默认 CSS 选择器
```

### S6. 双框架执行选择流程

```
1. 读取用例顶层 framework 字段（默认 playwright）
2. framework=playwright → 使用 Playwright 引擎执行
3. framework=selenium:
   a. 检查用例中是否包含 A5/A8 断言
   b. 检查用例中是否包含 Playwright 专有操作（tracing/codegen）
   c. 若含专有特性 → 降级为 playwright + 提示
   d. 若不含 → 使用 Selenium 引擎执行
4. Step 级 frameworkOverride:
   a. Selenium 用例中某步骤需 Playwright 能力 → 临时切换为 Playwright
   b. 仅支持 selenium→playwright 降级方向
   c. 降级步骤独立执行，不影响其他 Selenium 步骤
5. 结果 JSON 中 framework 字段记录实际执行框架
```

### S7. 降级提示规范

```
⚠️ 框架降级提示：用例 {name} 指定 selenium 框架，但包含以下 Playwright 专有特性：
- 断言 A5 (API 响应拦截)
- 断言 A8 (截图比对)
已自动降级为 Playwright 执行引擎。建议修改用例以兼容 Selenium，或保持 Playwright 框架。
```

**Step 级降级提示**：

```
⚠️ 步骤级降级提示：用例 {name} Step {index} 指定 frameworkOverride=playwright，
已临时使用 Playwright 执行引擎完成该步骤。其余步骤仍使用 Selenium 引擎。
```

---

## 异常处理

| 异常场景 | 处理策略 | Step 状态 |
|----------|----------|-----------|
| 用例 YAML 语法错误 | 报错并终止执行，提示用户修正 YAML | — |
| Schema 校验失败 | 报错并终止执行，提示缺失或无效字段 | — |
| 目标系统不可访问 | 用例标记为 error，提示用户启动系统 | error |
| 步骤执行超时 | 步骤标记为 error，记录超时原因 | error |
| 页面元素未找到 | 步骤标记为 error，记录元素选择器 | error |
| 前置步骤失败 | 后续步骤标记为 skip，说明"前置步骤失败" | skip |
| 网络请求异常 | 步骤标记为 error，记录请求 URL 和状态码 | error |
| 断言失败 | 步骤标记为 fail，记录断言详情和实际值 | fail |
| Selenium 用例含 A5/A8 | 降级为 Playwright 执行，提示用户 | — |
| 存储目录不存在 | 自动创建 `.asdm/workspace/auto-test/results/` 目录 | — |

---

## 框架选择与降级策略

### 选择流程

```
1. 读取用例 framework 字段
2. 若 selenium → 检查是否含 A5/A8 断言
3. 若含 A5/A8 → 降级为 playwright + 提示
4. 若含 Playwright 专有操作 → 降级为 playwright + 提示
5. 否则 → 使用指定框架执行
```

### 降级提示格式

```
⚠️ 框架降级提示：用例 {name} 指定 selenium 框架，但包含以下 Playwright 专有特性：
- 断言 A5 (API 响应拦截)
- 断言 A8 (截图比对)
已自动降级为 Playwright 执行引擎。建议修改用例以兼容 Selenium，或保持 Playwright 框架。
```
