# ASDM Action: Auto Test Record

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456792",
  "name": "auto-test-record",
  "displayName": "逐用例会话录制",
  "description": "通过 Playwright Codegen 启动持久浏览器会话，逐用例录制浏览器操作，每条用例完成后执行8子步骤后处理（选择器优化+断言推断+步骤优化+数据参数化+元数据增强+多页面标记+Stage划分+YAML组装），输出4区块优化摘要，支持 /next 继续下一条用例和 /end 结束会话",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.1"
  },
  "scenario": "auto-test-recording-session"
}
```

## Purpose

本 action 是 Web Auto Tester 的**逐用例会话录制**命令。用户指定目标 URL 和可选参数，AI 启动 Playwright Codegen 录制器并保持浏览器会话，用户在浏览器中操作录制第一条用例，完成后输入 `/next` 触发断点，AI 执行后处理（8 子步骤）并展示 4 区块优化摘要，保存 YAML 文件后重启 Codegen 继续录制下一条用例。用户输入 `/end` 结束整个会话，关闭浏览器并输出会话摘要。

核心变化：从单次录制（关闭浏览器即结束）改为**逐用例会话模式**（浏览器持久保持，`/next` 逐条完成，`/end` 结束会话），每条用例经过完整后处理引擎链。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有生成的文件、注释和文档均使用中文。

## Context Injection

在生成用例前，AI Agent **必须**读取并理解以下规范文件：

### Required Context Files

1. **YAML DSL 规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
   - Purpose: 了解用例格式定义、Schema 校验规则、操作类型映射、断言类型、新增字段（params/pageContext/pageTransition/confidence/inferredFrom）

2. **执行引擎规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
   - Purpose: 了解操作映射（9 种操作类型 API 对应）、断言判定规则、选择器约定

3. **选择器优化引擎规范** (Required for Step 5b)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md`
   - Purpose: 了解 10 级优先级表、5 种优化操作、稳定性标注规则

4. **断言推断引擎规范** (Required for Step 5c)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md`
   - Purpose: 了解 A1/A2/A4/A6 推断策略、置信度评分、pageMapFile 格式

5. **步骤优化引擎规范** (Required for Step 5d)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md`
   - Purpose: 了解表单填写组合并、智能等待替代、冗余等待去除、Stage 划分

6. **数据参数化规范** (Required for Step 5e)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md`
   - Purpose: 了解参数化提取规则、参数名推断优先级、`{{params.xxx}}` 引用语法

## Steps

### Step 1: 会话初始化

#### 1.1 相似用例检测

1. 扫描 `.asdm/workspace/auto-test/cases/` 目录下的所有 YAML 用例文件
2. 提取每个用例的 `metadata.targetUrl` 和 `tags` 字段
3. 与本次录制参数比较（URL 基础路径 + tags 交集）
4. 匹配度 ≥ 60%（URL 匹配 + tags 交集 ≥ 1）→ 提示用户已有相似用例

提示格式：

```markdown
⚠️ 相似用例检测：发现 {count} 条已有用例与本次录制目标相似

| # | 用例名称 | 目标 URL | 标签 | 匹配度 |
|---|---------|----------|------|--------|
| 1 | {name}  | {url}    | {tags} | {score}% |

💡 建议：如需补充已有用例，可直接编辑 YAML 文件；如需录制新场景，继续操作即可。
```

#### 1.2 Playwright 可用检查

1. 执行 `npx playwright --version` 确认 Playwright 已安装
2. 未安装 → 提示用户执行 `npx playwright install` 安装，会话中止
3. 安装完成 → 继续会话初始化

#### 1.3 启动持久浏览器会话 + Codegen

启动 Playwright Codegen，浏览器保持直到 `/end` 信号：

```bash
npx playwright codegen {url} --browser={browser} --viewport-size=1280,720 --lang=zh-CN --color-scheme=light
```

参数映射：
- `{url}` → 用户输入的 `url` 参数（必填）
- `--browser {browser}` → 用户输入的 `browser` 参数（默认 chromium）

**关键**：浏览器窗口在 `/next` 时不关闭，仅重启 Codegen；`/end` 时才关闭浏览器。

#### 1.4 输出启动提示

```markdown
### 🎥 录制会话已启动

> 目标 URL: {url} | 浏览器: {browser} | 视口: 1280×720

**本次会话参数**：
| 参数 | 值 |
|------|-----|
| selectorStrategy | {selectorStrategy} |
| dataParam | {dataParam} |
| pageMapFile | {pageMapFile 或 "无"} |
| tags | {tags 或 "无"} |

