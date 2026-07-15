# ASDM Action: Auto Test Report

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456793",
  "name": "auto-test-report",
  "displayName": "生成测试报告",
  "description": "读取执行结果 JSON，生成 HTML 自定义报告（摘要卡片+用例列表+步骤详情+截图内嵌+统计图表），可选 Allure 格式导出，保存到 reports/ 目录",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.1"
  },
  "scenario": "auto-test-reporting"
}
```

## Purpose

本 action 是 Web Auto Tester 的报告生成命令。用户指定结果文件或结果目录，AI 读取执行结果 JSON，计算摘要数据，生成专业 HTML 自定义报告（包含摘要卡片、用例列表、步骤详情、截图展示、统计图表），可选导出 Allure 格式报告，并保存到 `.asdm/workspace/auto-test/reports/` 目录。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有生成的报告内容、注释和文档均使用中文。

## Context Injection

在生成报告前，AI Agent **必须**读取并理解以下规范文件：

### Required Context Files

1. **报告格式规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-report-spec.md`
   - Purpose: 了解 HTML 报告模板结构、CSS 样式规范、截图内嵌方式、Allure 导出流程

2. **执行引擎规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
   - Purpose: 了解 AutoTestResult 数据模型、结果 ID 规则、状态映射

3. **YAML DSL 规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
   - Purpose: 了解 AutoTestReport 数据模型、断言类型定义

4. **目标结果文件** (Required)
   - Path: 用户指定或 `.asdm/workspace/auto-test/results/*.json`
   - Purpose: 读取执行结果数据生成报告

## Steps

### Step 1: 读取执行结果数据

1. 根据用户输入参数 `result` 定位结果数据：
   - 指定单个 `ATR-*.json` 文件路径 → 直接加载该 JSON 文件
   - 指定 results/ 目录路径 → 加载目录下所有 `ATR-*.json` 文件
   - 未指定 → 加载 `.asdm/workspace/auto-test/results/` 下所有 `ATR-*.json` 文件
   - `result=latest` → 仅加载最近一次执行的结果文件（按 startTime 倒序取最新）
2. 解析 JSON 内容为 `AutoTestResult` 结构
3. 如结果目录为空 → 提示用户先执行 `/auto-test-run` 生成结果

### Step 2: 计算摘要数据

汇总所有结果 JSON 的核心数据：

1. **通过率计算**：
   - `passRate = (passedCases / totalCases) * 100`，保留两位小数
   - `passedCases`：status 为 pass 的用例数
   - `totalCases`：总用例数
   - `failedCases`：status 为 fail 的用例数
   - `errorCases`：status 为 error 的用例数
   - `skippedCases`：status 为 skip 的用例数

2. **步骤统计**：
   - `totalSteps`：所有用例步骤总数
   - `passedSteps`：所有用例通过步骤总数
   - `failedSteps`：所有用例失败步骤总数
   - `skippedSteps`：所有用例跳过步骤总数

3. **耗时统计**：
   - `totalDuration`：所有用例执行耗时总和（毫秒）
   - `avgDuration`：平均每用例耗时（毫秒）

4. **断言分布**：
   - 统计各断言类型（A1~A8）的使用次数和通过率

5. **框架统计**：
   - Playwright 用例数 / Selenium 用例数

### Step 3: 生成 HTML 报告结构

按 `auto-test-report-spec.md` §2 模板结构生成完整 HTML 报告：

#### 3.1 摘要卡片区域

生成 5 个摘要卡片，每个卡片包含：
- 渐变背景色（通过→绿色渐变，失败→红色渐变，总步骤→蓝色渐变，耗时→紫色渐变，通过率→根据值渐变）
- 大数字展示（通过率百分比、通过数、失败数、总步骤数、总耗时）
- 卡片标题（中文）
- 底部副标题（如"占总用例 XX%")

```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│  通过率   │ │   通过    │ │   失败    │ │  总步骤   │ │  总耗时   │
│  85.71%  │ │    6     │ │    1     │ │   35     │ │  45.2s   │
│ 占总 7/7  │ │ 占总86%  │ │ 占总14%  │ │ pass 30  │ │ avg 6.5s │
└──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
```

