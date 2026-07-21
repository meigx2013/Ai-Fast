# FT-003 Web Auto Tester 实施计划

## 项目概述

将 FT-003 Web Auto Tester 特性设计文档拆解为可执行的实施计划，核心工作项：

1. 创建工具集骨架（manifest.json + README.md + INSTALL.md）和 YAML DSL 规范
2. 实现最小闭环：手动编写 YAML DSL 用例 → Playwright 执行 → 结果记录 + 失败截图
3. 扩展用例生成方式：需求文档 AI 生成 + Playwright Codegen 录制
4. 增强输出能力：HTML 自定义报告 + Allure 导出 + Selenium 辅框架适配
5. 运维命令：清理/列表命令

### 前置依赖

- `web-smoke-tester` 工具集（规范风格参考，非硬依赖）
- `release-note` 工具集（manifest.json 和 Action 文件格式参考）
- Playwright npm 包（执行引擎运行依赖）
- Node.js 18+（运行环境）

### 后续依赖

- 无（当前无其他特性依赖本特性）

---

## 进度概要

| Phase | 任务 | 状态 | 交付物 |
|-------|------|:----:|--------|
| **P1: 工具集骨架与 DSL 规范** | 1.1 工具集元数据注册与入口文档 | ✅ | manifest.json, README.md, INSTALL.md |
| | 1.2 YAML DSL 用例格式规范 | ✅ | auto-test-dsl-spec.md |
| | 1.3 工作区目录结构与命令快捷入口 | ✅ | workspace 目录, 6 个 Follow 文件 |
| **P2: 手动用例→执行→结果闭环** | 2.1 执行引擎 Action 与 7 阶段规范 | ✅ | auto-test-run.md, execution-spec.md |
| | 2.2 手动编写用例端到端验证 | ✅ | user-login-test.yaml, admin-login-test.yaml |
| | 2.3 结果记录与列表命令 | ✅ | auto-test-list.md |
| **P3: 用例生成扩展** | 3.1 需求文档 AI 生成用例命令 | ✅ | auto-test-generate.md |
| | 3.2 Playwright Codegen 录制用例命令 | ✅ | auto-test-record.md |
| **P4: 报告与截图增强** | 4.1 HTML 自定义报告生成命令与规范 | ✅ | auto-test-report.md, report-spec.md |
| | 4.2 Selenium 辅框架适配与双框架执行 | ✅ | execution-spec Selenium 适配章节, admin-login-selenium.yaml |
| **P5: 运维命令** | 5.1 清理资源命令 | ✅ | auto-test-clean.md |

---

## Phase 1: 工具集骨架与 DSL 规范

### 目标

创建工具集的完整骨架文件和 YAML DSL 用例格式规范，为后续所有命令开发提供基础支撑。

### 任务 1.1: 工具集元数据注册与入口文档

#### 核心逻辑

创建 `web-auto-tester` 工具集的三件入口文件，遵循 `release-note` 工具集的标准格式：

1. **manifest.json**：全局唯一 GUID、registry_id=`web-auto-tester`、name=`Web Auto Tester Toolset`、version=`0.0.2`、configType=`toolset`、commands 数组包含 6 个命令名
2. **README.md**：Header 元数据（toolset-id/name/version/description）→ Overview → Features（6个命令）→ Workflow → Structure → Spec Documents → Workspace → Copyright
3. **INSTALL.md**：Overview → 安装步骤（创建工作区目录→检测 AI 引擎可用性→注册 6 个命令→验证）→ Verification → Usage Examples → Notes

#### 交付物

- `.asdm/toolsets/web-auto-tester/manifest.json`
- `.asdm/toolsets/web-auto-tester/README.md`
- `.asdm/toolsets/web-auto-tester/INSTALL.md`

#### 验证步骤

- [ ] **V1.1.1** manifest.json 格式校验通过 → JSON 解析无错、guid 唯一、registry_id 正确
  `cat .asdm/toolsets/web-auto-tester/manifest.json | python -m json.tool`