**操作指引**：
1. 在打开的浏览器窗口中执行需要录制的操作
2. Codegen 窗口会实时显示录制的代码
3. **一条用例录制完成后**，在 IDE 中输入 `/next` 暂停当前用例进入命名
4. 如需录制更多用例，命名和保存后浏览器保持，继续操作并再次 `/next`
5. **所有用例录制完成后**，在 IDE 中输入 `/end` 结束会话

**信号说明**：
- `/next` — 完成当前用例，进入命名和后处理（浏览器保持，Codegen 重启）
- `/end` — 结束整个会话（浏览器关闭，输出会话摘要）

**提示**：
- 尽量使用稳定元素进行操作（避免随机定位）
- 操作顺序即测试步骤顺序
- 多页面/弹窗操作会被自动检测并标记
```

---

### Step 2: 用户操作录制

#### 2.1 Codegen 实时录制

Codegen 启动后，用户在浏览器窗口中操作：
- 页面导航（打开新页面）
- 点击元素（按钮/链接/菜单）
- 输入文本（表单字段）
- 选择下拉选项
- 等待元素出现
- 其他浏览器操作

Codegen 实时录制用户的操作序列，生成 Playwright TypeScript/JavaScript 代码。

#### 2.2 多页面/弹窗检测标记

录制过程中检测以下场景并标记：

| 场景 | 检测方式 | 标记字段 |
|------|----------|----------|
| 新标签页打开 | Codegen 中出现 `page.waitForEvent('popup')` 或新 page 上下文 | `pageTransition: new-tab` + `pageContext: newTab` |
| 新窗口打开 | Codegen 中出现 `page.waitForEvent('popup')` | `pageTransition: new-window` + `pageContext: popup` |
| 页面导航跳转 | `page.goto()` 或 `page.click()` 后 URL 变化 | `pageTransition: navigate` |
| 无跳转操作 | 点击后 URL 不变化 | `pageTransition: none` |

检测逻辑在 Step 5g（多页面标记）中填充到步骤字段。

---

### Step 3: 完成断点触发

用户在 IDE 中输入信号触发断点：

#### 3.1 信号分流

| 信号 | 含义 | 流向 |
|------|------|------|
| `/next` | 完成当前用例，暂停录制进入命名 | → Step 4（用例命名） |
| `/end` | 结束整个会话，不再录制 | → Step 8（会话结束） |

#### 3.2 信号识别规则

- 信号为精确匹配：`/next` 和 `/end` 必须完全一致（不区分大小写）
- `/next`：当前用例操作序列冻结，进入命名和后处理
- `/end`：跳过当前用例后处理，直接进入会话结束流程
- 无信号超时兜底：5 分钟无操作无信号 → 提示用户选择 `/next` 或 `/end`

```markdown
⏱️ 5 分钟无操作检测

请选择下一步操作：
- 输入 `/next` — 完成当前用例并继续录制
- 输入 `/end` — 结束整个录制会话
```

---

### Step 4: 用例命名

#### 4.1 用户指定名称

提示用户输入用例名称：

```markdown
📝 请为当前录制的用例指定名称：

用例名称将作为 YAML 文件名和用例标识，请遵循以下规则：
- 非空字符串
- 仅使用小写英文字母 + 连字符（如 `user-login-test`）
- 不与已有用例重名

