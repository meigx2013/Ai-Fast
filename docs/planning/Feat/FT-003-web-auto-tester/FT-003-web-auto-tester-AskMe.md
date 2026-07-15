# FT-003 Web Auto Tester — 需求访谈追问

> 本文档记录对 FT-003 Web Auto Tester 特性的逐问题追问，用于澄清需求模糊点后制定最终特性规格。

**创建日期**：2026-07-10
**状态**：已完成

---

## 背景摘要

### 核心价值

设计并开发一款 ASDM 工具集 `web-auto-tester`，实现对 Web 系统的全面自动化测试。与现有的 `web-smoke-tester`（专注于冒烟测试、自然语言驱动）不同，本工具集定位为**正式自动化测试工具**，支持双框架（Selenium / Playwright）、三种用例生成方式（需求文档→用例、录制→用例、手动编写用例）、本地与 CI/CD 双执行环境、以及 HTML 测试报告+截图输出。

核心解决的问题：
- 测试用例编写成本高 → 需求文档自动生成 + 录制生成降低门槛
- 单框架局限 → 双框架支持（Selenium + Playwright）适应不同团队技术栈
- 手工执行效率低 → 本地自动化执行 + CI/CD 集成
- 测试结果不可追溯 → HTML 报告 + 截图持久化存储

### 变更范围

| 变更模块 | 变更内容 |
|----------|----------|
| `.asdm/toolsets/web-auto-tester/` | 新增工具集：manifest.json、README.md、INSTALL.md、actions/、spec/ |
| `.codebuddy/commands/` | 注册斜杠命令快捷入口 |
| `.asdm/workspace/auto-test/` | 新增工作区目录：测试用例、执行结果、报告 |

### 已澄清问题（来自需求描述）

| 编号 | 问题 | 澄清结论 |
|:----:|------|----------|
| Q1 | 支持哪些测试框架？ | Selenium 和 Playwright 双框架 |
| Q2 | 用例生成方式有哪些？ | 需求文档生成 + 录制生成 + 手动输入 |
| Q3 | 执行环境有哪些？ | 本地浏览器 + CI/CD（Jenkins、GitHub Actions 等） |
| Q4 | 报告格式？ | HTML 格式 + 截图 |

---

## 决策点

### 决策点 1：工具集定位与命名

**问题**：本工具集与现有 `web-smoke-tester` 的定位关系如何？是独立的新工具集还是对现有工具集的升级/扩展？

**背景**：
- 项目中已有 `web-smoke-tester` 工具集（4个命令：run/list/report/clear），专注于**冒烟测试**，自然语言驱动
- 用户需求明确要求"自动化测试工具集"，涵盖用例生成、双框架、CI/CD集成、HTML报告等，远超冒烟测试范畴
- 两者服务不同场景：smoke-tester = P0/P1 快速验证；auto-tester = 全面功能测试

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 独立新工具集 `web-auto-tester`，与 `web-smoke-tester` 互补共存 | 定位清晰、职责分离、不影响现有工具集；用户可按场景选择 | 两个测试工具集可能让用户困惑选择 |
| B | 升级 `web-smoke-tester`，在其基础上扩展全部功能 | 统一入口、无新工具集学习成本 | 冲突定位：smoke-tester 变得过于庞大，冒烟测试的轻量特性被稀释 |
| C | 新工具集 `web-auto-tester` 替代 `web-smoke-tester`，后续废弃 smoke-tester | 单一入口、避免重复 | 丧失冒烟测试的轻量便捷特性 |

**推荐**：✅ 选项 A — 独立新工具集 `web-auto-tester`，与 `web-smoke-tester` 互补共存

**确认理由**：
1. 两者定位不同：smoke-tester 轻量快速验证 P0/P1，auto-tester 全面自动化测试
2. 用户需求明确超出冒烟测试范畴（用例生成、双框架、CI/CD、HTML报告）
3. 保持 smoke-tester 的轻量特性，不被膨胀功能稀释

**状态**：✅ 已确认

---

### 决策点 2：测试框架优先级与双框架策略

**问题**：Selenium 和 Playwright 双框架如何支持？是同时等权支持还是以一个为主、另一个为辅？

