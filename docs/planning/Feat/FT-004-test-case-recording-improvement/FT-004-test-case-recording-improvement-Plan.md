# FT-004 测试用例录制改进 实施计划

## 项目概述

本计划对 FT-003 Web Auto Tester 的 `/auto-test-record` 命令进行全面改进，核心工作项：

1. 重构录制命令为逐用例会话模式（持久浏览器 + `/next`/`/end` 信号控制）
2. 新增四大引擎规范（选择器优化、断言推断、步骤优化、数据参数化），从文档层面定义引擎行为
3. 扩展 DSL Spec 支持 `params`、`pageContext`、`pageTransition`、增强 `metadata`、`confidence`/`inferredFrom` 断言字段
4. 新增相似用例检测与多页面/弹窗录制支持

### 前置依赖

- FT-003 Web Auto Tester 工具集已部署（`.asdm/toolsets/web-auto-tester/`）
- Playwright 已安装可用（`npx playwright --version`）
- `.asdm/workspace/auto-test/cases/` 目录已存在

### 后续依赖

- FT-003 执行引擎需兼容扩展后的 DSL 字段（`pageContext`、`pageTransition`、`params`、`confidence`）
- FT-003 报告引擎需支持增强元数据展示

---

## 进度概要

| Phase | 任务 | 状态 | 交付物 |
|:-----:|------|:----:|--------|
| P1 | 1.1 DSL Spec 扩展 — 新增字段与校验规则 | ✅ | `auto-test-dsl-spec.md`（扩展版） |
| P1 | 1.2 选择器优化引擎规范 | ✅ | `auto-test-selector-optimization-spec.md` |
| P1 | 1.3 断言推断引擎规范 | ✅ | `auto-test-assertion-inference-spec.md` |
| P1 | 1.4 步骤优化引擎规范 | ✅ | `auto-test-step-optimization-spec.md` |
| P1 | 1.5 数据参数化规范 | ✅ | `auto-test-data-parameterization-spec.md` |
| P2 | 2.1 录制命令重构 — 逐用例会话模式 | ✅ | `auto-test-record.md`（重写版） |
| P2 | 2.2 录制命令新增参数与交互流程 | ✅ | `auto-test-record.md`（参数+交互定义） |
| P2 | 2.3 完成断点后处理流程定义 | ✅ | `auto-test-record.md`（Step 5~7） |
| P3 | 3.1 逐用例录制端到端验证 | ✅ | 录制产出 YAML 用例文件 |
| P3 | 3.2 选择器优化与断言推断验证 | ✅ | 优化摘要展示验证 |
| P3 | 3.3 数据参数化与多页面录制验证 | ✅ | 参数化 YAML + 多页面 YAML 验证 |

---

## Phase 1: 规范基础层 — DSL 扩展与引擎规范定义

### 目标

定义所有新增 DSL 字段、校验规则和四个引擎的规范文档，为录制命令重构提供规则基础。所有规范文件均以 Markdown 文档形式编写（纯文档驱动架构）。

---

### 任务 1.1: DSL Spec 扩展 — 新增字段与校验规则

#### 核心逻辑

在现有 `auto-test-dsl-spec.md` 中扩展以下内容：

1. **顶层新增 `params` 字段**：`params: object`（参数名→默认值映射），步骤中使用 `{{params.paramName}}` 引用
2. **Step 新增 `pageContext` 字段**：可选值 `main`（默认）/ `popup` / `newTab`
3. **Step 新增 `pageTransition` 字段**：可选值 `navigate` / `new-tab` / `new-window` / `none`（默认）
4. **Assertion 新增 `confidence` 字段**：可选值 `high` / `medium` / `low`
5. **Assertion 新增 `inferredFrom` 字段**：字符串，描述推断来源
6. **metadata 新增子字段**：`recordedAt`、`duration`、`pageTitle`、`pageStructure`（含 5 子字段）、`viewportActual`、`frontFramework`、`source`
7. **Schema 校验规则扩展**：
   - `params` 键名使用小写英文字母+下划线
   - `{{params.xxx}}` 引用时 `xxx` 必须在 `params` 中有对应键
   - `pageContext` 仅接受 `main/popup/newTab`
   - `pageTransition` 仅接受 `navigate/new-tab/new-window/none`
   - `confidence` 仅接受 `high/medium/low`
   - `pageContext: popup/newTab` 步骤应紧跟 `pageTransition` 步骤之后

