# Web Auto Tester 工具集 — 详细使用指南

**Toolset ID**: `web-auto-tester`
**Version**: v0.0.3
**Updated**: 2026-08-26

---

## 一、工具集概览

| 项目 | 值 |
|------|-----|
| **ID** | `web-auto-tester` |
| **版本** | v0.0.3 |
| **定位** | Web 系统自动化测试工具集，支持 AI 生成、浏览器录制、流水线编排执行、列表、报告、清理 |
| **框架支持** | Playwright（主框架）/ Selenium（辅框架） |
| **核心特色** | YAML DSL 用例驱动、8 种断言类型（A1~A8）、3 种截图策略、HTML 报告 + Allure 导出 |
| **工作目录** | `.asdm/workspace/auto-test/` |
| **语言** | 中文（简体中文） |

---

## 二、6 个斜杠命令速查表

| 命令 | 用途 | 快捷入口 |
|------|------|----------|
| `/auto-test-generate` | 根据测试用例描述 AI 自动生成 YAML DSL 测试用例 | `.codebuddy/commands/auto-test-generate.md` |
| `/auto-test-record` | 通过 Playwright Codegen 录制操作生成 YAML DSL 用例 | `.codebuddy/commands/auto-test-record.md` |
| `/auto-test-run` | 执行 YAML DSL 测试用例，生成执行结果 JSON | `.codebuddy/commands/auto-test-run.md` |
| `/auto-test-list` | 列出测试用例和执行结果 | `.codebuddy/commands/auto-test-list.md` |
| `/auto-test-report` | 生成 HTML 测试报告（可选 Allure 导出） | `.codebuddy/commands/auto-test-report.md` |
| `/auto-test-clean` | 清理测试工作区资源 | `.codebuddy/commands/auto-test-clean.md` |

---

## 三、命令详细说明

### 3.1 `/auto-test-generate` — AI 生成测试用例

**用途**：根据用户提供的测试用例描述自动生成 YAML DSL 测试用例，支持自然语言描述、结构化步骤描述、Markdown 测试文档三种输入方式，覆盖正向/逆向/边界值场景。

**参数说明**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| `description` | string | ✅ | 测试用例描述内容或文件路径（支持自然语言、结构化步骤、Markdown 文档） |
| `framework` | string | ❌ | 框架偏好，默认 `playwright` |
| `outputDir` | string | ❌ | 输出目录，默认 `.asdm/workspace/auto-test/cases/` |
| `coverage` | string | ❌ | 覆盖深度：`min` / `standard`（默认）/ `deep` |
| `dataParam` | string | ❌ | 数据参数化开关：`true` / `false`（默认） |

**执行流程（6 步）**：

1. **读取与解析测试用例描述** — 自动识别输入格式（结构化步骤/自然语言/Markdown文档），提取操作步骤、UI元素、输入值和验证点
2. **生成测试场景** — 为每个用例生成正向 + 逆向 + 边界值场景（标准覆盖：1 正向 + N 逆向）
3. **转换为 YAML DSL 结构** — 按操作类型映射表将场景操作转为 Step，推断选择器（基于 UI 元素描述和位置信息）
4. **自动推断断言** — navigate→A1/A2，click→A1/A2/A4，错误提示→A1+A4，边界值→A1/A4
5. **设置元数据与框架标记** — 标记 `source: generate`，自动推断标签，支持数据参数化
6. **输出 YAML 文件与审核提示** — 保存用例，提示用户验证选择器和断言

**命令示例**：

```
# 结构化步骤描述
/auto-test-generate description="1. 浏览器地址栏输入：https://platform-dt02.asdm.ai/ 2. 点击【登录】 3. 输入邮箱：admin@test.com 4. 输入密码：pass123 5. 点击【登录】按钮"

# Markdown 文件路径
/auto-test-generate description=docs/test-cases/login-test.md

# 自然语言描述
/auto-test-generate description="打开ASDM平台，点击右上角登录按钮，输入邮箱和密码，点击登录"

# 带参数
/auto-test-generate description="1. 打开 https://example.com 2. 输入用户名 3. 输入密码 4. 点击登录" framework=playwright coverage=deep dataParam=true
```

**输出示例**：

```yaml
name: asdm-login-happy-path
description: 验证用户通过ASDM平台登录流程（正向场景）
framework: playwright
capture: on-fail
tags: [auth, login, happy-path, P1]
source: generate
params:
  email: super-admin@asdm.ai
  password: superadmin@20260214
metadata:
  targetUrl: https://platform-dt02.asdm.ai/
  timeout: 30
  browser: chromium
stages:
  - name: 访问ASDM平台
    steps:
      - action: navigate
        target: https://platform-dt02.asdm.ai/
      - action: assert
        assertions:
          - type: A1
            target: .header
            expected: visible
            message: ASDM平台页面应可见
  - name: 点击登录入口
    steps:
      - action: click
        target: .header .login-btn
        pageTransition: navigate
      - action: assert
        assertions:
          - type: A1
            target: .login-form
            expected: visible
            message: 登录表单应可见
  - name: 输入凭证
    steps:
      - action: type
        target: .login-form input[name="email"]
        value: "{{params.email}}"
      - action: type
        target: .login-form input[name="password"]
        value: "{{params.password}}"
      - action: click
        target: .login-form .btn-primary
        capture: always
  - name: 登录验证
    steps:
      - action: wait
        target: .user-info
        timeout: 5
      - action: assert
        assertions:
          - type: A2
            target: current-url
            expected: /dashboard
            message: 登录成功后应跳转到仪表盘页面
          - type: A1
            target: .user-info
            expected: visible
            message: 用户信息区域应可见
```

