# ASDM Toolset - Web Auto Tester Toolset

toolset-id: web-auto-tester
toolset-name: Web Auto Tester Toolset
version: 0.0.2
updated-date: 2026-07-20
toolset-description: Web 系统自动化测试工具集，支持 YAML DSL 用例驱动、测试用例描述 AI 生成、Playwright Codegen 录制三种用例生成方式，Playwright 主框架 + Selenium 辅框架双框架兼容，本地执行，HTML 报告 + 可选 Allure 导出

## Overview

Web Auto Tester（工具集 ID：web-auto-tester）是一个面向 Web 系统全面自动化测试的独立 ASDM 工具集。它通过 YAML DSL 用例驱动测试执行，支持三种用例生成方式（测试用例描述 AI 生成、Playwright Codegen 录制、手动编写），以 Playwright 为主框架、Selenium 为可选辅框架实现双框架兼容，提供 HTML 自定义报告 + 可选 Allure 导出。

**核心定位**：web-auto-tester 是一个独立的自动化测试工具集，专注于本地环境下的全面功能测试。

## Features

### Common features

- YAML DSL 用例格式
- Playwright 主框架完整支持 + Selenium 辅框架基础兼容
- 8 种断言类型（A1~A8），覆盖页面可见、跳转、元素状态、内容匹配、API 响应、表单值、元素数量、截图比对
- 3 种截图策略（on-fail / full / always），失败步骤自动截图
- 执行结果结构化存储（AutoTestResult JSON）
- HTML 自定义报告（卡片式摘要 + 用例详情 + 截图内嵌 + 统计图表）
- 可选 Allure 格式导出
- 规范驱动架构，所有引擎行为由 spec 文件定义，AI Agent 按规范执行

### Feature 1: 测试用例描述 AI 生成用例（auto-test-generate）

根据用户提供的测试用例描述自动生成 YAML DSL 测试用例，支持三种输入方式。

- 支持自然语言描述、结构化步骤描述、Markdown 测试文档三种输入格式
- 自动解析操作步骤、UI 元素、输入值和验证点
- 默认仅生成正向场景（`scenarioType=positive-only`），可选生成逆向/边界值场景（`scenarioType=all`）
- 自动推断选择器（基于 UI 元素描述和位置信息）
- 自动推断断言（基于操作类型和验证点），优先将用户描述中的"预期结果"转换为断言
- 支持数据参数化（`dataParam=true` 时提取输入值为参数变量）
- 标记框架偏好和截图配置
- 输出 YAML 文件并提示用户审核

**输入**：测试用例描述内容或文件路径、框架偏好、输出目录、场景类型（scenarioType）、覆盖深度、数据参数化开关
**输出**：YAML DSL 用例文件列表

### Feature 2: 录制操作生成用例（auto-test-record）

通过 Playwright Codegen 录制操作生成 YAML DSL 测试用例。

- 启动 `npx playwright codegen` 录制器，打开目标页面
- 用户在浏览器中操作，实时录制
- 录制结束后提取操作序列
- 转换为 YAML DSL Step 格式
- 自动添加页面可见断言（A1）
- 输出 YAML 文件并提示用户补充断言

**输入**：目标 URL、框架偏好、浏览器类型
**输出**：YAML DSL 用例文件

### Feature 3: 执行自动化测试（auto-test-run）

执行 YAML DSL 测试用例，7 阶段规范流程。

- Phase 1：用例加载（YAML 解析 → Schema 校验 → 结构化）
- Phase 2：上下文准备（读取 metadata → 初始化浏览器选项）
- Phase 3：执行引擎（Playwright/Selenium 操作映射 → 逐步骤执行）
- Phase 4：断言判定（8 种断言类型 → 结果映射）
- Phase 5：截图采集（on-fail/full/always 三策略）
- Phase 6：结果记录（AutoTestResult JSON → ATR-{YYYYMMDD}-{NNN} ID）
- Phase 7：报告输出（摘要输出 + HTML 报告可选）

**输入**：用例文件路径或目录、框架偏好、截图策略、环境配置
**输出**：AutoTestResult JSON 文件

### Feature 4: 列出用例与结果（auto-test-list）

列出测试用例和执行结果。

- 三种展示模式：cases（用例列表）/ results（结果列表）/ all（合并展示）
- 按标签、框架、状态筛选过滤
- Markdown 表格格式化输出

**输入**：列出类型、筛选条件
**输出**：Markdown 表格

### Feature 5: 生成 HTML 测试报告（auto-test-report）

生成结构化 HTML 测试报告。

