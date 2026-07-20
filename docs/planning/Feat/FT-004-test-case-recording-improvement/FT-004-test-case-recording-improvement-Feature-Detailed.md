# FT-004 测试用例录制改进 — 详细设计

> 基于 [FT-004-test-case-recording-improvement-Feature-Overall.md](./FT-004-test-case-recording-improvement-Feature-Overall.md)（概要设计）和 [FT-004-test-case-recording-improvement-CodeResearch.md](./FT-004-test-case-recording-improvement-CodeResearch.md)（代码调研），对 7 个使用场景逐个进行详细设计，定义 Action 步骤流程、Spec 规范规则和 DSL 扩展细节。

**创建日期**：2026-07-20
**版本**：1.0.0

---

## 修订记录

| 版本 | 日期 | 修订人 | 修订内容 |
|------|------|--------|----------|
| 1.0.0 | 2026-07-20 | meiguangxian | 初始版本：7 个场景详细设计 |

---

## 目录

- [1. 录制命令重构 — auto-test-record Action](#1-录制命令重构)
- [2. DSL Spec 扩展](#2-dsl-spec-扩展)
- [3. 场景一：按用例逐条录制测试用例](#3-场景一按用例逐条录制)
- [4. 场景二：选择器优化与用户确认](#4-场景二选择器优化)
- [5. 场景三：断言推断与置信度评估](#5-场景三断言推断)
- [6. 场景四：步骤优化与合并](#6-场景四步骤优化)
- [7. 场景五：数据参数化提取](#7-场景五数据参数化)
- [8. 场景六：多页面与弹窗录制](#8-场景六多页面与弹窗)
- [9. 场景七：录制前相似用例提示](#9-场景七相似用例提示)
- [10. 新增 Spec 规范文件](#10-新增-spec-规范文件)
- [11. 实施检查清单](#11-实施检查清单)

---

## 1. 录制命令重构 — auto-test-record Action

### 1.1 流程架构重构

当前 6 步骤线性流程（单次录制→单用例）重构为**会话式逐用例录制流程**：

```
┌─────────────────────────────────────────────────────────────────┐
│                    录制会话 (Recording Session)                   │
│                                                                  │
│  Step 1: 会话初始化                                              │
│    ├─ 相似用例检测                                               │
│    ├─ 启动持久浏览器                                             │
│    └─ 启动 Codegen                                              │
│                                                                  │
│  ┌─────────────── 逐用例循环 (Per-Case Loop) ─────────────────┐  │
│  │                                                             │  │
│  │  Step 2: 用户操作录制                                       │  │
│  │  Step 3: 用户输入 /next → 完成断点触发                      │  │
│  │  Step 4: 用例命名                                           │  │
│  │  Step 5: 后处理（选择器优化 + 断言推断 + 步骤优化）          │  │
│  │  Step 6: 优化摘要展示                                       │  │
│  │  Step 7: 保存 YAML + Codegen 重启                           │  │
│  │                                                             │  │
│  │  ← 用户选择: 继续 (回到 Step 2) 或 /end (退出循环) ─       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Step 8: 会话结束                                                │
│    ├─ 关闭浏览器                                                 │
│    └─ 输出会话摘要                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 新增参数定义

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|:----:|--------|------|
| url | string | ✅ | — | 目标 URL（如 `http://localhost:3000`） |
| browser | string | ❌ | chromium | 浏览器类型 |
| tags | string[] | ❌ | `[]` | 用例标签（如 `module:auth,feature:login`） |
| dataParam | boolean | ❌ | false | 是否开启数据参数化提取 |
| pageMapFile | string | ❌ | — | 页面元素映射文件路径（可选，辅助 A1 断言推断） |
| selectorStrategy | string | ❌ | optimize | 选择器策略：`optimize`（自动优化+确认）/ `raw`（原始输出不优化） |

### 1.3 命令示例

```
/auto-test-record url=http://localhost:3000
/auto-test-record url=http://localhost:3000 tags=module:auth,feature:login
/auto-test-record url=http://localhost:3000 dataParam=true
/auto-test-record url=http://localhost:3000 pageMapFile=page-map.yaml
/auto-test-record url=http://localhost:3000 selectorStrategy=raw
```

### 1.4 完整步骤定义

#### Step 1: 会话初始化

1. **相似用例检测**（场景七）：
   - 扫描 `.asdm/workspace/auto-test/cases/` 目录
   - 基于 URL + tags 匹配已有相似用例
   - 提示用户："已有相似用例 {name}（匹配度 X%），是否继续录制？"
   - 用户确认 → 继续；用户选择查看 → 展示相似用例内容

2. **检查 Playwright 可用**：
   - 执行 `npx playwright --version` 确认安装
   - 未安装 → 提示 `npx playwright install` 后重试

3. **启动持久浏览器会话**：
   - 使用 Playwright 启动持久浏览器上下文
   - 视口 1280×720、语言 zh-CN、色彩方案 light
   - 浏览器保持打开状态直至 `/end` 信号

4. **启动 Codegen 录制器**：
   ```bash
   npx playwright codegen {url}
   ```
   - 参数映射与当前版本一致

5. **输出启动提示**：

```markdown
### 🎥 录制会话已启动（逐用例模式）

> 目标 URL: {url} | 浏览器: {browser} | 视口: 1280×720

**操作指引**：
1. 在浏览器窗口中执行需要录制的操作
2. 完成一个用例的操作后，在 IDE 输入 `/next` 信号
3. AI 将提示命名用例、展示优化摘要、保存 YAML 文件
4. 然后可以继续录制下一个用例，或输入 `/end` 结束整次录制

**本次会话参数**：
- 数据参数化: {dataParam} | 选择器策略: {selectorStrategy}
- 页面映射文件: {pageMapFile 或 "未指定"}
```

#### Step 2: 用户操作录制

1. 用户在浏览器窗口中执行操作（与当前版本一致）
2. Codegen 实时录制 TypeScript/JavaScript 代码
3. 操作序列存储在内存缓冲区中
4. **多页面/弹窗处理**（场景六）：
   - 检测 Codegen 代码中的 `page.waitForEvent('popup')` → 标记 `pageContext: popup`
   - 检测新 tab 操作 → 标记 `pageContext: newTab`
   - 检测 `page.goto()` → 标记 `pageTransition: navigate`

#### Step 3: 完成断点触发

1. 用户在 IDE 输入 `/next` 信号
2. AI 识别 `/next` 信号，暂停当前用例录制
3. 进入完成断点处理流程（Step 4~7）
4. 用户输入 `/end` → 直接跳至 Step 8（会话结束）

#### Step 4: 用例命名

1. AI 提示用户命名当前用例：
   ```
   请为当前录制的用例指定名称（建议格式：{页面模块}-{简短描述}，如 user-login-test）
   ```
2. 用户输入用例名称（如 `user-login-test`）
3. 名称校验：
   - 非空字符串
   - 小写英文字母 + 连字符
   - 与 `cases/` 目录已有文件不重名（重名 → 提示修改）
4. 名称确认后进入后处理流程

#### Step 5: 后处理（选择器优化 + 断言推断 + 步骤优化）

此步骤执行三个引擎的后处理逻辑（详见场景二~四）：

**5a. 提取操作序列**（与当前 Step 3 一致）

**5b. 选择器优化**（`selectorStrategy=optimize` 时执行，详见场景二）

**5c. 断言推断**（详见场景三）

**5d. 步骤优化**（详见场景四）

**5e. 数据参数化**（`dataParam=true` 时执行，详见场景五）

**5f. 元数据增强**（详见 §1.5 metadata 扩展）

**5g. 多页面/弹窗标记**（详见场景六）

**5h. Stage 划分与 YAML 组装**

#### Step 6: 优化摘要展示

展示内容分为 4 个区块：

```markdown
### 📊 用例「{caseName}」优化摘要

#### 1️⃣ 选择器优化（{selectorStrategy}）

| # | 原始选择器 | 优化后选择器 | 稳定性变化 |
|---|-----------|-------------|-----------|
| 1 | `.auth-form .el-form-item:nth-child(2) input` | `[name="password"]` | ❌低 → ✅高 |
| 2 | `#random-id-abc123 .btn` | `.login-form .submit-btn` | ❌低 → ⚠️中 |

> 共优化 {count} 个选择器，{improved} 个稳定性提升

#### 2️⃣ 断言推断（A1+A2+A4+A6）

| # | 类型 | target | expected | 置信度 | 推断来源 |
|---|------|--------|----------|:------:|---------|
| 1 | A1 | `.auth-form` | visible | 高 | 页面结构推断 |
| 2 | A2 | current-url | /home | 高 | navigate 后URL变化 |
| 3 | A4 | `.header-user .user-name` | testuser | 中 | DOM文本变化推断 |
| 4 | A6 | `[name="username"]` | testuser | 高 | type 操作后验证 |

> 共推断 {count} 条断言，高置信 {high} 条、中置信 {mid} 条、低置信 {low} 条

#### 3️⃣ 步骤优化

| 优化类型 | 数量 | 说明 |
|----------|:----:|------|
| 表单填写组合并 | 1 | 3个连续type合并为1组 |
| 硬等待→智能等待 | 2 | waitForTimeout→waitForSelector |
| 冗余等待去除 | 1 | 重复waitFor同一目标 |

#### 4️⃣ 数据参数化（dataParam={dataParam}）

| # | 参数名 | 默认值 | 原始步骤 |
|---|--------|--------|----------|
| 1 | username | testuser | type [name="username"] |
| 2 | password | password123 | type [name="password"] |

> *参数化已关闭（dataParam=false），输入值将硬编码*

---

**确认操作**：
- 以上优化已自动应用，如需调整请直接修改保存的 YAML 文件
- 输入 **继续** 录制下一个用例，或输入 **/end** 结束录制会话
```

#### Step 7: 保存 YAML + Codegen 重启

1. 组装完整 YAML DSL 用例文件（含扩展字段）
2. 保存到 `.asdm/workspace/auto-test/cases/{caseName}.yaml`
3. **Codegen 重启**（决策 0c：浏览器保持 + Codegen 重启）：
   - 关闭当前 Codegen 实例（清空录制缓冲区）
   - 浏览器窗口保持不变
   - 重新启动 Codegen 实例，用户继续在同一浏览器中操作
4. 输出保存确认：
   ```
   ✅ 用例「{caseName}」已保存 → .asdm/workspace/auto-test/cases/{caseName}.yaml
   
   🔄 Codegen 已重启，浏览器保持。请继续操作录制下一个用例。
   输入 `/next` 完成当前用例，或 `/end` 结束整次录制。
   ```
5. 返回 Step 2（逐用例循环继续）

#### Step 8: 会话结束

1. 用户输入 `/end` 信号
2. 关闭浏览器窗口
3. 输出会话摘要：

```markdown
### 🎥 录制会话结束

> 本次会话共录制 {totalCases} 个用例 | 总操作数 {totalOps} | 总录制时间 {duration}

| # | 用例名称 | 步骤数 | 断言数 | 选择器优化 | 保存路径 |
|---|----------|:------:|:------:|:----------:|----------|
| 1 | user-login-test | 8 | 4 | 2个优化 | cases/user-login-test.yaml |
| 2 | user-search-test | 6 | 3 | 1个优化 | cases/user-search-test.yaml |

**下一步建议**：
- 执行 `/auto-test-run` 验证录制用例的可执行性
- 检查并补充低置信度断言
- 为关键步骤添加 `capture: always` 截图标记
```

4. 结构化输出：

```json
{
  "phase": "auto-test-record-session",
  "status": "success",
  "sessionUrl": "http://localhost:3000",
  "browser": "chromium",
  "totalCases": 2,
  "cases": [
    {
      "name": "user-login-test",
      "file_path": ".asdm/workspace/auto-test/cases/user-login-test.yaml",
      "totalSteps": 8,
      "totalAssertions": 4,
      "selectorOptimizations": 2,
      "stepOptimizations": {"formGroups": 1, "smartWaits": 2, "redundantRemoved": 1}
    }
  ],
  "duration": "5m30s",
  "timestamp": "ISO 8601 datetime"
}
```

### 1.5 metadata 扩展定义

当前 metadata 子字段 → FT-004 扩展后：

| 字段 | 类型 | 说明 | 来源 | 新增 |
|------|------|------|------|:----:|
| targetUrl | string | 测试目标基础 URL | 当前 | ❌ |
| timeout | number | 全局超时秒数（默认 30） | 当前 | ❌ |
| browser | string | 浏览器类型 | 当前 | ❌ |
| viewport | object | 视口尺寸 | 当前 | ❌ |
| auth | object | 认证配置 | 当前 | ❌ |
| recordedAt | string | 录制时间（ISO 8601） | FT-004 | ✅ |
| duration | number | 录制耗时（秒） | FT-004 | ✅ |
| pageTitle | string | 页面标题 | FT-004 | ✅ |
| pageStructure | object | 页面结构标记 | FT-004 | ✅ |
| viewportActual | object | 实际视口尺寸 | FT-004 | ✅ |
| frontFramework | string | 前端框架（Vue/React/Angular/Unknown） | FT-004 | ✅ |
| source | string | 用例来源（固定 `record`） | 当前（提升为 metadata 子字段） | ✅ |

**pageStructure 子对象**：

| 字段 | 类型 | 说明 |
|------|------|------|
| hasDataTestId | boolean | 页面是否使用 data-testid 属性 |
| hasNameAttr | boolean | 页面是否使用 name 属性 |
| hasAriaLabel | boolean | 页面是否使用 aria-label 属性 |
| mainContentSelector | string | 推断的主内容区选择器 |
| headerSelector | string | 推断的头部区域选择器 |
| navSelector | string | 推断的导航区域选择器 |

---

## 2. DSL Spec 扩展

### 2.1 顶层新增 `params` 字段

```yaml
name: string
description: string
framework: string
capture: string
tags: string[]
params: object              # 🆕 FT-004 新增：数据参数化变量
  {paramName}: {defaultValue}  # 参数名→默认值映射
metadata: object
source: string
stages: Stage[]
```

**params 字段说明**：

| 字段 | 类型 | 必填 | 说明 | 示例 |
|------|------|:----:|------|------|
| params | object | ❌ | 数据参数化变量映射 | `{username: admin, password: admin123}` |

**参数引用语法**：步骤中使用 `{{params.paramName}}` 引用参数值：

```yaml
params:
  username: admin
  password: admin123
stages:
  - name: 登录
    steps:
      - action: type
        target: [name="username"]
        value: "{{params.username}}"
      - action: type
        target: [name="password"]
        value: "{{params.password}}"
```

### 2.2 Step 新增 `pageContext` 和 `pageTransition` 字段

```yaml
steps:
  - action: string
    target: string
    value: string
    capture: string
    timeout: number
    frameworkOverride: string
    pageContext: string       # 🆕 FT-004 新增：页面上下文
    pageTransition: string    # 🆕 FT-004 新增：页面跳转标记
    assertions: Assertion[]
```

| 字段 | 类型 | 必填 | 说明 | 可选值 |
|------|------|:----:|------|--------|
| pageContext | string | ❌ | 当前步骤所在的页面上下文 | `main`（默认）/ `popup` / `newTab` |
| pageTransition | string | ❌ | 当前步骤触发的页面跳转类型 | `navigate` / `new-tab` / `new-window` / `none`（默认） |

**使用示例**：

```yaml
steps:
  - action: click
    target: a.view-detail
    pageTransition: new-tab    # 点击链接打开新标签页
  - action: wait
    target: .detail-content
    pageContext: newTab         # 在新标签页中等待
  - action: click
    target: .close-btn
    pageContext: newTab         # 在新标签页中操作
```

### 2.3 断言新增 `confidence` 字段

```yaml
assertions:
  - type: string
    target: string
    expected: string
    message: string
    confidence: string       # 🆕 FT-004 新增：推断置信度
    inferredFrom: string     # 🆕 FT-004 新增：推断来源描述
```

| 字段 | 类型 | 必填 | 说明 | 可选值 |
|------|------|:----:|------|--------|
| confidence | string | ❌ | 断言推断的置信度评分 | `high` / `medium` / `low` |
| inferredFrom | string | ❌ | 断言推断的来源描述 | 如"页面结构推断"、"URL变化推断" |

**说明**：`confidence` 和 `inferredFrom` 仅对录制自动推断的断言有意义。手动编写或 AI 生成的断言无需这两个字段。

### 2.4 Schema 校验规则扩展

新增校验规则：

- `params` 对象的每个键名应使用小写英文字母 + 下划线
- 步骤 `value` 中使用 `{{params.xxx}}` 引用时，`xxx` 必须在 `params` 中有对应键
- `pageContext` 仅接受 `main` / `popup` / `newTab`
- `pageTransition` 仅接受 `navigate` / `new-tab` / `new-window` / `none`
- `confidence` 仅接受 `high` / `medium` / `low`
- 同一用例中 `pageContext: popup/newTab` 的步骤应紧跟 `pageTransition` 步骤之后

---

## 3. 场景一：按用例逐条录制

### 3.1 内部设计

已在 §1 录制命令重构中完整定义。核心流程：

- **会话初始化**（Step 1）：启动浏览器 + 相似用例检测
- **逐用例循环**（Step 2~7）：录制→`/next`→命名→后处理→摘要→保存→重启
- **会话结束**（Step 8）：`/end`→关闭→摘要

### 3.2 关键交互点

| 交互点 | 触发条件 | 用户操作 | AI 响应 |
|--------|----------|----------|---------|
| 相似用例提示 | Step 1 初始化时 | 确认继续或查看 | 展示匹配列表 |
| 完成信号 | 用户输入 `/next` | — | 暂停录制，进入断点 |
| 用例命名 | Step 4 | 输入用例名称 | 校验+确认 |
| 优化摘要确认 | Step 6 | 浏览确认 | 展示4区块摘要 |
| 继续/结束选择 | Step 7 结束后 | 输入"继续"或 `/end` | 重启Codegen或关闭浏览器 |

### 3.3 YAML 用例示例（逐用例录制产出）

**用例1：user-login-test**

```yaml
name: user-login-test
description: 逐用例录制 — 用户登录流程
framework: playwright
capture: on-fail
tags: [recorded, module:auth, feature:login]
source: record
params:                        # dataParam=true 时出现
  username: testuser
  password: password123
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
  browser: chromium
  recordedAt: "2026-07-20T10:30:00Z"
  duration: 45
  pageTitle: "登录 - Ai Fast"
  pageStructure:
    hasDataTestId: true
    hasNameAttr: true
    hasAriaLabel: false
    mainContentSelector: .auth-form
    headerSelector: .header
    navSelector: .nav-bar
  viewportActual: {width: 1280, height: 720}
  frontFramework: Vue
stages:
  - name: 登录页面访问
    steps:
      - action: navigate
        target: /login
      - action: assert
        assertions:
          - type: A1
            target: .auth-form
            expected: visible
            confidence: high
            inferredFrom: 页面结构推断（data-testid存在）
            message: 登录表单应可见
  - name: 输入凭证
    steps:
      - action: type
        target: [name="username"]
        value: "{{params.username}}"
      - action: type
        target: [name="password"]
        value: "{{params.password}}"
      - action: click
        target: .auth-form .el-button--primary
        capture: always
  - name: 登录验证
    steps:
      - action: wait
        target: .header-user
        timeout: 5
      - action: assert
        assertions:
          - type: A2
            target: current-url
            expected: /home
            confidence: high
            inferredFrom: navigate后URL变化
            message: 登录成功后应跳转到首页
          - type: A4
            target: .header-user .user-name
            expected: testuser
            confidence: medium
            inferredFrom: DOM文本变化推断
            message: 用户名应显示为 testuser
          - type: A6
            target: [name="username"]
            expected: testuser
            confidence: high
            inferredFrom: type操作后验证
            message: 用户名输入框值应为 testuser
```

---

## 4. 场景二：选择器优化

### 4.1 选择器优化引擎规范摘要

**触发条件**：`selectorStrategy=optimize`（默认），在完成断点 Step 5b 执行。

**优化策略优先级**：

| 优先级 | 选择器类型 | 稳定性 | 优化策略 |
|:------:|-----------|:------:|----------|
| 1 | `[data-testid="XXX"]` | ✅ 高 | 保持不变（最佳选择器） |
| 2 | `[name="XXX"]` | ✅ 高 | 保持不变（语义化属性） |
| 3 | `[aria-label="XXX"]` | ✅ 高 | 保持不变（无障碍属性） |
| 4 | `[role="XXX"]` | ✅ 高 | 保持不变（语义角色） |
| 5 | `#unique-id` | ✅ 高 | 检测是否动态ID → 动态则优化 |
| 6 | `.class-name` | ⚠️ 中 | 尝试缩短路径、找更稳定父级 |
| 7 | `.parent .child` | ⚠️ 中 | 尝试精简组合路径 |
| 8 | `text=XXX` | ⚠️ 中 | 建议替换为 data-testid |
| 9 | `:nth-child(N)` | ❌ 低 | **必须优化**：找同级稳定属性替代 |
| 10 | 动态ID（随机值） | ❌ 低 | **必须优化**：找同级稳定属性替代 |

**优化操作集**：

| 操作 | 适用场景 | 示例 |
|------|----------|------|
| **缩短路径** | 冗长组合选择器 | `body > div > div > form > input` → `form input` |
| **nth-child 替代** | `:nth-child(N)` 选择器 | `.el-form-item:nth-child(2) input` → `[name="password"]` 或 `.el-form-item:nth-child(2)` → `.password-field` |
| **动态ID 替代** | 随机ID属性 | `#abc123-random .btn` → `.login-form .submit-btn` |
| **语义化替代** | 非语义选择器 | `.btn-primary` → `[data-testid="submit-btn"]`（如果DOM中存在） |
| **路径精简** | 深层嵌套选择器 | `.auth-form .el-form .el-form-item .el-input input` → `.auth-form input` |

**优化摘要展示格式**：见 §1 Step 6 的 1️⃣ 区块。

**用户确认机制**：
- 自动优化低稳定性选择器
- 优化结果在摘要中展示（原始→优化后）
- 用户如不满意，可直接修改保存的 YAML 文件（无需逐条拒绝）
- `selectorStrategy=raw` 时跳过优化，保留 Codegen 原始输出

---

## 5. 场景三：断言推断

### 5.1 断言推断引擎规范摘要

**触发条件**：在完成断点 Step 5c 执行，对所有类型操作推断断言。

**四类断言推断规则**：

#### A1 元素可见推断

| 触发条件 | 推断策略 | 置信度 |
|----------|----------|:------:|
| `navigate` 操作后 | 页面结构动态推断核心可见元素 | 高（有data-testid）/ 中（h1/h2）/ 低（body） |
| `click` 操作后（页面未跳转） | 推断点击后出现的新元素（如弹窗、提示消息） | 中 |
| `wait` 操作后 | 等待目标元素本身即可见断言 | 高 |

**A1 页面结构动态推断优先级**（替代硬编码映射表）：

1. **用户提供映射文件**（`pageMapFile` 参数）→ 最高准确性，置信度：高
2. **页面 DOM 分析**：
   - 优先级：`[data-testid] > h1/h2 标题 > [name] > [aria-label] > .main/.content > body`
   - 分析规则：获取页面 DOM，按优先级查找首个匹配的核心元素
   - 置信度映射：data-testid→高、h1/h2→高、name→高、aria-label→中、.main/.content→中、body→低

#### A2 URL 跳转推断

| 触发条件 | 推断策略 | 置信度 |
|----------|----------|:------:|
| `navigate` 操作后 | 预期 URL 为 navigate 的 target 路径 | 高 |
| `click` 操作后（URL 发生变化） | 预期 URL 为变化后的 URL 路径 | 高 |

#### A4 内容匹配推断

| 触发条件 | 推断策略 | 置信度 |
|----------|----------|:------:|
| `click` 操作后 | 推断点击目标元素文案变化（如按钮 "登录"→"已登录"） | 中 |
| `navigate` 操作后 | 推断页面关键文本内容（如用户名、标题） | 中 |
| `type` 操作后 | 推断输入值在目标元素中可见 | 中 |

#### A6 表单值推断

| 触发条件 | 推断策略 | 置信度 |
|----------|----------|:------:|
| `type` 操作后 | 验证输入框当前值 = type 的 value | 高 |
| `select` 操作后 | 验证下拉框当前选中值 = select 的 value | 高 |

**推断结果标注**：每条推断断言附带 `confidence`（高/中/低）和 `inferredFrom`（推断来源描述）字段。

---

## 6. 场景四：步骤优化

### 6.1 步骤优化引擎规范摘要

**触发条件**：在完成断点 Step 5d 执行。

**三类优化规则**：

#### 表单填写组合并

| 条件 | 合并策略 | 示例 |
|------|----------|------|
| 连续 ≥2 个 `type` 操作 | 合并为注释标注的连续填写组 | 3个type(username+password+email) → 保持为独立步骤但添加 `group: form-fill` 注释标记 |

**合并格式**：不改变 YAML DSL Step 结构（不引入新的 action 类型），而是在步骤上方添加注释行：

```yaml
stages:
  - name: 输入凭证
    steps:
      # [form-fill-group] 连续表单填写组：用户名+密码
      - action: type
        target: [name="username"]
        value: "{{params.username}}"
      - action: type
        target: [name="password"]
        value: "{{params.password}}"
```

#### 智能等待替代

| 原始步骤 | 替代策略 | 示例 |
|----------|----------|------|
| `wait target=timeout:{ms}ms` | 替换为 `waitForSelector`，推断等待目标元素 | `wait timeout:3000ms` → `wait .header-user timeout:3` |
| `click`（提交类按钮）后 | 补充 `wait` 步骤，推断等待目标 | `click .submit-btn` → 后续补充 `wait .success-message timeout:5` |
| `navigate` 后 | 补充 `wait` 步骤，等待页面核心元素 | `navigate /home` → 后续补充 `wait .home-content timeout:5` |

#### 冗余等待去除

| 条件 | 去除策略 | 示例 |
|------|----------|------|
| 连续 ≥2 个 `wait` 同一 target | 仅保留第一个 | `wait .header timeout:5` + `wait .header timeout:3` → 仅保留第一个 |
| `wait` 后紧跟 `assert` 同一 target | 去除 wait（assert 本身含等待逻辑） | `wait .auth-form timeout:5` + `assert A1 .auth-form visible` → 仅保留 assert |

---

## 7. 场景五：数据参数化

### 7.1 数据参数化规范摘要

**触发条件**：`dataParam=true`，在完成断点 Step 5e 执行。

**参数化提取规则**：

| 提取目标 | 条件 | 参数名生成规则 | 示例 |
|----------|------|----------------|------|
| `type` 操作的 `value` | 所有 type 操作 | `{语义名称}`（基于 target 属性推断） | `type [name="username"] "testuser"` → `params.username = testuser` |
| `select` 操作的 `value` | 所有 select 操作 | `{语义名称}`（基于 target 属性推断） | `select [name="role"] "admin"` → `params.role = admin` |

**参数名推断优先级**：
1. `name` 属性值 → 如 `[name="username"]` → `username`
2. `data-testid` 属性值 → 如 `[data-testid="email-input"]` → `email`
3. `aria-label` 属性值 → 如 `[aria-label="搜索关键词"]` → `searchKeyword`
4. `id` 属性值 → 如 `#search-box` → `searchBox`
5. 无法推断 → 使用 `inputN` 序号（如 `input1`、`input2`）

**YAML 产出示例**：见 §2.1 params 字段定义和 §3.3 YAML 示例。

**`dataParam=false`（默认）**：输入值硬编码，不提取参数，优化摘要中标注"参数化已关闭"。

---

## 8. 场景六：多页面与弹窗录制

### 8.1 多页面处理规范摘要

**触发条件**：Codegen 代码中出现多页面/弹窗操作。

**Codegen 多页面代码识别**：

| Codegen 代码模式 | 识别为 | pageContext | pageTransition |
|-----------------|--------|-------------|----------------|
| `page.goto('url')` | 页面导航 | `main` | `navigate` |
| `page.waitForEvent('popup')` | 弹出窗口 | `popup` | `new-window` |
| `[newPage = context.waitForEvent('page')]` | 新标签页 | `newTab` | `new-tab` |
| `page.waitForEvent('framedetached')` | — | 忽略（iframe 不支持） | — |

**YAML DSL 标记格式**：见 §2.2 Step 扩展字段。

**录制流程处理**：
- 检测到新页面/弹窗时，AI 自动切换录制跟踪到新上下文
- 新页面/弹窗的操作序列标记对应的 `pageContext`
- 用户关闭弹窗/标签页时，AI 切回主页面上下文

**不支持 iframe**：iframe 内操作在 Codegen 中以 `frameLocator` 产出，当前解析规则忽略 iframe 上下文操作，仅保留主页面序列。

---

## 9. 场景七：录制前相似用例提示

### 9.1 相似用例检测规范摘要

**触发条件**：录制会话初始化 Step 1 时执行。

**检测算法**：

| 匹配维度 | 权重 | 匹配规则 |
|----------|:----:|----------|
| URL 匹配 | 50% | 目标 URL 与已有用例 `metadata.targetUrl` 比对，路径完全匹配=100%，部分匹配按相似度打分 |
| tags 匹配 | 30% | 用户提供 tags 与已有用例 tags 比对，交集/并集比率 |
| 名称匹配 | 20% | URL 推断的名称与已有用例名称语义相似度 |

**匹配阈值**：综合匹配度 ≥ 60% 视为"相似用例"。

**提示格式**：

```markdown
### ⚠️ 相似用例提示

检测到以下已有用例可能与本次录制场景重复：

| # | 用例名称 | 匹配度 | URL | tags |
|---|----------|:------:|-----|------|
| 1 | user-login-test | 85% | http://localhost:3000 | [auth, user] |
| 2 | admin-login-test | 65% | http://localhost:3001 | [auth, admin] |

**建议**：
- 查看已有用例内容：输入 `view {用例名称}` 查看 YAML 详情
- 继续录制：输入 `continue` 开始录制（新用例独立保存）
- 取消录制：输入 `cancel` 退出
```

---

## 10. 新增 Spec 规范文件

### 10.1 文件清单

| # | 文件路径 | 内容 |
|---|----------|------|
| 1 | `.asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md` | 选择器优化引擎规范（优先级、策略、评分、摘要格式） |
| 2 | `.asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md` | 断言推断引擎规范（A1/A2/A4/A6 触发条件、推断策略、置信度） |
| 3 | `.asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md` | 步骤优化引擎规范（表单合并、智能等待、去冗余） |
| 4 | `.asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md` | 数据参数化规范（提取规则、参数名推断、YAML格式） |

### 10.2 各规范文件核心章节

**选择器优化规范**：
1. 选择器稳定性评分规则（10级优先级表）
2. 优化操作集定义（5种操作）
3. 优化摘要展示格式
4. 用户确认机制
5. `selectorStrategy` 参数说明

**断言推断规范**：
1. A1/A2/A4/A6 四类推断触发条件表
2. A1 页面结构动态推断优先级规则
3. 置信度评分规则（高/中/低）
4. 映射文件（pageMapFile）格式定义
5. 推断结果标注格式（confidence + inferredFrom）

**步骤优化规范**：
1. 表单填写组合并规则（注释标注格式）
2. 智能等待替代规则（3种场景）
3. 冗余等待去除规则（2种条件）
4. Stage 划分策略（与当前一致）

**数据参数化规范**：
1. 参数化提取规则（type/select 操作）
2. 参数名推断优先级（5级）
3. `{{params.xxx}}` 引用语法
4. `dataParam` 参数说明
5. YAML 格式示例

---

## 11. 实施检查清单

### 11.1 需修改/创建的文件

| # | 文件 | 变更类型 | 状态 |
|---|------|:--------:|:----:|
| 1 | `.asdm/toolsets/web-auto-tester/actions/auto-test-record.md` | ✏️ 重写 | ⬜ 待实施 |
| 2 | `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md` | ✏️ 扩展 | ⬜ 待实施 |
| 3 | `.asdm/toolsets/web-auto-tester/spec/auto-test-selector-optimization-spec.md` | 🆕 新增 | ⬜ 待实施 |
| 4 | `.asdm/toolsets/web-auto-tester/spec/auto-test-assertion-inference-spec.md` | 🆕 新增 | ⬜ 待实施 |
| 5 | `.asdm/toolsets/web-auto-tester/spec/auto-test-step-optimization-spec.md` | 🆕 新增 | ⬜ 待实施 |
| 6 | `.asdm/toolsets/web-auto-tester/spec/auto-test-data-parameterization-spec.md` | 🆕 新增 | ⬜ 待实施 |

### 11.2 不需要创建的文件

| 路径 | 原因 |
|------|------|
| `.asdm/toolsets/web-auto-tester/src/recorder/` | 纯文档驱动架构，无编译代码 |
| 新的 Action 命令文件 | FT-004 不引入新命令 |

### 11.3 变更范围修正记录

| Overall 原始描述 | 修正后描述 | 修正原因 |
|-----------------|-----------|----------|
| `.asdm/toolsets/web-auto-tester/specs/` (修改) | `.asdm/toolsets/web-auto-tester/spec/` (修改+新增) | 实际目录名为 `spec/`，非 `specs/` |
| `.asdm/toolsets/web-auto-tester/src/recorder/` (修改) | 删除此项 | 纯文档驱动架构，无 TypeScript 源代码 |

---

**文档版本**：1.0.0
**创建日期**：2026-07-20
**最后更新**：2026-07-20
**维护者**：AI Planner
