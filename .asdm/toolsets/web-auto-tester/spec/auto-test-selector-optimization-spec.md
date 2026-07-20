# Web Auto Tester - 选择器优化引擎规范

**Document Version**: 1.0
**Last Updated**: 2026-07-20
**Toolset ID**: web-auto-tester
**Related Spec**: `auto-test-dsl-spec.md`（Step.target 字段）

---

## 1. 概述

选择器优化引擎在录制后处理阶段（Step 5b）自动优化 Codegen 录制的原始选择器，提升选择器稳定性，减少因页面结构变动导致的测试失败。

核心原则：
- **稳定性优先**：优先选择不易受页面结构变动影响的选择器
- **可读性提升**：将冗长的 CSS 路径替换为语义化选择器
- **非破坏性**：优化失败时保留原始选择器，不强制替换

---

## 2. 选择器稳定性评分 — 10 级优先级表

| 优先级 | 选择器类型 | 稳定性 | 示例 | 说明 |
|:------:|-----------|:------:|------|------|
| 1 | `[data-testid]` | ✅ 高 | `[data-testid="login-btn"]` | 开发者有意标记的测试标识，最稳定 |
| 2 | `[data-cy]` / `[data-qa]` | ✅ 高 | `[data-cy="submit"]` | 类似 data-testid 的测试专用属性 |
| 3 | `aria-label` 属性 | ✅ 高 | `[aria-label="搜索"]` | 无障碍标签，语义明确且不易变动 |
| 4 | `name` 属性 | ⚠️ 中 | `[name="username"]` | 表单字段常用，较稳定但可能重命名 |
| 5 | `id` 属性（非动态） | ⚠️ 中 | `#login-form` | 唯一标识，但可能被移除或重构 |
| 6 | 语义化标签 | ⚠️ 中 | `h1`, `button[type="submit"]` | HTML 语义标签，较稳定 |
| 7 | 文本内容选择器 | ⚠️ 中 | `text=登录` / `//button[text()="登录"]` | 依赖文案，文案变更时失效 |
| 8 | 组合类名选择器 | ❌ 低 | `.auth-form .el-button--primary` | 路径依赖 DOM 层级，结构变动时失效 |
| 9 | `nth-child` / `nth-of-type` | ❌ 低 | `.form-item:nth-child(2) input` | 依赖元素位置，极易因插入元素而失效 |
| 10 | 动态/随机 ID | ❌ 低 | `#react-abc123-root` | 框架生成的随机 ID，每次渲染可能不同 |

### 稳定性标注规则

| 标注 | 含义 | 优化目标 |
|------|------|----------|
| ✅ 高 | 无需优化，已是最佳选择器 | 保留原样 |
| ⚠️ 中 | 可优化，但不紧急 | 视情况优化 |
| ❌ 低 | 必须优化，极易失效 | 强制优化或标注风险 |

---

## 3. 优化操作集 — 5 种操作

### 3.1 缩短路径（Path Shortening）

**适用场景**：选择器路径过长，包含冗余中间层级

**规则**：去除不影响唯一性的中间层级选择器

**示例**：

| 原始选择器 | 优化后选择器 | 说明 |
|------------|-------------|------|
| `.app .main .content .auth-form .el-button--primary` | `.auth-form .el-button--primary` | 去除 .app/.main/.content 冗余层级 |
| `div > div > div > form > button` | `form button` | 去除冗余 div 层级 |

### 3.2 nth-child 替代（nth-child Replacement）

**适用场景**：选择器包含 `nth-child` / `nth-of-type`，依赖元素位置

**规则**：
1. 优先查找同级元素的唯一属性（name、data-testid、aria-label）
2. 次选查找父元素的唯一属性 + 子元素类型
3. 无唯一属性时保留 nth-child 并标注为低稳定性

**示例**：

| 原始选择器 | 优化后选择器 | 优化路径 |
|------------|-------------|----------|
| `.form-item:nth-child(2) input` | `input[name="password"]` | 查找同级 name 属性 |
| `.menu-item:nth-child(3)` | `.menu-item[aria-label="设置"]` | 查找同级 aria-label |
| `.list-item:nth-child(1) .title` | `.list-item:first-child .title` | 无法找到唯一属性，保留 nth 但标注 |

### 3.3 动态 ID 替代（Dynamic ID Replacement）

**适用场景**：选择器包含框架生成的随机 ID（如 React/Vue 的自动 ID）

**规则**：
1. 检测模式：包含随机字符串的 id 选择器（`#react-xxx-root`、`#vue-xxx-123`）
2. 替换为同级元素的稳定属性（data-testid、aria-label、name）
3. 无稳定属性时使用父元素 + 元素类型组合

**示例**：

| 原始选择器 | 优化后选择器 | 说明 |
|------------|-------------|------|
| `#react-abc123-root .login-btn` | `.login-btn[data-testid="submit"]` | 替换动态根 ID |
| `#vue-456-form input` | `form.auth-form input[name="email"]` | 替换动态 form ID |

### 3.4 语义化替代（Semantic Replacement）

**适用场景**：选择器使用无语义的类名或标签组合

**规则**：
1. 将 `.xxx-btn` 替换为 `button[aria-label="xxx"]`（如有 aria-label）
2. 将 `.xxx-input` 替换为 `input[name="xxx"]`（如有 name 属性）
3. 将 `.xxx-link` 替换为 `a[href="/xxx"]`（如有 href 属性）

**示例**：

