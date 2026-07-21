# FT-003 Web Auto Tester — 需求访谈追问

> 本文档记录对 FT-003 Web Auto Tester 特性的逐问题追问，用于澄清需求模糊点后制定最终特性规格。

**创建日期**：2026-07-10
**最后更新**：2026-07-20
**状态**：已更新（v2.0 — 去掉 CI/CD 功能、工具集定位改为独立）

---

## 背景摘要

### 核心价值

设计并开发一款 ASDM 工具集 `web-auto-tester`，实现对 Web 系统的全面自动化测试。本工具集定位为**独立**的自动化测试工具集，与 `web-smoke-tester`（专注于冒烟测试、自然语言驱动）**不形成互补关系**。web-auto-tester 支持双框架（Selenium / Playwright）、三种用例生成方式（需求文档→用例、录制→用例、手动编写用例）、本地执行环境、以及 HTML 测试报告+截图输出。**不提供 CI/CD 集成功能**。

核心解决的问题：
- 测试用例编写成本高 → 需求文档自动生成 + 录制生成降低门槛
- 单框架局限 → 双框架支持（Selenium + Playwright）适应不同团队技术栈
- 手工执行效率低 → 本地自动化执行
- 测试结果不可追溯 → HTML 报告 + 截图持久化存储

### 变更范围

| 变更模块 | 变更内容 |
|----------|----------|
| `.asdm/toolsets/web-auto-tester/` | 更新工具集：manifest.json（v0.0.2，去掉 ci 命令）、README.md（去掉 CI/CD 描述）、删除 actions/auto-test-ci.md、删除 spec/auto-test-ci-spec.md |
| `.codebuddy/commands/` | 删除 auto-test-ci.md 斜杠命令快捷入口 |
| `.asdm/workspace/auto-test/` | 工作区目录去掉 ci/ 子目录 |

### 已澄清问题（来自需求描述）

| 编号 | 问题 | 澄清结论 |
|:----:|------|----------|
| Q1 | 支持哪些测试框架？ | Selenium 和 Playwright 双框架 |
| Q2 | 用例生成方式有哪些？ | 需求文档生成 + 录制生成 + 手动输入 |
| Q3 | 执行环境有哪些？ | 本地浏览器（不提供 CI/CD 集成） |
| Q4 | 报告格式？ | HTML 格式 + 截图 |

---

## 决策点

### 决策点 1：工具集定位与命名

**问题**：本工具集与现有 `web-smoke-tester` 的定位关系如何？

**背景**：
- 项目中已有 `web-smoke-tester` 工具集，专注于**冒烟测试**，自然语言驱动
- 用户需求明确要求"自动化测试工具集"，涵盖用例生成、双框架、HTML报告等，远超冒烟测试范畴

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 独立新工具集 `web-auto-tester`，与 `web-smoke-tester` 互补共存 | 定位清晰、职责分离 | 两个测试工具集可能让用户困惑选择 |
| B | 独立新工具集 `web-auto-tester`，与 `web-smoke-tester` **不互补**，各自独立运行 | 定位最清晰、无关联困惑、完全独立演进 | 无协同效应 |
| C | 升级 `web-smoke-tester`，在其基础上扩展全部功能 | 统一入口、无新工具集学习成本 | smoke-tester 变得过于庞大 |
| D | 新工具集替代 `web-smoke-tester` | 单一入口 | 丧失冒烟测试的轻量便捷特性 |

**最终决定**：✅ 选项 B — 独立新工具集 `web-auto-tester`，与 `web-smoke-tester` **不互补**，各自独立运行

**确认理由**：
1. web-auto-tester 是独立的自动化测试工具集，有自己的定位和目标
2. 与 web-smoke-tester 不形成互补关系，两者各自独立、各自演进
3. 用户可按场景独立使用，不存在"配合使用"的关联设计

**状态**：✅ 已确认（原为选项A，2026-07-20 更新为选项B）

---

### 决策点 2：测试框架优先级与双框架策略

**问题**：Selenium 和 Playwright 双框架如何支持？是同时等权支持还是以一个为主、另一个为辅？

**背景**：
- Selenium：业界成熟、社区庞大、语言支持广、但 API 较老
- Playwright：微软出品、API 现代化、内置 auto-wait/tracing/screenshots/codegen
- 双框架"等权支持"意味着用例格式需兼容两种框架的执行引擎，设计复杂度高

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | Playwright 为主框架，Selenium 为可选辅框架 | Playwright API 更现代、内置功能丰富；Selenium 兼容老项目 | 辅框架的用例格式可能简化 |
| B | 双框架等权支持，同一用例可在两种框架执行 | 灵活度最高、覆盖所有团队技术栈 | 用例格式设计复杂、需双引擎适配 |
| C | 仅支持 Playwright | 最简洁、维护成本低 | 无法兼容 Selenium 用户 |