**背景**：
- Selenium：业界成熟、社区庞大、语言支持广（Java/Python/JS/C#）、但 API 较老、无内置等待/截图/录制的现代化功能
- Playwright：微软出品、API 现代化、内置 auto-wait/tracing/screenshots/codegen、但社区较新、仅支持 JS/Python/Java/C#
- 双框架"等权支持"意味着用例格式需兼容两种框架的执行引擎，设计复杂度高
- 项目已有 smoke-tester 使用 Playwright（browser-runner.ts）

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | Playwright 为主框架，Selenium 为可选辅框架 | Playwright API 更现代、内置功能丰富、与项目已有实践一致；Selenium 兼容老项目 | 辅框架的用例格式可能简化 |
| B | 双框架等权支持，同一用例可在两种框架执行 | 灵活度最高、覆盖所有团队技术栈 | 用例格式设计复杂、需双引擎适配 |
| C | 仅支持 Playwright | 最简洁、与项目已有实践一致、维护成本低 | 无法兼容 Selenium 用户的现有脚本 |

**推荐**：✅ 选项 A — Playwright 为主框架，Selenium 为可选辅框架

**确认理由**：
1. Playwright API 更现代化，内置 auto-wait、tracing、screenshots、codegen，减少额外开发
2. 项目已有 Playwright 实践（smoke-tester/browser-runner.ts）
3. Selenium 作为辅框架兼容老项目，降低迁移成本
4. 用例格式以 Playwright 语法为基准，Selenium 通过适配层转换执行

**状态**：✅ 已确认

---

### 决策点 3：测试用例生成方式详解

**问题**：三种用例生成方式（需求文档生成、录制生成、手动输入）的具体机制如何实现？

**背景**：
- "需求文档生成"：AI 解析需求文档（如 PRD、用户故事）自动生成测试用例。需要定义输入格式和生成规则
- "录制生成"：通过录制用户操作生成测试脚本。Playwright 内置 Codegen，Selenium 有 IDE 录制器
- "手动输入"：用户直接编写测试用例。需要定义用例格式（YAML/JSON/自定义DSL）
- 三种方式生成的用例需统一存储格式，便于执行引擎统一处理

**选项**：

| 子决策 | 选项 | 描述 | 优点 | 缺点 |
|--------|------|------|------|------|
| 3a 需求文档生成输入 | A | Markdown 格式需求文档（PRD/用户故事） | 与项目已有 AskMe/Feature 文档格式一致 | 需 AI 解析自然语言 |
| 3a 需求文档生成输入 | B | 结构化 YAML/JSON 输入（预定义字段） | 解析确定性高 | 用户需按格式编写 |
| 3b 录制生成机制 | A | Playwright Codegen 录制 → 自动转换为统一用例格式 | Playwright 内置、录制质量高 | 仅 Playwright 框架可用 |
| 3b 录制生成机制 | B | Selenium IDE 录制 → 导出为统一格式 | 覆盖 Selenium 用户 | 录制质量不如 Codegen |
| 3b 录制生成机制 | C | 双录制器支持（Playwright Codegen + Selenium IDE） | 双框架覆盖 | 开发适配层成本高 |
| 3c 手动输入格式 | A | YAML DSL 格式（与 smoke-tester Pipeline YAML 类似） | 可读性好、与项目风格一致 | YAML 语法较复杂 |
| 3c 手动输入格式 | B | JSON Schema 格式 | 机器解析确定性高 | 人工编写体验差 |
| 3c 手动输入格式 | C | 自然语言 DSL（AI 解析为可执行步骤） | 门槛最低 | 解析不确定性高 |

**推荐**：
- 3a: ✅ 选项 A — Markdown 格式需求文档，与项目文档风格一致，AI 自动解析生成用例
- 3b: ✅ 选项 A — Playwright Codegen 录制为主（质量高、内置），辅以手动 Selenium IDE 导出
- 3c: ✅ 选项 A — YAML DSL 格式，与 smoke-tester Pipeline YAML 风格一致，可读性好

**确认理由**：
1. Markdown 需求文档与项目已有 AskMe/Feature 文档格式天然一致
2. Playwright Codegen 录制质量业界领先，内置转换功能
3. YAML DSL 可读性好，与 smoke-tester Pipeline YAML 风格统一，降低学习成本

**状态**：✅ 已确认

---

### 决策点 4：CI/CD 集成方式