---

### 3.2 `/auto-test-record` — 逐用例会话录制

**用途**：通过 Playwright Codegen 启动持久浏览器会话，逐用例录制操作，每条用例完成后执行 8 子步骤后处理，输出 4 区块优化摘要。

**参数说明**：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|:----:|--------|------|
| `url` | string | ✅ | — | 目标 URL（如 `http://localhost:3000`） |
| `framework` | string | ❌ | `playwright` | 框架偏好（录制仅支持 Playwright） |
| `browser` | string | ❌ | `chromium` | 浏览器类型 |
| `tags` | string[] | ❌ | [] | 用例标签，如 `module:auth,feature:login` |
| `dataParam` | boolean | ❌ | `false` | 数据参数化开关，`true` 时提取输入值为参数变量 |
| `pageMapFile` | string | ❌ | null | 页面元素映射文件路径（辅助断言推断） |
| `selectorStrategy` | string | ❌ | `optimize` | 选择器策略：`optimize`（自动优化）或 `raw`（保留原始） |

**执行流程（8 步）**：

1. **会话初始化** — 相似用例检测 → Playwright 可用检查 → 启动 Codegen → 输出启动提示
2. **用户操作录制** — Codegen 实时录制 + 多页面/弹窗检测标记
3. **完成断点触发** — `/next` 完成当前用例 / `/end` 结束会话
4. **用例命名** — 用户指定名称（小写+连字符），校验非空/格式/不重名
5. **后处理（8 子步骤）**：
   - **5a** 提取操作序列 — 从 Codegen 代码解析操作 + 选择器清洗 + URL 处理
   - **5b** 选择器优化 — 10 级优先级表评估 + 5 种优化操作（缩短路径/替代 nth-child/替代动态 ID/语义化替代/路径精简）
   - **5c** 断言推断 — navigate→A1+A2、click→A1+A2+A4、type→A4+A6、select→A6、wait→A1，标注 confidence + inferredFrom
   - **5d** 步骤优化 — 表单填写组合并（`# [form-fill-group]`）、智能等待替代、冗余等待去除、Stage 划分
   - **5e** 数据参数化 — type/select value → `{{params.xxx}}`（仅 `dataParam=true` 时）
   - **5f** 元数据增强 — recordedAt/duration/pageTitle/pageStructure/frontFramework/viewportActual
   - **5g** 多页面标记 — pageTransition/pageContext 字段填充
   - **5h** Stage 划分与 YAML 组装
6. **优化摘要展示** — 4 区块表格（选择器优化 / 断言推断 / 步骤优化 / 数据参数化）
7. **保存 YAML + Codegen 重启** — 保存文件 → 重启 Codegen → 浏览器保持
8. **会话结束** — `/end` → 关闭浏览器 → 输出会话摘要

**信号说明**：

| 信号 | 含义 | 流向 |
|------|------|------|
| `/next` | 完成当前用例，暂停录制进入命名 | → Step 4（用例命名） |
| `/end` | 结束整个会话，不再录制 | → Step 8（会话结束） |

**命令示例**：

```
# 基础录制
/auto-test-record url=http://localhost:3000

# 带标签的模块化录制
/auto-test-record url=http://localhost:3000 tags=module:auth,feature:login

# 启用数据参数化（适合数据驱动测试）
/auto-test-record url=http://localhost:3000 dataParam=true

# 提供页面映射文件（提升断言推断置信度）
/auto-test-record url=http://localhost:3000 pageMapFile=./page-map.yaml

# 保留原始选择器（调试场景）
/auto-test-record url=http://localhost:3000 selectorStrategy=raw

# 完整参数组合
/auto-test-record url=http://localhost:3000 tags=module:auth,feature:login dataParam=true pageMapFile=./page-map.yaml selectorStrategy=optimize
```

**输出示例（参数化 + 增强 metadata）**：

```yaml
name: user-login-test
description: 验证用户端登录流程（逐用例会话录制）
framework: playwright
capture: on-fail
tags: [auth, user, P1]
source: record
params:
  username: testuser
  password: password123
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
  browser: chromium
  recordedAt: "2026-07-20T10:30:00Z"
  duration: 45
  pageTitle: 登录
  frontFramework: vue
  pageStructure:
    hasSidebar: false
    hasNavbar: true
    hasFooter: false
    mainContentSelector: .auth-form
    layoutType: top-nav
  viewportActual:
    width: 1280
    height: 720
stages:
  - name: 登录页面访问
    steps:
      - action: navigate
        target: /login
        pageTransition: navigate
      - action: assert
        assertions:
          - type: A1
            target: .auth-form
            expected: visible
            confidence: high
            inferredFrom: "navigate后[data-testid]"
            message: 登录表单应可见
  - name: 输入凭证
    steps:
      # [form-fill-group] 表单填写组：登录表单
      - action: type
        target: input[name="username"]
        value: "{{params.username}}"
      - action: type
        target: input[name="password"]
        value: "{{params.password}}"
      - action: click
        target: button[type="submit"]
  - name: 登录验证
    steps:
      - action: assert
        assertions:
          - type: A2
            target: current-url
            expected: /home
            confidence: high
            inferredFrom: "click后URL实际跳转"
            message: 登录成功后应跳转到首页
```