| 原始选择器 | 优化后选择器 | 说明 |
|------------|-------------|------|
| `.submit-btn` | `button[type="submit"]` | 类名 → 语义属性 |
| `.search-input` | `input[name="search"]` | 类名 → name 属性 |
| `.home-link` | `a[href="/home"]` | 类名 → href 属性 |

### 3.5 路径精简（Path Simplification）

**适用场景**：选择器包含不必要的伪类、层级分隔符

**规则**：
1. 去除 `>` 直接子元素符号（除非影响唯一性）
2. 去除冗余的 `:first-child`（如果同级只有该类型元素）
3. 合并相同父元素下的多个选择器

**示例**：

| 原始选择器 | 优化后选择器 | 说明 |
|------------|-------------|------|
| `.form > .form-item > .input > input` | `.form-item input` | 去除 > 符号和冗余层级 |
| `.list :first-child` | `.list-item:first-child` | 明确元素类型 |

---

## 4. 优化摘要展示格式

优化完成后，在 Step 6（优化摘要展示）中按以下格式展示选择器优化结果：

### 4.1 选择器优化区块模板

```
1️⃣ 选择器优化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| # | 原始选择器                    | 优化后选择器              | 稳定性变化 |
|---|-------------------------------|--------------------------|-----------|
| 1 | .form-item:nth-child(2) input | input[name="password"]   | ❌低→✅高  |
| 2 | #react-abc123 .submit-btn     | button[type="submit"]    | ❌低→⚠️中 |
| 3 | .app .main .content .title    | .content .title          | ⚠️中→⚠️中 |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计：优化 3/5 个选择器 | 稳定性提升 2 个 | 无法优化 0 个
```

### 4.2 统计行格式

- **优化总数**：被优化选择器数 / 总选择器数
- **稳定性提升数**：稳定性等级提升的选择器数
- **无法优化数**：无稳定替代方案的选择器数

---

## 5. 用户确认机制

### 5.1 自动优化规则

- 稳定性为 ❌低 的选择器：**自动优化**，无需逐条确认
- 稳定性为 ⚠️中 的选择器：**自动优化**（如果存在更稳定替代）
- 稳定性为 ✅高 的选择器：**不优化**，保留原样

### 5.2 摘要展示与确认

优化完成后展示摘要表格，用户可：
- **直接修改 YAML**：对优化结果不满意时，直接编辑生成的 YAML 文件
- **无需逐条拒绝**：整体接受优化结果，后续可手动微调

### 5.3 无法优化时的处理

当选择器无法找到更稳定的替代方案时：
- 保留原始选择器
- 在摘要中标注"无法优化"
- 建议用户手动添加 `data-testid` 属性或指定稳定选择器

---

## 6. `selectorStrategy` 参数说明

`selectorStrategy` 是 `/auto-test-record` 命令的参数，控制选择器优化行为：

| 值 | 说明 | 适用场景 |
|----|------|----------|
| `optimize`（默认） | 自动优化低稳定性选择器，生成优化摘要 | 正常录制，追求稳定用例 |
| `raw` | 保留 Codegen 原始选择器，不优化 | 调试场景，需要精确复现录制路径 |

### 使用方式

```yaml
# 命令参数
/auto-test-record url=http://localhost:3000 selectorStrategy=optimize
/auto-test-record url=http://localhost:3000 selectorStrategy=raw
```

### 行为差异

| 行为 | optimize | raw |
|------|----------|-----|
| 缩短路径 | ✅ 执行 | ❌ 不执行 |
| nth-child 替代 | ✅ 执行 | ❌ 不执行 |
| 动态 ID 替代 | ✅ 执行 | ❌ 不执行 |
| 语义化替代 | ✅ 执行 | ❌ 不执行 |
| 路径精简 | ✅ 执行 | ❌ 不执行 |
| 优化摘要展示 | ✅ 展示 | ❌ 不展示 |
| 稳定性标注 | ✅ 标注 | ❌ 不标注 |

---

## 7. 优化引擎执行流程

```
原始选择器列表（来自 Codegen 录制）
    │
    ▼
[1] 逐个评估稳定性等级（10 级优先级表）
    │
    ▼
[2] 对 ❌低/⚠️中 稳定性选择器执行 5 种优化操作
    │   ├─ 缩短路径
    │   ├─ nth-child 替代
    │   ├─ 动态 ID 替代
    │   ├─ 语义化替代
    │   └─ 路径精简
    │
    ▼
[3] 优化后重新评估稳定性等级
    │
    ▼
[4] 生成优化摘要表格（原始→优化后→稳定性变化）
    │
    ▼
[5] 用户确认（整体接受或手动修改 YAML）
    │
    ▼
输出优化后选择器列表 → Step 5c（断言推断）
```

---

## 8. Selenium 选择器特殊规则

Selenium 用例的选择器优化遵循额外规则：

| 规则 | 说明 |
|------|------|
| 前缀保留 | 优化后选择器保留 `css=` / `id=` / `xpath=` 前缀 |
| XPath 优化 | 对 XPath 选择器执行类似优化（去除冗余层级、替换位置依赖） |
| css= 优先 | 优化时优先转换为 `css=` 前缀的 CSS 选择器 |
| 混合策略 | 优化后如需 XPath，保留 `xpath=` 前缀 |

**示例**：

| 原始选择器 | 优化后选择器 |
|------------|-------------|
| `css=.form-item:nth-child(2) input` | `css=input[name="password"]` |
| `xpath=//div[@id="react-abc"]/button` | `css=button[type="submit"]` |

---

## 9. 版本记录

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-07-20 | 初始版本：10级优先级表、5种优化操作、摘要格式、用户确认机制、selectorStrategy 参数 |