#### 3.2 用例列表区域

生成每个用例的概要行：
- 用例名称 + 状态色标签（✅ pass 绿色 / ❌ fail 红色 / ⚠️ error 橙色 / ⏭️ skip 灰色）
- 步骤通过数/总数
- 执行耗时
- 执行框架
- 标签列表

#### 3.3 步骤详情区域

为每个用例生成折叠面板式步骤详情：
- 面板标题：`{用例名称} — {状态标签} — {耗时}`
- 面板内容：步骤详情表格（步骤序号 / 操作类型 / 目标 / 预期 / 实际 / 状态）
- 失败步骤行红色高亮（`background: #fee; color: #c00;`）
- 错误步骤行橙色高亮（`background: #ffe8cc; color: #c60;`）
- 跳过步骤行灰色背景（`background: #f5f5f5; color: #999;`）

#### 3.4 截图展示区域

内嵌失败和标记步骤的截图：
- 从 `screenshots/` 目录读取相关截图文件
- 截图路径从 `stepResults[].screenshotPath` 字段获取
- 使用缩略图展示（`max-width: 200px`）+ 点击放大机制
- 失败截图优先展示，标记截图次要展示
- 截图不存在时显示占位文字："截图未采集"

#### 3.5 统计图表区域

生成 ASCII 风格统计图表：

**通过率分布图**：

```
通过率分布:
▓▓▓▓▓▓▓▓▓░░  85.71%  (6/7 用例通过)
  pass: 6  fail: 1  error: 0  skip: 0
```

**断言类型分布图**：

```
断言类型分布:
A1 页面可见  ▓▓▓▓▓░░░░░  5次 (通过率 100%)
A2 页面跳转  ▓▓▓░░░░░░░  3次 (通过率 100%)
A4 内容匹配  ▓▓▓▓░░░░░░  4次 (通过率 75%)
A7 元素数量  ▓░░░░░░░░░  1次 (通过率 100%)
```

### Step 4: 可选 Allure 导出

如用户指定 `format=allure`，执行 Allure 格式导出：

1. **检测 Allure 可用性**：
   - 执行 `allure --version` 检测 Allure CLI 是否安装
   - 未安装 → 提示用户安装并继续生成 HTML 报告

2. **转换 JSON → Allure 格式**（参照 `auto-test-report-spec.md` §4）：
   - 每个 AutoTestResult → 一个 Allure `*-result.json` 文件
   - 每个 Step → 一个 Allure test step
   - 断言结果 → Allure assertion
   - 截图 → Allure attachment
   - 状态映射：pass→passed, fail→failed, error→broken, skip→skipped

3. **生成 Allure 报告**：
   - 将 Allure 结果文件保存到 `.asdm/workspace/auto-test/reports/allure-results/`
   - 执行 `allure generate allure-results -o allure-report`
   - Allure HTML 报告保存到 `.asdm/workspace/auto-test/reports/allure-report/`

4. **Allure 不可用时的降级**：
   - 仍生成自定义 HTML 报告
   - 输出提示："Allure CLI 未安装，仅生成自定义 HTML 报告。安装 Allure：`npm install -g allure-commandline`"

### Step 5: 保存 HTML 报告

1. 组合完整的 HTML 文件（内嵌 CSS 样式 + 截图 base64 内嵌）
2. 生成报告文件名：`report-{YYYYMMDD}-{NNN}.html`
   - YYYYMMDD：生成日期
   - NNN：当天序号（从已有报告文件的最大序号+1）
3. 保存到 `.asdm/workspace/auto-test/reports/`
4. 输出报告摘要和文件路径

## Execution Guidelines

### 截图内嵌策略

- 截图文件存在 → 读取并转换为 base64 内嵌到 HTML（避免外部文件依赖）
- 截图文件不存在 → 显示占位文字"截图未采集"
- 大截图（>1MB）→ 仅显示缩略图，全尺寸图延迟加载
- 默认仅内嵌失败截图和标记步骤截图（`capture: always`）

### 报告样式一致性