---

### 3.3 `/auto-test-run` — 执行自动化测试

**用途**：读取全部 YAML DSL 测试用例后自动编排执行流水线（用例先后依赖 DAG + 参数依赖传递），生成 sh 执行脚本，按依赖分层顺序执行；case 指向单个文件时为单用例模式（跳过编排，向后兼容）。

**参数说明**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| `case` | string | ✅ | 用例文件路径（单用例模式）、目录路径（流水线模式），或留空使用默认 `cases/` 目录（流水线模式） |
| `framework` | string | ❌ | 框架偏好，覆盖用例设置（`playwright` / `selenium`） |
| `capture` | string | ❌ | 截图策略，覆盖用例设置（`on-fail` / `full`） |
| `mode` | string | ❌ | 编排执行模式：`sequence`（默认，按拓扑序全串行）/ `parallel`（同层无依赖用例并行） |
| `dryRun` | boolean | ❌ | `true` 时仅加载用例 + 编排 + 生成 sh 脚本与编排图，不实际执行；默认 `false` |

**流水线编排 DSL 扩展**（在用例 `metadata` 中声明）：

| 扩展字段 | 说明 | 示例 |
|----------|------|------|
| `metadata.dependsOn` | 用例级硬依赖声明（数组，值为被依赖用例名） | `dependsOn: [user-login-test]` |
| `metadata.outputs` | 本用例输出声明（供下游引用，从步骤结果提取） | `auth_token: {from: step, stepIndex: 5, field: actual}` |
| `params` 值中的 `{{outputs.X.y}}` | 跨用例参数引用（隐式建立硬依赖，运行时从参数上下文注入） | `token: "{{outputs.user-login-test.auth_token}}"` |

**依赖推断规则（无显式声明时自动编排）**：

| 优先级 | 信号 | 强度 |
|:------:|------|------|
| D1 | `metadata.dependsOn` 显式声明 | 硬依赖 |
| D2 | params 含 `{{outputs.X.y}}` 引用 | 硬依赖 |
| D3 | 文件名数字前缀（`01-login.yaml` → `02-order.yaml`） | 软依赖（推断） |
| D4 | tags 语义（auth/login → 根节点；create 先于 query/delete） | 软依赖（推断） |
| D5 | 同 targetUrl 系统分组（跨系统可并行） | 软依赖（分组） |

硬依赖上游 fail/error → 下游用例自动 BLOCKED（skip）；软依赖不阻塞执行。硬依赖成环 → 报错终止；软依赖成环 → 降级同层并行。

**编排执行 Pipeline**：

| Phase | 名称 | 说明 |
|:-----:|------|------|
| 1 | 用例全量加载 | YAML 解析 → Schema 校验 → 数据提取摘要 |
| 1.5 | 流水线编排 | 依赖图构建 → 参数依赖构建 → 环检测 → 拓扑分层 → 编排图 → **生成 sh 执行脚本** |
| 2 | 上下文准备 | 读取 metadata → 参数解析（本地 + 跨用例）→ 6 项数据自检 |
| 3 | 执行引擎 | 按编排顺序逐用例：依赖检查（BLOCKED 判定）→ 逐步骤执行 |
| 4 | 断言判定 | 8 种断言类型（A1~A8）→ 结果映射 pass/fail/error/skip |
| 5 | 截图采集 | on-fail/full/always 三策略 → 文件命名 → 存储到 screenshots/ |
| 6 | 结果记录 | AutoTestResult JSON → outputs 提取 → ctx 写入 → 状态回写 |
| 7 | 报告输出 | 流水线级汇总表格 + 结构化 JSON |

**编排产物**（保存到 `.asdm/workspace/auto-test/pipelines/`）：

| 产物 | 说明 |
|------|------|
| `pipeline-{YYYYMMDD}-{NNN}.sh` | sh 执行脚本（支持 `--dry-run` / `--only {case}` 参数） |
| `PIPE-{YYYYMMDD}-{NNN}.ctx.env` | 参数上下文（上游用例输出注入，下游 `{{outputs.X.y}}` 解析来源） |
| `PIPE-{YYYYMMDD}-{NNN}.status` | 流水线状态（`{case}={pass\|fail\|error\|skip:BLOCKED_BY:{dep}}`） |

**框架选择与降级策略**：

```
1. 读取用例 framework 字段
2. framework=playwright → 使用 Playwright 引擎执行
3. framework=selenium:
   a. 检查是否含 A5/A8 断言
   b. 如含专有特性 → 降级为 playwright + 提示
   c. 否则 → 使用 Selenium 引擎执行
4. Step 级 frameworkOverride:
   a. 仅支持 selenium→playwright 降级方向
```

**认证处理**（metadata.auth）：

| 认证方式 | 执行逻辑 |
|----------|----------|
| `login` | 先访问 loginUrl → 输入用户名+密码 → 获取登录态 |
| `token` | 在浏览器中注入 localStorage 或 cookie |
| `basic` | 设置 HTTP Basic Auth 头 |

**命令示例**：

```
# 流水线模式：加载全部用例 → 自动编排 → 生成 sh → 顺序执行
/auto-test-run
/auto-test-run case=.asdm/workspace/auto-test/cases/

# 流水线模式：同层并行执行
/auto-test-run case=cases/ mode=parallel

# 编排预演：只生成编排图与 sh 脚本，不执行
/auto-test-run dryRun=true

# 单用例模式：跳过编排，直接 7 阶段执行（向后兼容）
/auto-test-run case=user-login-test.yaml
/auto-test-run case=admin-login-test.yaml framework=playwright capture=full
```

