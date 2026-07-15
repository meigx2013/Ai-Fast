# Web Auto Tester 报告格式规范

**Document Version**: 1.0
**Last Updated**: 2026-07-14
**Toolset ID**: web-auto-tester

## Overview

本文档定义 Web Auto Tester 报告生成引擎的完整规范，包括 HTML 自定义报告模板结构、CSS 样式规范、截图内嵌方式、Allure 导出流程。所有报告功能由 AI Agent 按本规范生成，无实际编译代码。

---

## 1. HTML 报告模板结构

### 1.1 报告整体结构

HTML 报告由以下五个区域组成，自上而下排列：

```
┌─────────────────────────────────────────────────────────────────────┐
│  [1. 报告标题与时间]                                                 │
│  报告标题 + 生成时间 + 用例统计摘要                                   │
├─────────────────────────────────────────────────────────────────────┤
│  [2. 摘要卡片区域]                                                   │
│  5个渐变卡片: 通过率 / 通过数 / 失败数 / 总步骤 / 总耗时              │
├─────────────────────────────────────────────────────────────────────┤
│  [3. 用例列表区域]                                                   │
│  每个用例: 名称 + 状态标签 + 步骤数 + 耗时 + 框架 + 标签             │
├─────────────────────────────────────────────────────────────────────┤
│  [4. 步骤详情区域（折叠面板）]                                        │
│  每个用例展开: 步骤表格 + 截图展示 + 断言详情                        │
├─────────────────────────────────────────────────────────────────────┤
│  [5. 统计图表区域]                                                   │
│  通过率分布图 + 断言类型分布图                                        │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 报告标题区域

```html
<div class="report-header">
  <h1>Web Auto Tester 测试报告</h1>
  <div class="report-meta">
    <span>生成时间：{generatedAt}</span>
    <span>总用例：{totalCases}</span>
    <span>通过率：{passRate}%</span>
  </div>
</div>
```

### 1.3 摘要卡片区域

5 个卡片水平排列，每个卡片包含：
- 渐变背景色
- 大数字（核心统计值）
- 卡片标题
- 底部副标题

| 卡片 | 标题 | 大数字 | 副标题 | 渐变背景 |
|:----:|------|--------|--------|----------|
| 1 | 通过率 | `{passRate}%` | 占总 `{passedCases}/{totalCases}` | 绿色渐变 #52c41a→#95de64 |
| 2 | 通过用例 | `{passedCases}` | 占总 `{passRate}%` | 绿色渐变 #52c41a→#95de64 |
| 3 | 失败用例 | `{failedCases + errorCases}` | fail: `{failedCases}` / error: `{errorCases}` | 红色渐变 #f5222d→#ff7875 |
| 4 | 总步骤 | `{totalSteps}` | pass: `{passedSteps}` / fail: `{failedSteps}` | 蓝色渐变 #1890ff→#69c0ff |
| 5 | 总耗时 | `{totalDurationFormatted}` | avg: `{avgDurationFormatted}` | 紫色渐变 #722ed1→#b37feb |

### 1.4 用例列表区域

每个用例一行，包含以下信息：

| 列 | 内容 | 格式 |
|----|------|------|
| # | 序号 | 数字 |
| 用例名称 | testCaseName | 字符串 |
| 状态 | status | ✅/❌/⚠️/⏭️ 状态色标签 |
| 步骤通过 | passedSteps/totalSteps | 数字比例 |
| 耗时 | duration | 格式化时间 |
| 框架 | framework | playwright/selenium |
| 标签 | tags | 标签列表 |

**状态色标签样式**：

| 状态 | 标签 | 颜色 |
|------|------|------|
| pass | ✅ 通过 | 绿色背景 #f6ffed，绿色文字 #52c41a，绿色边框 #b7eb8f |
| fail | ❌ 失败 | 红色背景 #fff2f0，红色文字 #f5222d，红色边框 #ffa39e |
| error | ⚠️ 异常 | 橙色背景 #fff7e6，橙色文字 #fa8c16，橙色边框 #ffd591 |
| skip | ⏭️ 跳过 | 灰色背景 #f5f5f5，灰色文字 #999，灰色边框 #d9d9d9 |

### 1.5 步骤详情区域

折叠面板式展示，每个用例一个面板：

**面板标题**：
```
{testCaseName} — {状态标签} — 步骤 {passedSteps}/{totalSteps} — 耗时 {duration}
```

**面板内容 — 步骤表格**：

| 列 | 内容 | 格式 |
|----|------|------|
| # | stepIndex | 数字 |
| 操作 | action | 操作类型名称 |
| 目标 | target | 选择器或 URL |
| 预期 | expected | 预期结果 |
| 实际 | actual | 实际观察值 |
| 状态 | status | ✅/❌/⚠️/⏭️ |
| 耗时 | duration | 步骤耗时 |
| 错误信息 | errorMessage | 仅失败/异常步骤显示 |

**步骤行样式规则**：

| 步骤状态 | 行样式 |
|----------|--------|
| pass | 默认样式（白色背景） |
| fail | 红色高亮：`background: #fee; color: #c00; border-left: 3px solid #f5222d;` |
| error | 橙色高亮：`background: #ffe8cc; color: #c60; border-left: 3px solid #fa8c16;` |
| skip | 灰色背景：`background: #f5f5f5; color: #999;` |

