# Web Auto Tester - 数据参数化规范

**Document Version**: 1.0
**Last Updated**: 2026-07-20
**Toolset ID**: web-auto-tester
**Related Spec**: `auto-test-dsl-spec.md`（params 字段、`{{params.xxx}}` 引用语法）

---

## 1. 概述

数据参数化引擎在录制后处理阶段（Step 5e）将硬编码的输入值提取为可复用的参数变量，支持用例在不同数据集下重复执行，提升用例的可维护性和可复用性。

核心原则：
- **显式开关**：`dataParam` 参数控制是否启用参数化，默认关闭（false）
- **参数名推断**：基于元素属性自动推断参数名，优先使用语义化名称
- **双花括号引用**：步骤 value 使用 `{{params.xxx}}` 语法引用参数值

---

## 2. 参数化提取规则

### 2.1 提取目标

| 操作类型 | 提取字段 | 说明 |
|----------|----------|------|
| type | value | 输入文本值提取为参数 |
| select | value | 下拉选择值提取为参数 |

### 2.2 提取条件

- `dataParam=true` 时：所有 type/select 操作的 value 均提取为参数
- `dataParam=false` 时（默认）：不提取，输入值保持硬编码

### 2.3 不提取的操作

| 操作类型 | 说明 |
|----------|------|
| navigate | URL 路径不参数化（页面导航路径通常固定） |
| click | 无 value 字段，不参数化 |
| wait | 无 value 字段，不参数化 |
| scroll | 滚动参数通常固定，不参数化 |
| hover | 无 value 字段，不参数化 |
| upload | 文件路径不参数化 |
| screenshot | 无 value 字段，不参数化 |
| assert | 断言 expected 值不参数化（断言预期值应固定） |

---

## 3. 参数名推断优先级 — 5 级

参数名从元素属性推断，按以下优先级选取：

| 优先级 | 属性来源 | 推断规则 | 示例 |
|:------:|---------|----------|------|
| 1 | `name` 属性 | 直接取 name 属性值作为参数名 | `input[name="username"]` → `username` |
| 2 | `data-testid` 属性 | 取 data-testid 值，去除前缀/后缀 | `[data-testid="login-username-input"]` → `login_username` |
| 3 | `aria-label` 属性 | 取 aria-label 值，转换为英文小写+下划线 | `[aria-label="邮箱地址"]` → `email_address` |
| 4 | `id` 属性（非动态） | 取 id 值，去除随机后缀 | `#password-field` → `password_field` |
| 5 | 序号 `inputN` | 按步骤顺序编号 | 无任何属性 → `input1`, `input2`, `input3` |

### 3.1 参数名格式规则

| 规则 | 说明 | 示例 |
|------|------|------|
| 小写英文字母 + 下划线 | 参数名仅允许 `[a-z_]+` | `username`, `login_password` |
| 去除前缀后缀 | 去除 `-input`, `-field`, `-box` 等通用后缀 | `login-username-input` → `login_username` |
| 中文翻译 | aria-label 含中文时转换为拼音或英文 | `邮箱地址` → `email_address` |
| 序号兜底 | 无属性时按 `inputN` 格式命名 | `input1`, `input2` |

### 3.2 推断示例

| 元素选择器 | 推断优先级 | 参数名 | 原始 value |
|-----------|-----------|--------|-----------|
| `input[name="username"]` | 1（name） | `username` | `testuser` |
| `[data-testid="login-username-input"]` | 2（data-testid） | `login_username` | `testuser` |
| `[aria-label="密码"]` | 3（aria-label） | `password` | `password123` |
| `#email-field` | 4（id） | `email` | `user@example.com` |
| `.form-item:nth-child(3) input` | 5（序号） | `input3` | `测试值` |

---

## 4. `{{params.xxx}}` 引用语法

### 4.1 语法格式

步骤 value 中使用双花括号引用参数：

```yaml
# 硬编码（dataParam=false）
- action: type
  target: input[name="username"]
  value: testuser

# 参数化引用（dataParam=true）
- action: type
  target: input[name="username"]
  value: "{{params.username}}"
```

### 4.2 引用规则

| 规则 | 说明 |
|------|------|
| 双花括号包裹 | `{{params.paramName}}` 格式，花括号内无空格 |
| 引用对应键 | `xxx` 必须在顶层 `params` 中有对应键名 |
| 仅替换 value | 仅在 type/select 操作的 value 字段中替换 |
| 不替换 target | 选择器不参数化（保持稳定性） |
| 不替换 expected | 断言预期值不参数化 |

