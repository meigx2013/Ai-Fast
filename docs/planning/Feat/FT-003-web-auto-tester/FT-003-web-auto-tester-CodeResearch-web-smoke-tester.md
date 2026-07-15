# FT-003 Code Research — web-smoke-tester

> 代码库路径：`.asdm/toolsets/web-smoke-tester/`
> 扫描日期：2026-07-13

---

## 1. 目录结构与关键文件

```
.asdm/toolsets/web-smoke-tester/
├── README.md                          — 工具集概览与元数据
├── INSTALL.md                         — 安装流程与命令注册
├── actions/                           — 斜杠命令定义目录
│   ├── smoke-test-run.md              — 核心：执行冒烟测试
│   ├── smoke-test-list.md             — 列出测试记录
│   ├── smoke-test-report.md           — 生成汇总报告
│   └── smoke-test-clear.md            — 清空测试记录
└── spec/                              — 规范文档目录
    ├── smoke-test-shared-spec.md      — 共享规范：数据模型、存储、输出
    ├── smoke-test-pipeline-spec.md    — 执行Pipeline规范
    └── smoke-test-report-spec.md      — 报告规范
```

**关键发现**：该工具集**没有 `manifest.json`**，元数据嵌入在 README.md 的 YAML 式头部中。这是与 release-note 等其他工具集的差异点。

---

## 2. 现有实现分析

### 2.1 核心设计理念

该工具集是**纯粹的规范驱动型（spec-driven）**，不存在任何 `.ts`、`.py`、`.js` 的实现代码。所有"引擎"功能由 **AI Agent 按规范文档执行** 实现。

### 2.2 虚拟引擎（由 AI Agent 执行规范实现）

| 虚拟引擎 | 定义位置 | 能力 |
|----------|---------|------|
| 步骤解析器 | pipeline-spec Phase 1 | 自然语言→SmokeTestStep[]；操作类型映射（打开/输入/点击/验证/等待/上传/滚动） |
| 上下文加载器 | pipeline-spec Phase 2 | 读取项目信息、环境配置、认证信息；环境健康检测 |
| 执行引擎 | pipeline-spec Phase 3 | 3种模式：代码分析/浏览器/混合；30秒超时；快速失败策略 |
| 断言引擎 | pipeline-spec Phase 4 | 5种断言类型：页面可见/页面跳转/元素状态/内容匹配/API响应 |
| 记录生成器 | pipeline-spec Phase 5 | 填充SmokeTestRecord；ID生成STR-{YYYYMMDD}-{NNN}；持久化JSON |
| 输出格式化器 | pipeline-spec Phase 6 + report-spec | Markdown表格输出；3种格式：即时/列表/完整报告 |

### 2.3 数据模型 Schema

| 模型 | 关键字段 |
|------|----------|
| SmokeTestRecord | id, scenarioName, steps[], status(pass/fail/error/skip), totalSteps, passedSteps, failedSteps, duration, startTime, endTime, tags[] |
| SmokeTestStep | stepIndex, action, target, inputValue, expected, actual, status(pass/fail/skip/pending), duration, errorMessage |
| SmokeTestReport | title, generatedAt, totalScenarios, passedScenarios, failedScenarios, passRate, records[] |

### 2.4 存储结构

```
.smoke-tester/
├── records/
│   ├── STR-20260609-001.json    # 每条记录一个文件
│   └── ...
└── latest-report.json           # 最近汇总报告
```

### 2.5 执行流程

```
用户输入 → Phase1 解析 → Phase2 上下文加载 → Phase3 执行 → Phase4 断言 → Phase5 记录 → Phase6 输出
```

### 2.6 4个斜杠命令

| 命令 | GUID | 功能 |
|------|------|------|
| `/smoke-test-run` | f1a2b3c4-...-b01 | 核心执行：自然语言→步骤→执行→断言→记录→输出 |
| `/smoke-test-list` | f1a2b3c4-...-b02 | 列出记录：读取JSON→筛选→排序→表格 |
| `/smoke-test-report` | f1a2b3c4-...-b03 | 生成报告：统计→格式化→AI分析→持久化 |
| `/smoke-test-clear` | f1a2b3c4-...-b04 | 清空：确认→删除JSON→保留目录→确认 |

---

## 3. 关键发现与缺失项

| 编号 | 发现/缺失项 | 说明 |
|------|------------|------|
| smoke-G1 | **无 manifest.json** | 元数据在 README.md 中，不符合 ASDM 工具集标准格式 |
| smoke-G2 | **无实际引擎代码** | 纯规范驱动，AI 模拟执行，无 Playwright/Selenium 实际驱动 |
| smoke-G3 | **无 YAML DSL 用例格式** | 仅支持自然语言输入，无结构化用例管理 |
| smoke-G4 | **无 HTML 报告** | 仅 Markdown 表格输出，无卡片式 HTML 报告 |
| smoke-G5 | **无截图机制** | 规范中提及但未实现任何截图采集逻辑 |
| smoke-G6 | **无 CI/CD 集成** | 不支持 Jenkins/GitHub Actions 配置生成 |
| smoke-G7 | **无用例生成/录制** | 无需求文档→用例生成、无录制→用例转换 |
| smoke-G8 | **单场景执行** | 不支持套件编排、多用例批量执行、并行策略 |
| smoke-G9 | **无 Selenium 支持** | 仅提及 Playwright 概念，未实现双框架 |

---

## 4. 可复用资产

从 smoke-tester 可直接迁移到 auto-tester 的设计资产：

| 可复用内容 | 来源 |
|-----------|------|
| 数据模型骨架 | SmokeTestRecord/Step 接口 → 可扩展为 AutoTestRecord |
| ID 生成规则 | STR-{YYYYMMDD}-{NNN} → 可调整前缀 |
| 状态枚举 | pass/fail/error/skip → 可复用并扩展 |
| 断言类型分类 | 5种断言类型 → 可扩展更多断言类别 |
| Action 文件结构 | Metadata+Process+Input+Output+Configuration → 直接复用 |
| INSTALL 模式 | 检测Engine→注册命令→引用指引 → 直接复用 |
| Pipeline 6阶段概念 | 解析→加载→执行→断言→记录→输出 → 可扩展 |
| 存储目录模式 | records/ + latest-report.json → 可扩展为 cases/results/reports/screenshots |

---

## 5. 与 web-auto-tester 的差距对比

| 维度 | smoke-tester | auto-tester(规划) | 差距 |
|------|-------------|-----------------|------|
| 测试级别 | 冒烟 P0/P1 | 全面功能测试 | 需扩展断言 |
| 驱动方式 | 自然语言 | YAML DSL/AI生成/录制 | 需3种新引擎 |
| 用例管理 | 无 | cases/ 目录管理 | 完全缺失 |
| 测试框架 | AI模拟 | Playwright+Selenium | 需双框架适配 |
| 报告 | Markdown表格 | HTML+可选Allure | 需HTML报告生成器 |
| 截图 | 无 | 默认失败+可选全步骤 | 完全缺失 |
| CI/CD | 不支持 | Jenkins/GitHub Actions | 完全缺失 |
| 斜杠命令 | 4个 | 7个 | 需新增generate/record/ci |

---

## 6. 与其他代码库的交互接口

- **`.codebuddy/commands/`**：4个命令快捷入口指向 actions/ 文件
- **`.asdm/workspace/`**：工作区存储 `.smoke-tester/` 目录下
- **无跨代码库 API 调用**：纯本地文件系统操作