- [ ] **V1.1.2** manifest.json commands 字段包含6个命令名 → 数组长度为6且与 action 文件名对应
  `cat .asdm/toolsets/web-auto-tester/manifest.json | python -m json.tool | grep -c "auto-test"`
- [ ] **V1.1.3** README.md 包含完整章节结构 → Header + Overview + Features + Workflow + Structure + Spec + Workspace
  `grep -c "^##" .asdm/toolsets/web-auto-tester/README.md`
- [ ] **V1.1.4** INSTALL.md 包含安装步骤和验证 → 检测引擎→注册命令→验证→示例完整
  `grep "创建工作区" .asdm/toolsets/web-auto-tester/INSTALL.md`
- [ ] **V1.1.5** manifest/README/INSTALL 三文件一致性 → registry_id=toolset-id、name=toolset-name、commands 与 Features 一一对应
  `diff <(cat manifest.json | python -m json.tool | grep registry_id) <(grep "toolset-id" README.md)`
- [ ] **V1.1.6** 工具集目录存在且结构完整 → manifest.json + README.md + INSTALL.md + actions/ + spec/ 目录均存在
  `ls .asdm/toolsets/web-auto-tester/`

---

### 任务 1.2: YAML DSL 用例格式规范

#### 核心逻辑

编写 `auto-test-dsl-spec.md`，定义 YAML DSL 用例的完整格式规范。内容基于 Detailed 文档 §4（YAML DSL 规范）的详细定义，包括：

1. 用例文件顶层结构（name/description/framework/capture/tags/metadata/stages）
2. Stage 与 Step 定义（action/target/value/capture/timeout/assertions）
3. 断言定义（A1~A8 类型、target/expected/message）
4. 框架标记与捕获配置（framework/frameworkOverride/capture/on-fail/full/always）
5. 用例示例（Playwright 登录测试 + Selenium 简化登录测试）
6. 与 smoke-tester Pipeline YAML 的风格一致性说明

#### 交付物

- `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`

#### 验证步骤

