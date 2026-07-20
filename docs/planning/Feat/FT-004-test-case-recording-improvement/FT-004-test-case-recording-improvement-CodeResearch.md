# FT-004 测试用例录制改进 — 代码调研总结

> 基于对 FT-003 Web Auto Tester 工具集的全面代码扫描，整理现有实现细节、架构特征和关键发现，为 FT-004 详细设计提供代码层面的事实依据。

**创建日期**：2026-07-20
**调研范围**：`.asdm/toolsets/web-auto-tester/`（FT-003 工具集全部文件）
**调研状态**：✅ 完成

---

## 调研代码库清单

| # | 代码库 | 路径 | 说明 |
|---|--------|------|------|
| 1 | web-auto-tester | `.asdm/toolsets/web-auto-tester/` | FT-003 Web Auto Tester 工具集，包含录制命令、规范、引擎代码（纯文档驱动，无 TypeScript 源码） |

---

## 1. web-auto-tester — 架构与关键发现

### 1.1 架构特征：纯文档驱动

**核心发现**：整个 web-auto-tester 工具集是**纯文档驱动架构**，没有 TypeScript 源代码文件。`src/recorder/` 目录（FT-004 Overall 变更范围提到的）**当前不存在**。所有引擎行为由 spec 文件定义，AI Agent 按规范执行。文档标注"无实际编译代码"。

这意味着 FT-004 的所有改进同样以**文档驱动方式**实施——更新 Action 文件（流程步骤）、更新 Spec 文件（规则定义），而非编写 TypeScript 引擎代码。

### 1.2 目录结构

```
.asdm/toolsets/web-auto-tester/
├── README.md                     (10.05 KB) — 工具集入口文档
├── INSTALL.md                    (14.21 KB) — 安装指南（多引擎适配）
├── manifest.json                 (661 B)   — 工具集元数据注册
├── actions/
│   ├── auto-test-generate.md     (17.68 KB) — AI 生成用例 Action
│   ├── auto-test-record.md       (14.86 KB) — 录制生成用例 Action（FT-004 改进目标 ⭐）
│   ├── auto-test-run.md          (7.12 KB)  — 执行测试 Action
│   ├── auto-test-list.md         (6.38 KB)  — 列出用例与结果 Action
│   ├── auto-test-report.md       (12.05 KB) — 生成报告 Action
│   ├── auto-test-ci.md           (11.22 KB) — CI/CD 配置 Action
│   └── auto-test-clean.md        (10.06 KB) — 清理资源 Action
└── spec/  ← 注意：不是 specs，是 spec
    ├── auto-test-dsl-spec.md     (18.86 KB) — YAML DSL 用例格式规范
    ├── auto-test-execution-spec.md (24.42 KB) — 执行引擎 7 阶段规范
    ├── auto-test-report-spec.md  (19.47 KB) — 报告格式规范
    └── auto-test-ci-spec.md      (23.54 KB) — CI/CD 配置规范
```

### 1.3 当前录制命令 (`auto-test-record.md`) 详细分析

#### 1.3.1 当前录制流程（6 步骤）

| 步骤 | 功能 | 关键细节 |
|------|------|----------|
| **Step 1** | 启动 Playwright Codegen | 检查 PW 可用 → `npx playwright codegen {url}` → 固定视口 1280×720 |
| **Step 2** | 用户操作与实时录制 | 用户在浏览器操作，Codegen 实时录制 TypeScript/JS 代码 |
| **Step 3** | 提取操作序列 | Codegen 代码解析：`page.goto→navigate`, `page.click→click`, `page.fill→type`, `page.selectOption→select`, `page.hover→hover`, `page.waitForSelector→wait`, `page.waitForTimeout→wait` |
| **Step 4** | 转换为 YAML DSL Step 格式 | 操作映射 + URL 处理（剥离基础URL）+ **按 navigate 划分 Stage** + 补充 wait 步骤 |
| **Step 5** | 自动添加断言 | 仅添加 **A1 页面可见**断言，使用硬编码 URL→元素映射表推断 target |
| **Step 6** | 输出 YAML 文件与审核提示 | 设置元数据 + 保存文件 + 输出录制摘要 + 结构化 JSON |

#### 1.3.2 当前录制模式的核心痛点（FT-004 将解决的）