- 所有样式内嵌到 HTML（不依赖外部 CSS 文件）
- 遵循 `auto-test-report-spec.md` §3 CSS 样式规范
- 颜色方案：绿色(#52c41a)→通过, 红色(#f5222d)→失败, 橙色(#fa8c16)→异常, 灰色(#999)→跳过
- 卡片渐变色：通过→#52c41a→#95de64, 失败→#f5222d→#ff7875, 总步骤→#1890ff→#69c0ff

### Allure 转换规则

| AutoTestResult 字段 | Allure 对应字段 |
|---------------------|----------------|
| testCaseName | name |
| status: pass | status: passed |
| status: fail | status: failed |
| status: error | status: broken |
| status: skip | status: skipped |
| duration | duration (毫秒) |
| startTime | start (时间戳毫秒) |
| stepResults | steps[] |
| tags | labels[] (tag 类型) |
| environment | parameters[] |

### 报告文件命名

- HTML 报告：`report-{YYYYMMDD}-{NNN}.html`
- Allure 结果目录：`allure-results/`
- Allure 报告目录：`allure-report/`
- 检查已有报告文件序号，避免命名冲突

### 无结果数据处理

- results/ 目录为空 → 提示用户先执行 `/auto-test-run`
- 单个结果文件 JSON 解析失败 → 跳过该文件并提示
- 所有截图文件不存在 → 报告中截图区域显示占位文字

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| result | string | ❌ | 结果文件路径、目录路径、latest（最近一次），默认加载全部 |
| format | string | ❌ | 报告格式：html（默认）/ allure / both |

### 命令示例

```
/auto-test-report
/auto-test-report result=latest
/auto-test-report result=.asdm/workspace/auto-test/results/
/auto-test-report result=ATR-20260714-001.json
/auto-test-report result=latest format=allure
/auto-test-report format=both
```

## Output

### 报告生成摘要

```markdown
### 📊 测试报告已生成

> 总用例 {totalCases} | ✅ 通过 {passedCases} ({passRate}%) | ❌ 失败 {failedCases} | ⚠️ 异常 {errorCases} | ⏭️ 跳过 {skippedCases}

**总步骤**：{totalSteps} ({passedSteps} 通过 / {failedSteps} 失败 / {skippedSteps} 跳过)
**总耗时**：{totalDuration}ms (平均 {avgDuration}ms/用例)
**执行框架**：Playwright {pwCases} / Selenium {selCases}

**报告路径**：`.asdm/workspace/auto-test/reports/{reportFileName}`
**Allure 报告**：`.asdm/workspace/auto-test/reports/allure-report/`（如选择了 Allure 格式）

**断言分布**：
- A1 页面可见：{count}次 (通过率 {rate}%)
- A2 页面跳转：{count}次 (通过率 {rate}%)
- A4 内容匹配：{count}次 (通过率 {rate}%)
- ...
```

### 结构化输出

```json
{
  "phase": "auto-test-report",
  "status": "success",
  "report_id": "report-20260714-001",
  "format": "html|allure|both",
  "total_cases": 7,
  "passed_cases": 6,
  "failed_cases": 1,
  "error_cases": 0,
  "skipped_cases": 0,
  "pass_rate": "85.71%",
  "total_steps": 35,
  "passed_steps": 30,
  "failed_steps": 5,
  "total_duration_ms": 45200,
  "avg_duration_ms": 6500,
  "framework_stats": {
    "playwright": 5,
    "selenium": 2
  },
  "assertion_stats": {
    "A1": {"count": 5, "pass_rate": "100%"},
    "A2": {"count": 3, "pass_rate": "100%"},
    "A4": {"count": 4, "pass_rate": "75%"},
    "A7": {"count": 1, "pass_rate": "100%"}
  },
  "report_path": ".asdm/workspace/auto-test/reports/report-20260714-001.html",
  "allure_path": ".asdm/workspace/auto-test/reports/allure-report/",
  "timestamp": "ISO 8601 datetime"
}
```

## Configuration

Refer to:
- [auto-test-report-spec.md](../spec/auto-test-report-spec.md) — HTML 报告模板结构、CSS 样式规范、截图内嵌、Allure 导出流程
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — AutoTestResult 数据模型、结果 ID 规则、状态映射
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — AutoTestReport 数据模型、断言类型 A1~A8 定义