**输出示例**：

```markdown
### 🧪 自动化测试流水线执行结果：PIPE-20260826-001

| 用例 | 层级 | 硬依赖 | 状态 | 步骤 | 耗时 | 结果文件 |
|------|:----:|--------|:----:|------|:----:|---------|
| user-login-test | L1 | — | ✅ pass | 7/7 | 8.5s | ATR-20260826-001.json |
| order-create-test | L2 | user-login-test | ❌ fail | 3/6 | 5.2s | ATR-20260826-003.json |
| order-query-test | L3 | order-create-test | ⏭️ skip | 0/5 | — | —（BLOCKED_BY: order-create-test） |

**流水线状态**：❌ 失败 | **用例**：1 通过 / 1 失败 / 1 跳过 | **总耗时**：13.7s
**执行脚本**：pipelines/pipeline-20260826-001.sh
```

---

### 3.4 `/auto-test-list` — 列出用例与结果

**用途**：列出测试用例和执行结果，以 Markdown 表格形式展示，支持筛选过滤。

**参数说明**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| `type` | string | ❌ | 列出类型：`cases` / `results` / `all`（默认） |
| `filter` | string | ❌ | 篮选条件（`tag` / `framework` / `status` / `name`） |

**3 种展示模式**：

| 模式 | 说明 |
|------|------|
| `cases` | 列出 `cases/` 目录下所有 YAML 用例 |
| `results` | 列出 `results/` 目录下所有执行结果 |
| `all` | 合并展示（默认） |

**4 种筛选参数**：

| 过滤参数 | 适用模式 | 过滤规则 | 示例 |
|----------|----------|----------|------|
| `tag=XXX` | cases | 用例 tags 包含指定标签 | `tag=auth` |
| `framework=XXX` | cases/results | framework 字段匹配 | `framework=selenium` |
| `status=XXX` | results | status 字段匹配 | `status=fail` |
| `name=XXX` | cases/results | name 包含关键词 | `name=login` |

**命令示例**：

```
/auto-test-list
/auto-test-list type=cases
/auto-test-list type=results
/auto-test-list type=results filter=status=fail
/auto-test-list type=cases filter=tag=auth
/auto-test-list type=all filter=name=login
```

**输出示例（Cases 列表）**：

```markdown
## 📋 测试用例列表

> 共 2 个用例 | Playwright: 1 | Selenium: 1

| # | 用例名称 | 框架 | 标签 | 来源 | 步骤数 | 目标 URL | 创建时间 |
|:-:|---------|:----:|------|:----:|:------:|---------|---------|
| 1 | user-login-test | playwright | auth, user, P1 | manual | 7 | http://localhost:3000 | 2026-07-14 |
| 2 | admin-login-selenium | selenium | auth, admin | manual | 5 | http://localhost:3001 | 2026-07-14 |
```

**输出示例（Results 列表）**：

```markdown
## 📋 执行结果列表

> 共 2 条结果 | ✅ 1 通过 | ❌ 1 失败

| # | 结果 ID | 用例名称 | 状态 | 步骤通过 | 耗时 | 执行框架 | 执行时间 | 失败原因 |
|:-:|---------|---------|:----:|:-------:|:----:|:-------:|---------|---------|
| 1 | ATR-20260714-001 | user-login-test | ✅ pass | 7/7 | 8.5s | playwright | 2026-07-14 10:30 | - |
| 2 | ATR-20260714-002 | admin-login-selenium | ❌ fail | 3/5 | 5.2s | selenium | 2026-07-14 10:35 | Step 4 断言失败 |
```

---

### 3.5 `/auto-test-report` — 生成测试报告

**用途**：读取执行结果 JSON，生成 HTML 自定义报告或 Allure 格式报告。

**参数说明**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| `result` | string | ❌ | 结果文件路径、目录路径、`latest`（最近一次），默认加载全部 |
| `format` | string | ❌ | 报告格式：`html`（默认）/ `allure` / `both` |

**HTML 报告 5 区域结构**：

| 区域 | 内容 |
|------|------|
| 1. 报告标题 | 标题 + 生成时间 + 用例统计摘要 |
| 2. 摘要卡片 | 5 个渐变卡片（通过率/通过数/失败数/总步骤/总耗时） |
| 3. 用例列表 | 每行一个用例，含状态色标签（✅/❌/⚠️/⏭️） |
| 4. 步骤详情 | 折叠面板 + 步骤表格 + 截图展示（base64 内嵌） |
| 5. 统计图表 | 通过率分布条形图 + 断言类型分布图 |

**Allure 导出流程**：

1. 检测 `allure --version` 可用性
2. AutoTestResult → Allure JSON 格式转换
3. 状态映射：pass→passed, fail→failed, error→broken, skip→skipped
4. 截图转换为 Allure attachment
5. `allure generate allure-results -o allure-report --clean`

**Allure 不可用降级**：仅生成 HTML 报告 + 提示安装命令 `npm install -g allure-commandline`

**命令示例**：

```
/auto-test-report
/auto-test-report result=latest
/auto-test-report result=.asdm/workspace/auto-test/results/
/auto-test-report result=ATR-20260714-001.json
/auto-test-report result=latest format=allure
/auto-test-report format=both
```

**输出示例**：