### 1.6 截图展示区域

每个步骤详情面板下方展示关联截图：

**截图展示规则**：

| 截图来源 | 展示优先级 | 展示方式 |
|----------|:----------:|----------|
| 失败步骤截图（on-fail） | 最高 | 缩略图 + 点击放大 |
| 标记步骤截图（always） | 中 | 缩略图 + 点击放大 |
| 全步骤截图（full） | 低 | 缩略图列表 + 点击放大 |

**截图展示格式**：

```html
<div class="screenshot-section">
  <h4>步骤 {stepIndex} 截图</h4>
  <div class="screenshot-container">
    <img class="screenshot-thumb" 
         src="data:image/png;base64,{base64Data}"
         alt="步骤 {stepIndex} 截图"
         onclick="openFullscreen(this)"
         style="max-width: 200px; cursor: pointer;" />
    <div class="screenshot-meta">
      策略: {strategy} | 文件: {originalPath}
    </div>
  </div>
</div>
```

**截图不存在时**：
```html
<div class="screenshot-placeholder">
  截图未采集（策略: {strategy}）
</div>
```

### 1.7 统计图表区域

使用 HTML + 内嵌 CSS 绘制 ASCII 风格图表：

#### 通过率分布图

```
通过率分布:
██████████░░░░░░░░░░░░  85.71%  (6/7 用例通过)
  ✅ 通过: 6  ❌ 失败: 1  ⚠️ 异常: 0  ⏭️ 跳过: 0
```

**HTML 实现**：使用 `<div>` + 内联宽度百分比构建条形图

```html
<div class="chart-bar">
  <div class="bar-pass" style="width: {passRate}%;">{passRate}%</div>
  <div class="bar-fail" style="width: {failRate}%;">{failRate}%</div>
</div>
<div class="chart-legend">
  ✅ 通过: {passedCases} | ❌ 失败: {failedCases} | ⚠️ 异常: {errorCases} | ⏭️ 跳过: {skippedCases}
</div>
```

#### 断言类型分布图

每个断言类型一行水平条形图：

```
断言类型分布:
A1 页面可见  ████████████░░░░░░  5次 (通过率 100%)
A2 页面跳转  ███████░░░░░░░░░░░  3次 (通过率 100%)
A4 内容匹配  ██████████░░░░░░░░  4次 (通过率 75%)
A7 元素数量  ██░░░░░░░░░░░░░░░░  1次 (通过率 100%)
```

**HTML 实现**：

```html
<div class="assertion-chart">
  <div class="assertion-row">
    <span class="assertion-label">A1 页面可见</span>
    <div class="assertion-bar" style="width: {percentage}%;">
      <span class="bar-text">{count}次 (通过率 {rate}%)</span>
    </div>
  </div>
  <!-- ... each assertion type row ... -->
</div>
```