- [ ] **V1.2.1** DSL spec 文件存在且内容完整 → 包含顶层结构/Stage/Step/Assertion/框架标记/捕获配置章节
  `grep -c "^##" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.2.2** DSL spec 包含 Playwright 用例示例 → YAML 示例含 framework: playwright
  `grep "framework: playwright" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.2.3** DSL spec 包含 Selenium 用例示例 → YAML 示例含 framework: selenium
  `grep "framework: selenium" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.2.4** DSL spec 定义8种断言类型 → A1~A8 全部列举
  `grep -c "^| A[1-8]" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.2.5** DSL spec 包含数据模型字段表 → AutoTestCase/AutoTestResult 模型字段完整
  `grep "ATC-" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
- [ ] **V1.2.6** DSL spec 与 smoke-tester 风格一致性说明 → 提及 Pipeline YAML 风格延续
  `grep "smoke-tester" .asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`

---

### 任务 1.3: 工作区目录结构与命令快捷入口

#### 配置要点

| 配置项 | 值 | 说明 |
|--------|------|------|
| workspace 根目录 | `.asdm/workspace/auto-test/` | 测试工作区路径 |
| cases 目录 | `cases/` | 用例 YAML 存放 |
| results 目录 | `results/` | 执行结果 JSON 存放 |
| reports 目录 | `reports/` | HTML 报告存放 |
| screenshots 目录 | `screenshots/` | 截图文件存放 |
| 命令文件格式 | `Follow .asdm/toolsets/web-auto-tester/actions/{action-name}.md` | CodeBuddy 格式 |

#### 交付物

- `.asdm/workspace/auto-test/` 目录结构（含 4 个子目录 + .gitkeep）
- `.codebuddy/commands/auto-test-generate.md`
- `.codebuddy/commands/auto-test-record.md`
- `.codebuddy/commands/auto-test-run.md`
- `.codebuddy/commands/auto-test-list.md`
- `.codebuddy/commands/auto-test-report.md`
- `.codebuddy/commands/auto-test-clean.md`

#### 验证步骤

- [ ] **V1.3.1** 工作区目录4个子目录存在 → cases/results/reports/screenshots 目录均存在
  `ls .asdm/workspace/auto-test/`
- [ ] **V1.3.2** 每个子目录含 .gitkeep → 4 个 .gitkeep 文件存在
  `find .asdm/workspace/auto-test -name ".gitkeep" | wc -l`
- [ ] **V1.3.3** 6个命令快捷入口文件存在 → auto-test-generate/record/run/list/report/clean
  `ls .codebuddy/commands/auto-test-*.md | wc -l`
- [ ] **V1.3.4** 每个命令文件内容为 Follow 指向 → 格式正确且路径指向 web-auto-tester/actions/
  `head -1 .codebuddy/commands/auto-test-run.md`
- [ ] **V1.3.5** 命令文件名与 Follow 路径一致 → 文件名与 action 文件名一一对应
  `grep "Follow" .codebuddy/commands/auto-test-run.md`

---

## Phase 2: 手动用例→执行→结果闭环

### 目标

实现最短的可验证闭环：用户手动编写 YAML DSL 用例 → 执行 `/auto-test-run` → 生成执行结果 JSON + 失败截图 → 执行 `/auto-test-list` 查看结果。此 Phase 完成后，核心能力已端到端可用。

### 任务 2.1: 执行引擎 Action 与 7 阶段规范

#### 核心逻辑

创建两个核心文件：

1. **auto-test-run.md（Action 文件）**：定义 `/auto-test-run` 命令的完整流程，包括 Metadata JSON 块、Purpose、Language Setting、Context Injection（引用 execution-spec 和 dsl-spec）、Steps（7 阶段执行流程）、Execution Guidelines、Usage、Output Summary

2. **auto-test-execution-spec.md（Spec 文件）**：定义执行引擎的 7 阶段规范：
   - Phase 1 用例加载：YAML 解析 → schema 校验 → AutoTestCase 结构化
   - Phase 2 上下文准备：读取 metadata（targetUrl/timeout/browser/viewport/auth）→ 初始化浏览器选项
   - Phase 3 执行引擎：Playwright 主引擎操作映射（9 种操作类型 API 对应）→ Step 逐个执行 → 异常捕获
   - Phase 4 断言判定：8 种断言类型（A1~A8）→ 结果映射（pass/fail/error/skip）
   - Phase 5 截图采集：on-fail/full/always 三策略 → 文件命名规则 → 存储路径
   - Phase 6 结果记录：AutoTestResult JSON 生成 → ID 规则 ATR-{YYYYMMDD}-{NNN} → 持久化到 results/
   - Phase 7 报告输出：简要摘要输出（详细 HTML 报告在 P4 实现）

#### 交付物

- `.asdm/toolsets/web-auto-tester/actions/auto-test-run.md`
- `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`

#### 验证步骤

- [ ] **V2.1.1** auto-test-run.md Action 文件存在且格式完整 → Metadata + Purpose + Context + Steps + Guidelines + Usage + Output
  `grep -c "^##" .asdm/toolsets/web-auto-tester/actions/auto-test-run.md`
- [ ] **V2.1.2** Action 的 toolset.guid 与 manifest.json guid 一致 → 三处 GUID 相同
  `grep "guid" .asdm/toolsets/web-auto-tester/actions/auto-test-run.md`
- [ ] **V2.1.3** execution-spec 定义7个 Phase → Phase 1~7 全部覆盖
  `grep -c "^### Phase" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V2.1.4** execution-spec 包含 Playwright 操作映射表 → 9 种操作类型 API 对应
  `grep "page.goto" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V2.1.5** execution-spec 包含8种断言类型 → A1~A8 定义
  `grep -c "A[1-8]" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V2.1.6** execution-spec 包含截图策略 → on-fail/full/always 三策略 + 文件命名
  `grep "ATR-" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V2.1.7** execution-spec 包含 ID 生成规则 → ATR-{YYYYMMDD}-{NNN} 格式定义
  `grep "ATR-{YYYYMMDD}" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V2.1.8** execution-spec 包含框架选择策略 → framework 字段 → 引擎适配逻辑
  `grep "framework" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`