**最终决定**：✅ 选项 A — Playwright 为主框架，Selenium 为可选辅框架

**确认理由**：
1. Playwright API 更现代化，内置 auto-wait、tracing、screenshots、codegen
2. Selenium 作为辅框架兼容老项目，降低迁移成本
3. 用例格式以 Playwright 语法为基准，Selenium 通过适配层转换执行

**状态**：✅ 已确认

---

### 决策点 3：测试用例生成方式详解

**问题**：三种用例生成方式的具体机制如何实现？

**选项**：

| 子决策 | 选项 | 描述 | 优点 | 缺点 |
|--------|------|------|------|------|
| 3a 需求文档生成输入 | A | Markdown 格式需求文档（PRD/用户故事） | 与项目已有文档格式一致 | 需 AI 解析自然语言 |
| 3a 需求文档生成输入 | B | 结构化 YAML/JSON 输入 | 解析确定性高 | 用户需按格式编写 |
| 3b 录制生成机制 | A | Playwright Codegen 录制 → 转换为统一用例格式 | Playwright 内置、录制质量高 | 仅 Playwright 框架可用 |
| 3b 录制生成机制 | B | Selenium IDE 录制 → 导出为统一格式 | 覆盖 Selenium 用户 | 录制质量不如 Codegen |
| 3b 录制生成机制 | C | 双录制器支持 | 双框架覆盖 | 开发适配层成本高 |
| 3c 手动输入格式 | A | YAML DSL 格式 | 可读性好、与项目风格一致 | YAML 语法较复杂 |
| 3c 手动输入格式 | B | JSON Schema 格式 | 机器解析确定性高 | 人工编写体验差 |
| 3c 手动输入格式 | C | 自然语言 DSL | 门槛最低 | 解析不确定性高 |

**最终决定**：
- 3a: ✅ 选项 A — Markdown 格式需求文档，AI 自动解析生成用例
- 3b: ✅ 选项 A — Playwright Codegen 录制为主
- 3c: ✅ 选项 A — YAML DSL 格式

**状态**：✅ 已确认

---

### 决策点 4：CI/CD 集成（已移除）

**原问题**：CI/CD 集成的实现方式？

**最终决定**：❌ **去掉 CI/CD 功能** — 本工具集不提供 CI/CD 集成功能，专注于本地自动化测试执行

**确认理由**：
1. web-auto-tester 定位为本地自动化测试工具集，不涉及 CI/CD 流程
2. CI/CD 配置属于 DevOps 领域，应由专业 CI/CD 工具或平台自行处理
3. 去掉 CI/CD 功能使工具集职责更聚焦、更轻量

**影响**：
- 删除 `auto-test-ci` 命令（从 7 个命令减至 6 个）
- 删除 `actions/auto-test-ci.md`
- 删除 `spec/auto-test-ci-spec.md`
- 删除 `.codebuddy/commands/auto-test-ci.md`
- 工作区去掉 `ci/` 目录

**状态**：✅ 已确认（2026-07-20 决定去掉）

---

### 决策点 5：HTML 测试报告格式

**问题**：HTML 测试报告的具体格式和风格如何？

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 集成 Allure Report | 业界标准、美观交互式 | 需安装 Allure 命令行工具 |
| B | 自定义 HTML 报告 | 完全可控、无外部依赖 | 开发成本较高 |
| C | 双模式：默认自定义 HTML + 可选 Allure 导出 | 平衡可控性和标准兼容 | 需维护两种格式化器 |

**最终决定**：✅ 选项 C — 双模式：默认自定义 HTML 报告 + 可选 Allure 导出

**状态**：✅ 已确认

---

### 决策点 6：截图策略

**问题**：测试截图在何时采集？

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 仅失败时截图 + 关键步骤标记截图 | 存储合理 | 成功路径缺少视觉证据 |
| B | 每步骤自动截图 | 证据最完整 | 报告体积大 |
| C | 默认仅失败截图，可选全步骤截图 | 平衡存储和证据 | 需用户主动配置 |

**最终决定**：✅ 选项 C — 默认仅失败截图，可选全步骤截图

**状态**：✅ 已确认

---

### 决策点 7：斜杠命令设计

**问题**：工具集应提供哪些斜杠命令？

**选项**：