#### 交付物

- `auto-test-dsl-spec.md` 扩展版，含所有新增字段定义、数据模型更新、校验规则扩展、YAML 示例

#### 验证步骤

- [ ] **V1.1.1** 检查 DSL Spec 文件包含 `params` 字段定义 → 顶层字段说明中有 params 字段及类型描述
  `grep -c "params" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.1.2** 检查 DSL Spec 文件包含 `pageContext` 和 `pageTransition` 字段定义 → Step 字段表中有新增行
  `grep -c "pageContext\|pageTransition" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.1.3** 检查 DSL Spec 文件包含 `confidence` 和 `inferredFrom` 字段定义 → Assertion 字段表中有新增行
  `grep -c "confidence\|inferredFrom" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.1.4** 检查 DSL Spec 文件包含扩展后的 metadata 子字段定义 → metadata 字段表中有 recordedAt/duration/pageTitle/pageStructure/viewportActual/frontFramework
  `grep -c "recordedAt\|pageStructure\|viewportActual\|frontFramework" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.1.5** 检查 DSL Spec 文件包含新增 Schema 校验规则 → 校验规则节中有 params/pageContext/pageTransition/confidence 相关规则
  `grep -A5 "Schema 校验" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md | grep -c "params\|pageContext\|confidence"`
- [ ] **V1.1.6** 检查 DSL Spec 文件包含参数引用语法 `{{params.xxx}}` 的说明 → YAML 示例中有引用语法
  `grep -c "{{params" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`

---

### 任务 1.2: 选择器优化引擎规范

#### 核心逻辑

创建 `auto-test-selector-optimization-spec.md`，定义选择器优化引擎的全部行为规范：

1. **选择器稳定性评分规则**：10级优先级表（`[data-testid]` → `:nth-child`），每级标注稳定性（高/中/低）
2. **优化操作集**：5种操作（缩短路径、nth-child替代、动态ID替代、语义化替代、路径精简），每种含适用场景和示例
3. **优化摘要展示格式**：4区块格式（选择器优化表格含原始→优化后→稳定性变化列，统计行含优化总数和稳定性提升数）
4. **用户确认机制**：自动优化低稳定性选择器 + 摘要展示 + 用户可直接修改 YAML（无需逐条拒绝）
5. **`selectorStrategy` 参数说明**：`optimize`（默认，自动优化+确认）/ `raw`（原始输出不优化）

#### 交付物

- `.asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`

#### 验证步骤

- [ ] **V1.2.1** 规范文件存在 → 文件在 spec 目录下
  `ls .asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`
- [ ] **V1.2.2** 规范包含 10 级优先级表 → 表格含至少 10 行选择器类型及稳定性标注
  `grep -c "data-testid\|nth-child\|动态ID\|aria-label" .asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`
- [ ] **V1.2.3** 规范包含 5 种优化操作定义 → 每种操作含适用场景和示例
  `grep -c "缩短路径\|nth-child 替代\|动态ID 替代\|语义化替代\|路径精简" .asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`
- [ ] **V1.2.4** 规范包含 `selectorStrategy` 参数说明 → 含 optimize/raw 两种策略描述
  `grep -c "selectorStrategy\|optimize\|raw" .asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`
- [ ] **V1.2.5** 规范包含优化摘要展示格式模板 → 含表格结构和统计行格式
  `grep -c "原始选择器\|优化后选择器\|稳定性变化\|优化.*数量\|稳定性.*提升" .asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`
