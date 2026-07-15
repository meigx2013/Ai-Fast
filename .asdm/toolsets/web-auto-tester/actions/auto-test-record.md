# ASDM Action: Auto Test Record

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456792",
  "name": "auto-test-record",
  "displayName": "录制生成测试用例",
  "description": "通过 Playwright Codegen 录制浏览器操作，自动转换为 YAML DSL 测试用例，为导航步骤添加 A1 页面可见断言，输出可编辑的 YAML 用例文件",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.1"
  },
  "scenario": "auto-test-recording"
}
```

## Purpose

本 action 是 Web Auto Tester 的录制生成命令。用户指定目标 URL，AI 启动 Playwright Codegen 录制器，用户在浏览器中操作，Codegen 实时录制操作序列，录制结束后提取操作并转换为 YAML DSL 用例格式，自动为导航步骤添加页面可见断言（A1），输出可编辑的 YAML 用例文件。用例标记 `source: record` 以追溯来源。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有生成的文件、注释和文档均使用中文。

## Context Injection

在生成用例前，AI Agent **必须**读取并理解以下规范文件：

### Required Context Files

1. **YAML DSL 规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
   - Purpose: 了解用例格式定义、Schema 校验规则、操作类型映射、断言类型、数据模型

2. **执行引擎规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
   - Purpose: 了解操作映射（9 种操作类型 API 对应）、断言判定规则、选择器约定

## Steps

### Step 1: 启动 Playwright Codegen 录制器

1. 检查 Playwright 是否可用：
   - 执行 `npx playwright --version` 确认 Playwright 已安装
   - 未安装 → 提示用户执行 `npx playwright install` 安装

2. 构建并启动 Codegen 命令：

   ```
   npx playwright codegen {url}
   ```

   参数映射：
   - `{url}` → 用户输入的 `url` 参数（必填）
   - `--browser {browser}` → 用户输入的 `browser` 参数（默认 chromium）
   - 可选参数：
     - `--viewport-size=1280,720` → 固定视口尺寸
     - `--lang=zh-CN` → 设置语言
     - `--color-scheme=light` → 设置色彩方案

3. Codegen 启动后输出提示信息：

```markdown
### 🎥 Playwright Codegen 录制器已启动

> 目标 URL: {url} | 浏览器: {browser} | 视口: 1280×720

**操作指引**：
1. 在打开的浏览器窗口中执行需要录制的操作
2. Codegen 窗口会实时显示录制的代码
3. 操作完成后关闭浏览器窗口结束录制
4. 录制的操作将自动转换为 YAML DSL 测试用例

**提示**：
- 尽量使用稳定元素进行操作（避免随机定位）
- 操作顺序即测试步骤顺序
- 关闭浏览器后 AI 将自动提取录制结果
```

### Step 2: 用户操作与实时录制

1. Codegen 启动后，用户在浏览器窗口中操作：
   - 页面导航（打开新页面）
   - 点击元素（按钮/链接/菜单）
   - 输入文本（表单字段）
   - 选择下拉选项
   - 等待元素出现
   - 其他浏览器操作

2. Codegen 实时录制用户的操作序列，生成 Playwright TypeScript/JavaScript 代码

3. 用户关闭浏览器窗口 → 录制结束

### Step 3: 提取操作序列

录制结束后，从 Codegen 生成的代码中提取操作序列：

#### 3.1 Codegen 代码解析规则

从 Playwright Codegen 生成的代码中提取以下操作类型：

| Codegen 代码模式 | 提取操作 | target | value |
|-----------------|---------|--------|-------|
| `page.goto('url')` | navigate | URL路径 | — |
| `page.click('selector')` | click | CSS选择器 | — |
| `page.fill('selector', 'value')` | type | CSS选择器 | 输入值 |
| `page.type('selector', 'value')` | type | CSS选择器 | 输入值 |
| `page.selectOption('selector', 'value')` | select | CSS选择器 | 选项值 |
| `page.hover('selector')` | hover | CSS选择器 | — |
| `page.waitForSelector('selector')` | wait | CSS选择器 | — |
| `page.waitForTimeout(ms)` | wait | `timeout:{ms}ms` | — |
| `page.setViewportSize(...)` | — | 忽略（配置操作） | — |
| `page.screenshot(...)` | screenshot | CSS选择器 | — |
| `locator.click()` | click | locator字符串 | — |
| `locator.fill('value')` | type | locator字符串 | 输入值 |

#### 3.2 选择器清洗策略

- 去除 Playwright 内部选择器前缀（如 `internal:...`）
- 保留标准 CSS 选择器：`.class`、`#id`、`[attr="val"]`
- 保留文本选择器：`text=XXX`
- 保留 data-testid 选择器：`[data-testid="XXX"]`
- 保留组合选择器：`.parent .child`
- 不稳定选择器标记：nth-child、动态 ID → 在审核提示中标记

#### 3.3 操作序列结构化

将提取的操作序列转换为结构化数据：