---

## 2. CSS 样式规范

### 2.1 全局样式

```css
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  line-height: 1.6;
  color: #333;
  background: #f0f2f5;
  margin: 0;
  padding: 20px;
}

.report-container {
  max-width: 1200px;
  margin: 0 auto;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  padding: 24px;
}
```

### 2.2 卡片渐变样式

```css
.summary-card {
  flex: 1;
  min-width: 160px;
  padding: 16px 20px;
  border-radius: 8px;
  color: #fff;
  text-align: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.summary-card .card-value {
  font-size: 36px;
  font-weight: 700;
  line-height: 1.2;
}

.summary-card .card-title {
  font-size: 14px;
  opacity: 0.9;
  margin-bottom: 4px;
}

.summary-card .card-sub {
  font-size: 12px;
  opacity: 0.8;
}

/* 渐变色定义 */
.card-pass { background: linear-gradient(135deg, #52c41a, #95de64); }
.card-fail { background: linear-gradient(135deg, #f5222d, #ff7875); }
.card-step { background: linear-gradient(135deg, #1890ff, #69c0ff); }
.card-time { background: linear-gradient(135deg, #722ed1, #b37feb); }
.card-rate { 
  background: linear-gradient(135deg, #52c41a, #95de64); 
  /* 通过率 < 50% 时使用红色渐变 */
  /* background: linear-gradient(135deg, #f5222d, #ff7875); */
}
```

### 2.3 状态色标签样式

```css
.status-tag {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}

.status-pass { background: #f6ffed; color: #52c41a; border: 1px solid #b7eb8f; }
.status-fail { background: #fff2f0; color: #f5222d; border: 1px solid #ffa39e; }
.status-error { background: #fff7e6; color: #fa8c16; border: 1px solid #ffd591; }
.status-skip { background: #f5f5f5; color: #999; border: 1px solid #d9d9d9; }
```

### 2.4 折叠面板样式

```css
.detail-panel {
  border: 1px solid #e8e8e8;
  border-radius: 6px;
  margin-bottom: 12px;
  overflow: hidden;
}

.detail-panel-header {
  background: #fafafa;
  padding: 12px 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: 600;
}

.detail-panel-header:hover {
  background: #f0f0f0;
}

.detail-panel-body {
  padding: 16px;
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.3s ease;
}

.detail-panel.expanded .detail-panel-body {
  max-height: none;
}
```

### 2.5 步骤行高亮样式

```css
.step-row-pass { }
.step-row-fail { background: #fee; color: #c00; border-left: 3px solid #f5222d; }
.step-row-error { background: #ffe8cc; color: #c60; border-left: 3px solid #fa8c16; }
.step-row-skip { background: #f5f5f5; color: #999; }
```

### 2.6 截图样式

```css
.screenshot-section {
  margin-top: 8px;
  padding: 8px 12px;
  background: #fafafa;
  border-radius: 4px;
}

.screenshot-thumb {
  max-width: 200px;
  max-height: 150px;
  cursor: pointer;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  transition: transform 0.2s;
}

.screenshot-thumb:hover {
  transform: scale(1.05);
}

.screenshot-placeholder {
  padding: 8px 12px;
  background: #f5f5f5;
  color: #999;
  border-radius: 4px;
  font-style: italic;
}

/* 全屏查看弹窗 */
.fullscreen-overlay {
  display: none;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.85);
  z-index: 9999;
  text-align: center;
  cursor: pointer;
}

.fullscreen-overlay img {
  max-width: 95%;
  max-height: 95%;
  margin: auto;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}
```

### 2.7 图表样式