- [ ] **V1.2.6** 规范包含用户确认机制说明 → 含自动优化规则和 YAML 直接修改说明
  `grep -c "用户确认\|直接修改\|YAML" .asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`

---

### 任务 1.3: 断言推断引擎规范

#### 核心逻辑

创建 `auto-test-assertion-inference-spec.md`，定义断言推断引擎的全部行为规范：

1. **A1 元素可见推断**：触发条件（navigate后、click后页面未跳转、wait后）、推断策略（页面结构动态推断优先级：`[data-testid] > h1/h2 > [name] > [aria-label] > .main/.content > body`）、置信度映射
2. **A2 URL跳转推断**：触发条件（navigate后、click后URL变化）、推断策略、置信度
3. **A4 内容匹配推断**：触发条件（click后文案变化、navigate后关键文本、type后输入值可见）、推断策略、置信度
4. **A6 表单值推断**：触发条件（type后、select后）、推断策略、置信度
5. **置信度评分规则**：高（≥80%）、中（50~80%）、低（<50%），三级标注
6. **映射文件（pageMapFile）格式定义**：可选辅助 A1 推断，YAML 格式含 URL→选择器映射
7. **推断结果标注格式**：`confidence` + `inferredFrom` 字段标注规则

#### 交付物

- `.asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`

#### 验证步骤

- [ ] **V1.3.1** 规范文件存在 → 文件在 spec 目录下
  `ls .asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`
- [ ] **V1.3.2** 规范包含 A1 推断触发条件和策略 → 含 navigate/click/wait 三种触发条件及推断策略
  `grep -c "A1\|元素可见\|navigate.*后\|click.*后\|wait.*后\|页面结构动态" .asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`
- [ ] **V1.3.3** 规范包含 A2/A4/A6 推断触发条件和策略 → 每类断言含触发条件表和推断策略
  `grep -c "A2\|URL.*跳转\|A4\|内容匹配\|A6\|表单值" .asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`
- [ ] **V1.3.4** 规范包含 A1 页面结构动态推断优先级规则 → 含优先级排序列表和置信度映射
  `grep -c "data-testid.*优先\|h1.*h2\|aria-label\|\.main\|置信度映射" .asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`
- [ ] **V1.3.5** 规范包含置信度评分规则 → 含高/中/低三级定义及百分比阈值
  `grep -c "≥80%\|50.*80%\|<50%\|高.*中.*低" .asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`
- [ ] **V1.3.6** 规范包含 pageMapFile 映射文件格式定义 → 含 YAML 格式示例和 URL→选择器映射说明
  `grep -c "pageMapFile\|映射文件\|URL.*选择器" .asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`
- [ ] **V1.3.7** 规范包含推断结果标注格式 → 含 confidence 和 inferredFrom 字段说明
  `grep -c "confidence\|inferredFrom\|推断来源" .asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`

---

### 任务 1.4: 步骤优化引擎规范

#### 核心逻辑

创建 `auto-test-step-optimization-spec.md`，定义步骤优化引擎的全部行为规范：

1. **表单填写组合并规则**：连续 ≥2 个 `type` 操作合并标注（`# [form-fill-group]` 注释标记，不改变 DSL Step 结构）
2. **智能等待替代规则**：3种场景（`wait timeout:XXXms` → `wait target:selector timeout:N`、click提交按钮后补充wait、navigate后补充wait核心元素）
3. **冗余等待去除规则**：2种条件（连续 ≥2 个 wait 同一 target 仅保留第一个、wait 后紧跟 assert 同一 target 去除 wait）
4. **Stage 划分策略**：按 navigate 划分（与当前一致）

#### 交付物

- `.asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`

#### 验证步骤

- [ ] **V1.4.1** 规范文件存在 → 文件在 spec 目录下
  `ls .asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`
- [ ] **V1.4.2** 规范包含表单填写组合并规则 → 含触发条件（≥2个连续type）和合并格式（注释标记）
  `grep -c "form-fill-group\|连续.*type\|表单.*合并\|注释" .asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`