---

### 任务 2.2: 手动编写用例端到端验证

#### 核心逻辑

通过实际手动编写 YAML DSL 用例并执行，验证 P2 闭环的完整可用性：

1. 编写 Playwright 登录测试用例 `user-login-test.yaml`（基于 Detailed 文档 §4.6 示例）
2. 编写 Admin 登录测试用例 `admin-login-test.yaml`
3. 通过 `/auto-test-run` 命令执行用例，验证：
   - YAML 解析成功（Phase 1）
   - 浏览器启动并执行步骤（Phase 2-3）
   - 断言判定正确（Phase 4）
   - 失败步骤截图生成（Phase 5）
   - 结果 JSON 持久化（Phase 6）
   - 摘要输出正确（Phase 7）

#### 交付物

- `.asdm/workspace/auto-test/cases/user-login-test.yaml`
- `.asdm/workspace/auto-test/cases/admin-login-test.yaml`
- 验证通过的执行结果 JSON（至少1个 ATR 文件）

#### 验证步骤

- [ ] **V2.2.1** 用例 YAML 文件语法正确 → YAML 解析无错
  `python -c "import yaml; yaml.safe_load(open('.asdm/workspace/auto-test/cases/user-login-test.yaml'))"`
- [ ] **V2.2.2** 用例符合 DSL spec schema → 包含 name/framework/stages 等必填字段
  `grep "name:" .asdm/workspace/auto-test/cases/user-login-test.yaml`
- [ ] **V2.2.3** 执行 `/auto-test-run` 后生成结果 JSON → results/ 目录出现 ATR-{date}-*.json
  `ls .asdm/workspace/auto-test/results/`
- [ ] **V2.2.4** 结果 JSON 包含完整字段 → id/testCaseId/status/totalSteps/stepResults 全部存在
  `cat .asdm/workspace/auto-test/results/ATR-*.json | python -m json.tool | grep "testCaseId"`
- [ ] **V2.2.5** 失败步骤生成截图 → screenshots/ 目录出现截图文件（如有失败步骤）
  `ls .asdm/workspace/auto-test/screenshots/`
- [ ] **V2.2.6** Admin 登录用例使用 Selenium 选择器格式 → css= 前缀选择器
  `grep "css=" .asdm/workspace/auto-test/cases/admin-login-test.yaml`

---

### 任务 2.3: 结果记录与列表命令

#### 核心逻辑

创建 `/auto-test-list` 命令的 Action 文件，定义结果和用例的查询与展示能力：

1. **auto-test-list.md（Action 文件）**：Metadata + Purpose + Context Injection + Steps（读取 cases/ 或 results/ → 解析 JSON/YAML → 按筛选条件过滤 → 格式化 Markdown 表格输出）+ Guidelines + Usage + Output

2. 列表命令支持三种展示模式：
   - `type=cases`：列出 cases/ 目录下所有 YAML 用例（名称/框架/标签/来源/创建时间）
   - `type=results`：列出 results/ 目录下所有执行结果（ID/用例名/状态/步骤数/耗时/时间）
   - `type=all`：合并展示

#### 交付物

- `.asdm/toolsets/web-auto-tester/actions/auto-test-list.md`

#### 验证步骤

- [ ] **V2.3.1** auto-test-list.md Action 文件存在且格式完整 → Metadata + Steps + Output 全部章节
  `grep -c "^##" .asdm/toolsets/web-auto-tester/actions/auto-test-list.md`
- [ ] **V2.3.2** Action 定义三种列表模式 → cases/results/all
  `grep "type=" .asdm/toolsets/web-auto-tester/actions/auto-test-list.md`