```json
{
  "operations": [
    {"order": 1, "action": "navigate", "target": "/login", "value": null},
    {"order": 2, "action": "type", "target": "[name=\"username\"]", "value": "testuser"},
    {"order": 3, "action": "type", "target": "[name=\"password\"]", "value": "password123"},
    {"order": 4, "action": "click", "target": ".btn-primary", "value": null},
    {"order": 5, "action": "navigate", "target": "/home", "value": null}
  ]
}
```

### Step 4: 转换为 YAML DSL Step 格式

将操作序列转换为 YAML DSL Step 格式，按操作类型映射：

#### 4.1 操作映射规则

参照 `auto-test-dsl-spec.md` §4 操作类型映射表：

```yaml
steps:
  - action: navigate
    target: /login
  - action: type
    target: [name="username"]
    value: testuser
  - action: type
    target: [name="password"]
    value: password123
  - action: click
    target: .btn-primary
  - action: wait
    target: .header-user
    timeout: 5
```

#### 4.2 URL 处理规则

- `page.goto('http://localhost:3000/login')` → `target: /login`（剥离基础 URL，仅保留路径）
- `page.goto('http://localhost:3000')` → `target: /`（首页路径）
- 基础 URL 存入 `metadata.targetUrl`

#### 4.3 Stage 划分策略

按导航步骤划分 Stage：

- 每个 `navigate` 操作 → 新的 Stage 开始
- 第一个 Stage：从首次导航到下一次导航前的所有操作
- 后续 Stage：从后续导航到下一个导航前的所有操作
- 最后的导航步骤之后的操作 → 最后一个 Stage

示例划分：

```
navigate /login → [Stage 1: 登录页面访问] 开始
  type [name="username"] testuser → 属于 Stage 1
  type [name="password"] password123 → 属于 Stage 1
  click .btn-primary → 属于 Stage 1
navigate /home → [Stage 2: 首页验证] 开始
  wait .header-user → 属于 Stage 2
```

Stage 命名策略：
- 首次导航 → "页面访问"或根据 URL 推断（如 `/login` → "登录页面访问"）
- 后续导航 → 根据目标 URL 推断（如 `/home` → "首页验证"、`/products` → "商品页面"）

#### 4.4 等待操作补充

- 在 `click` 操作（提交类按钮）后自动补充 `wait` 步骤
- wait 目标：推断下一个页面的关键元素
- wait timeout：默认 5 秒

### Step 5: 自动添加断言

为导航步骤自动添加 A1 页面可见断言：

#### 5.1 自动断言规则

| 触发条件 | 添加断言 | 说明 |
|----------|---------|------|
| 每个 navigate 步骤之后 | A1 页面可见 | 验证目标页面核心元素可见 |
| 首次 navigate 之后 | A1 + A2（可选） | 验证页面可见 + URL 路径 |
| 录制包含表单操作 | A6 表单值（可选） | 验证输入框当前值 |

#### 5.2 A1 断言推断策略

对每个导航目标页面推断核心可见元素：

| 导航目标 | 推断 A1 target | 说明 |
|----------|---------------|------|
| `/login` | `.auth-form` 或 `.login-form` | 登录表单可见 |
| `/home` 或 `/` | `.header` 或 `.home-content` | 首页内容可见 |
| `/admin` 或 `/dashboard` | `.sidebar` 或 `.dashboard` | 管理后台可见 |
| `/products` 或 `/list` | `.list-content` | 列表内容可见 |
| `/detail` 或 `/edit` | `.detail-form` 或 `.edit-form` | 详情/编辑表单可见 |
| 其他未知路径 | `.page-content` 或 `body` | 通用页面内容可见 |

#### 5.3 断言示例

```yaml
- action: navigate
  target: /login
- action: assert
  assertions:
    - type: A1
      target: .auth-form
      expected: visible
      message: 登录页面表单应可见
```

### Step 6: 输出 YAML 文件与审核提示

1. 设置用例顶层字段：
   - `name`：基于 URL 和操作推断（如 `recorded-login-test`）
   - `description`：描述录制场景（中文）
   - `framework`：固定为 `playwright`（Codegen 仅支持 Playwright）
   - `capture`：默认 `on-fail`
   - `tags`：`[recorded, {页面模块}]`
   - `source`：固定为 `record`
   - `metadata`：
     - `targetUrl`：从录制的首个 navigate URL 提取基础 URL
     - `timeout`：默认 30
     - `browser`：使用 `browser` 参数值（默认 chromium）

2. 保存 YAML 文件：
   - 输出目录：`.asdm/workspace/auto-test/cases/`
   - 文件命名：`{name}.yaml`
   - 文件编码：UTF-8

3. 输出录制摘要：