- [ ] **V1.4.3** 规范包含智能等待替代规则 → 含3种替代场景说明和示例
  `grep -c "waitForTimeout\|waitForSelector\|智能等待\|提交.*按钮\|navigate.*后" .asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`
- [ ] **V1.4.4** 规范包含冗余等待去除规则 → 含2种去除条件和示例
  `grep -c "冗余\|重复.*wait\|同一.*target\|去除.*wait\|assert.*同一" .asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`
- [ ] **V1.4.5** 规范包含 Stage 划分策略说明 → 含按 navigate 划分的描述
  `grep -c "Stage.*划分\|navigate.*划分\|阶段" .asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`
- [ ] **V1.4.6** 规范含 YAML 合并格式示例 → 示例中有 `# [form-fill-group]` 注释标记
  `grep -c "#\[form-fill-group\]" .asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`

---

### 任务 1.5: 数据参数化规范

#### 核心逻辑

创建 `auto-test-data-parameterization-spec.md`，定义数据参数化的全部行为规范：

1. **参数化提取规则**：提取目标（type操作的value、select操作的value），提取条件（所有type/select操作）
2. **参数名推断优先级**：5级优先级（`name`属性 → `data-testid`属性 → `aria-label`属性 → `id`属性 → 序号`inputN`）
3. **`{{params.xxx}}` 引用语法**：步骤 value 中使用双花括号引用参数
4. **`dataParam` 参数说明**：`true`（开启参数化）/ `false`（默认，不参数化，输入值硬编码）
5. **YAML 格式示例**：含 `params` 顶层字段 + 步骤引用示例
6. **优化摘要展示格式**：参数化区块含参数名/默认值/原始步骤表格，关闭时标注"参数化已关闭"

#### 交付物

- `.asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`

#### 验证步骤

- [ ] **V1.5.1** 规范文件存在 → 文件在 spec 目录下
  `ls .asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`
- [ ] **V1.5.2** 规范包含参数化提取规则 → 含 type/select 操作的提取规则和示例
  `grep -c "type.*操作\|select.*操作\|提取.*value\|参数名" .asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`
- [ ] **V1.5.3** 规范包含参数名推断优先级（5级） → 含 name/data-testid/aria-label/id/inputN 推断规则
  `grep -c "name.*属性\|data-testid.*属性\|aria-label.*属性\|id.*属性\|inputN\|推断.*优先" .asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`
- [ ] **V1.5.4** 规范包含 `{{params.xxx}}` 引用语法说明 → 含引用格式和步骤示例
  `grep -c "{{params" .asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`
- [ ] **V1.5.5** 规范包含 `dataParam` 参数说明 → 含 true/false 两种模式描述
  `grep -c "dataParam\|参数化.*开关\|默认.*false" .asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`
- [ ] **V1.5.6** 规范含完整 YAML 格式示例 → 含 params 顶层和步骤引用
  `grep -c "params:" .asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`

---

## Phase 2: 录制命令重构 — 逐用例会话流程定义

### 目标

基于 Phase 1 的规范基础，将 `auto-test-record.md` 从当前 6 步骤线性流程重写为 8 步骤逐用例会话流程，包含所有新增参数、交互点、后处理引擎调用和优化摘要展示。

---

### 任务 2.1: 录制命令重构 — 逐用例会话模式

#### 核心逻辑

将 `auto-test-record.md` 从当前 6 步骤线性流程重构为逐用例会话录制流程：