- [ ] **V2.3.3** 执行 `/auto-test-list type=results` → 输出 Markdown 表格含最近执行结果
  （手动验证：执行命令后检查输出格式）
- [ ] **V2.3.4** 执行 `/auto-test-list type=cases` → 输出 Markdown 表格含所有用例
  （手动验证：执行命令后检查输出格式）
- [ ] **V2.3.5** 筛选过滤功能 → 按 tag/framework/status 筛选结果正确
  （手动验证：带 filter 参数执行命令）

---

## Phase 3: 用例生成扩展

### 目标

扩展用例生成方式，实现需求文档 AI 生成和 Playwright Codegen 录制两种用例生成命令。完成后，用户可通过三种方式获取测试用例。

### 任务 3.1: 需求文档 AI 生成用例命令

#### 核心逻辑

创建 `/auto-test-generate` 命令的 Action 文件，定义从 Markdown 需求文档自动生成 YAML DSL 测试用例的完整流程：

1. **auto-test-generate.md（Action 文件）**：Metadata + Purpose + Context Injection（引用 dsl-spec）+ Steps：
   - Step 1：读取 Markdown 文档，提取功能描述段落和验收标准
   - Step 2：为每个功能点生成 1-N 个测试场景（正向/逆向/边界值）
   - Step 3：将场景转换为 YAML DSL stages/steps 结构
   - Step 4：为每个 step 自动推断断言（基于验收标准）
   - Step 5：标记框架偏好（默认 playwright）和截图配置（默认 on-fail）
   - Step 6：输出 YAML 文件并提示用户审核
2. 输入参数：document（Markdown 文档内容或路径）、framework（默认 playwright）、outputDir（默认 cases/）
3. 输出：YAML DSL 用例文件列表

#### 交付物

- `.asdm/toolsets/web-auto-tester/actions/auto-test-generate.md`

#### 验证步骤

- [ ] **V3.1.1** auto-test-generate.md Action 文件存在且格式完整 → Metadata + Steps + Output
  `grep -c "^##" .asdm/toolsets/web-auto-tester/actions/auto-test-generate.md`
- [ ] **V3.1.2** Action 定义需求文档解析步骤 → 提取功能描述 + 验收标准
  `grep "Markdown" .asdm/toolsets/web-auto-tester/actions/auto-test-generate.md`
- [ ] **V3.1.3** Action 定义场景生成策略 → 正向/逆向/边界值覆盖
  `grep "边界值" .asdm/toolsets/web-auto-tester/actions/auto-test-generate.md`
- [ ] **V3.1.4** Action 定义 YAML DSL 转换步骤 → stages/steps + 断言推断
  `grep "YAML DSL" .asdm/toolsets/web-auto-tester/actions/auto-test-generate.md`
- [ ] **V3.1.5** 执行 `/auto-test-generate` 传入 Markdown PRD → 输出 YAML 用例文件且格式符合 dsl-spec
  （手动验证：提供 PRD 文档执行命令，检查生成的 YAML）
- [ ] **V3.1.6** 生成的用例包含 source: generate 标记 → 用例来源可追溯
  `grep "source: generate" .asdm/workspace/auto-test/cases/*.yaml`

---

### 任务 3.2: Playwright Codegen 录制用例命令

#### 核心逻辑

创建 `/auto-test-record` 命令的 Action 文件，定义通过 Playwright Codegen 录制操作生成 YAML DSL 测试用例的流程：

1. **auto-test-record.md（Action 文件）**：Metadata + Purpose + Context Injection（引用 dsl-spec）+ Steps：
   - Step 1：启动 `npx playwright codegen {url}` 命令，打开目标页面
   - Step 2：用户在浏览器中操作，Codegen 实时录制
   - Step 3：录制结束后提取操作序列（click/type/navigate/wait）
   - Step 4：转换为 YAML DSL Step 格式，按操作类型映射
   - Step 5：对每个导航步骤自动添加页面可见断言（A1）
   - Step 6：输出 YAML 文件并提示用户补充断言和截图配置