```markdown
### 📊 测试报告已生成

> 总用例 7 | ✅ 通过 6 (85.71%) | ❌ 失败 1 | ⚠️ 异常 0 | ⏭️ 跳过 0

**总步骤**：35 (30 通过 / 5 失败 / 0 跳过)
**总耗时**：45200ms (平均 6500ms/用例)
**执行框架**：Playwright 5 / Selenium 2

**报告路径**：`.asdm/workspace/auto-test/reports/report-20260714-001.html`
```

---

### 3.6 `/auto-test-clean` — 清理测试资源

**用途**：清理测试工作区中的过期资源，保留目录结构和 `.gitkeep`。

**参数说明**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| `scope` | string | ❌ | 清理范围：`results` / `reports` / `screenshots` / `all`，未指定则交互式选择 |
| `confirm` | string | ❌ | 确认标志：`true`（直接执行）/ `false`（需确认，默认） |

**4 种清理范围**：

| 范围 | 清理内容 |
|------|----------|
| `results` | `results/` 下的所有 `ATR-*.json` 文件 |
| `reports` | `reports/` 下的所有 `report-*.html` + `allure-results/` + `allure-report/` |
| `screenshots` | `screenshots/` 下的所有 `*.png` 文件 |
| `all` | 以上三项全部清理 |

**清理规则**：
- 列出文件数量和大小 → 用户确认 → 删除文件
- 保留 `.gitkeep` 文件和目录结构
- 不删除 `cases/` 目录及其内容

**命令示例**：

```
/auto-test-clean
/auto-test-clean scope=results
/auto-test-clean scope=all confirm=true
/auto-test-clean scope=screenshots confirm=true
/auto-test-clean scope=reports
```

**输出示例**：

```markdown
### 🧹 清理完成

> 清理范围：all | 删除 16 个文件 | 释放 1.45 MB 空间

**保留内容**：
- ✅ 目录结构完整保留
- ✅ .gitkeep 文件保留
- ✅ cases/ 用例文件未受影响
```

---

## 四、YAML DSL 用例格式规范

### 4.1 顶层结构

```yaml
name: string               # 必填，用例名称，唯一标识
description: string         # 可选，用例描述
framework: string           # 可选，playwright(默认)或selenium
capture: string             # 可选，on-fail(默认)或full
tags: string[]              # 可选，标签列表，用于分类和筛选
params: object              # 可选，参数名→默认值映射，{{params.xxx}}引用
metadata: object            # 可选，自定义元数据
source: string              # 可选，用例来源：generate/record/manual
stages: Stage[]             # 必填，测试阶段列表
```

### 4.2 metadata 子字段

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `targetUrl` | string | 测试目标基础 URL | `http://localhost:3000` |
| `timeout` | number | 全局超时秒数（默认 30） | `30` |
| `browser` | string | 浏览器类型 | `chromium`、`firefox`、`webkit`、`chrome` |
| `viewport` | object | 视口尺寸 | `{width: 1280, height: 720}` |
| `auth` | object | 认证配置 | `{type: login, username: admin, password: xxx}` |
| `recordedAt` | string | 录制时间（ISO 8601） | `2026-07-20T10:30:00Z` |
| `duration` | number | 录制耗时（秒） | `45` |
| `pageTitle` | string | 页面标题 | `登录` |
| `pageStructure` | object | 页面结构信息 | 见下表 |
| `viewportActual` | object | 实际视口尺寸 | `{width: 1280, height: 720}` |
| `frontFramework` | string | 前端框架识别 | `vue` / `react` / `angular` / `unknown` |

**pageStructure 子字段**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `hasSidebar` | boolean | 是否有侧边栏 |
| `hasNavbar` | boolean | 是否有导航栏 |
| `hasFooter` | boolean | 是否有页脚 |
| `mainContentSelector` | string | 主内容区域选择器 |
| `layoutType` | string | 布局类型：`sidebar-left` / `sidebar-right` / `top-nav` / `full-page` |

**auth 子字段**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | 认证方式：`login` / `token` / `basic` |
| `username` | string | 用户名（login 类型） |
| `password` | string | 密码（login 类型） |
| `token` | string | 认证令牌（token 类型） |
| `loginUrl` | string | 登录页面路径（login 类型） |

### 4.3 Stage 与 Step 定义

**Stage**：

```yaml
stages:
  - name: string             # 必填，阶段名称
    steps: Step[]            # 必填，步骤列表
```

**Step**：

```yaml
steps:
  - action: string          # 必填，操作类型
    target: string          # 必填，目标选择器或 URL
    value: string           # 可选，输入值（type/select必填），支持 {{params.xxx}}
    pageContext: string     # 可选，main(默认)/popup/newTab
    pageTransition: string  # 可选，none(默认)/navigate/new-tab/new-window
    capture: string         # 可选，步骤截图策略：always强制截图
    timeout: number         # 可选，步骤超时秒数
    frameworkOverride: string  # 可选，步骤级框架偏好覆盖
    assertions: Assertion[]    # 可选，断言列表（action:assert时使用）
```

### 4.4 操作类型映射