1. **Step 1: 会话初始化** — 相似用例检测 + Playwright可用检查 + 启动持久浏览器会话 + 启动 Codegen + 输出启动提示
2. **Step 2: 用户操作录制** — Codegen实时录制 + 多页面/弹窗检测标记
3. **Step 3: 完成断点触发** — `/next` 信号暂停当前用例，`/end` 直接跳至会话结束
4. **Step 4: 用例命名** — 用户指定名称 + 名称校验（非空、小写+连字符、不重名）
5. **Step 5: 后处理** — 提取操作序列 + 选择器优化(5b) + 断言推断(5c) + 步骤优化(5d) + 数据参数化(5e) + 元数据增强(5f) + 多页面标记(5g) + Stage划分与YAML组装(5h)
6. **Step 6: 优化摘要展示** — 4区块展示（选择器优化、断言推断、步骤优化、数据参数化）
7. **Step 7: 保存 YAML + Codegen 重启** — 组装YAML + 保存到cases目录 + Codegen重启 + 输出确认
8. **Step 8: 会话结束** — `/end` → 关闭浏览器 → 输出会话摘要 → 结构化JSON输出

#### 交付物

- `auto-test-record.md` 重写版，含完整 8 步骤会话流程定义

#### 验证步骤

- [ ] **V2.1.1** 录制命令文件包含 8 步骤流程定义 → 每个步骤有标题和详细描述
  `grep -c "Step [1-8]" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.1.2** Step 1 包含相似用例检测逻辑 → 含扫描cases目录+URL+tags匹配+提示用户
  `grep -c "相似用例\|cases.*目录\|匹配度\|提示.*已有" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.1.3** Step 1 包含持久浏览器会话启动逻辑 → 含浏览器保持直到 `/end` 的描述
  `grep -c "持久浏览器\|浏览器.*保持\|/end.*关闭" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.1.4** Step 3 包含 `/next` 和 `/end` 信号处理 → 含两种信号的分流逻辑
  `grep -c "/next\|/end\|完成断点\|会话结束" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.1.5** Step 4 包含用例命名校验规则 → 含非空、小写+连字符、不重名三条校验
  `grep -c "用例命名\|校验\|小写.*连字符\|重名" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.1.6** Step 7 包含 Codegen 重启逻辑 → 含"关闭Codegen实例+浏览器保持+重启Codegen"描述
  `grep -c "Codegen.*重启\|关闭.*Codegen\|浏览器.*保持\|重新启动" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.1.7** Step 8 包含会话摘要输出格式 → 含表格（用例名称/步骤数/断言数/选择器优化/保存路径）+下一步建议
  `grep -c "会话摘要\|用例名称\|步骤数\|断言数\|下一步建议" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`

---

### 任务 2.2: 录制命令新增参数与交互流程

#### 核心逻辑

在重构后的 `auto-test-record.md` 中定义新增参数和关键交互点：

1. **新增参数**：
   - `tags: string[]`（可选，默认空，用例标签如 `module:auth,feature:login`）
   - `dataParam: boolean`（可选，默认 false，数据参数化开关）
   - `pageMapFile: string`（可选，页面元素映射文件路径）
   - `selectorStrategy: string`（可选，默认 optimize，选择器策略）
2. **命令示例**：含 5 种参数组合示例
3. **关键交互点表**：5 个交互点（相似用例提示、完成信号、用例命名、优化摘要确认、继续/结束选择）
4. **启动提示模板**：含操作指引和本次会话参数展示

#### 交付物

- `auto-test-record.md` 参数定义节、交互点表、命令示例节

#### 验证步骤

- [ ] **V2.2.1** 录制命令文件包含新增参数定义 → 含 tags/dataParam/pageMapFile/selectorStrategy 四个参数
  `grep -c "tags\|dataParam\|pageMapFile\|selectorStrategy" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.2.2** 录制命令文件包含参数类型和默认值 → 每个参数含类型/必填/默认值列
  `grep -c "string.*可选\|boolean.*可选\|默认.*false\|默认.*optimize" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.2.3** 录制命令文件包含命令示例 → 含至少 5 种参数组合示例
  `grep -c "/auto-test-record" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.2.4** 录制命令文件包含关键交互点表 → 含 5 个交互点及触发条件/用户操作/AI响应
  `grep -c "交互点\|触发条件\|用户操作\|AI.*响应" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.2.5** 录制命令文件包含启动提示模板 → 含操作指引和会话参数展示格式
  `grep -c "录制会话已启动\|操作指引\|本次会话参数" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`