2. 输入参数：url（目标 URL）、framework（默认 playwright）、browser（默认 chromium）
3. 输出：YAML DSL 用例文件

#### 交付物

- `.asdm/toolsets/web-auto-tester/actions/auto-test-record.md`

#### 验证步骤

- [ ] **V3.2.1** auto-test-record.md Action 文件存在且格式完整 → Metadata + Steps + Output
  `grep -c "^##" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V3.2.2** Action 定义 Codegen 启动步骤 → npx playwright codegen {url}
  `grep "playwright codegen" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V3.2.3** Action 定义录制转换步骤 → 操作序列 → YAML DSL Step 格式
  `grep "YAML DSL" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V3.2.4** Action 定义自动断言添加 → 导航步骤自动添加 A1 页面可见断言
  `grep "A1" .asdm/toolsets/web-auto-tester/actions/auto-test-record.md`
- [ ] **V3.2.5** 执行 `/auto-test-record url=http://localhost:3000` → 录制器启动且生成 YAML 用例
  （手动验证：执行命令后在浏览器操作，检查生成的 YAML）
- [ ] **V3.2.6** 录制生成的用例包含 source: record 标记 → 用例来源可追溯
  `grep "source: record" .asdm/workspace/auto-test/cases/*.yaml`

---

## Phase 4: 报告与截图增强

### 目标

增强输出能力：实现 HTML 自定义报告生成 + Allure 可选导出，以及 Selenium 辅框架适配。完成后用户可获取专业可视化报告，且 Selenium 用例可执行。

### 任务 4.1: HTML 自定义报告生成命令与规范

#### 核心逻辑

创建 `/auto-test-report` 命令的 Action 文件和报告格式规范：

1. **auto-test-report.md（Action 文件）**：Metadata + Purpose + Context Injection（引用 report-spec 和 execution-spec）+ Steps：
   - Step 1：读取执行结果 JSON（单个或目录）
   - Step 2：计算摘要数据（通过率/失败数/跳过数/总步骤/执行时间）
   - Step 3：生成 HTML 报告结构：
     - 摘要卡片：渐变背景 + 大数字展示
     - 用例列表：状态色标签（绿/红/灰）
     - 步骤详情：折叠面板 + 失败步骤红色高亮
     - 截图展示：内嵌失败/标记步骤截图 + 缩略图 + 点击放大
     - 统计图表：ASCII 图表展示通过率和断言分布
   - Step 4：可选 Allure 导出（转换 JSON → Allure 格式 → 调用 allure generate）
   - Step 5：保存 HTML 报告到 reports/ 目录

2. **auto-test-report-spec.md（Spec 文件）**：定义报告的完整格式规范：
   - HTML 报告模板结构（卡片 + 列表 + 详情 + 截图 + 统计）
   - Allure 导出流程规范
   - CSS 样式规范（卡片渐变/状态色/折叠面板）
   - 截图内嵌方式

#### 交付物

- `.asdm/toolsets/web-auto-tester/actions/auto-test-report.md`
- `.asdm/toolsets/web-auto-tester/spec/auto-test-report-spec.md`

#### 验证步骤

- [ ] **V4.1.1** auto-test-report.md Action 文件存在且格式完整 → Metadata + Steps + Output
  `grep -c "^##" .asdm/toolsets/web-auto-tester/actions/auto-test-report.md`
- [ ] **V4.1.2** report-spec 定义 HTML 报告模板 → 摘要卡片 + 用例列表 + 步骤详情 + 截图 + 统计
  `grep -c "^##" .asdm/toolsets/web-auto-tester/spec/auto-test-report-spec.md`
- [ ] **V4.1.3** report-spec 包含 CSS 样式规范 → 卡片渐变/状态色/折叠面板定义
  `grep "渐变" .asdm/toolsets/web-auto-tester/spec/auto-test-report-spec.md`