---

## 5. `dataParam` 参数说明

`dataParam` 是 `/auto-test-record` 命令的参数，控制数据参数化开关：

| 值 | 说明 | 适用场景 |
|----|------|----------|
| `false`（默认） | 不参数化，输入值保持硬编码 | 单次验证，数据不需复用 |
| `true` | 启用参数化，提取输入值为参数变量 | 数据驱动测试，需多数据集执行 |

### 5.1 行为差异

| 行为 | dataParam=true | dataParam=false |
|------|----------------|-----------------|
| 顶层 params 字段 | ✅ 添加 | ❌ 不添加 |
| type value 替换 | ✅ 替换为 `{{params.xxx}}` | ❌ 保持硬编码 |
| select value 替换 | ✅ 替换为 `{{params.xxx}}` | ❌ 保持硬编码 |
| 参数化摘要展示 | ✅ 展示 4️⃣ 区块 | ✅ 标注"参数化已关闭" |

---

## 6. YAML 格式示例

### 6.1 参数化用例示例

```yaml
name: user-login-test
description: 验证用户端登录流程（参数化）
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
stages:
  - name: 登录页面访问
    steps:
      - action: navigate
        target: /login
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
```

### 6.2 非参数化用例示例（dataParam=false）

```yaml
name: user-login-test
description: 验证用户端登录流程
framework: playwright
capture: on-fail
tags: [auth, user, P1]
source: record
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
stages:
  - name: 登录页面访问
    steps:
      - action: navigate
        target: /login
  - name: 输入凭证
    steps:
      - action: type
        target: input[name="username"]
        value: testuser          # 硬编码值
      - action: type
        target: input[name="password"]
        value: password123       # 硬编码值
      - action: click
        target: button[type="submit"]
```

### 6.3 多参数化用例示例

```yaml
name: user-search-product-test
description: 验证用户搜索商品流程（参数化）
params:
  username: testuser
  password: password123
  search_keyword: 手机
  category: 电子产品
metadata:
  targetUrl: http://localhost:3000
  timeout: 30
stages:
  - name: 登录
    steps:
      - action: type
        target: input[name="username"]
        value: "{{params.username}}"
      - action: type
        target: input[name="password"]
        value: "{{params.password}}"
      - action: click
        target: button[type="submit"]
  - name: 搜索商品
    steps:
      - action: type
        target: .search-bar input
        value: "{{params.search_keyword}}"
      - action: select
        target: select[name="category"]
        value: "{{params.category}}"
      - action: click
        target: .search-bar .search-btn
```

---

## 7. 优化摘要展示格式

数据参数化完成后，在 Step 6 中按以下格式展示：

### 7.1 参数化开启时（dataParam=true）

```
4️⃣ 数据参数化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| 参数名           | 默认值        | 原始步骤                     |
|-----------------|--------------|------------------------------|
| username        | testuser     | type → input[name="username"] |
| password        | password123  | type → input[name="password"] |
| search_keyword  | 手机          | type → .search-bar input      |
| category        | 电子产品      | select → select[name="category"] |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计：提取 4 个参数 | type 操作 3 个 | select 操作 1 个
💡 提示：修改 params 默认值即可使用不同数据集重新执行
```

### 7.2 参数化关闭时（dataParam=false）

```
4️⃣ 数据参数化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ 参数化已关闭（dataParam=false）
输入值将保持硬编码。如需参数化，下次录制时使用：
/auto-test-record url=... dataParam=true
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 8. 参数化引擎执行流程

```
操作序列（来自 Codegen 录制 + 选择器优化 + 断言推断 + 步骤优化）
    │
    ▼
[0] 检查 dataParam 参数
    │   ├─ false → 标注"参数化已关闭"，跳过后续步骤
    │   ├─ true → 继续
    │
    ▼
[1] 识别 type/select 操作的 value 字段
    │
    ▼
[2] 逐个推断参数名（5 级优先级）
    │   ├─ name 属性 → data-testid → aria-label → id → 序号
    │
    ▼
[3] 构建 params 顶层字段（参数名 → 默认值映射）
    │
    ▼
[4] 替换 type/select 的 value 为 {{params.xxx}}
    │
    ▼
[5] 生成参数化摘要表格
    │
    ▼
输出参数化后步骤序列 → Step 5f（元数据增强）
```

---

## 9. 版本记录

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-07-20 | 初始版本：参数化提取规则、5级参数名推断、引用语法、dataParam参数、YAML格式、摘要格式 |