输入用例名称后，AI 将进入后处理流程。
```

#### 4.2 名称校验规则

| 校验规则 | 条件 | 失败处理 |
|----------|------|----------|
| 非空校验 | 名称不为空字符串 | 提示重新输入 |
| 格式校验 | 仅包含 `[a-z0-9-]+` | 提示修改为小写+连字符格式 |
| 不重名校验 | 名称不与 `cases/` 目录下已有 YAML 文件名冲突 | 提示修改名称或追加序号 |

校验通过 → 进入 Step 5（后处理）

---

### Step 5: 后处理（8 子步骤）

从 Codegen 录制的原始操作序列开始，依次执行 8 个后处理子步骤，每步引用对应规范文件：

#### 5a. 提取操作序列

从 Codegen 生成的代码中提取操作序列，与当前 Step 3 一致：

**Codegen 代码解析规则**：

| Codegen 代码模式 | 提取操作 | target | value |
|-----------------|---------|--------|-------|
| `page.goto('url')` | navigate | URL路径 | — |
| `page.click('selector')` | click | CSS选择器 | — |
| `page.fill('selector', 'value')` | type | CSS选择器 | 输入值 |
| `page.type('selector', 'value')` | type | CSS选择器 | 输入值 |
| `page.selectOption('selector', 'value')` | select | CSS选择器 | 选项值 |
| `page.hover('selector')` | hover | CSS选择器 | — |
| `page.waitForSelector('selector')` | wait | CSS选择器 | — |
| `page.waitForTimeout(ms)` | wait | `timeout:{ms}ms` | — |
| `locator.click()` | click | locator字符串 | — |
| `locator.fill('value')` | type | locator字符串 | 输入值 |

**选择器清洗策略**：
- 去除 Playwright 内部选择器前缀（如 `internal:...`）
- 保留标准 CSS 选择器、文本选择器、data-testid 选择器
- 不稳定选择器（nth-child、动态 ID）在 Step 5b 中优化

**URL 处理规则**：
- `page.goto('http://localhost:3000/login')` → `target: /login`（剥离基础 URL）
- 基础 URL 存入 `metadata.targetUrl`

#### 5b. 选择器优化

引用规范：`auto-test-selector-optimization-spec.md`

根据 `selectorStrategy` 参数执行选择器优化：

- `selectorStrategy=optimize`（默认）：
  1. 逐个评估选择器稳定性等级（10 级优先级表）
  2. 对 ❌低/⚠️中 稳定性选择器执行 5 种优化操作：
     - 缩短路径
     - nth-child 替代
     - 动态 ID 替代
     - 语义化替代
     - 路径精简
  3. 优化后重新评估稳定性等级
  4. 无法优化时保留原始选择器并标注"无法优化"

- `selectorStrategy=raw`：
  - 不执行优化，保留 Codegen 原始选择器

#### 5c. 断言推断

引用规范：`auto-test-assertion-inference-spec.md`

逐步骤检测触发条件，推断验证断言：

| 触发时机 | 检测断言类型 |
|----------|------------|
| navigate 后 | A1（页面可见）+ A2（URL 跳转） |
| click 后 | A1（可见性变化）+ A2（URL 跳转）+ A4（内容变化） |
| type 后 | A4（输入值可见）+ A6（表单值验证） |
| select 后 | A6（选中值验证） |
| wait 后 | A1（元素可见） |

推断策略：
- 有 `pageMapFile` → 使用映射选择器（置信度 high）
- 无 `pageMapFile` → 使用页面结构动态推断优先级表

每条推断断言标注 `confidence`（high/medium/low）和 `inferredFrom`（推断来源描述）。

#### 5d. 步骤优化

引用规范：`auto-test-step-optimization-spec.md`

执行以下优化操作：

1. **表单填写组合并**：连续 ≥ 2 个 type 操作添加 `# [form-fill-group]` 注释标记
2. **智能等待替代**：
   - 固定时间等待 → 元素等待
   - click 提交按钮后补充 wait
   - navigate 后补充 wait 核心元素
3. **冗余等待去除**：
   - 连续 ≥ 2 个 wait 同一 target → 仅保留首个
   - wait 后紧跟 assert 同一 target → 去除 wait
4. **Stage 划分**：按 navigate 操作划分 Stage + 推断 Stage 名称

#### 5e. 数据参数化

引用规范：`auto-test-data-parameterization-spec.md`

根据 `dataParam` 参数执行数据参数化：

- `dataParam=true`：
  1. 识别 type/select 操作的 value 字段
  2. 逐个推断参数名（5 级优先级：name → data-testid → aria-label → id → 序号）
  3. 构建顶层 `params` 字段（参数名 → 默认值映射）
  4. 替换 type/select 的 value 为 `{{params.xxx}}`

- `dataParam=false`（默认）：
  - 不提取，输入值保持硬编码

#### 5f. 元数据增强

补充 metadata 增强子字段：

| 字段 | 值来源 | 示例 |
|------|--------|------|
| `recordedAt` | 录制完成时间（ISO 8601） | `2026-07-20T10:30:00Z` |
| `duration` | 录制耗时（秒） | `45` |
| `pageTitle` | 录制时页面标题 | `登录` |
| `pageStructure` | 页面结构检测（5 子字段） | `{hasSidebar: false, hasNavbar: true, ...}` |
| `viewportActual` | 录制时实际视口尺寸 | `{width: 1280, height: 720}` |
| `frontFramework` | 前端框架识别 | `vue` / `react` / `angular` / `unknown` |