---

### 任务 2.3: 完成断点后处理流程定义

#### 核心逻辑

在重构后的 `auto-test-record.md` 中详细定义 Step 5（后处理）和 Step 6（优化摘要展示）的完整内容：

1. **Step 5 后处理 8 个子步骤**：
   - 5a. 提取操作序列（与当前 Step 3 一致）
   - 5b. 选择器优化（引用 selector-optimization-spec 规则）
   - 5c. 断言推断（引用 assertion-inference-spec 规则，四类推断）
   - 5d. 步骤优化（引用 step-optimization-spec 规则）
   - 5e. 数据参数化（dataParam=true 时执行，引用 parameterization-spec 规则）
   - 5f. 元数据增强（recordedAt/duration/pageTitle/pageStructure/viewportActual/frontFramework）
   - 5g. 多页面/弹窗标记（pageContext/pageTransition 字段填充）
   - 5h. Stage 划分与 YAML 组装
2. **Step 6 优化摘要展示 4 区块模板**：
   - 1️⃣ 选择器优化区块（表格含原始→优化后→稳定性变化）
   - 2️⃣ 断言推断区块（表格含类型/target/expected/置信度/推断来源）
   - 3️⃣ 步骤优化区块（表格含优化类型/数量/说明）
   - 4️⃣ 数据参数化区块（表格含参数名/默认值/原始步骤 + 关闭标注）
3. **确认操作指引**：输入"继续"或"/end"

#### 交付物

- `auto-test-record.md` Step 5 和 Step 6 的完整定义

#### 验证步骤

- [ ] **V2.3.1** 录制命令 Step 5 包含 8 个子步骤 → 含 5a~5h 子步骤标题
  `grep -c "5a\|5b\|5c\|5d\|5e\|5f\|5g\|5h" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.3.2** Step 5b 引用选择器优化规范 → 含对 selector-optimization-spec 的引用
  `grep -c "selector-optimization\|选择器优化.*规范\|引用.*spec" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.3.3** Step 5c 引用断言推断规范 → 含对 assertion-inference-spec 的引用
  `grep -c "assertion-inference\|断言推断.*规范\|A1.*A2.*A4.*A6" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.3.4** Step 6 包含 4 区块摘要展示模板 → 含选择器/断言/步骤/参数化 4 个区块
  `grep -c "选择器优化\|断言推断\|步骤优化\|数据参数化\|优化摘要" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.3.5** Step 6 断言推断区块含置信度列 → 表格模板含 confidence 列
  `grep -c "置信度\|confidence" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V2.3.6** Step 6 包含确认操作指引 → 含"继续"和"/end"选择说明
  `grep -c "继续\|/end\|确认操作" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`

---

## Phase 3: 端到端验证 — 录制产出物质量校验

### 目标

通过实际录制会话验证重构后的录制命令和四个引擎规范是否协同工作，产出合规的 YAML 用例文件。

---

### 任务 3.1: 逐用例录制端到端验证

#### 核心逻辑

执行完整的逐用例录制会话，验证：

1. **会话初始化**：相似用例检测提示、浏览器启动、Codegen启动
2. **逐用例循环**：录制→`/next`→命名→后处理→摘要→保存→Codegen重启→继续/结束
3. **YAML 产出合规**：用例文件含完整 metadata（增强字段）、stages、source:record
4. **会话摘要**：表格含用例名称/步骤数/断言数/选择器优化/保存路径

#### 交付物

- 至少 2 个录制产出的 YAML 用例文件（如 `user-login-test.yaml`、`user-search-test.yaml`）
- 会话摘要输出

#### 验证步骤

- [ ] **V3.1.1** 启动录制会话 → 浏览器窗口打开，提示信息含逐用例模式操作指引
  `/auto-test-record url=http://localhost:3000`