- 摘要卡片：渐变背景 + 大数字展示（通过率/失败数/跳过数）
- 用例列表：状态色标签（绿/红/灰）
- 步骤详情：折叠面板 + 失败步骤红色高亮
- 截图展示：内嵌失败/标记步骤截图 + 缩略图 + 点击放大
- 统计图表：ASCII 图表展示通过率和断言分布
- 可选 Allure 导出（JSON → Allure 格式 → allure generate）

**输入**：结果文件或目录、报告格式
**输出**：HTML 报告文件路径

### Feature 6: 清理测试资源（auto-test-clean）

清理测试工作区中的过期资源。

- 4 种清理范围：results / reports / screenshots / all
- 清理前列出文件数量和大小
- 用户确认后执行删除
- 保留目录结构和 .gitkeep

**输入**：清理范围、确认标志
**输出**：清理确认信息

## Toolset Workflow

Once Web Auto Tester is installed, user can use the following commands:

1. `/auto-test-generate`：根据测试用例描述自动生成 YAML DSL 测试用例
2. `/auto-test-record`：通过 Playwright Codegen 录制操作生成 YAML DSL 测试用例
3. `/auto-test-run`：执行 YAML DSL 测试用例，生成执行结果 JSON
4. `/auto-test-list`：列出测试用例和执行结果
5. `/auto-test-report`：生成 HTML 测试报告（可选 Allure 导出）
6. `/auto-test-clean`：清理测试工作区资源

### 使用方式

#### 生成用例：测试用例描述

```shell
/auto-test-generate description="1. 浏览器地址栏输入：https://platform-dt02.asdm.ai/ 2. 点击【登录】 3. 输入邮箱：admin@test.com 4. 输入密码：pass123 5. 点击【登录】按钮"
```

#### 生成用例：Markdown 文件

```shell
/auto-test-generate description=docs/test-cases/login-test.md
```

#### 生成用例：录制操作

```shell
/auto-test-record url=http://localhost:3000 browser=chromium
```

#### 执行测试

```shell
/auto-test-run case=cases/user-login-test.yaml
```

#### 列出结果

```shell
/auto-test-list type=results filter=status:fail
```

#### 生成报告

```shell
/auto-test-report result=results/ format=html
```

#### 清理资源

```shell
/auto-test-clean scope=all confirm=true
```

## Toolset Structure

The Web Auto Tester toolset has the following structure:

```text
.asdm/toolsets/web-auto-tester/
├── INSTALL.md                                    # 安装指南
├── README.md                                     # 入口文档
├── manifest.json                                 # 工具集元数据注册
├── actions/
│   ├── auto-test-generate.md                     # 测试用例描述生成用例 Action
│   ├── auto-test-record.md                       # 录制生成用例 Action
│   ├── auto-test-run.md                          # 执行测试 Action
│   ├── auto-test-list.md                         # 列出用例与结果 Action
│   ├── auto-test-report.md                       # 生成报告 Action
│   └── auto-test-clean.md                        # 清理资源 Action
└── spec/
    ├── auto-test-dsl-spec.md                     # YAML DSL 用例格式规范
    ├── auto-test-execution-spec.md               # 执行引擎 7 阶段规范
    └── auto-test-report-spec.md                  # 报告格式规范
```

### Spec Documents

The toolset uses the following spec documents:

- **auto-test-dsl-spec.md**：YAML DSL 用例格式规范，定义用例文件结构、Stage/Step、断言类型、框架标记、捕获配置、数据模型
- **auto-test-execution-spec.md**：执行引擎 7 阶段规范，定义用例加载、上下文准备、执行引擎、断言判定、截图采集、结果记录、报告输出
- **auto-test-report-spec.md**：HTML 报告格式规范，定义报告模板结构、CSS 样式、Allure 导出流程

## Toolset Workspace

The Web Auto Tester toolset has the following workspace structure:

```text
.asdm/workspace/auto-test/
├── cases/                          # 测试用例存储（YAML DSL 文件）
│   ├── user-login-test.yaml
│   ├── admin-login-selenium.yaml
│   └── ...
├── results/                        # 执行结果存储（AutoTestResult JSON）
│   ├── ATR-20260714-001.json
│   └── ...
├── reports/                        # HTML 测试报告
│   ├── report-20260714.html
│   ├── allure-results/             # Allure 中间数据（可选）
│   └── ...
└── screenshots/                    # 截图存储
    ├── ATR-20260714-S03-fail.png
    ├── ATR-20260714-S05-marked.png
    └── ...
```

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
