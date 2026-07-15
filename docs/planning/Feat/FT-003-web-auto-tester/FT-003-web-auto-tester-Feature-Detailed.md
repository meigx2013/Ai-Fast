# FT-003 Web Auto Tester特性文档

> **🔗 前置文档引用**：本文档基于 [FT-003-web-auto-tester-Feature-Overall.md](./FT-003-web-auto-tester-Feature-Overall.md)（概要设计文档）编写。Overall 中的总体概述、使用场景、核心概念等是本详细设计的直接输入来源。

> 最后更新：2026-07-14

---

## 修订记录

| 版本 | 日期 | 修订人 | 修订内容 |
|------|------|--------|----------|
| 1.0.0 | 2026-07-14 | meiguangxian | 初始详细设计版本 |

---

## 目录

- [1. 总体概述 — 背景、目标与核心概念](#1-总体概述)
  - [1.1 背景与问题](#11-背景与问题)
  - [1.2 特性目标](#12-特性目标)
  - [1.3 核心概念](#13-核心概念)
  - [1.4 定位与边界](#14-定位与边界)
  - [1.5 已确认决策汇总](#15-已确认决策汇总)
  - [1.6 变更范围](#16-变更范围)
- [2. 使用场景 — 操作步骤与预期结果](#2-使用场景)
  - [2.1 需求文档自动生成测试用例](#21-需求文档自动生成测试用例)
  - [2.2 录制操作生成测试用例](#22-录制操作生成测试用例)
  - [2.3 手动编写 YAML DSL 测试用例](#23-手动编写-yaml-dsl-测试用例)
  - [2.4 本地执行自动化测试](#24-本地执行自动化自动化测试)
  - [2.5 CI/CD 集成执行自动化测试](#25-cicd-集成执行自动化测试)
  - [2.6 生成 HTML 测试报告](#26-生成-html-测试报告)
  - [2.7 清理测试资源](#27-清理测试资源)
- [3. 技术方案 — 架构、引擎与执行流程](#3-技术方案)
  - [3.1 系统架构](#31-系统架构)
  - [3.2 测试引擎架构](#32-测试引擎架构)
  - [3.3 用例生成引擎](#33-用例生成引擎)
  - [3.4 执行引擎与双框架适配](#34-执行引擎与双框架适配)
  - [3.5 断言引擎](#35-断言引擎)
  - [3.6 截图采集引擎](#36-截图采集引擎)
  - [3.7 报告生成引擎](#37-报告生成引擎)
  - [3.8 CI/CD 配置生成引擎](#38-cicd-配置生成引擎)
- [4. YAML DSL 规范 — 用例格式定义](#4-yaml-dsl-规范)
  - [4.1 用例文件结构](#41-用例文件结构)
  - [4.2 顶层字段说明](#42-顶层字段说明)
  - [4.3 Stage 与 Step 定义](#43-stage-与-step-定义)
  - [4.4 断言定义](#44-断言定义)
  - [4.5 框架标记与捕获配置](#45-框架标记与捕获配置)
  - [4.6 用例示例](#46-用例示例)
- [5. 数据模型 — 核心数据结构与存储](#5-数据模型)
  - [5.1 核心数据模型关系](#51-核心数据模型关系)
  - [5.2 AutoTestCase 数据模型](#52-autotestcase-数据模型)
  - [5.3 AutoTestResult 数据模型](#53-autotestresult-数据模型)
  - [5.4 AutoTestReport 数据模型](#54-autotestreport-数据模型)
  - [5.5 工作区存储结构](#55-工作区存储结构)
- [6. 接口设计 — 斜杠命令与交互规格](#6-接口设计)
  - [6.1 斜杠命令一览](#61-斜杠命令一览)
  - [6.2 /auto-test-generate — 需求文档生成用例](#62-auto-test-generate)
  - [6.3 /auto-test-record — 录制生成用例](#63-auto-test-record)
  - [6.4 /auto-test-run — 执行测试](#64-auto-test-run)
  - [6.5 /auto-test-list — 列出用例与结果](#65-auto-test-list)
  - [6.6 /auto-test-report — 生成报告](#66-auto-test-report)
  - [6.7 /auto-test-ci — 生成 CI/CD 配置](#67-auto-test-ci)
  - [6.8 /auto-test-clean — 清理资源](#68-auto-test-clean)
- [7. 变更摘要 — 模块级变更范围](#7-变更摘要)
- [8. 依赖关系 — 前置、后续与第三方依赖](#8-依赖关系)
  - [8.1 前置依赖](#81-前置依赖)
  - [8.2 后续依赖](#82-后续依赖)
  - [8.3 代码库依赖](#83-代码库依赖)
  - [8.4 第三方依赖](#84-第三方依赖)
- [9. 完成规范 (DoD) — 验收标准](#9-完成规范-dod)
  - [9.1 核心功能](#91-核心功能)
  - [9.2 数据一致性](#92-数据一致性)
  - [9.3 用户体验](#93-用户体验)
  - [9.4 兼容性](#94-兼容性)
- [10. 相关文档 — 关联文档引用](#10-相关文档)

---

## 1. 总体概述

### 1.1 背景与问题

当前项目中已有 `web-smoke-tester` 工具集，专注于**冒烟测试**，通过自然语言驱动快速验证 P0/P1 级别的系统可用性。然而，冒烟测试仅覆盖最基础的可用性检查，无法满足全面功能验证的需求。

测试团队面临以下核心痛点：

- **用例编写成本高**：测试人员需要手工编写大量测试脚本，耗时且易出错
- **单框架局限**：现有工具仅支持 Playwright，无法兼容 Selenium 用户的技术栈和存量脚本
- **手工执行效率低**：功能测试依赖人工逐项执行，缺乏自动化执行和 CI/CD 集成能力
- **测试结果不可追溯**：缺少结构化的 HTML 报告和截图存档，难以回溯和定位问题

### 1.2 特性目标

设计并开发 ASDM 工具集 `web-auto-tester`，实现对 Web 系统的**全面自动化测试**，核心目标如下：

- **降低用例编写门槛**：支持三种用例生成方式（需求文档自动生成、录制操作生成、手动编写），覆盖从零基础到专业测试人员的全谱系用户
- **双框架兼容**：以 Playwright 为主框架、Selenium 为可选辅框架，兼容不同团队技术栈
- **自动化执行闭环**：本地一键执行 + CI/CD 平台集成（Jenkins/GitHub Actions），实现测试全流程自动化
- **结构化报告输出**：HTML 测试报告 + 截图存档，支持自定义报告和可选 Allure 导出

### 1.3 核心概念

| 概念 | 定义 |
|------|------|
| **工具集 (Toolset)** | ASDM 生态中的独立功能单元，包含 manifest、actions、specs，通过斜杠命令交互 |
| **测试用例 (Test Case)** | 描述单个测试场景的结构化定义，包括操作步骤、断言条件和预期结果 |
| **YAML DSL** | 手动编写测试用例的结构化格式，与 smoke-tester Pipeline YAML 风格一致 |
| **主/辅框架** | Playwright 为主框架（优先支持、完整功能），Selenium 为辅框架（兼容适配、基础功能） |
| **测试报告 (Report)** | 测试执行结果的 HTML 结构化输出，包含摘要、详情、截图和统计数据 |
| **CI/CD 配置** | 自动生成的 Jenkinsfile 或 GitHub Actions YAML，可直接用于持续集成 |

### 1.4 定位与边界

**定位**：`web-auto-tester` 是独立于 `web-smoke-tester` 的**正式自动化测试工具集**，两者互补共存：

| 维度 | web-smoke-tester | web-auto-tester |
|------|------------------|-----------------|
| 测试级别 | 冒烟测试（P0/P1 快速验证） | 全面功能测试（全场景覆盖） |
| 驱动方式 | 自然语言驱动 | 用例驱动（YAML DSL / AI 生成 / 录制） |
| 测试框架 | Playwright | Playwright + Selenium |
| 报告格式 | Markdown 表格 | HTML + 可选 Allure |
| CI/CD | 不支持 | 支持（Jenkins/GitHub Actions） |

**边界**：
- 仅覆盖 **Web系统**的自动化测试，不涉及移动端或 API 纯接口测试
- 不替代单元测试框架（如 Jest、JUnit），定位为端到端功能测试
- CI/CD 配置生成覆盖 Jenkins 和 GitHub Actions 两个主流平台，其他平台提供模板参考

### 1.5 已确认决策汇总

以下决策在 AskMe 需求访谈中已全部确认：

| # | 决策点 | 已确认方案 |
|---|--------|-----------|
| 1 | 工具集定位与命名 | 独立新工具集 `web-auto-tester`，与 `web-smoke-tester` 互补共存 |
| 2 | 测试框架优先级 | Playwright 为主框架，Selenium 为可选辅框架 |
| 3 | 用例生成方式 | Markdown 需求文档生成 + Playwright Codegen 录制 + YAML DSL 手动编写 |
| 4 | CI/CD 集成方式 | 生成常用平台配置（Jenkins/GitHub Actions）+ 其他平台模板参考 |
| 5 | HTML 报告格式 | 默认自定义 HTML 报告 + 可选 Allure 导出 |
| 6 | 截图策略 | 默认仅失败截图，可选全步骤截图 |
| 7 | 斜杠命令设计 | 7 个命令：generate/record/run/list/report/ci/clean |

### 1.6 变更范围

| 变更模块 | 变更类型 | 功能说明 |
|----------|:--------:|----------|
| `.asdm/toolsets/web-auto-tester/` | 🔲 新增 | 工具集完整目录：manifest.json、README.md、INSTALL.md、actions/（7个命令）、spec/ |
| `.codebuddy/commands/` | 🔲 新增 | 注册 7 个斜杠命令快捷入口 |
| `.asdm/workspace/auto-test/` | 🔲 新增 | 工作区目录：测试用例存储、执行结果、报告输出 |

---

## 2. 使用场景

### 2.1 需求文档自动生成测试用例

**角色**：测试负责人 / 产品经理

1. 用户执行 `/auto-test-generate` 命令，提供 Markdown 格式的需求文档（PRD 或用户故事）
2. AI 解析需求文档中的功能描述、验收标准和业务规则
3. 系统自动生成覆盖每个功能点的测试用例，采用 YAML DSL 格式
4. 生成的用例保存到 `.asdm/workspace/auto-test/cases/` 目录
5. 用户可查看、编辑和补充生成的用例

**预期结果**：从一份 PRD 文档自动生成一组结构化的 YAML DSL 测试用例，覆盖文档中描述的所有功能点和验收标准

### 2.2 录制操作生成测试用例

**角色**：测试工程师

1. 用户执行 `/auto-test-record` 命令，指定目标 URL 和测试框架（默认 Playwright）
2. 系统启动 Playwright Codegen 录制器，打开目标页面
3. 用户在浏览器中执行需要测试的操作步骤
4. 录制完成后，系统将录制结果自动转换为 YAML DSL 格式的测试用例
5. 转换后的用例保存到 `.asdm/workspace/auto-test/cases/` 目录

**预期结果**：通过浏览器录制操作，自动生成与用户操作步骤对应的 YAML DSL 测试用例，无需手动编写

### 2.3 手动编写 YAML DSL 测试用例

**角色**：专业测试工程师

1. 用户参照 YAML DSL 规范，在 `.asdm/workspace/auto-test/cases/` 目录下手动编写测试用例文件
2. YAML DSL 格式与 smoke-tester Pipeline YAML 风格一致，包含 stages、steps、assertions 等结构
3. 用户可在用例中标记关键步骤的截图需求（`capture: full` 或默认仅失败截图）
4. 用例文件支持 Playwright 和 Selenium 两种框架的语法标记

**预期结果**：测试人员可按熟悉的 YAML DSL 格式编写测试用例，格式与项目已有工具风格统一

### 2.4 本地执行自动化测试

**角色**：测试工程师

1. 用户执行 `/auto-test-run` 命令，指定用例文件或用例目录
2. 系统加载 YAML DSL 用例，选择对应的执行引擎（Playwright 或 Selenium）
3. 执行引擎启动浏览器，逐步执行用例中的操作步骤和断言
4. 失败步骤自动截图（默认策略），标记为 `capture: full` 的步骤全步骤截图
5. 执行完成后，结果保存到 `.asdm/workspace/auto-test/results/` 目录

**预期结果**：本地浏览器自动化执行测试用例，失败步骤自动截图，结果结构化存储

### 2.5 CI/CD 集成执行自动化测试

**角色**：DevOps 工程师

1. 用户执行 `/auto-test-ci` 命令，选择目标 CI/CD 平台（Jenkins 或 GitHub Actions）
2. 系统根据用户选择的平台，生成对应的 CI/CD 配置文件（Jenkinsfile 或 GitHub Actions YAML）
3. 配置文件包含测试执行、报告生成和失败通知的完整流程
4. 生成的配置文件可直接放入项目仓库的对应位置使用
5. 其他平台（GitLab CI、Azure Pipelines）提供模板参考文档

**预期结果**：一键生成可直接使用的 Jenkins 或 GitHub Actions CI/CD 配置文件，实现测试自动化持续执行

### 2.6 生成 HTML 测试报告

**角色**：测试负责人 / 项目经理

1. 用户执行 `/auto-test-report` 命令，指定结果目录或最近一次执行结果
2. 系统读取执行结果数据，生成自定义 HTML 报告（卡片式摘要 + 用例详情 + 截图内嵌 + 统计数据）
3. HTML 报告保存到 `.asdm/workspace/auto-test/reports/` 目录
4. 用户可选择导出 Allure 格式报告（需安装 Allure 命令行工具）
5. 报告包含执行摘要（通过率、失败数、跳过数）、每个用例的详细步骤和截图

**预期结果**：生成结构化 HTML 测试报告，包含卡片式摘要、用例详情、截图和统计数据，可选导出 Allure 格式

### 2.7 清理测试资源

**角色**：测试工程师

1. 用户执行 `/auto-test-clean` 命令，选择清理范围（结果、报告、截图或全部）
2. 系统清理 `.asdm/workspace/auto-test/` 下对应的文件和目录
3. 清理前确认清理范围，避免误删重要数据

**预期结果**：按指定范围清理测试工作区中的过期结果、报告和截图，保持工作区整洁

---

## 3. 技术方案

### 3.1 系统架构

`web-auto-tester` 采用**规范驱动型架构**，与 `web-smoke-tester` 和 `release-note` 一致：所有引擎功能由 AI Agent 按 spec 规范文档执行，无实际编译代码。工具集提供 YAML DSL 格式定义、执行流程规范和输出规范，AI Agent 读取这些规范后驱动测试执行。

```
┌─────────────────────────────────────────────────────────────┐
│                     用户交互层                                │
│  /auto-test-generate  /auto-test-record  /auto-test-run      │
│  /auto-test-list  /auto-test-report  /auto-test-ci  /clean   │
├─────────────────────────────────────────────────────────────┤
│                    Action 指令层                              │
│  actions/auto-test-{command}.md — 流程定义、参数、输出规范     │
├─────────────────────────────────────────────────────────────┤
│                    引擎层（AI Agent 执行）                     │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │用例生成  │ │执行引擎  │ │断言引擎  │ │截图采集  │       │
│  │引擎      │ │(PW/SEL) │ │引擎      │ │引擎      │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                    │
│  │报告生成  │ │CI/CD    │ │结果记录  │                    │
│  │引擎      │ │配置引擎  │ │引擎      │                    │
│  └──────────┘ └──────────┘ └──────────┘                    │
├─────────────────────────────────────────────────────────────┤
│                    数据存储层                                 │
│  .asdm/workspace/auto-test/                                  │
│  ├── cases/     ├── results/     ├── reports/  ├── screenshots/ │
│  └─────────────────────────────────────────────────────────────┘
```

**架构特点**：

- **规范驱动**：所有引擎行为由 spec 文件定义，AI Agent 按规范执行，无编译代码
- **双框架适配**：Playwright 主引擎直接驱动，Selenium 辅引擎通过 YAML DSL 适配层转换
- **统一数据流**：三种生成方式的用例统一为 YAML DSL 格式，由同一执行引擎处理
- **可复用设计**：从 `web-smoke-tester` 继承数据模型骨架、ID 生成规则、断言分类、Pipeline 阶段概念

### 3.2 测试引擎架构

整体测试流程分为 7 个阶段，扩展了 smoke-tester 的 6 阶段 Pipeline 概念：

```
Phase 1: 用例加载 → Phase 2: 上下文准备 → Phase 3: 执行引擎 → Phase 4: 断言判定 → Phase 5: 截图采集 → Phase 6: 结果记录 → Phase 7: 报告输出
```

| Phase | 名称 | 输入 | 输出 | 说明 |
|:-----:|------|------|------|------|
| 1 | 用例加载 | YAML DSL 文件路径 | AutoTestCase 结构 | 解析 YAML → 验证 schema → 加载为结构化用例 |
| 2 | 上下文准备 | 用例 metadata | 运行上下文 | 读取环境配置、浏览器选项、认证信息 |
| 3 | 执行引擎 | Step 列表 | 执行结果 | Playwright/Selenium 适配执行操作步骤 |
| 4 | 断言判定 | 断言定义 + 实际值 | pass/fail/error/skip | 多类型断言匹配 |
| 5 | 截图采集 | 断言结果 + capture 配置 | 截图文件路径 | 默认失败截图，可选全步骤 |
| 6 | 结果记录 | 全流程数据 | AutoTestResult JSON | ID 生成 ATR-{YYYYMMDD}-{NNN}，持久化 |
| 7 | 报告输出 | 结果 JSON | HTML/Allure 报告 | 卡片式摘要 + 用例详情 + 截图内嵌 |

### 3.3 用例生成引擎

三种用例生成方式统一输出 YAML DSL 格式：

| 生成方式 | 输入 | 转换过程 | 输出 |
|----------|------|----------|------|
| **需求文档生成** | Markdown PRD/用户故事 | AI 解析功能描述 + 验收标准 → 识别测试场景 → 生成步骤 + 断言 → YAML DSL | `.asdm/workspace/auto-test/cases/{name}.yaml` |
| **录制生成** | 目标 URL | Playwright Codegen 录制 → 提取操作序列 → 转换为 Step 格式 → 添加断言建议 → YAML DSL | `.asdm/workspace/auto-test/cases/{name}.yaml` |
| **手动编写** | 用户直接编辑 | 用户按 YAML DSL 规范编写 → schema 校验 → 保存 | `.asdm/workspace/auto-test/cases/{name}.yaml` |

**需求文档生成引擎**的关键流程：

1. 解析 Markdown 文档，提取功能描述段落和验收标准列表
2. 为每个功能点生成 1-N 个测试场景（正向、逆向、边界值）
3. 将场景转换为 YAML DSL 的 stages/steps 结构
4. 为每个 step 自动推断断言（基于验收标准）
5. 标记框架偏好（默认 playwright）和截图配置（默认 on-fail）
6. 输出 YAML 文件并提示用户审核

**录制生成引擎**的关键流程：

1. 启动 `npx playwright codegen {url}` 命令
2. 用户在浏览器中操作，Codegen 实时录制
3. 录制结束后提取操作序列（click/type/navigate/wait）
4. 转换为 YAML DSL Step 格式，按操作类型映射
5. 对每个导航步骤自动添加页面可见断言
6. 输出 YAML 文件并提示用户补充断言和截图配置

### 3.4 执行引擎与双框架适配

**Playwright 主引擎**：

| 操作类型 | Playwright API | 说明 |
|----------|---------------|------|
| navigate | `page.goto(url)` | 打开页面 |
| click | `page.click(selector)` | 点击元素 |
| type | `page.fill(selector, value)` | 输入文本 |
| wait | `page.waitForSelector/waitForTimeout` | 等待元素或时间 |
| scroll | `page.evaluate(scroll logic)` | 滚动页面 |
| upload | `page.setInputFiles(selector, files)` | 上传文件 |
| hover | `page.hover(selector)` | 鼠标悬停 |
| select | `page.selectOption(selector, value)` | 下拉选择 |
| screenshot | `page.screenshot({path})` | 截图 |
| assert | `expect(page).toHaveURL/toBeVisible/...` | 内置断言 |

**Selenium 辅引擎**：

Selenium 通过适配层支持基础操作，功能集缩减：

| 操作类型 | Selenium API | 限制说明 |
|----------|-------------|----------|
| navigate | `driver.get(url)` | 完全支持 |
| click | `element.click()` | 完全支持 |
| type | `element.sendKeys(value)` | 完全支持 |
| wait | `WebDriverWait(driver, timeout)` | 完全支持 |
| scroll | `driver.executeScript(scroll)` | 完全支持 |
| screenshot | `driver.save_screenshot(path)` | 完全支持 |
| hover | `ActionChains(driver).move_to_element()` | 支持，需导入 ActionChains |
| select | `Select(element).select_by_value()` | 支持，需导入 Select |
| assert | 手动比对 + driver.find_element | 无内置 expect，需手动比对 |

**框架选择策略**：

- 用例文件的 `framework` 字段指定框架偏好：`playwright`（默认）或 `selenium`
- 执行时根据框架字段选择对应引擎适配
- Selenium 用例仅支持基础操作类型和断言，不支持 Playwright 专有特性（如 tracing、codegen）
- 如用例指定 `selenium` 但包含 Playwright 专有操作，执行时降级为 playwright 并提示用户

### 3.5 断言引擎

扩展 smoke-tester 的 5 种断言类型，新增 3 种：

| 编号 | 断言类型 | 适用框架 | 说明 |
|:----:|----------|:--------:|------|
| A1 | 页面可见 | PW/SEL | 验证页面/元素是否可见 |
| A2 | 页面跳转 | PW/SEL | 验证 URL 跳转到预期路径 |
| A3 | 元素状态 | PW/SEL | 验证元素属性（enabled/disabled/visible/hidden） |
| A4 | 内容匹配 | PW/SEL | 验证页面/元素文本包含预期内容 |
| A5 | API 响应 | PW | 验证接口返回数据（仅 Playwright 支持 `page.route`拦截） |
| A6 | 表单值 | PW/SEL | 验证表单输入框的当前值 |
| A7 | 元素数量 | PW/SEL | 验证匹配选择器的元素数量 |
| A8 | 截图比对 | PW | 视觉回归断言（仅 Playwright 支持 `toHaveScreenshot`） |

**断言结果映射**：

| 实际 vs 预期 | 结果 |
|:------------:|------|
| 完全匹配 | **pass** |
| 不匹配 | **fail** |
| 执行异常（超时/元素未找到） | **error** |
| 条件不满足跳过 | **skip** |

### 3.6 截图采集引擎

| 截图策略 | 触发条件 | 文件命名 | 说明 |
|----------|----------|----------|------|
| **on-fail（默认）** | 断言结果为 fail/error | `ATR-{id}-S{stepIndex}-fail.png` | 仅失败步骤截图 |
| **full** | 每个步骤执行后 | `ATR-{id}-S{stepIndex}-{status}.png` | 全步骤截图 |
| **标记步骤** | 用例中 `capture: always` | `ATR-{id}-S{stepIndex}-marked.png` | 用户标记的关键步骤强制截图 |

**截图存储路径**：`.asdm/workspace/auto-test/screenshots/`

**Playwright 截图特性**：

- 支持 `page.screenshot({fullPage: true})` 全页截图
- 支持 `locator.screenshot()` 元素级截图
- 支持 tracing（完整操作序列录制），作为高级可选功能

**Selenium 截图特性**：

- 仅支持 `driver.save_screenshot()` 全页截图
- 不支持元素级截图和 tracing

### 3.7 报告生成引擎

**自定义 HTML 报告结构**：

| 章节 | 内容 | 样式 |
|------|------|------|
| **摘要卡片** | 通过率/失败数/跳过数/总步骤/执行时间 | 渐变背景 + 大数字 |
| **用例列表** | 每个用例名称/状态/耗时/标签 | 状态色标签（绿/红/灰） |
| **步骤详情** | 操作类型/目标/实际值/断言结果 | 折叠面板，失败步骤红色高亮 |
| **截图展示** | 内嵌失败/标记步骤截图 | 图片缩略图 + 点击放大 |
| **统计图表** | 通过率分布/断言类型分布 | ASCII 图表展示 |

**Allure 导出**（可选）：

- 将 AutoTestResult JSON 转换为 Allure 结果格式
- 调用 `allure generate` 生成 Allure HTML 报告
- 需用户预先安装 Allure 命令行工具

### 3.8 CI/CD 配置生成引擎

| 平台 | 生成文件 | 内容 |
|------|----------|------|
| **Jenkins** | `Jenkinsfile` | Pipeline 定义：安装依赖→启动目标服务→执行测试→生成报告→失败通知 |
| **GitHub Actions** | `.github/workflows/auto-test.yml` | Workflow 定义：checkout→setup→test→report→notify |
| **GitLab CI** | `.gitlab-ci.yml`（模板参考） | 同 GitHub Actions 结构 |
| **Azure Pipelines** | `azure-pipelines.yml`（模板参考） | 同 Jenkins 结构 |

**Jenkins 配置要点**：

- 支持 Declarative Pipeline 和 Scripted Pipeline 两种风格
- 包含 Playwright 安装阶段（`npx playwright install`）
- 测试结果归档（`archiveArtifacts`）
- HTML 报告发布（`publishHTML`）
- 失败邮件通知（`emailext`）

**GitHub Actions 配置要点**：

- 使用 `actions/checkout` + `actions/setup-node`
- Playwright 安装步骤
- 测试执行命令
- 报告上传为 Artifact
- 失败时 Slack/Email 通知（可选 Action）

---

## 4. YAML DSL 规范

### 4.1 用例文件结构

YAML DSL 用例文件遵循以下顶层结构：

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| name | string | ✅ | 用例名称，唯一标识 |
| description | string | ❌ | 用例描述 |
| framework | string | ❌ | 框架偏好：`playwright`（默认）或 `selenium` |
| capture | string | ❌ | 截图策略：`on-fail`（默认）或 `full` |
| tags | string[] | ❌ | 标签列表，用于分类和筛选 |
| metadata | object | ❌ | 自定义元数据（目标URL、超时等） |
| stages | Stage[] | ✅ | 测试阶段列表 |

### 4.2 顶层字段说明

**metadata 子字段**：

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| targetUrl | string | 测试目标基础 URL | `http://localhost:3000` |
| timeout | number | 全局超时秒数 | 30 |
| browser | string | 浏览器类型 | `chromium`、`firefox`、`webkit` |
| viewport | object | 视口尺寸 | `{width: 1280, height: 720}` |
| auth | object | 认证配置 | `{type: login, username: admin, password: xxx}` |

### 4.3 Stage 与 Step 定义

**Stage 结构**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| name | string | ✅ | 阶段名称（如登录、搜索、验证） |
| steps | Step[] | ✅ | 步骤列表 |

**Step 结构**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| action | string | ✅ | 操作类型：navigate/click/type/wait/scroll/upload/hover/select/assert |
| target | string | ✅ | 目标选择器或 URL |
| value | string | ❌ | 输入值（type/select 操作必填） |
| capture | string | ❌ | 步骤截图策略：`always` 或继承 stage 配置 |
| timeout | number | ❌ | 步骤超时秒数，覆盖全局配置 |

### 4.4 断言定义

断言作为 Step 的 `action: assert` 类型，附加 `assertions` 字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| type | string | ✅ | 断言类型：A1~A8 |
| target | string | ✅ | 断言目标选择器 |
| expected | string | ✅ | 预期值 |
| message | string | ❌ | 断言失败时的自定义消息 |

### 4.5 框架标记与捕获配置

**框架标记**：

- 用例顶层 `framework` 字段设置全局框架偏好
- 单个 Step 可通过 `frameworkOverride` 临时切换框架（仅限 Selenium 用例中的特定步骤降级）

**捕获配置**：

- 用例顶层 `capture: on-fail | full` 设置全局截图策略
- 单个 Step 通过 `capture: always` 强制该步骤截图
- Selenium 用例仅支持全页截图，不支持元素级截图标记

### 4.6 用例示例

**Playwright 用例示例**（登录测试）：

```yaml
name: user-login-test
description: 验证用户端登录流程
framework: playwright
capture: on-fail
tags: [auth, user, P1]
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
        type: A1
        target: .auth-form
        expected: visible
  - name: 输入凭证
    steps:
      - action: type
        target: .auth-form .el-form-item:first-child input
        value: testuser
      - action: type
        target: .auth-form .el-form-item:nth-child(2) input
        value: password123
      - action: click
        target: .auth-form .el-button--primary
        capture: always
  - name: 登录验证
    steps:
      - action: wait
        target: .header-user
        timeout: 5
      - action: assert
        type: A2
        target: /home
        expected: /home
      - action: assert
        type: A4
        target: .header-user .user-name
        expected: testuser
```

**Selenium 用例示例**（简化版登录测试）：

```yaml
name: admin-login-selenium
description: 验证管理端登录流程（Selenium框架）
framework: selenium
capture: on-fail
tags: [auth, admin, selenium]
metadata:
  targetUrl: http://localhost:3001
  timeout: 30
  browser: chrome
stages:
  - name: 登录
    steps:
      - action: navigate
        target: /login
      - action: type
        target: css=.login-form .el-form-item:first-child input
        value: admin
      - action: type
        target: css=.login-form .el-form-item:nth-child(2) input
        value: admin123
      - action: click
        target: css=.login-form .el-button--primary
      - action: wait
        target: css=.sidebar
        timeout: 5
      - action: assert
        type: A1
        target: css=.sidebar
        expected: visible
```

---

## 5. 数据模型

### 5.1 核心数据模型关系

```
AutoTestCase ──1:N──→ AutoTestStep
      │                    │
      │                    │
      ↓                    ↓
AutoTestResult ──1:N──→ AutoTestStepResult
      │                    │
      ↓                    ↓
AutoTestReport ──1:N──→ AutoTestResult
                        AutoTestStepResult ──0:1──→ ScreenshotFile
```

### 5.2 AutoTestCase 数据模型

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 用例 ID：`ATC-{YYYYMMDD}-{NNN}` |
| name | string | 用例名称 |
| description | string | 用例描述 |
| framework | string | 框架偏好：playwright/selenium |
| capture | string | 截图策略：on-fail/full |
| tags | string[] | 标签列表 |
| metadata | object | 元数据配置 |
| stages | Stage[] | 阶段列表 |
| source | string | 用例来源：generate/record/manual |
| createdAt | string | 创建时间（ISO 8601） |
| updatedAt | string | 更新时间（ISO 8601） |

**Stage 子模型**：

| 字段 | 类型 | 说明 |
|------|------|------|
| name | string | 阶段名称 |
| steps | Step[] | 步骤列表 |

**Step 子模型**：

| 字段 | 类型 | 说明 |
|------|------|------|
| action | string | 操作类型 |
| target | string | 目标选择器 |
| value | string | 输入值 |
| capture | string | 截图策略 |
| timeout | number | 步骤超时 |
| assertions | Assertion[] | 断言列表 |

**Assertion 子模型**：

| 字段 | 类型 | 说明 |
|------|------|------|
| type | string | 断言类型（A1~A8） |
| target | string | 断言目标 |
| expected | string | 预期值 |
| message | string | 失败消息 |

### 5.3 AutoTestResult 数据模型

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 结果 ID：`ATR-{YYYYMMDD}-{NNN}` |
| testCaseId | string | 关联用例 ID |
| testCaseName | string | 用例名称 |
| status | string | 整体状态：pass/fail/error/skip |
| totalSteps | number | 总步骤数 |
| passedSteps | number | 通过步骤数 |
| failedSteps | number | 失败步骤数 |
| skippedSteps | number | 跳过步骤数 |
| duration | number | 执行耗时（毫秒） |
| startTime | string | 开始时间（ISO 8601） |
| endTime | string | 结束时间（ISO 8601） |
| framework | string | 实际执行框架 |
| stepResults | StepResult[] | 步骤结果列表 |
| environment | object | 执行环境信息 |

**StepResult 子模型**：

| 字段 | 类型 | 说明 |
|------|------|------|
| stepIndex | number | 步骤序号 |
| action | string | 操作类型 |
| target | string | 目标 |
| expected | string | 预期值 |
| actual | string | 实际值 |
| status | string | 状态：pass/fail/error/skip |
| duration | number | 步骤耗时（毫秒） |
| errorMessage | string | 错误信息 |
| screenshotPath | string | 截图路径（如有） |

### 5.4 AutoTestReport 数据模型

| 字段 | 类型 | 说明 |
|------|------|------|
| title | string | 报告标题 |
| generatedAt | string | 生成时间（ISO 8601） |
| totalCases | number | 总用例数 |
| passedCases | number | 通过用例数 |
| failedCases | number | 失败用例数 |
| skippedCases | number | 跳过用例数 |
| passRate | string | 通过率（百分比） |
| totalDuration | number | 总耗时（毫秒） |
| results | AutoTestResult[] | 结果列表 |

### 5.5 工作区存储结构

```
.asdm/workspace/auto-test/
├── cases/                          # 测试用例存储
│   ├── user-login-test.yaml        # 每个用例一个 YAML 文件
│   ├── admin-login-selenium.yaml
│   └── ...
├── results/                        # 执行结果存储
│   ├── ATR-20260714-001.json       # 每次执行一个结果文件
│   └── ...
├── reports/                        # 测试报告存储
│   ├── report-20260714.html        # HTML 报告
│   ├── allure-results/             # Allure 中间数据（可选）
│   └── ...
├── screenshots/                    # 截图存储
│   ├── ATR-20260714-S03-fail.png   # 失败步骤截图
│   ├── ATR-20260714-S05-marked.png # 标记步骤截图
│   └── ...
└── ci/                             # CI/CD 配置输出
    ├── Jenkinsfile
    ├── .github/workflows/auto-test.yml
    └── ...
```

---

## 6. 接口设计

### 6.1 斜杠命令一览

| 命令 | GUID | 功能 | 对应 Action 文件 |
|------|------|------|-----------------|
| `/auto-test-generate` | 待分配 | 需求文档生成测试用例 | `actions/auto-test-generate.md` |
| `/auto-test-record` | 待分配 | 录制操作生成测试用例 | `actions/auto-test-record.md` |
| `/auto-test-run` | 待分配 | 执行自动化测试 | `actions/auto-test-run.md` |
| `/auto-test-list` | 待分配 | 列出用例与执行结果 | `actions/auto-test-list.md` |
| `/auto-test-report` | 待分配 | 生成 HTML 测试报告 | `actions/auto-test-report.md` |
| `/auto-test-ci` | 待分配 | 生成 CI/CD 配置 | `actions/auto-test-ci.md` |
| `/auto-test-clean` | 待分配 | 清理测试资源 | `actions/auto-test-clean.md` |

### 6.2 /auto-test-generate

**功能**：从 Markdown 需求文档自动生成 YAML DSL 测试用例

**输入参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| document | string | ✅ | Markdown 需求文档内容或文件路径 |
| framework | string | ❌ | 框架偏好，默认 playwright |
| outputDir | string | ❌ | 输出目录，默认 cases/ |

**执行流程**：
1. 读取 Markdown 文档，提取功能描述和验收标准
2. 生成测试场景（正向/逆向/边界值）
3. 转换为 YAML DSL 格式
4. 保存到 cases/ 目录

**输出**：YAML DSL 用例文件列表

### 6.3 /auto-test-record

**功能**：通过 Playwright Codegen 录制操作生成 YAML DSL 测试用例

**输入参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| url | string | ✅ | 目标页面 URL |
| framework | string | ❌ | 框架偏好，默认 playwright |
| browser | string | ❌ | 浏览器类型，默认 chromium |

**执行流程**：
1. 启动 Playwright Codegen 录制器
2. 用户操作浏览器
3. 录制结束后转换为 YAML DSL
4. 保存到 cases/ 目录

**输出**：YAML DSL 用例文件

### 6.4 /auto-test-run

**功能**：执行 YAML DSL 测试用例

**输入参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| case | string | ✅ | 用例文件路径或目录路径 |
| framework | string | ❌ | 框架偏好，覆盖用例设置 |
| capture | string | ❌ | 截图策略，覆盖用例设置 |
| env | string | ❌ | 环境配置（dev/staging/production） |

**执行流程**：
1. 加载 YAML DSL 用例
2. 根据 framework 字段选择引擎
3. 逐阶段执行步骤和断言
4. 失败步骤截图
5. 记录结果到 results/

**输出**：AutoTestResult JSON 文件

### 6.5 /auto-test-list

**功能**：列出测试用例和执行结果

**输入参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| type | string | ❌ | 列出类型：cases/results/all，默认 all |
| filter | string | ❌ | 筛选条件（标签、框架、状态） |

**执行流程**：
1. 读取 cases/ 或 results/ 目录
2. 按筛选条件过滤
3. 格式化输出表格

**输出**：Markdown 表格

### 6.6 /auto-test-report

**功能**：生成 HTML 测试报告

**输入参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| result | string | ❌ | 结果文件或目录，默认最近一次 |
| format | string | ❌ | 报告格式：html/allure，默认 html |

**执行流程**：
1. 读取执行结果数据
2. 生成 HTML 报告（卡片式摘要 + 用例详情 + 截图）
3. 保存到 reports/ 目录

**输出**：HTML 报告文件路径

### 6.7 /auto-test-ci

**功能**：生成 CI/CD 配置文件

**输入参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| platform | string | ✅ | 目标平台：jenkins/github-actions/gitlab-ci/azure-pipelines |
| casesDir | string | ❌ | 用例目录路径 |
| nodeVersion | string | ❌ | Node.js 版本，默认 18 |

**执行流程**：
1. 根据平台选择配置模板
2. 填充项目信息（用例路径、Node 版本等）
3. 生成配置文件

**输出**：CI/CD 配置文件

### 6.8 /auto-test-clean

**功能**：清理测试资源

**输入参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| scope | string | ✅ | 清理范围：results/reports/screenshots/all |
| confirm | boolean | ❌ | 确认执行，默认 false |

**执行流程**：
1. 确认清理范围
2. 删除对应目录下文件
3. 保留目录结构

**输出**：清理确认信息

---

## 7. 变更摘要

> 具体的文件组织、类名、包结构等技术决策由开发人员在实现阶段自行决定，以下仅列出需要新增或修改的功能模块和变更范围。

| 变更模块 | 变更类型 | 功能说明 | 关联需求 |
|----------|:--------:|----------|----------|
| `.asdm/toolsets/web-auto-tester/manifest.json` | 🔲 新增 | 工具集元数据注册文件 | D1 工具集定位 |
| `.asdm/toolsets/web-auto-tester/README.md` | 🔲 新增 | 工具集概览文档 | D1 工具集定位 |
| `.asdm/toolsets/web-auto-tester/INSTALL.md` | 🔲 新增 | 安装指南 | D7 斜杠命令 |
| `.asdm/toolsets/web-auto-tester/actions/` | 🔲 新增 | 7个斜杠命令 Action 文件 | D7 斜杠命令 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md` | 🔲 新增 | YAML DSL 用例格式规范 | D3 用例生成 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md` | 🔲 新增 | 执行引擎7阶段规范 | D2 双框架 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-report-spec.md` | 🔲 新增 | 报告格式规范（HTML+Allure） | D5 报告格式 |
| `.asdm/toolsets/web-auto-tester/spec/auto-test-ci-spec.md` | 🔲 新增 | CI/CD 配置生成规范 | D4 CI/CD |
| `.codebuddy/commands/auto-test-*.md` | 🔲 新增 | 7个命令快捷入口 | D7 斜杠命令 |
| `.asdm/workspace/auto-test/` | 🔲 新增 | 工作区目录结构 | D6 截图策略 |

---

## 8. 依赖关系

### 8.1 前置依赖

| 依赖特性 | 说明 | 状态 |
|----------|------|------|
| FT-003 web-smoke-tester | 数据模型骨架、Pipeline 阶段概念、断言类型分类的参考来源 | ✅ 已存在 |

> web-smoke-tester 是参考来源而非硬依赖，auto-tester 可独立运行。

### 8.2 后续依赖

| 依赖特性 | 说明 |
|----------|------|
| 无 | 当前无其他特性依赖本特性 |

### 8.3 代码库依赖

| 代码库 | 路径 | 交互方式 |
|--------|------|----------|
| `.asdm/toolsets/web-smoke-tester/` | 规范参考 | 参考 spec 设计风格和数据模型 |
| `.asdm/toolsets/release-note/` | 规范参考 | 参考 manifest.json 格式和 Action 文件结构 |
| `.codebuddy/commands/` | 命令注册 | 新增7个快捷命令 |
| `ai-fast-web/` | 测试目标 | 本工具集的目标测试项目 |

### 8.4 第三方依赖

| 依赖 | 类型 | 说明 | 是否必须 |
|------|------|------|:--------:|
| Playwright | npm 包 | 主框架浏览器自动化 | ✅ 必须 |
| Selenium WebDriver | npm 包 | 辅框架浏览器自动化 | ❌ 可选 |
| Allure Commandline | CLI 工具 | Allure 报告生成 | ❌ 可选 |
| Node.js 18+ | 运行环境 | 执行引擎运行环境 | ✅ 必须 |

---

## 9. 完成规范 (DoD)

> **状态说明**：
> - **已完成**：✅ 该功能点已实现，无需额外开发
> - **部分完成**：🟡 该功能点部分实现，需进一步完善
> - **待实现**：❌ 该功能点尚未实现，需要在开发阶段实现

### 9.1 核心功能

| 编号 | 完成点 | 说明 | 状态 | 完成状态说明 |
|------|--------|------|------|------------|
| 9.1.1 | 工具集目录结构 | manifest.json、README.md、INSTALL.md、actions/、spec/ 完整目录 | ❌ | 全部待创建 |
| 9.1.2 | manifest.json 元数据 | guid、registry_id、name、version、commands 完整注册 | ❌ | 需新建并分配 GUID |
| 9.1.3 | 7个斜杠命令 Action | generate/record/run/list/report/ci/clean 各命令流程定义 | ❌ | 需逐个编写 |
| 9.1.4 | YAML DSL 规范 | 用例格式定义（顶层字段、Stage、Step、Assertion） | ❌ | 需编写 dsl-spec |
| 9.1.5 | 需求文档生成引擎 | Markdown PRD → YAML DSL 用例转换规范 | ❌ | 需编写在 generate action 中 |
| 9.1.6 | 录制生成引擎 | Playwright Codegen → YAML DSL 用例转换规范 | ❌ | 需编写在 record action 中 |
| 9.1.7 | 执行引擎7阶段规范 | 用例加载→上下文→执行→断言→截图→记录→报告 | ❌ | 需编写 execution-spec |
| 9.1.8 | 双框架适配 | Playwright 主引擎 + Selenium 辅引擎操作映射 | ❌ | 需在 execution-spec 中定义 |
| 9.1.9 | 断言引擎 | 8种断言类型（A1~A8）规范定义 | ❌ | 需在 execution-spec 中定义 |
| 9.1.10 | 截图采集引擎 | on-fail/full/always 三策略 + 文件命名规范 | ❌ | 需在 execution-spec 中定义 |
| 9.1.11 | 报告生成引擎 | HTML 自定义报告 + 可选 Allure 导出规范 | ❌ | 需编写 report-spec |
| 9.1.12 | CI/CD 配置生成 | Jenkins/GitHub Actions 配置 + 其他平台模板 | ❌ | 需编写 ci-spec |
| 9.1.13 | 命令注册 | 7个 `.codebuddy/commands/` 快捷入口 | ❌ | 需创建7个 Follow 文件 |
| 9.1.14 | 工作区目录 | cases/results/reports/screenshots/ci 结构 | ❌ | 需创建目录和 .gitkeep |

### 9.2 数据一致性

| 编号 | 完成点 | 说明 | 状态 | 完成状态说明 |
|------|--------|------|------|------------|
| 9.2.1 | ID 生成一致性 | ATC/ATR ID 格式统一，全局唯一无冲突 | ❌ | 需在 spec 中定义规则 |
| 9.2.2 | 三种生成方式格式统一 | generate/record/manual 输出同一 YAML DSL 格式 | ❌ | 需确保 dsl-spec 覆盖所有来源 |
| 9.2.3 | manifest/action 一致性 | guid/id/name 在 manifest 和 action 三处一致 | ❌ | 需参照 release-note 模式 |
| 9.2.4 | 结果与用例关联 | ResulttestCaseId 正确关联 CaseID | ❌ | 需在 spec 中定义 |

### 9.3 用户体验

| 编号 | 完成点 | 说明 | 状态 | 完成状态说明 |
|------|--------|------|------|------------|
| 9.3.1 | INSTALL.md 清晰安装指引 | 检测引擎→注册命令→验证→示例完整流程 | ❌ | 需参照 release-note INSTALL 模式 |
| 9.3.2 | YAML DSL 可读性 | 格式与 smoke-tester Pipeline YAML 风格一致 | ❌ | 需参照 smoke-tester spec |
| 9.3.3 | HTML 报告可读性 | 卡片式摘要 + 折叠详情 + 截图内嵌 | ❌ | 需在 report-spec 中定义 |
| 9.3.4 | 错误提示友好 | 用例校验错误、框架不兼容、引擎缺失等提示 | ❌ | 需在 action 中定义错误处理 |

### 9.4 兼容性

| 编号 | 完成点 | 说明 | 状态 | 完成状态说明 |
|------|--------|------|------|------------|
| 9.4.1 | Playwright 完整功能 | 全部9种操作 + A1~A8 断言 + tracing 截图 | ❌ | 需在 execution-spec 中完整定义 |
| 9.4.2 | Selenium 基础功能 | 基础9种操作 + A1~A7 断言（不含A5/A8） | ❌ | 需定义 Selenium 适配层 |
| 9.4.3 | 框架降级策略 | Selenium 用例含 Playwright 专有操作时降级提示 | ❌ | 需在 execution-spec 中定义 |
| 9.4.4 | CI/CD 多平台 | Jenkins + GitHub Actions 直接生成 + 2个模板参考 | ❌ | 需在 ci-spec 中定义 |

---

## 10. 相关文档

- [FT-003 概要设计](./FT-003-web-auto-tester-Feature-Overall.md) — 概要设计文档，总体概述和使用场景来源
- [FT-003 需求访谈](./FT-003-web-auto-tester-AskMe.md) — 需求访谈追问，已确认决策汇总
- [FT-003 调研 — web-smoke-tester](./FT-003-web-auto-tester-CodeResearch-web-smoke-tester.md) — 现有冒烟测试工具集调研
- [FT-003 调研 — ai-fast-web](./FT-003-web-auto-tester-CodeResearch-ai-fast-web.md) — 目标测试项目调研
- [FT-003 调研 — codebuddy-commands](./FT-003-web-auto-tester-CodeResearch-codebuddy-commands.md) — 命令注册机制调研
- [FT-003 调研 — release-note](./FT-003-web-auto-tester-CodeResearch-release-note.md) — 工具集规范参考调研
- [ASDM 产品规划](../../ASDM-ProductPlanning.md) — 产品规划总览
- [web-smoke-tester README](../../../.asdm/toolsets/web-smoke-tester/README.md) — 冒烟测试工具集参考
- [release-note README](../../../.asdm/toolsets/release-note/README.md) — 工具集规范模板参考