| 选项 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | 6 个命令：auto-test-generate、auto-test-record、auto-test-run、auto-test-list、auto-test-report、auto-test-clean | 功能完整、职责单一、不含 CI/CD | 命令数适中 |
| B | 4 个命令：run（含生成/录制/执行）、list、report、clean | 简洁 | run 命令功能过重 |
| C | 5 个命令：askme、run、list、report、clean | 职责平衡 | 比 smoke-tester 多1个 |

**最终决定**：✅ 选项 A — 6 个命令，职责单一完整，不含 CI/CD

**命令列表**：

| 命令 | 功能 | 说明 |
|------|------|------|
| `/auto-test-generate` | 需求文档 AI 生成用例 | 从 Markdown PRD 自动生成 YAML DSL 用例 |
| `/auto-test-record` | 录制操作生成用例 | Playwright Codegen 录制 → YAML DSL |
| `/auto-test-run` | 执行自动化测试 | 7 阶段规范流程执行 YAML DSL 用例 |
| `/auto-test-list` | 列出用例与结果 | cases/results/all 三模式 + 筛选 |
| `/auto-test-report` | 生成 HTML 测试报告 | 自定义 HTML + 可选 Allure 导出 |
| `/auto-test-clean` | 清理测试资源 | results/reports/screenshots/all 四范围 |

**状态**：✅ 已确认（原为 7 个命令含 CI，2026-07-20 更新为 6 个命令去掉 CI）

---

## 决策汇总

| # | 决策 | 最终方案 | 状态 |
|---|------|---------|------|
| 1 | 工具集定位与命名 | B：独立工具集 `web-auto-tester`，与 smoke-tester **不互补** | ✅ 已更新 |
| 2 | 测试框架优先级 | A：Playwright 为主，Selenium 为辅 | ✅ 已确认 |
| 3 | 用例生成方式 | 3a-A(Markdown) + 3b-A(Codegen) + 3c-A(YAML DSL) | ✅ 已确认 |
| 4 | CI/CD 集成 | ❌ 去掉 CI/CD 功能 | ✅ 已更新 |
| 5 | HTML 报告格式 | C：默认自定义 HTML + 可选 Allure 导出 | ✅ 已确认 |
| 6 | 截图策略 | C：默认仅失败截图，可选全步骤截图 | ✅ 已确认 |
| 7 | 斜杠命令设计 | A：6 个命令（generate/record/run/list/report/clean） | ✅ 已更新 |

---

## 回答记录

### 决策点 1 回答

**回答**：✅ 选项 B — 独立新工具集 `web-auto-tester`，与 `web-smoke-tester` **不互补**，各自独立运行
**日期**：2026-07-20（原 2026-07-10 选择选项A，现更新为选项B）

### 决策点 2 回答

**回答**：✅ 选项 A — Playwright 为主框架，Selenium 为可选辅框架
**日期**：2026-07-10

### 决策点 3 回答

**回答**：✅ 3a-A(Markdown需求文档) + 3b-A(Playwright Codegen录制) + 3c-A(YAML DSL手动编写)
**日期**：2026-07-10

### 决策点 4 回答

**回答**：❌ 去掉 CI/CD 功能 — 本工具集不提供 CI/CD 集成，专注于本地自动化测试
**日期**：2026-07-20

### 决策点 5 回答

**回答**：✅ 选项 C — 默认自定义HTML报告 + 可选Allure导出
**日期**：2026-07-10

### 决策点 6 回答

**回答**：✅ 选项 C — 默认仅失败截图，可选全步骤截图
**日期**：2026-07-10

### 决策点 7 回答

**回答**：✅ 选项 A — 6个命令：auto-test-generate/record/run/list/report/clean（去掉 auto-test-ci）
**日期**：2026-07-20（原为 7 个命令含 CI，现去掉 CI 更新为 6 个）

---

## 变更记录

| 日期 | 变更内容 |
|------|----------|
| 2026-07-10 | 初始版本，7个决策点全部确认 |
| 2026-07-20 | 决策点1从"互补共存"改为"独立不互补"；决策点4去掉CI/CD功能；决策点7从7个命令改为6个命令；删除CI/CD相关文件3个 |

---

## 关联文档

- [ASDM Product Planning](../../ASDM-ProductPlanning.md) — 产品规划总览
- [web-auto-tester README](../../../.asdm/toolsets/web-auto-tester/README.md) — 工具集入口文档（已更新）
- [web-auto-tester manifest](../../../.asdm/toolsets/web-auto-tester/manifest.json) — 工具集元数据（已更新）

---

**文档版本**：2.0
**创建日期**：2026-07-10
**最后更新**：2026-07-20
**维护者**：AI Planner