| # | 痛点 | 当前行为 | FT-004 改进方向 |
|---|------|----------|----------------|
| 1 | **单用例模式** | 每次录制仅产出 1 个 YAML，每次需重新启动浏览器 | 逐用例录制模式，浏览器保持，`/next` 切换 |
| 2 | **选择器质量差** | Codegen 原始输出无优化，nth-child、动态 ID 等不稳定 | 选择器优化引擎 + 混合确认模式 |
| 3 | **断言仅 A1** | 仅对 navigate 步骤添加 A1 页面可见断言 | A1+A2+A4+A6 四类推断 + 置信度 |
| 4 | **A1 推断原始** | 硬编码映射表（`/login→.auth-form`），未知路径 fallback 到 `.page-content`/`body` | 页面结构动态推断（data-testid > h1/h2 > .main > body） |
| 5 | **步骤冗余** | 录制输出 1:1 映射，无合并、去冗余 | 步骤合并 + 智能等待 + 去冗余 |
| 6 | **无参数化** | 输入值硬编码，无 `params` 变量支持 | 可选参数化（`dataParam` 参数，默认 false） |
| 7 | **无多页面/弹窗** | 仅单页面线性录制 | 支持多页面/弹窗（`pageContext` 字段） |
| 8 | **元数据基础** | 仅 targetUrl/timeout/browser | 增强元数据（recordedAt/pageStructure 等） |

#### 1.3.3 当前选择器清洗策略（Step 3.2）

- 去除 Playwright 内部选择器前缀（`internal:...`）
- 保留标准 CSS 选择器（`.class`、`#id`、`[attr="val"]`）
- 保留文本选择器（`text=XXX`）、data-testid 选择器（`[data-testid="XXX"]`）
- 保留组合选择器（`.parent .child`）
- **不稳定选择器仅标记，不自动优化**（nth-child、动态 ID 仅在审核提示中标注）

#### 1.3.4 当前 A1 断言推断策略（Step 5.2）— 硬编码映射表

| 导航目标 | 推断 A1 target | 说明 |
|----------|---------------|------|
| `/login` | `.auth-form` 或 `.login-form` | 登录表单可见 |
| `/home` 或 `/` | `.header` 或 `.home-content` | 首页内容可见 |
| `/admin` 或 `/dashboard` | `.sidebar` 或 `.dashboard` | 管理后台可见 |
| `/products` 或 `/list` | `.list-content` | 列表内容可见 |
| `/detail` 或 `/edit` | `.detail-form` 或 `.edit-form` | 详情/编辑表单可见 |
| 其他未知路径 | `.page-content` 或 `body` | 通用页面内容可见 |

**问题**：未知路径 fallback 到 `.page-content`/`body` 几乎无验证价值，无法适配不同项目的前端结构。

#### 1.3.5 当前选择器稳定性评估（Execution Guidelines）

| 选择器类型 | 稳定性 | 当前处理 |
|-----------|:------:|----------|
| `[data-testid="XXX"]` | ✅ 高 | 最佳选择器 |
| `#unique-id` | ✅ 高 | 可接受 |
| `.class-name` | ⚠️ 中 | 可能变化 |
| `.parent .child` | ⚠️ 中 | 可能变化 |
| `text=XXX` | ⚠️ 中 | 文本可能变化 |
| `:nth-child(N)` | ❌ 低 | 仅标记建议替换 |
| 动态 ID（随机值） | ❌ 低 | 仅标记建议替换 |

#### 1.3.6 当前录制参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| url | string | ✅ | 目标 URL |
| framework | string | ❌ | 框架偏好，默认 playwright |
| browser | string | ❌ | 浏览器类型，默认 chromium |

FT-004 需新增参数：`dataParam`（bool, 默认 false）、`pageMapFile`（string, 可选）、`tags`（string[], 可选）、`interactive`（概念已重构为逐用例完成断点）。

### 1.4 DSL Spec 关键结构 (`auto-test-dsl-spec.md`)

#### 1.4.1 顶层字段

```yaml
name: string               # 必填，用例名称
description: string         # 可选
framework: string           # 可选，playwright/selenium
capture: string             # 可选，on-fail/full
tags: string[]              # 可选
metadata: object            # 可选
source: string              # 可选，generate/record/manual
stages: Stage[]             # 必填
```

FT-004 需扩展：新增 `params` 字段（数据参数化）、metadata 子字段扩展。

#### 1.4.2 Step 定义

```yaml
steps:
  - action: string          # 必填
    target: string          # 必填
    value: string           # 可选
    capture: string         # 可选
    timeout: number         # 可选
    frameworkOverride: string  # 可选
    assertions: Assertion[]    # 可选
```