```css
.chart-bar {
  height: 24px;
  background: #f0f0f0;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 4px;
}

.bar-pass { 
  height: 100%; 
  background: #52c41a; 
  color: #fff; 
  float: left; 
  text-align: center;
  font-size: 12px;
  line-height: 24px;
}

.bar-fail { 
  height: 100%; 
  background: #f5222d; 
  color: #fff; 
  float: left; 
  text-align: center;
  font-size: 12px;
  line-height: 24px;
}

.assertion-chart {
  margin: 16px 0;
}

.assertion-row {
  display: flex;
  align-items: center;
  margin-bottom: 6px;
}

.assertion-label {
  width: 120px;
  font-size: 13px;
  text-align: right;
  padding-right: 8px;
}

.assertion-bar {
  height: 20px;
  background: linear-gradient(90deg, #1890ff, #69c0ff);
  border-radius: 4px;
  min-width: 20px;
  position: relative;
}

.bar-text {
  font-size: 11px;
  color: #333;
  padding-left: 8px;
}
```

---

## 3. 截图内嵌方式

### 3.1 Base64 内嵌

所有截图以 base64 格式内嵌到 HTML 中，避免外部文件依赖：

```
<img src="data:image/png;base64,{base64EncodedImageData}" />
```

**base64 转换流程**：

1. 从 `.asdm/workspace/auto-test/screenshots/` 读取截图 PNG 文件
2. 将 PNG 二进制数据编码为 base64 字符串
3. 构建 `data:image/png;base64,{data}` 格式的 src 属性
4. 内嵌到 HTML 的 `<img>` 元素

### 3.2 缩略图 + 点击放大

- 默认展示缩略图：`max-width: 200px; max-height: 150px`
- 点击缩略图 → 全屏展示弹窗
- 全屏弹窗使用 JavaScript 控制：

```javascript
function openFullscreen(img) {
  var overlay = document.getElementById('fullscreen-overlay');
  overlay.innerHTML = '<img src="' + img.src + '" />';
  overlay.style.display = 'block';
}

function closeFullscreen() {
  document.getElementById('fullscreen-overlay').style.display = 'none';
}
```

### 3.3 截图体积优化

| 截图大小 | 处理策略 |
|----------|----------|
| < 500KB | 直接 base64 内嵌 |
| 500KB ~ 1MB | base64 内嵌，仅缩略图展示 |
| > 1MB | 仅缩略图 base64 内嵌，全尺寸图标注原始路径 |

### 3.4 截图关联规则

- 每个步骤的截图路径从 `stepResults[].screenshotPath` 字段获取
- 截图路径格式：`ATR-{resultId}-S{stepIndex}-{strategy}.png`
- 截图文件存储在 `.asdm/workspace/auto-test/screenshots/`
- HTML 报告中缩略图与步骤序号对应

---

## 4. Allure 导出流程规范

### 4.1 Allure 结果格式转换

将 AutoTestResult JSON 转换为 Allure 结果格式：

#### 状态映射

| AutoTestResult status | Allure status |
|:---------------------:|:-------------:|
| pass | passed |
| fail | failed |
| error | broken |
| skip | skipped |

#### 字段映射

| AutoTestResult 字段 | Allure 结果文件字段 | 转换规则 |
|---------------------|---------------------|----------|
| testCaseName | name | 直接映射 |
| status | status | 按状态映射表 |
| duration | duration | 直接映射（毫秒） |
| startTime | start | ISO 8601 → Unix 时间戳毫秒 |
| tags | labels | 每个 tag → `{name: "tag", value: tagValue}` |
| framework | labels | `{name: "framework", value: frameworkValue}` |
| environment | parameters | 每个 env 字段 → `{name: key, value: value}` |
| stepResults | steps | 每个 StepResult → Allure step |

#### Allure 结果文件格式

```json
{
  "name": "{testCaseName}",
  "status": "{mappedStatus}",
  "stage": "finished",
  "start": {startTimeTimestampMs},
  "duration": {durationMs},
  "labels": [
    {"name": "tag", "value": "{tag1}"},
    {"name": "tag", "value": "{tag2}"},
    {"name": "framework", "value": "{framework}"},
    {"name": "suite", "value": "web-auto-tester"}
  ],
  "parameters": [
    {"name": "browser", "value": "{browser}"},
    {"name": "targetUrl", "value": "{targetUrl}"},
    {"name": "viewport", "value": "{viewport}"},
    {"name": "os", "value": "{os}"}
  ],
  "steps": [
    {
      "name": "Step {stepIndex}: {action} {target}",
      "status": "{mappedStepStatus}",
      "start": {stepStartTimeMs},
      "duration": {stepDurationMs},
      "attachments": []
    }
  ]
}
```