`pageStructure` 子字段来源：
- `hasSidebar` / `hasNavbar` / `hasFooter`：检测页面中是否存在侧边栏/导航栏/页脚元素
- `mainContentSelector`：推断主内容区域选择器
- `layoutType`：推断布局类型（sidebar-left/sidebar-right/top-nav/full-page）

#### 5g. 多页面/弹窗标记

根据 Step 2.2 的检测结果填充步骤字段：

| 检测场景 | 步骤字段填充 |
|----------|-------------|
| navigate 操作 | `pageTransition: navigate`（当前步骤） |
| 新标签页打开 | `pageTransition: new-tab`（触发步骤）+ `pageContext: newTab`（后续步骤） |
| 新窗口打开 | `pageTransition: new-window`（触发步骤）+ `pageContext: popup`（后续步骤） |
| 无跳转操作 | 不填充（默认 none/main） |

#### 5h. Stage 划分与 YAML 组装

1. 按 navigate 操作划分 Stage（与 Step 5d 一致）
2. 推断 Stage 名称（根据 URL 路径 + 操作语义）
3. 组装完整 YAML 用例文件结构：
   - 顶层字段：name, description, framework, capture, tags, params（如有）, metadata, source: record, stages
   - 每个 Stage：name + steps 列表
   - 每个 Step：action, target, value, pageContext/pageTransition（如有）, assertions（如有）

---

### Step 6: 优化摘要展示

后处理完成后，展示 4 区块优化摘要表格：

#### 1️⃣ 选择器优化区块

```
1️⃣ 选择器优化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| # | 原始选择器                    | 优化后选择器              | 稳定性变化 |
|---|-------------------------------|--------------------------|-----------|
| 1 | .form-item:nth-child(2) input | input[name="password"]   | ❌低→✅高  |
| 2 | #react-abc123 .submit-btn     | button[type="submit"]    | ❌低→⚠️中 |
| 3 | .content .title               | .content .title          | ⚠️中→⚠️中 |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计：优化 {optimized}/{total} 个选择器 | 稳定性提升 {improved} 个 | 无法优化 {unoptimizable} 个
```

#### 2️⃣ 断言推断区块

```
2️⃣ 断言推断
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| # | 类型 | target                  | expected      | 置信度  | 推断来源              |
|---|------|-------------------------|---------------|---------|----------------------|
| 1 | A1   | .auth-form              | visible       | ✅ 高   | navigate后[data-testid] |
| 2 | A2   | current-url             | /home         | ✅ 高   | navigate操作目标路径    |
| 3 | A4   | .search-bar input       | 手机           | ✅ 高   | type操作输入值验证      |
| 4 | A6   | input[name="username"]  | testuser      | ✅ 高   | type操作值验证          |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计：推断 {total} 条断言 | 高置信度 {high} 条 | 中置信度 {medium} 条 | 低置信度 {low} 条（建议删除）
💡 建议：低置信度断言建议删除或手动重写
```

#### 3️⃣ 步骤优化区块

```
3️⃣ 步骤优化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| # | 优化类型             | 数量 | 说明                          |
|---|---------------------|------|-------------------------------|
| 1 | 表单填写组合并        | {n}组 | {描述}                        |
| 2 | 智能等待替代          | {n}处 | {描述}                        |
| 3 | 冗余等待去除          | {n}处 | {描述}                        |
| 4 | Stage 划分           | {n}个 | {描述}                        |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计：原始步骤 {original} → 优化后步骤 {optimized} | 减少 {reduced} 步 | 增强注释 {comments} 处
```

#### 4️⃣ 数据参数化区块

`dataParam=true` 时：

```
4️⃣ 数据参数化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| 参数名           | 默认值        | 原始步骤                     |
|-----------------|--------------|------------------------------|
| username        | testuser     | type → input[name="username"] |
| password        | password123  | type → input[name="password"] |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计：提取 {count} 个参数 | type 操作 {typeCount} 个 | select 操作 {selectCount} 个
💡 提示：修改 params 默认值即可使用不同数据集重新执行
```

`dataParam=false` 时：

```
4️⃣ 数据参数化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ 参数化已关闭（dataParam=false）
输入值将保持硬编码。如需参数化，下次录制时使用：
/auto-test-record url=... dataParam=true
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 确认操作指引

```markdown
✅ 用例「{name}」后处理完成，优化摘要已展示。