- [ ] **V3.1.2** 录制第一条用例操作后输入 `/next` → AI 提示命名用例，进入完成断点处理
  （在 IDE 输入 `/next`）
- [ ] **V3.1.3** 指定用例名称 → 名称校验通过，进入后处理流程
  （输入用例名称如 `user-login-test`）
- [ ] **V3.1.4** 后处理完成后优化摘要展示 → 4区块摘要正常显示
  （查看 AI 输出的优化摘要）
- [ ] **V3.1.5** 用例 YAML 文件保存成功 → 文件存在于 `.asdm/workspace/auto-test/cases/` 目录
  `ls .asdm/workspace/auto-test/cases/user-login-test.yaml`
- [ ] **V3.1.6** Codegen 重启后继续录制第二条用例 → 浏览器保持，新用例录制正常
  （继续操作并输入 `/next`）
- [ ] **V3.1.7** 输入 `/end` 结束会话 → 会话摘要正常输出，浏览器关闭
  （在 IDE 输入 `/end`）

---

### 任务 3.2: 选择器优化与断言推断验证

#### 核心逻辑

验证选择器优化引擎和断言推断引擎在录制后处理中的效果：

1. **选择器优化**：录制含 nth-child/动态ID 的操作 → 优化摘要中展示原始→优化后选择器对比
2. **断言推断**：录制含 navigate/click/type 操作 → 推断 A1+A2+A4+A6 断言并标注置信度
3. **优化摘要展示**：选择器优化区块和断言推断区块正常渲染

#### 交付物

- 含优化后选择器和推断断言的 YAML 用例文件

#### 验证步骤

- [ ] **V3.2.1** 录制含不稳定选择器（如 nth-child）的操作 → 优化摘要中展示优化对比
  （录制含表单填写的页面操作）
- [ ] **V3.2.2** YAML 用例文件的选择器字段不含 nth-child → 优化后选择器为语义化选择器
  `grep -c "nth-child" .asdm/workspace/auto-test/cases/*.yaml`
  （预期结果：0 或仅在注释中出现）
- [ ] **V3.2.3** 录制含 navigate 操作 → 断言推断含 A1（页面可见）和 A2（URL跳转）
  （录制含页面跳转的操作序列）
- [ ] **V3.2.4** 录制含 type 操作 → 断言推断含 A6（表单值验证）和 A4（内容匹配）
  （录制含表单输入的操作序列）
- [ ] **V3.2.5** 推断断言含 confidence 和 inferredFrom 字段 → YAML 文件中每条推断断言有标注
  `grep -c "confidence:" .asdm/workspace/auto-test/cases/*.yaml`
  （预期结果：≥1）
- [ ] **V3.2.6** 优化摘要的选择器区块含稳定性变化标注 → 展示 ❌低→✅高 或 ⚠️中
  （查看 AI 输出的优化摘要 1️⃣ 区块）

---

### 任务 3.3: 数据参数化与多页面录制验证

#### 核心逻辑

验证 `dataParam=true` 时的参数化提取和多页面/弹窗录制功能：

1. **数据参数化**：`dataParam=true` → 录制含表单填写 → 硬编码数据提取为 params 变量 → 步骤 value 使用 `{{params.xxx}}` 引用
2. **多页面/弹窗**：录制含新标签页/弹窗操作 → YAML 中标记 pageContext 和 pageTransition
3. **参数化摘要展示**：4️⃣ 区块含参数名/默认值/原始步骤表格

#### 交付物

- 含 params 字段的参数化 YAML 用例文件
- 含 pageContext/pageTransition 字段的多页面 YAML 用例文件

#### 验证步骤

- [ ] **V3.3.1** 以 `dataParam=true` 启动录制 → 后处理执行参数化提取
  `/auto-test-record url=http://localhost:3000 dataParam=true`