```markdown
### 🎥 录制用例生成完成

> 录制了 {totalOperations} 个操作 | 自动生成 {totalStages} 个 Stage | 自动添加 {totalAssertions} 个 A1 断言

| Stage | 名称 | 步骤数 | 自动断言 |
|:-----:|------|:------:|:--------:|
| 1 | 登录页面访问 | 4 | A1 (.auth-form visible) |
| 2 | 首页验证 | 2 | A1 (.header visible) |

**⚠️ 审核提示**：
- 录制选择器可能不稳定，请验证并优化（建议使用 [data-testid] 选择器）
- 已自动为导航步骤添加 A1 页面可见断言，请补充业务断言（A2/A3/A4 等）
- 建议为关键步骤添加 `capture: always` 截图标记
- 建议执行 `/auto-test-run` 验证用例可执行性
- 录制仅支持 Playwright 框架，如需 Selenium 版本请手动修改选择器格式

**文件路径**：`.asdm/workspace/auto-test/cases/{name}.yaml`
```

4. 结构化输出：

```json
{
  "phase": "auto-test-record",
  "status": "success",
  "url": "http://localhost:3000",
  "browser": "chromium",
  "total_operations": 5,
  "total_stages": 2,
  "total_assertions": 2,
  "auto_assertions": ["A1 (.auth-form visible)", "A1 (.header visible)"],
  "case_name": "recorded-login-test",
  "file_path": ".asdm/workspace/auto-test/cases/recorded-login-test.yaml",
  "unstable_selectors": [],
  "timestamp": "ISO 8601 datetime"
}
```

## Execution Guidelines

### Codegen 启动失败处理

- Playwright 未安装 → 提示 `npx playwright install` 后重试
- 指定 browser 不支持 → 降级为 chromium 并提示
- URL 不可访问 → 提示用户确认目标系统是否启动

### 录制操作过滤

- 忽略 Codegen 内部配置操作（setViewportSize、setBackgroundColor 等）
- 忽略纯视觉操作（如仅改变字体大小等不影响功能的操作）
- 保留所有功能性交互操作（click、type、select、navigate）

### 选择器稳定性评估

录制结束后评估选择器稳定性：

| 选择器类型 | 稳定性 | 建议 |
|-----------|:------:|------|
| `[data-testid="XXX"]` | ✅ 高 | 最佳选择器 |
| `#unique-id` | ✅ 高 | 可接受 |
| `.class-name` | ⚠️ 中 | 可能变化 |
| `.parent .child` | ⚠️ 中 | 可能变化 |
| `text=XXX` | ⚠️ 中 | 文本可能变化 |
| `:nth-child(N)` | ❌ 低 | 建议替换 |
| 动态 ID（随机值） | ❌ 低 | 建议替换 |

- 不稳定选择器在审核提示中标记并建议替换
- 建议用户提供 `data-testid` 属性映射以优化选择器

### 空录制处理

- 如用户仅打开页面未操作 → 生成仅含 navigate + A1 断言的最小用例
- 提示用户：`"录制操作序列为空，已生成最小用例（仅页面访问+可见断言）。建议重新录制并执行更多操作。"`

### 用例命名规范

- 录制用例名称格式：`recorded-{页面模块}-{简短描述}`
- 基于首个 navigate URL 推断页面模块：
  - `/login` → `login`
  - `/home` → `home`
  - `/admin/dashboard` → `admin-dashboard`
  - `/products/search` → `product-search`
- 示例：`recorded-login-test`、`recorded-home-navigation`

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| url | string | ✅ | 目标 URL（如 http://localhost:3000） |
| framework | string | ❌ | 框架偏好，默认 playwright（录制仅支持 Playwright） |
| browser | string | ❌ | 浏览器类型，默认 chromium |

### 命令示例

```
/auto-test-record url=http://localhost:3000
/auto-test-record url=http://localhost:3000 browser=chromium
/auto-test-record url=https://example.com/login
/auto-test-record url=http://localhost:3001/admin
```

## Output

### YAML 用例文件示例

```yaml
name: recorded-login-test
description: 通过 Playwright Codegen 录制的登录流程测试用例
framework: playwright
capture: on-fail
tags: [recorded, auth]
source: record
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
            message: 登录页面表单应可见
      - action: type
        target: [name="username"]
        value: testuser
      - action: type
        target: [name="password"]
        value: password123
      - action: click
        target: .btn-primary
  - name: 首页验证
    steps:
      - action: wait
        target: .header-user
        timeout: 5
      - action: assert
        assertions:
          - type: A1
            target: .header
            expected: visible
            message: 首页头部应可见
```

### 最小录制示例（仅页面访问）

```yaml
name: recorded-home-visit
description: 通过 Playwright Codegen 录制的首页访问测试用例（最小录制）
framework: playwright
capture: on-fail
tags: [recorded, home]
source: record
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
  browser: chromium
stages:
  - name: 首页访问
    steps:
      - action: navigate
        target: /
      - action: assert
        assertions:
          - type: A1
            target: .page-content
            expected: visible
            message: 首页内容应可见
```

## Configuration

Refer to:
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — YAML DSL 用例格式定义、Schema 校验、操作类型映射、断言类型 A1~A8
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 7 阶段执行规范、操作映射、断言判定、选择器约定