- [ ] **V4.1.4** report-spec 包含 Allure 导出流程 → JSON 转换 + allure generate
  `grep "allure" .asdm/toolsets/web-auto-tester/spec/auto-test-report-spec.md`
- [ ] **V4.1.5** 执行 `/auto-test-report` → 生成 HTML 文件且包含摘要卡片 + 截图内嵌
  （手动验证：执行命令后打开 HTML 报告检查）
- [ ] **V4.1.6** HTML 报告文件保存到 reports/ 目录 → 报告文件路径正确
  `ls .asdm/workspace/auto-test/reports/*.html`

---

### 任务 4.2: Selenium 辅框架适配与双框架执行

#### 核心逻辑

在 execution-spec.md 中新增 Selenium 辅引擎适配章节，实现双框架执行能力：

1. Selenium 操作映射表（9 种基础操作 API 对应）
2. Selenium 断言适配（A1~A7 支持，A5/A8 不支持说明）
3. Selenium 截图限制（仅全页截图，不支持元素级和 tracing）
4. 框架选择策略（framework 字段 → 引擎适配逻辑）
5. 降级策略（Selenium 用例含 Playwright 专有操作时降级为 playwright + 提示）
6. CSS 选择器前缀约定（`css=` 前缀用于 Selenium 用例的 SelectorStrategy）

同时编写 Selenium 用例示例验证双框架执行闭环。

#### 交付物

- 更新 `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`（新增 Selenium 适配章节）
- `.asdm/workspace/auto-test/cases/admin-login-selenium.yaml`（Selenium 示例用例）

#### 验证步骤

- [ ] **V4.2.1** execution-spec 包含 Selenium 适配章节 → Selenium 操作映射表
  `grep "Selenium" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V4.2.2** Selenium 操作映射覆盖9种基础操作 → navigate/click/type/wait/scroll/screenshot/hover/select/assert
  `grep -c "driver\." .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V4.2.3** Selenium 断言适配说明 → A1~A7 支持 + A5/A8 不支持说明
  `grep "A5" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V4.2.4** 降级策略定义 → framework 字段 + 降级提示逻辑
  `grep "降级" .asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
- [ ] **V4.2.5** Selenium 示例用例 YAML 存在 → framework: selenium + css= 选择器
  `cat .asdm/workspace/auto-test/cases/admin-login-selenium.yaml`
- [ ] **V4.2.6** 执行 `/auto-test-run` 对 Selenium 用例 → 结果 JSON 含 framework: selenium
  （手动验证：执行 Selenium 用例检查结果）

---

## Phase 5: 运维命令

### 目标

完成运维管理命令，使工具集功能完整闭环。用户可通过清理命令管理工作区。

### 任务 5.1: 清理资源命令

#### 核心逻辑

创建 `/auto-test-clean` 命令的 Action 文件，定义清理测试资源的完整流程：

1. **auto-test-clean.md（Action 文件）**：Metadata + Purpose + Steps：
   - Step 1：确认清理范围（results/reports/screenshots/all）
   - Step 2：列出将要删除的文件数量和大小
   - Step 3：用户确认后执行删除
   - Step 4：保留目录结构（不删除子目录本身和 .gitkeep）
   - Step 5：输出清理确认信息（删除文件数、释放空间）

#### 交付物

- `.asdm/toolsets/web-auto-tester/actions/auto-test-clean.md`

#### 验证步骤

- [ ] **V5.1.1** auto-test-clean.md Action 文件存在且格式完整 → Metadata + Steps + Output
  `grep -c "^##" .asdm/toolsets/web-auto-tester/actions/auto-test-clean.md`
- [ ] **V5.1.2** Action 定义4种清理范围 → results/reports/screenshots/all
  `grep "scope" .asdm/toolsets/web-auto-tester/actions/auto-test-clean.md`
- [ ] **V5.1.3** Action 定义确认机制 → 清理前列出文件数量和大小
  `grep "确认" .asdm/toolsets/web-auto-tester/actions/auto-test-clean.md`