**问题**：CI/CD 集成的实现方式是什么？是生成可部署的 CI/CD 配置文件，还是提供模板供用户参考修改？

**背景**：
- CI/CD 平台众多（Jenkins、GitHub Actions、GitLab CI、Azure Pipelines 等），配置语法各异
- 工具集本身是 AI Agent 驱动的，不直接运行 CI/CD Pipeline
- 用户需求提到"Jenkins、GitHub Actions等"，暗示多平台支持

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 生成完整 CI/CD 配置文件（Jenkinsfile / GitHub Actions YAML），可直接使用 | 用户零配置即可接入 CI/CD | 需覆盖多平台、配置文件可能需微调 |
| B | 提供模板参考 + 使用指南，用户手动调整 | 灵活度高、覆盖面广 | 用户需手动配置 |
| C | 生成 CI/CD 配置文件 + 模板参考，默认生成常用平台（Jenkins/GitHub Actions），其他平台提供模板 | 常用平台可直接使用，其他平台有参考 | 开发量稍大 |

**推荐**：✅ 选项 C — 生成常用平台配置文件 + 其他平台模板参考

**确认理由**：
1. Jenkins 和 GitHub Actions 是最主流的 CI/CD 平台，直接生成可用配置
2. 其他平台（GitLab CI、Azure Pipelines）提供模板和指南
3. 兼顾便捷性和灵活性

**状态**：✅ 已确认

---

### 决策点 5：HTML 测试报告格式

**问题**：HTML 测试报告的具体格式和风格如何？使用成熟报告框架（如 Allure）还是自定义 HTML 报告？

**背景**：
- Allure Report：业界标准测试报告框架，支持 Playwright/Selenium、美观、交互式、但有外部依赖
- 自定义 HTML：完全可控、无外部依赖、但开发成本高
- 需求提到"HTML格式测试报告+截图"，但未指定风格
- smoke-tester 已有报告功能（markdown 表格格式），本工具集需升级为 HTML

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 集成 Allure Report，生成 Allure HTML 报告 | 业界标准、美观交互式、Playwright原生支持 | 需安装 Allure 命令行工具 |
| B | 自定义 HTML 报告（卡片式摘要+用例详情+截图内嵌+CSS样式） | 完全可控、无外部依赖、可定制品牌风格 | 开发成本较高 |
| C | 双模式：默认生成自定义 HTML 报告，可选导出 Allure 格式 | 平衡可控性和标准兼容 | 需维护两种格式化器 |

**推荐**：✅ 选项 C — 双模式：默认自定义 HTML 报告 + 可选 Allure 导出

**确认理由**：
1. 自定义 HTML 报告完全可控、无外部依赖，满足"零配置即可使用"需求
2. Allure 导出为可选功能，满足需要标准报告对接的需求
3. 与 smoke-tester 报告风格保持延续（卡片式摘要），但升级为 HTML

**状态**：✅ 已确认

---

### 决策点 6：截图策略

**问题**：测试截图在何时采集？仅失败时采集还是每个步骤都采集？

**背景**：
- 截图是测试报告的关键组成部分，帮助定位问题
- 每步骤截图会导致报告体积大、存储占用高
- 仅失败截图可能丢失成功路径的关键上下文
- Playwright 支持 page.screenshot() 和 tracing（含截图序列）

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 仅失败时截图 + 关键步骤标记截图（用户可在用例中标记需截图步骤） | 存储合理、失败时有证据 | 成功路径缺少视觉证据 |
| B | 每步骤自动截图 | 证据最完整 | 报告体积大、存储占用高 |
| C | 默认仅失败截图，用户可通过配置启用全步骤截图 | 平衡存储和证据 | 需用户主动配置 |

**推荐**：✅ 选项 C — 默认仅失败截图，可选全步骤截图

**确认理由**：
1. 默认仅失败截图，存储合理、报告轻量
2. 用户可通过用例配置 `capture: full` 启用全步骤截图
3. Playwright tracing 可作为高级功能额外提供

**状态**：✅ 已确认

---

### 决策点 7：斜杠命令设计

**问题**：工具集应提供哪些斜杠命令？命令粒度如何划分？