- [ ] **V3.3.2** YAML 用例文件含 `params` 顶层字段 → 参数映射存在
  `grep -c "^params:" .asdm/workspace/auto-test/cases/*.yaml`
  （预期结果：≥1）
- [ ] **V3.3.3** 步骤 value 使用 `{{params.xxx}}` 引用 → 硬编码值已替换为参数引用
  `grep -c "{{params" .asdm/workspace/auto-test/cases/*.yaml`
  （预期结果：≥1）
- [ ] **V3.3.4** 优化摘要 4️⃣ 区块展示参数化表格 → 含参数名/默认值/原始步骤列
  （查看 AI 输出的优化摘要数据参数化区块）
- [ ] **V3.3.5** 录制含新标签页打开的操作 → YAML 中有 `pageTransition: new-tab` 和 `pageContext: newTab` 标记
  （录制含链接点击打开新标签页的操作）
- [ ] **V3.3.6** YAML 用例文件含 pageContext/pageTransition 字段 → 多页面标记正确
  `grep -c "pageContext\|pageTransition" .asdm/workspace/auto-test/cases/*.yaml`
  （预期结果：≥1）
- [ ] **V3.3.7** 以 `dataParam=false`（默认）启动录制 → 输入值硬编码，优化摘要标注"参数化已关闭"
  `/auto-test-record url=http://localhost:3000`
  （预期结果：YAML 中无 params 字段，摘要标注参数化关闭）

---

## 实施顺序建议

1. P1 任务 1.1 → DSL Spec 扩展（所有其他规范和命令依赖此基础）
2. P1 任务 1.2~1.5 → 四个引擎规范文件（可并行编写）
3. P2 任务 2.1 → 录制命令主体流程重构
4. P2 任务 2.2 → 录制命令参数与交互点定义
5. P2 任务 2.3 → 后处理与优化摘要流程定义
6. P3 任务 3.1 → 逐用例录制端到端验证
7. P3 任务 3.2 → 选择器优化与断言推断验证
8. P3 任务 3.3 → 参数化与多页面验证

## 风险与挑战

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| DSL 扩展字段与 FT-003 执行引擎不兼容 | 录制产出的 YAML 用例无法被执行引擎正确解析 | 在 DSL Spec 中标注新增字段为"可选"，执行引擎遇到未知字段时忽略而非报错 |
| 选择器优化规则在特定页面结构下无法找到稳定替代 | 优化后的选择器仍然不稳定 | 定义 fallback 策略：无法优化时保留原始选择器并在摘要中标注"无法优化"，建议用户手动指定 |
| 断言推断置信度评分过于主观 | 推断结果不可靠，误导用户 | 置信度评分基于确定性规则（如 data-testid→高、body→低），而非主观判断；低置信度断言建议用户删除 |
| 逐用例录制 `/next`/`/end` 信号在 IDE 中无法正确识别 | 录制流程无法推进 | 在 Action 文件中明确信号格式（`/next` 和 `/end` 为精确匹配），并提供超时兜底（5分钟无操作自动暂停） |
| pageMapFile 映射文件格式过于复杂 | 用户不愿使用映射文件 | 映射文件为完全可选，不提供时使用页面结构动态推断；格式尽量简单（URL→选择器一行映射） |

## 变更模块总览

| 变更模块 | 涉及Phase | 核心变更 |
|----------|:---------:|----------|
| `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md` | P1 | 扩展 params/pageContext/pageTransition/confidence/inferredFrom/metadata 字段 + 校验规则 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md` | P1 | 新增选择器优化引擎规范 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md` | P1 | 新增断言推断引擎规范 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md` | P1 | 新增步骤优化引擎规范 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md` | P1 | 新增数据参数化规范 |
| `.asdm/toolsets/web-auto-tester/actions/auto-test-record.md` | P2 | 重写为 8 步骤逐用例会话流程 |
| `.asdm/workspace/auto-test/cases/` | P3 | 录制产出的 YAML 用例文件 |