- [ ] **V5.1.4** Action 定义保留目录结构 → 不删除子目录和 .gitkeep
  `grep ".gitkeep" .asdm/toolsets/web-auto-tester/actions/auto-test-clean.md`
- [ ] **V5.1.5** 执行 `/auto-test-clean scope=results` → results/ 目录下文件被清空但目录保留
  （手动验证：执行命令后检查目录状态）

---

## 实施顺序建议

1. **P1 任务 1.1**：工具集骨架 → 所有后续文件依赖此目录和元数据
2. **P1 任务 1.2**：DSL 规范 → 用例格式定义是执行引擎的前提
3. **P1 任务 1.3**：工作区和命令入口 → 物理基础设施
4. **P2 任务 2.1**：执行引擎 Action + Spec → 核心引擎定义
5. **P2 任务 2.2**：手动用例端到端验证 → 闭环验证
6. **P2 任务 2.3**：列表命令 → 结果查询
7. **P3 任务 3.1**：AI 生成命令 → 扩展生成方式
8. **P3 任务 3.2**：录制生成命令 → 扩展生成方式
9. **P4 任务 4.1**：报告命令 + Spec → 可视化输出
10. **P4 任务 4.2**：Selenium 适配 → 双框架能力
11. **P5 任务 5.1**：清理命令 → 运维完善

---

## 风险与挑战

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| YAML DSL 规范复杂度过高 | 用户学习成本大，手动编写意愿低 | 保持与 smoke-tester Pipeline YAML 风格一致，提供3个完整示例，AI 生成和录制降低手动编写需求 |
| Playwright Codegen 录制转 YAML 不精确 | 录制结果丢失操作细节或选择器不稳定 | 录制后提示用户审核和补充断言，使用稳定选择器策略 |
| Selenium 辅框架功能限制 | Selenium 用例能力少于 Playwright，用户可能困惑 | 在 DSL spec 明确标注 Selenium 限制（不支持 A5/A8/tracing/元素截图），降级时提示 |
| 规范驱动架构执行依赖 AI 能力 | AI Agent 理解 spec 的准确度决定执行质量 | spec 文件编写足够详细和结构化，提供完整示例和校验规则，降低 AI 解歧义难度 |
| HTML 报告内嵌截图体积过大 | 报告文件膨胀，加载缓慢 | 截图使用缩略图 + 点击放大模式，全尺寸图延迟加载，默认仅失败截图 |

---

## 变更模块总览

| 变更模块 | 涉及 Phase | 核心变更 |
|----------|-----------|----------|
| `.asdm/toolsets/web-auto-tester/manifest.json` | P1 | 工具集元数据注册 |
| `.asdm/toolsets/web-auto-tester/README.md` | P1 | 工具集入口文档 |
| `.asdm/toolsets/web-auto-tester/INSTALL.md` | P1 | 安装指南 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md` | P1 | YAML DSL 用例格式规范 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md` | P2, P4 | 执行引擎规范 + Selenium 适配 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-report-spec.md` | P4 | 报告格式规范 |
| `.asdm/toolsets/web-auto-tester/actions/auto-test-run.md` | P2 | 执行测试 Action |
| `.asdm/toolsets/web-auto-tester/actions/auto-test-list.md` | P2 | 列出结果 Action |
| `.asdm/toolsets/web-auto-tester/actions/auto-test-generate.md` | P3 | AI 生成用例 Action |
| `.asdm/toolsets/web-auto-tester/actions/auto-test-record.md` | P3 | 录制用例 Action |
| `.asdm/toolsets/web-auto-tester/actions/auto-test-report.md` | P4 | 报告生成 Action |
| `.asdm/toolsets/web-auto-tester/actions/auto-test-clean.md` | P5 | 清理资源 Action |
| `.codebuddy/commands/auto-test-*.md` | P1 | 6个命令快捷入口 |
| `.asdm/workspace/auto-test/` | P1, P2 | 工作区目录 + 示例用例 |