**背景**：
- smoke-tester 有 4 个命令（run/list/report/clear）
- release-note 有 1 个命令（generate-release-note）
- 自动化测试工具集涉及用例管理、执行、报告、CI/CD等多个环节
- 命令过多增加学习成本，命令过少功能不便使用

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 7 个命令：auto-test-generate（生成用例）、auto-test-record（录制用例）、auto-test-run（执行测试）、auto-test-list（列出用例/结果）、auto-test-report（生成报告）、auto-test-ci（生成CI配置）、auto-test-clean（清理） | 功能完整、每命令职责单一 | 命令数较多 |
| B | 4 个命令：auto-test-run（含生成/录制/执行）、auto-test-list、auto-test-report、auto-test-ci | 简洁、类似 smoke-tester 模式 | run 命令功能过重 |
| C | 5 个命令：auto-test-askme（交互澄清+生成用例）、auto-test-run（执行测试）、auto-test-list（列出结果）、auto-test-report（生成报告）、auto-test-ci（CI配置） | 职责平衡、askme 交互生成 | 比 smoke-tester 多1个 |

**推荐**：✅ 选项 A — 7 个命令，职责单一完整

**确认理由**：
1. 自动化测试流程涉及多个独立环节（生成/录制/执行/报告/CI），单一命令过重
2. 与 smoke-tester 的 4 命令模式保持风格一致但扩展合理
3. 每命令职责清晰，降低学习成本

**状态**：✅ 已确认

---

## 决策汇总

| # | 决策 | 推荐方案 | 状态 |
|---|------|---------|------|
| 1 | 工具集定位与命名 | A：独立新工具集 `web-auto-tester`，与 smoke-tester 互补 | ✅ 已确认 |
| 2 | 测试框架优先级 | A：Playwright 为主，Selenium 为辅 | ✅ 已确认 |
| 3 | 用例生成方式 | 3a-A(Markdown) + 3b-A(Codegen) + 3c-A(YAML DSL) | ✅ 已确认 |
| 4 | CI/CD 集成方式 | C：生成常用平台配置 + 其他平台模板 | ✅ 已确认 |
| 5 | HTML 报告格式 | C：默认自定义 HTML + 可选 Allure 导出 | ✅ 已确认 |
| 6 | 截图策略 | C：默认仅失败截图，可选全步骤截图 | ✅ 已确认 |
| 7 | 斜杠命令设计 | A：7 个命令（generate/record/run/list/report/ci/clean） | ✅ 已确认 |

---

## 回答记录

> 用户确认全部推荐方案，跳过逐一确认流程。

### 决策点 1 回答

**回答**：✅ 选项 A — 独立新工具集 `web-auto-tester`，与 `web-smoke-tester` 互补共存
**日期**：2026-07-10

### 决策点 2 回答

**回答**：✅ 选项 A — Playwright 为主框架，Selenium 为可选辅框架
**日期**：2026-07-10

### 决策点 3 回答

**回答**：✅ 3a-A(Markdown需求文档) + 3b-A(Playwright Codegen录制) + 3c-A(YAML DSL手动编写)
**日期**：2026-07-10

### 决策点 4 回答

**回答**：✅ 选项 C — 生成常用平台配置文件（Jenkins/GitHub Actions）+ 其他平台模板参考
**日期**：2026-07-10

### 决策点 5 回答

**回答**：✅ 选项 C — 默认自定义HTML报告 + 可选Allure导出
**日期**：2026-07-10

### 决策点 6 回答

**回答**：✅ 选项 C — 默认仅失败截图，可选全步骤截图
**日期**：2026-07-10

### 决策点 7 回答

**回答**：✅ 选项 A — 7个命令：auto-test-generate/record/run/list/report/ci/clean
**日期**：2026-07-10

---

## 关联文档

- [ASDM Product Planning](../../ASDM-ProductPlanning.md) — 产品规划总览
- [web-smoke-tester README](../../../.asdm/toolsets/web-smoke-tester/README.md) — 现有冒烟测试工具集
- [release-note README](../../../.asdm/toolsets/release-note/README.md) — 参考工具集规范
- [smoke-tester Pipeline Spec](../../../.asdm/toolsets/web-smoke-tester/spec/smoke-test-pipeline-spec.md) — Pipeline YAML 格式参考

---

**文档版本**：1.0
**创建日期**：2026-07-10
**最后更新**：2026-07-13
**维护者**：AI Planner