| 操作类型 | 说明 | target | value | Playwright API | Selenium API |
|----------|------|--------|-------|----------------|--------------|
| `navigate` | 打开页面 | URL路径 | — | `page.goto(url)` | `driver.get(url)` |
| `click` | 点击元素 | CSS选择器 | — | `page.click(selector)` | `element.click()` |
| `type` | 输入文本 | CSS选择器 | 输入值 | `page.fill(selector, value)` | `element.sendKeys(value)` |
| `wait` | 等待元素 | CSS选择器 | — | `page.waitForSelector` | `WebDriverWait(driver, timeout)` |
| `scroll` | 滚动页面 | 滚动位置 | — | `page.evaluate(scroll)` | `driver.executeScript(scroll)` |
| `upload` | 上传文件 | CSS选择器 | 文件路径 | `page.setInputFiles` | `element.sendKeys(filepath)` |
| `hover` | 鼠标悬停 | CSS选择器 | — | `page.hover(selector)` | `ActionChains.move_to_element()` |
| `select` | 下拉选择 | CSS选择器 | 选项值 | `page.selectOption` | `Select.select_by_value()` |
| `screenshot` | 截图 | CSS选择器 | — | `page.screenshot({path})` | `driver.save_screenshot(path)` |
| `assert` | 断言判定 | — | — | `expect(page).toBeVisible/...` | 手动比对 + `find_element` |

### 4.5 断言定义

```yaml
- action: assert
  assertions:
    - type: string          # 必填，断言类型 A1~A8
      target: string        # 必填，断言目标
      expected: string      # 必填，预期值
      confidence: string    # 可选，推断置信度：high/medium/low
      inferredFrom: string  # 可选，推断来源描述
      message: string       # 可选，断言失败自定义消息
```

### 4.6 8 种断言类型

| 编号 | 类型 | PW支持 | SEL支持 | target | expected | 说明 |
|:----:|------|:------:|:------:|--------|----------|------|
| A1 | 页面可见 | ✅ | ✅ | CSS选择器 | `visible`/`hidden` | 验证元素可见性 |
| A2 | 页面跳转 | ✅ | ✅ | `current-url` | URL路径 | 验证 URL 跳转 |
| A3 | 元素状态 | ✅ | ✅ | CSS选择器 | `enabled`/`disabled`等 | 验证元素属性 |
| A4 | 内容匹配 | ✅ | ✅ | CSS选择器 | 预期文本 | 验证文本内容 |
| A5 | API响应 | ✅ | ❌ | `api:{path}` | `{status: N}` | 验证接口返回（仅PW） |
| A6 | 表单值 | ✅ | ✅ | CSS选择器 | 预期值 | 验证输入框当前值 |
| A7 | 元素数量 | ✅ | ✅ | CSS选择器 | 预期数量 | 验证元素数量 |
| A8 | 截图比对 | ✅ | ❌ | CSS选择器 | 基准图路径 | 视觉回归（仅PW） |

**断言结果映射**：

| 实际 vs 预期 | 结果 |
|:------------:|------|
| 完全匹配 | **pass** |
| 不匹配 | **fail** |
| 执行异常 | **error** |
| 条件不满足 | **skip** |

### 4.7 选择器约定

**Playwright 用例**：
- CSS 选择器：`.auth-form .el-button--primary`
- 数据属性：`[data-testid="login-btn"]`
- 文本选择器：`text=登录`

**Selenium 用例**（前缀约定）：
- `css=.login-form .btn-primary` → CSS_SELECTOR
- `id=username` → By.ID
- `xpath=//div[@class='form']` → By.XPATH
- 无前缀 → 默认 CSS_SELECTOR

### 4.8 截图策略

| 策略 | 触发条件 | 文件命名 |
|------|----------|----------|
| `on-fail`（默认） | 断言 fail/error 时 | `ATR-{id}-S{stepIndex}-fail.png` |
| `full` | 每步骤执行后 | `ATR-{id}-S{stepIndex}-{status}.png` |
| `always`（步骤标记） | 用户标记的关键步骤 | `ATR-{id}-S{stepIndex}-marked.png` |

优先级规则：`always > full > on-fail`

所有截图保存到 `.asdm/workspace/auto-test/screenshots/`

### 4.9 Schema 校验规则

| 校验项 | 规则 | 失败处理 |
|--------|------|----------|
| `name` | 非空字符串，建议小写+连字符 | 报错并终止 |
| `stages` | 数组类型，长度 ≥ 1 | 报错并终止 |
| Stage.`name` | 非空字符串 | 报错并跳过 |
| Step.`action` | 必填，值在操作类型映射表中 | 报错标记 error |
| Step.`target` | 必填 | 报错标记 error |
| Step.`value` | type/select 操作必填 | 报错标记 error |
| Step.`assertions` | assert 操作必填且 ≥ 1 | 报错标记 error |
| `framework` | 值为 playwright 或 selenium | 默认 playwright |
| `params.xxx` 引用 | `xxx` 必须在顶层 `params` 中有对应键 | 报错 |

---

## 五、数据模型 ID 规则

| 模型 | ID 格式 | 示例 |
|------|---------|------|
| 用例 (AutoTestCase) | `ATC-{YYYYMMDD}-{NNN}` | `ATC-20260714-001` |
| 结果 (AutoTestResult) | `ATR-{YYYYMMDD}-{NNN}` | `ATR-20260714-001` |
| 流水线 (Pipeline) | `PIPE-{YYYYMMDD}-{NNN}` | `PIPE-20260826-001` |
| 执行脚本 | `pipeline-{YYYYMMDD}-{NNN}.sh` | `pipeline-20260826-001.sh` |
| 截图 | `ATR-{resultId}-S{stepIndex}-{strategy}.png` | `ATR-20260714-001-S03-fail.png` |
| 报告 | `report-{YYYYMMDD}-{NNN}.html` | `report-20260714-001.html` |