#### 截图转换为 Allure Attachment

每个有截图的步骤生成 Allure attachment：

```json
{
  "name": "screenshot-step-{stepIndex}",
  "type": "image/png",
  "source": "{screenshotFileName}"
}
```

- 截图文件复制到 `allure-results/` 目录
- attachment source 指向复制的截图文件名

### 4.2 Allure 命令行调用

#### Allure CLI 检测

```
allure --version
```

- 返回版本号 → Allure 可用
- 命令不存在 → Allure 不可用，降级为仅 HTML 报告
- 安装提示：`npm install -g allure-commandline`

#### Allure 报告生成

```
allure generate {allure-results-dir} -o {allure-report-dir} --clean
```

参数：
- `{allure-results-dir}` → `.asdm/workspace/auto-test/reports/allure-results/`
- `{allure-report-dir}` → `.asdm/workspace/auto-test/reports/allure-report/`
- `--clean` → 清理旧的报告目录

### 4.3 Allure 不可用时的降级策略

| 场景 | 处理 |
|------|------|
| Allure CLI 未安装 | 仅生成自定义 HTML 报告 + 提示安装命令 |
| Allure generate 失败 | 仅生成自定义 HTML 报告 + 提示错误信息 |
| format=allure 但 Allure 不可用 | 降级为 format=html + 提示 |
| format=both 但 Allure 不可用 | 仅生成 HTML 报告 + 提示 Allure 部分 skipped |

---

## 5. 报告文件命名与存储

### 5.1 HTML 报告命名

- 格式：`report-{YYYYMMDD}-{NNN}.html`
- YYYYMMDD：生成日期
- NNN：当天三位序号（从已有报告文件的最大序号+1）
- 检查 `.asdm/workspace/auto-test/reports/` 已有文件，避免冲突

### 5.2 存储路径

| 文件类型 | 存储路径 |
|----------|----------|
| HTML 自定义报告 | `.asdm/workspace/auto-test/reports/report-{date}-{seq}.html` |
| Allure 结果文件 | `.asdm/workspace/auto-test/reports/allure-results/` |
| Allure HTML 报告 | `.asdm/workspace/auto-test/reports/allure-report/` |

### 5.3 报告自包含性

- HTML 报告内嵌所有 CSS 样式（不依赖外部 CSS 文件）
- HTML 报告内嵌截图 base64 数据（不依赖外部图片文件）
- HTML 报告内嵌 JavaScript（缩略图点击放大、折叠面板切换）
- 报告可独立打开和分享，无需附加文件

---

## 6. AutoTestReport 数据模型

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 报告 ID：`report-{YYYYMMDD}-{NNN}` |
| title | string | 报告标题 |
| generatedAt | string | 生成时间（ISO 8601） |
| totalCases | number | 总用例数 |
| passedCases | number | 通过用例数 |
| failedCases | number | 失败用例数 |
| errorCases | number | 异常用例数 |
| skippedCases | number | 跳过用例数 |
| passRate | string | 通过率（百分比，两位小数） |
| totalSteps | number | 总步骤数 |
| passedSteps | number | 通过步骤数 |
| failedSteps | number | 失败步骤数 |
| skippedSteps | number | 跳过步骤数 |
| totalDuration | number | 总耗时（毫秒） |
| avgDuration | number | 平均每用例耗时（毫秒） |
| results | AutoTestResult[] | 关联结果列表 |
| assertionStats | object | 断言类型统计 |
| frameworkStats | object | 框架统计（playwright/selenium 用例数） |
| format | string | 报告格式：html/allure/both |
| htmlPath | string | HTML 报告文件路径 |
| allurePath | string | Allure 报告目录路径（可选） |