请选择下一步操作：
- 输入「继续」— 保存 YAML 文件，重启 Codegen，录制下一条用例
- 输入「/end」— 保存 YAML 文件，结束整个录制会话
```

---

### Step 7: 保存 YAML + Codegen 重启

#### 7.1 保存 YAML 文件

1. 组装完整 YAML 用例文件内容
2. 保存到 `.asdm/workspace/auto-test/cases/{name}.yaml`
3. 文件编码：UTF-8

#### 7.2 Codegen 重启逻辑

1. **关闭当前 Codegen 实例**（仅关闭 Codegen 窗口，不关闭浏览器）
2. **浏览器保持**（浏览器窗口继续打开，用户可继续操作）
3. **重启 Codegen**（重新启动 Playwright Codegen，连接到同一浏览器会话）

```bash
# 关闭 Codegen 进程
# 重新启动 Codegen（连接到持久浏览器）
npx playwright codegen {url} --browser={browser} --viewport-size=1280,720
```

#### 7.3 输出保存确认

```markdown
✅ 用例已保存：`.asdm/workspace/auto-test/cases/{name}.yaml`

🔄 Codegen 已重启，浏览器保持打开。

请在浏览器中继续操作录制下一条用例，完成后输入 `/next`。
或输入 `/end` 结束录制会话。
```

---

### Step 8: 会话结束

#### 8.1 关闭浏览器

`/end` 信号触发后：
1. 关闭浏览器窗口
2. 关闭 Codegen 进程（如有）
3. 释放浏览器会话资源

#### 8.2 输出会话摘要

```markdown
### 🎥 录制会话结束

> 会话时长: {duration} 分钟 | 录制用例数: {caseCount} 条

| # | 用例名称 | 步骤数 | 断言数 | 选择器优化 | 保存路径 |
|---|---------|:------:|:------:|-----------|----------|
| 1 | {name}  | {steps}| {assert}| {optimized}/{total} | {path} |
| 2 | {name}  | {steps}| {assert}| {optimized}/{total} | {path} |

💡 下一步建议：
- 执行 `/auto-test-run` 验证录制用例的可执行性
- 执行 `/auto-test-list` 查看所有录制用例列表
- 手动编辑 YAML 文件微调选择器、断言或参数
```

#### 8.3 结构化 JSON 输出

```json
{
  "phase": "auto-test-record",
  "status": "success",
  "sessionDuration": "{duration_minutes}",
  "totalCases": {caseCount},
  "cases": [
    {
      "name": "{name}",
      "filePath": ".asdm/workspace/auto-test/cases/{name}.yaml",
      "totalSteps": {steps},
      "totalAssertions": {assert},
      "selectorOptimizations": "{optimized}/{total}",
      "inferredAssertions": {inferredCount},
      "confidenceSummary": {"high": {h}, "medium": {m}, "low": {l}}
    }
  ],
  "timestamp": "ISO 8601 datetime"
}
```

---

## 关键交互点

| # | 交互点 | 触发条件 | 用户操作 | AI 响应 |
|---|-------|---------|---------|---------|
| 1 | 相似用例提示 | Step 1 扫描到相似用例 | 无需操作（信息提示） | 展示相似用例表格 + 建议 |
| 2 | 完成信号 | 一条用例操作完成 | 输入 `/next` 或 `/end` | `/next` → Step 4 命名；`/end` → Step 8 结束 |
| 3 | 用例命名 | `/next` 后进入命名 | 输入用例名称（小写+连字符） | 校验名称 → 通过后进入 Step 5 后处理 |
| 4 | 优化摘要确认 | Step 6 展示后 | 输入「继续」或 `/end` | 继续 → Step 7 保存+重启；/end → Step 8 |
| 5 | 继续/结束选择 | Step 7 保存后 | 继续操作或输入 `/end` | 继续操作 → 录制下一条用例；/end → Step 8 |

---

## Execution Guidelines

### Codegen 启动失败处理

- Playwright 未安装 → 提示 `npx playwright install` 后重试
- 指定 browser 不支持 → 降级为 chromium 并提示
- URL 不可访问 → 提示用户确认目标系统是否启动

### 录制操作过滤

- 忽略 Codegen 内部配置操作（setViewportSize、setBackgroundColor 等）
- 忽略纯视觉操作（如仅改变字体大小等不影响功能的操作）
- 保留所有功能性交互操作（click、type、select、navigate）

### 空录制处理

- 如用户仅打开页面未操作 → 生成仅含 navigate + A1 断言的最小用例
- 提示用户：`"录制操作序列为空，已生成最小用例（仅页面访问+可见断言）。建议重新录制并执行更多操作。"`

### 信号超时兜底

- 5 分钟无操作无信号 → 提示用户选择 `/next` 或 `/end`
- 提示后 2 分钟仍无响应 → 自动 `/end` 结束会话

### 后处理引擎调用顺序

后处理 8 子步骤必须按固定顺序执行（5a → 5b → 5c → 5d → 5e → 5f → 5g → 5h），每个子步骤引用对应规范文件：

| 子步骤 | 规范文件 | 必须顺序 |
|--------|---------|:--------:|
| 5a 提取操作序列 | auto-test-dsl-spec.md | 1 |
| 5b 选择器优化 | auto-test-selector-optimization-spec.md | 2 |
| 5c 断言推断 | auto-test-assertion-inference-spec.md | 3 |
| 5d 步骤优化 | auto-test-step-optimization-spec.md | 4 |
| 5e 数据参数化 | auto-test-data-parameterization-spec.md | 5 |
| 5f 元数据增强 | auto-test-dsl-spec.md（metadata 子字段） | 6 |
| 5g 多页面标记 | auto-test-dsl-spec.md（pageContext/pageTransition） | 7 |
| 5h Stage 划分与 YAML 组装 | auto-test-dsl-spec.md + auto-test-step-optimization-spec.md | 8 |

---

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|:----:|--------|------|
| url | string | ✅ | — | 目标 URL（如 http://localhost:3000） |
| framework | string | ❌ | playwright | 框架偏好（录制仅支持 Playwright） |
| browser | string | ❌ | chromium | 浏览器类型 |
| tags | string[] | ❌ | [] | 用例标签，如 `module:auth,feature:login` |
| dataParam | boolean | ❌ | false | 数据参数化开关，true 时提取输入值为参数变量 |
| pageMapFile | string | ❌ | null | 页面元素映射文件路径（辅助 A1 断言推断） |
| selectorStrategy | string | ❌ | optimize | 选择器策略：optimize（自动优化）或 raw（保留原始） |

### 命令示例（5 种参数组合）

```bash
# 示例 1：基础录制（默认参数）
/auto-test-record url=http://localhost:3000