---

## 六、工作目录结构

```
.asdm/workspace/auto-test/
├── cases/                    # YAML 用例文件
│   ├── .gitkeep
│   ├── user-login-test.yaml
│   └── admin-login-test.yaml
├── pipelines/                # 流水线编排产物
│   ├── .gitkeep
│   ├── pipeline-20260826-001.sh    # sh 执行脚本（自动编排生成）
│   ├── PIPE-20260826-001.ctx.env   # 参数上下文（上游输出注入）
│   └── PIPE-20260826-001.status    # 流水线状态
├── results/                  # 执行结果 JSON
│   ├── .gitkeep
│   ├── ATR-20260714-001.json
│   └── ATR-20260714-002.json
├── reports/                  # 测试报告
│   ├── .gitkeep
│   ├── report-20260714-001.html
│   ├── allure-results/       # Allure 中间数据（可选）
│   │   └── .gitkeep
│   └── allure-report/        # Allure HTML 报告（可选）
│       └── .gitkeep
├── screenshots/              # 截图存储
│   ├── .gitkeep
│   ├── ATR-20260714-S03-fail.png
│   └── ATR-20260714-S02-marked.png
└── page-maps/                # 页面结构映射（可选）
    └── login.json
```

---

## 七、典型使用流程

### 流程一：从测试用例描述生成用例 → 执行 → 报告

```
1. /auto-test-generate description="1. 浏览器地址栏输入：https://platform-dt02.asdm.ai/ 2. 点击【登录】 3. 输入邮箱：admin@test.com 4. 输入密码：pass123 5. 点击【登录】按钮" framework=playwright
   → 生成 YAML 用例到 cases/

2. /auto-test-list type=cases
   → 确认用例列表

3. /auto-test-run case=cases/
   → 执行所有用例，生成结果 JSON

4. /auto-test-report format=html
   → 生成 HTML 报告

5. /auto-test-list type=results
   → 查看执行结果
```

### 流程二：浏览器录制 → 执行 → 报告

```
1. /auto-test-record url=http://localhost:3000 dataParam=true
   → 录制操作 → /next 命名 → /end 结束

2. /auto-test-run case=cases/user-login-test.yaml
   → 执行录制用例

3. /auto-test-report result=latest format=both
   → 生成 HTML + Allure 报告
```

### 流程三：执行 → 分析失败 → 修复 → 重新执行

```
1. /auto-test-run
   → 执行全部用例

2. /auto-test-list type=results filter=status=fail
   → 查看失败结果

3. 手动修改 YAML 用例（选择器/断言）

4. /auto-test-run case=cases/user-login-test.yaml
   → 重新执行修复后的用例

5. /auto-test-report result=latest
   → 重新生成报告

6. /auto-test-clean scope=results confirm=true
   → 清理旧结果（可选）
```

---

## 八、Selenium 辅框架适配要点

### 8.1 功能边界对比

| 能力维度 | Playwright（主） | Selenium（辅） |
|----------|:----------------:|:--------------:|
| 操作类型 | 全部 9 种 + upload + screenshot | 全部 9 种（基础操作） |
| 断言类型 | A1~A8（8种全覆盖） | A1~A4、A6、A7（6种） |
| 截图能力 | 全页 + 元素级 + tracing | 仅全页截图 |
| 选择器语法 | Playwright 选择器 + CSS | css= / id= / xpath= 前缀 |
| API 拦截 | page.route() 支持 | ❌ 不支持 |
| 视觉回归 | toHaveScreenshot 支持 | ❌ 不支持 |
| 隐式等待 | 自动等待机制 | 需手动 WebDriverWait |

### 8.2 Selenium 用例注意事项

1. 选择器必须使用 `css=` / `id=` / `xpath=` 前缀
2. 不应包含 A5（API 响应）或 A8（截图比对）断言
3. 如含 A5/A8 → 自动降级为 Playwright + 提示用户
4. 截图仅支持全页截图（`driver.save_screenshot()`）
5. 无内置 expect/assertion，断言采用手动比对模式

### 8.3 降级提示格式

```
⚠️ 框架降级提示：用例 {name} 指定 selenium 框架，但包含以下 Playwright 专有特性：
- 断言 A5 (API 响应拦截)
- 断言 A8 (截图比对)
已自动降级为 Playwright 执行引擎。建议修改用例以兼容 Selenium，或保持 Playwright 框架。
```

---

## 九、录制后处理引擎链

录制命令 `/auto-test-record` 完成操作录制后，依次执行 8 个后处理子步骤：

| 子步骤 | 规范文件 | 说明 |
|--------|---------|------|
| 5a 提取操作序列 | `auto-test-dsl-spec.md` | Codegen 代码解析 + 选择器清洗 |
| 5b 选择器优化 | `auto-test-selector-optimization-spec.md` | 10 级优先级表 + 5 种优化操作 |
| 5c 断言推断 | `auto-test-assertion-inference-spec.md` | A1/A2/A4/A6 推断 + 置信度标注 |
| 5d 步骤优化 | `auto-test-step-optimization-spec.md` | 表单组合并 + 等待优化 + Stage 划分 |
| 5e 数据参数化 | `auto-test-data-parameterization-spec.md` | value → `{{params.xxx}}` |
| 5f 元数据增强 | `auto-test-dsl-spec.md` | recordedAt/pageStructure/frontFramework |
| 5g 多页面标记 | `auto-test-dsl-spec.md` | pageContext/pageTransition |
| 5h YAML 组装 | `auto-test-dsl-spec.md` + `auto-test-step-optimization-spec.md` | 完整 YAML 生成 |