FT-004 需扩展：新增 `pageContext` 字段（多页面/弹窗）、`pageTransition` 字段（页面跳转标记）。

#### 1.4.3 操作类型映射（10 种）

| 操作 | PW API | SEL API |
|------|---------|---------|
| navigate | `page.goto()` | `driver.get()` |
| click | `page.click()` | `element.click()` |
| type | `page.fill()` | `element.sendKeys()` |
| wait | `waitForSelector/Timeout` | `WebDriverWait()` |
| scroll | `page.evaluate()` | `executeScript()` |
| upload | `setInputFiles()` | `sendKeys(filepath)` |
| hover | `page.hover()` | `ActionChains` |
| select | `selectOption()` | `Select.select_by_value()` |
| screenshot | `page.screenshot()` | `save_screenshot()` |
| assert | `expect()` | `find_element + 比对` |

#### 1.4.4 断言类型（A1~A8）

| 编号 | 类型 | 适用框架 | 说明 |
|:----:|------|:--------:|------|
| A1 | 页面可见 | PW/SEL | 元素是否可见 |
| A2 | 页面跳转 | PW/SEL | URL 路径跳转 |
| A3 | 元素状态 | PW/SEL | 元素属性状态 |
| A4 | 内容匹配 | PW/SEL | 文本内容匹配 |
| A5 | API 响应 | PW only | 接口返回数据 |
| A6 | 表单值 | PW/SEL | 表单当前值 |
| A7 | 元素数量 | PW/SEL | 匹配元素数量 |
| A8 | 截图比对 | PW only | 视觉回归 |

FT-004 断言推断范围：A1+A2+A4+A6（四类），附带置信度评分。

#### 1.4.5 数据模型

- **AutoTestCase (ATC)**：11 个字段（id/name/description/framework/capture/tags/metadata/stages/source/createdAt/updatedAt）
- **AutoTestResult (ATR)**：14 个字段（id/testCaseId/status/totalSteps/passedSteps/failedSteps/...）
- **Stage**：name + steps
- **Step**：action/target/value/capture/timeout/frameworkOverride/assertions
- **Assertion**：type/target/expected/message

FT-004 需扩展 ATC 数据模型：新增 `params` 字段、metadata 子字段扩展。

#### 1.4.6 Schema 校验规则

- `name` 非空字符串，小写+连字符
- `stages` 数组 ≥ 1
- 每个 Stage：`name` 非空 + `steps` ≥ 1
- 每个 Step：`action` 必填 + `target` 必填
- `type`/`select` 的 `value` 必填
- `assert` 的 `assertions` ≥ 1
- `framework` 只接受 `playwright` 或 `selenium`

### 1.5 执行引擎规范 (`auto-test-execution-spec.md`)

7 阶段执行规范定义了完整的执行管道。FT-004 不涉及执行引擎变更，但录制改进产出的 YAML 用例需兼容该规范的操作映射和断言判定规则。

### 1.6 Workspace 用例目录

```
.asdm/workspace/auto-test/
├── cases/
│   ├── user-login-test.yaml          (Playwright 登录用例)
│   ├── admin-login-test.yaml         (Selenium 登录用例)
│   └── admin-login-selenium.yaml     (Selenium 框架用例)
├── results/      (.gitkeep)
├── reports/      (.gitkeep)
├── screenshots/  (.gitkeep)
└── ci/           (GitHub Actions/Jenkins/GitLab/Azure 配置)
```

FT-004 的相似用例检测需扫描 `cases/` 目录。