# 示例 2：带标签的模块化录制
/auto-test-record url=http://localhost:3000 tags=module:auth,feature:login

# 示例 3：启用数据参数化（适合数据驱动测试）
/auto-test-record url=http://localhost:3000 dataParam=true

# 示例 4：提供页面映射文件（提升断言推断置信度）
/auto-test-record url=http://localhost:3000 pageMapFile=./page-map.yaml

# 示例 5：保留原始选择器（调试场景）
/auto-test-record url=http://localhost:3000 selectorStrategy=raw

# 示例 6：完整参数组合
/auto-test-record url=http://localhost:3000 tags=module:auth,feature:login dataParam=true pageMapFile=./page-map.yaml selectorStrategy=optimize
```

## Output

### YAML 用例文件示例 — 参数化 + 增强 metadata

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

### 非参数化用例示例（dataParam=false）

```yaml
name: user-home-visit
description: 验证首页访问流程
framework: playwright
capture: on-fail
tags: [home, P2]
source: record
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
  browser: chromium
  recordedAt: "2026-07-20T10:35:00Z"
  duration: 15
  pageTitle: 首页
stages:
  - name: 首页访问
    steps:
      - action: navigate
        target: /
        pageTransition: navigate
      - action: assert
        assertions:
          - type: A1
            target: .page-content
            expected: visible
            confidence: high
            inferredFrom: "navigate后页面结构动态推断[.page-content]"
            message: 首页内容应可见
```

## Configuration

Refer to:
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — YAML DSL 用例格式定义、Schema 校验、操作类型映射、断言类型 A1~A8、新增字段
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 7 阶段执行规范、操作映射、断言判定、选择器约定
- [auto-test-selector-optimization-spec.md](../spec/auto-test-selector-optimization-spec.md) — 选择器优化引擎：10级优先级表、5种优化操作、selectorStrategy
- [auto-test-assertion-inference-spec.md](../spec/auto-test-assertion-inference-spec.md) — 断言推断引擎：A1/A2/A4/A6 推断、置信度评分、pageMapFile
- [auto-test-step-optimization-spec.md](../spec/auto-test-step-optimization-spec.md) — 步骤优化引擎：表单组合并、智能等待、冗余去除、Stage 划分
- [auto-test-data-parameterization-spec.md](../spec/auto-test-data-parameterization-spec.md) — 数据参数化：参数提取、参数名推断、{{params.xxx}} 引用、dataParam 参数