---

## 十、选择器优化引擎（10 级优先级表）

| 优先级 | 选择器类型 | 稳定性 | 示例 |
|:------:|-----------|:------:|------|
| 1 | `[data-testid]` | ✅ 高 | `[data-testid="login-btn"]` |
| 2 | `[data-cy]` / `[data-qa]` | ✅ 高 | `[data-cy="submit"]` |
| 3 | `aria-label` 属性 | ✅ 高 | `[aria-label="搜索"]` |
| 4 | `name` 属性 | ⚠️ 中 | `[name="username"]` |
| 5 | `id` 属性（非动态） | ⚠️ 中 | `#login-form` |
| 6 | 语义化标签 | ⚠️ 中 | `button[type="submit"]` |
| 7 | 文本内容选择器 | ⚠️ 中 | `text=登录` |
| 8 | 组合类名选择器 | ❌ 低 | `.auth-form .el-button--primary` |
| 9 | `nth-child` / `nth-of-type` | ❌ 低 | `.form-item:nth-child(2) input` |
| 10 | 动态/随机 ID | ❌ 低 | `#react-abc123-root` |

---

## 十一、数据参数化规范

### 参数名推断优先级（5 级）

| 优先级 | 来源 | 示例参数名 |
|:------:|------|-----------|
| 1 | `name` 属性 | `username`（来自 `[name="username"]`） |
| 2 | `data-testid` 属性 | `login-btn`（来自 `[data-testid="login-btn"]`） |
| 3 | `aria-label` 属性 | `search`（来自 `[aria-label="搜索"]`） |
| 4 | `id` 属性 | `email`（来自 `#email`） |
| 5 | 序号命名 | `input_1` / `input_2` |

### 参数引用语法

- 顶层 `params` 字段定义参数名和默认值
- 步骤 `value` 中使用 `{{params.xxx}}` 引用
- 未定义 `params` 时，步骤 value 不应出现 `{{params.xxx}}`

```yaml
params:
  username: testuser
  password: password123
stages:
  - name: 输入凭证
    steps:
      - action: type
        target: input[name="username"]
        value: "{{params.username}}"
```

---

## 十二、异常处理规则

| 异常场景 | 处理策略 | Step 状态 |
|----------|----------|-----------|
| YAML 语法错误 | 报错并终止执行，提示修正 | — |
| Schema 校验失败 | 报错并终止执行，提示缺失字段 | — |
| 目标系统不可访问 | 用例标记为 error，提示启动系统 | error |
| 步骤执行超时 | 标记为 error，记录超时原因 | error |
| 页面元素未找到 | 标记为 error，记录选择器 | error |
| 前置步骤失败 | 后续步骤标记为 skip | skip |
| 网络请求异常 | 标记为 error，记录请求信息 | error |
| 断言失败 | 标记为 fail，记录断言详情 | fail |
| Selenium 含 A5/A8 | 降级为 Playwright + 提示 | — |

---

## 十三、前置条件

### 安装 Playwright

```bash
npm init playwright@latest
# 或
npx playwright install
```

### 安装 Allure（可选）

```bash
npm install -g allure-commandline
```

### 确认目标系统可访问

执行测试前确保目标 Web 系统已启动且可访问。

---

## 十四、规范文档索引

| 规范文件 | 路径 | 说明 |
|----------|------|------|
| YAML DSL 规范 | `spec/auto-test-dsl-spec.md` | 用例格式定义、Schema 校验、操作映射、断言类型 A1~A8、数据模型 |
| 执行引擎规范 | `spec/auto-test-execution-spec.md` | 7 阶段执行流程、操作映射、断言判定、截图策略、Selenium 适配 |
| 报告格式规范 | `spec/auto-test-report-spec.md` | HTML 报告模板结构、CSS 样式、截图内嵌、Allure 导出流程 |
| 选择器优化规范 | `spec/auto-test-selector-optimization-spec.md` | 10 级优先级表、5 种优化操作、稳定性标注 |
| 断言推断规范 | `spec/auto-test-assertion-inference-spec.md` | A1/A2/A4/A6 推断策略、置信度评分、pageMapFile |
| 步骤优化规范 | `spec/auto-test-step-optimization-spec.md` | 表单组合并、智能等待替代、冗余去除、Stage 划分 |
| 数据参数化规范 | `spec/auto-test-data-parameterization-spec.md` | 参数提取规则、参数名推断、{{params.xxx}} 引用语法 |

---

## 十五、Action 文件索引

| Action 文件 | 路径 | 说明 |
|-------------|------|------|
| AI 生成用例 | `actions/auto-test-generate.md` | 测试用例描述解析→场景生成→YAML转换→断言推断→输出 |
| 逐用例录制 | `actions/auto-test-record.md` | 会话初始化→操作录制→8子步骤后处理→YAML保存 |
| 执行测试 | `actions/auto-test-run.md` | 7阶段执行Pipeline→结果JSON→摘要输出 |
| 列出用例/结果 | `actions/auto-test-list.md` | 3种模式+4种筛选→Markdown表格 |
| 生成报告 | `actions/auto-test-report.md` | HTML报告5区域+可选Allure导出 |
| 清理资源 | `actions/auto-test-clean.md` | 4种范围→确认→删除→保留目录结构 |

---

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