### 1.7 manifest.json 元数据

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
  "id": "web-auto-tester",
  "name": "Web Auto Tester Toolset",
  "version": "0.0.1",
  "type": "toolset",
  "description": "Web 系统自动化测试工具集"
}
```

---

## 2. 关键发现汇总 — 对 FT-004 设计的影响

### 2.1 纯文档驱动架构的影响

**发现**：工具集无 TypeScript 源代码，所有行为由 Action/Spec 文档定义。

**影响**：
- FT-004 的改进实施方式是**更新 Action 文件（流程步骤）和 Spec 文件（规则定义）**
- 不需要编写 TypeScript 引擎代码（如 `selector-optimizer.ts`、`assertion-inferrer.ts`）
- 改进逻辑作为 Action 步骤描述，AI Agent 按规范执行
- 需新增的 spec 文件（选择器优化规范、断言推断规范等）同样以 Markdown 文档形式编写

### 2.2 目录命名不一致

**发现**：规范目录名为 `spec/`（不是 `specs/`），而 FT-004 Overall 变更范围写作 `specs/`。

**影响**：FT-004 新增规范文件应放入 `spec/` 目录（与现有结构一致），路径修正为：
- `.asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`
- `.asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`
- `.asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`
- `.asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`

### 2.3 当前录制流程的 6 步骤需扩展为逐用例模式

**发现**：当前 6 步骤是单次录制→单用例产出的线性流程。

**影响**：FT-004 需将录制流程重构为：
- **会话初始化**（Step 1：启动浏览器 + 相似用例检测）
- **逐用例循环**（Step 2~7：录制→`/next`→命名→后处理→优化摘要→保存→Codegen重启）
- **会话结束**（Step 8：`/end`→关闭浏览器→会话摘要）

### 2.4 DSL Spec 扩展点

**发现**：DSL Spec 的 Step 定义当前无 `pageContext`/`pageTransition`/`params` 字段。

**影响**：FT-004 需扩展 DSL Spec 的以下部分：
1. **顶层新增** `params` 字段（数据参数化）
2. **Step 新增** `pageContext` 字段（多页面/弹窗：`main/popup/newTab`）
3. **Step 新增** `pageTransition` 字段（页面跳转标记：`navigate/new-tab/new-window`）
4. **metadata 新增** 子字段（`recordedAt`/`duration`/`pageTitle`/`pageStructure`/`viewportActual`）
5. **Schema 校验** 新增 `params` 和 `pageContext` 校验规则

### 2.5 选择器优化引擎的设计约束

**发现**：当前选择器处理仅为"清洗"（去除内部前缀）+ "标注"（标记不稳定），无自动优化。

**影响**：FT-004 的选择器优化引擎（文档形式）需定义：
- 优化策略优先级：`[data-testid] > [name] > [aria-label] > [role] > id > .class > :nth-child`
- 优化操作集：缩短路径、去除 nth-child、替换动态 ID、语义化替代
- 稳定性评分规则
- 优化摘要展示格式

### 2.6 断言推断引擎的设计约束

**发现**：当前断言推断仅 A1，且使用硬编码 URL→元素映射表。

**影响**：FT-004 的断言推断引擎（文档形式）需定义：
- 四类断言推断触发条件：A1（navigate后）、A2（URL变化）、A4（元素文本变化）、A6（表单填写后）
- 置信度评分规则：高（≥80%）、中（50~80%）、低（<50%）
- A1 推断方式从硬编码映射表改为页面结构动态推断
- 推断优先级：`[data-testid] > h1/h2 标题 > .main/.content > body`

### 2.7 步骤优化引擎的设计约束

**发现**：当前仅对 click（提交按钮）后补充 wait，无步骤合并或去冗余。

**影响**：FT-004 步骤优化引擎（文档形式）需定义：
- 表单填写组合并规则（连续 type → form-fill-group）
- 智能等待替代规则（`waitForTimeout` → `waitForSelector`/`waitForNavigation`）
- 冗余等待去重规则（连续重复 waitFor 同目标）
- Stage 划分策略是否调整

---

## 3. FT-004 实施路径建议

### 3.1 需修改的文件清单

| # | 文件路径 | 变更类型 | 变更内容 |
|---|----------|:--------:|----------|
| 1 | `.asdm/toolsets/web-auto-tester/actions/auto-test-record.md` | ✏️ 重写 | 从 6 步骤线性流程重构为逐用例录制会话流程 |
| 2 | `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md` | ✏️ 扩展 | 新增 params/pageContext/pageTransition/metadata扩展/校验规则 |
| 3 | `.asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md` | 🆕 新增 | 选择器优化引擎规范 |
| 4 | `.asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md` | 🆕 新增 | 断言推断引擎规范 |
| 5 | `.asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md` | 🆕 新增 | 步骤优化引擎规范 |
| 6 | `.asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md` | 🆕 新增 | 数据参数化规范 |

### 3.2 不需要创建的文件

| 路径 | 原因 |
|------|------|
| `.asdm/toolsets/web-auto-tester/src/recorder/` 目录及 TypeScript 文件 | 纯文档驱动架构，无编译代码 |
| 新的 Action 命令文件 | FT-004 不引入新命令，仅改进 `/auto-test-record` |

### 3.3 变更范围修正

Overall 文档变更范围中提到的 `src/recorder/` 目录修改应修正为 **spec 规范文件新增**，因为工具集是纯文档驱动架构，无 TypeScript 源代码。

---

**文档版本**：1.0
**创建日期**：2026-07-20
**维护者**：AI Planner
