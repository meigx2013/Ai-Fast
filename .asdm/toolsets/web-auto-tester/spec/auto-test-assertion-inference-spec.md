# Web Auto Tester - 断言推断引擎规范

**Document Version**: 1.0
**Last Updated**: 2026-07-20
**Toolset ID**: web-auto-tester
**Related Spec**: `auto-test-dsl-spec.md`（Assertion.confidence/inferredFrom 字段）

---

## 1. 概述

断言推断引擎在录制后处理阶段（Step 5c）自动推断操作步骤后的验证断言，为录制的用例添加必要的断言，减少用户手动编写断言的工作量。

核心原则：
- **确定性优先**：基于页面结构确定性规则推断，而非主观猜测
- **置信度标注**：每条推断断言标注置信度（高/中/低），低置信度断言建议用户删除
- **辅助可选**：pageMapFile 映射文件为可选辅助，不提供时使用页面结构动态推断

---

## 2. A1 元素可见推断

### 2.1 触发条件

| 触发时机 | 说明 | 典型场景 |
|----------|------|----------|
| navigate 后 | 页面导航后检测目标页面关键元素是否可见 | 打开登录页 → 断言登录表单可见 |
| click 后页面未跳转 | 点击后 URL 未变化，检测元素可见性变化 | 点击展开按钮 → 断言面板可见 |
| wait 后 | 等待元素后断言该元素已可见 | 等待加载完成 → 断言内容区域可见 |

### 2.2 推断策略 — 页面结构动态推断优先级

当无 pageMapFile 时，按以下优先级从页面结构中选择断言目标：

| 优先级 | 选择器类型 | 置信度映射 | 说明 |
|:------:|-----------|-----------|------|
| 1 | `[data-testid]` | ✅ 高 | 开发者有意标记，最可靠的可见性标识 |
| 2 | `h1` / `h2` 标题标签 | ✅ 高 | 页面主标题，通常唯一且稳定 |
| 3 | `[name]` 属性 | ⚠️ 中 | 表单字段标识，较稳定 |
| 4 | `[aria-label]` 属性 | ⚠️ 中 | 无障碍标签，语义明确 |
| 5 | `.main` / `.content` / `.page-*` 类名 | ⚠️ 中 | 页面主内容区域标识 |
| 6 | `body` | ❌ 低 | 仅断言页面整体可见，信息量少 |

### 2.3 推断输出格式

```yaml
- type: A1
  target: .auth-form           # 推断的可见性断言目标
  expected: visible
  confidence: high              # 置信度标注
  inferredFrom: "navigate后页面结构[data-testid]"  # 推断来源
  message: 登录表单应可见
```

---

## 3. A2 URL 跳转推断

### 3.1 触发条件

| 触发时机 | 说明 | 典型场景 |
|----------|------|----------|
| navigate 后 | 直接导航到目标 URL | 打开 `/home` → 断言 URL 包含 `/home` |
| click 后 URL 变化 | 点击后检测到 URL 跳转 | 点击登录按钮 → 断言 URL 变为 `/dashboard` |

### 3.2 推断策略

| 策略 | 说明 | 置信度 |
|------|------|--------|
| navigate 目标路径 | 直接取 navigate 的 target 值作为 expected URL | ✅ 高（≥90%） |
| click 后实际 URL | 取 click 后页面实际 URL 路径部分 | ⚠️ 中（50~80%） |
| 路径模式匹配 | URL 包含预期路径而非精确匹配 | ⚠️ 中 |

### 3.3 推断输出格式

```yaml
# navigate 后推断
- type: A2
  target: current-url
  expected: /home
  confidence: high
  inferredFrom: "navigate操作目标路径"
  message: 页面应跳转到首页

# click 后推断
- type: A2
  target: current-url
  expected: /dashboard
  confidence: medium
  inferredFrom: "click后URL实际跳转"
  message: 点击后应跳转到仪表板
```

---

## 4. A4 内容匹配推断

### 4.1 触发条件

| 触发时机 | 说明 | 典型场景 |
|----------|------|----------|
| click 后文案变化 | 点击后检测到页面文案/文本变化 | 点击搜索 → 断言搜索结果包含关键词 |
| navigate 后关键文本 | 导航到新页面后检测页面关键文本 | 打开用户页 → 断言包含用户名 |
| type 后输入值可见 | 输入后检测输入框显示的值 | 输入搜索词 → 断言搜索框显示输入值 |

### 4.2 推断策略

| 策略 | 说明 | 置信度 |
|------|------|--------|
| click 后页面文本差异 | 比较点击前后页面文本变化，取新增的关键文本 | ⚠️ 中（需排除无关文本） |
| navigate 后页面标题/核心文本 | 取页面 h1/h2 标题或核心内容文本 | ✅ 高（标题通常稳定） |
| type 后输入框显示值 | 验证输入框当前显示值等于输入值 | ✅ 高（确定性规则） |

### 4.3 推断输出格式

```yaml
# type 后推断
- type: A4
  target: .search-bar input
  expected: 手机
  confidence: high
  inferredFrom: "type操作输入值验证"
  message: 搜索框应显示输入的关键词

# navigate 后推断
- type: A4
  target: h1
  expected: 用户管理
  confidence: high
  inferredFrom: "navigate后页面标题"
  message: 页面标题应显示"用户管理"
```

---

## 5. A6 表单值推断

### 5.1 触发条件

| 触发时机 | 说明 | 典型场景 |
|----------|------|----------|
| type 后 | 输入文本后验证输入框当前值 | 输入用户名 → 断言用户名框值为 testuser |
| select 后 | 下拉选择后验证选中值 | 选择角色 → 断言角色下拉框值为 admin |

### 5.2 推断策略

| 策略 | 说明 | 置信度 |
|------|------|--------|
| type 后输入值验证 | 验证 input 元素的当前值等于 type 的 value | ✅ 高（确定性规则） |
| select 后选中值验证 | 验证 select 元素的当前选中值等于 select 的 value | ✅ 高（确定性规则） |

### 5.3 推断输出格式

```yaml
# type 后推断
- type: A6
  target: input[name="username"]
  expected: testuser
  confidence: high
  inferredFrom: "type操作值验证"
  message: 用户名输入框应显示 testuser

# select 后推断
- type: A6
  target: select[name="role"]
  expected: admin
  confidence: high
  inferredFrom: "select操作值验证"
  message: 角色下拉框应选中 admin
```

---

## 6. 置信度评分规则

### 6.1 三级置信度定义

| 等级 | 百分比阈值 | 标注 | 含义 | 建议 |
|:----:|-----------|------|------|------|
| 高 | ≥ 80% | `high` | 基于确定性规则推断，结果可靠 | 保留，无需修改 |
| 中 | 50% ~ 80% | `medium` | 基于页面结构推断，可能需要微调 | 保留，建议检查 expected 值 |
| 低 | < 50% | `low` | 基于不确定信息推断，结果可能不准确 | 建议删除或手动重写 |

### 6.2 置信度映射规则

| 推断类型 | 推断策略 | 置信度 |
|----------|----------|--------|
| A1 | `[data-testid]` 选择器 | ✅ 高 |
| A1 | `h1/h2` 选择器 | ✅ 高 |
| A1 | `[name]` 选择器 | ⚠️ 中 |
| A1 | `[aria-label]` 选择器 | ⚠️ 中 |
| A1 | `.main/.content` 选择器 | ⚠️ 中 |
| A1 | `body` 选择器 | ❌ 低 |
| A2 | navigate 目标路径 | ✅ 高 |
| A2 | click 后实际 URL | ⚠️ 中 |
| A4 | type 后输入值可见 | ✅ 高 |
| A4 | navigate 后页面标题 | ✅ 高 |
| A4 | click 后文案变化 | ⚠️ 中 |
| A6 | type 后输入值验证 | ✅ 高 |
| A6 | select 后选中值验证 | ✅ 高 |

### 6.3 pageMapFile 辅助时的置信度提升

当提供 pageMapFile 映射文件时，A1 推断的置信度规则：
- 映射文件中明确指定的选择器 → ✅ 高（用户显式指定）
- 映射文件中未覆盖的 URL → 使用页面结构动态推断（按原优先级表）

---

## 7. pageMapFile 映射文件格式定义

### 7.1 文件格式

pageMapFile 为可选 YAML 文件，提供 URL → 选择器映射，辅助 A1 元素可见推断：

```yaml
# pageMapFile 格式示例
pages:
  - url: /login          # URL 路径（精确匹配或正则模式）
    selectors:           # 该页面的关键可见元素选择器列表
      - .auth-form
      - .login-title
    titleSelector: h1    # 页面标题选择器（可选）
    
  - url: /home
    selectors:
      - .header-user
      - .sidebar-nav
    titleSelector: h1
    
  - url: /products       # 支持正则模式
    selectors:
      - .search-bar
      - .product-list
    titleSelector: .page-title
    
  - url: /dashboard*
    selectors:
      - .dashboard-content
      - .sidebar-menu
    titleSelector: h1
```

### 7.2 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| pages | array | ✅ | 页面映射列表 |
| pages[].url | string | ✅ | URL 路径，支持精确匹配和正则模式（`*` 通配符） |
| pages[].selectors | string[] | ✅ | 该页面的关键可见元素选择器列表 |
| pages[].titleSelector | string | ❌ | 页面标题选择器，用于 A4 内容匹配推断 |

### 7.3 使用方式

```bash
/auto-test-record url=http://localhost:3000 pageMapFile=./page-map.yaml
```

### 7.4 匹配规则

- 精确匹配优先：URL 完全匹配时使用对应映射
- 正则模式次选：`*` 通配符匹配时使用对应映射
- 无匹配时回退：URL 不在映射文件中时，使用页面结构动态推断

---

## 8. 推断结果标注格式

### 8.1 confidence 字段标注规则

每条推断断言必须标注 `confidence` 字段：

```yaml
assertions:
  - type: A1
    target: .auth-form
    expected: visible
    confidence: high        # 必填，推断断言必须标注
    inferredFrom: "navigate后[data-testid]"
    message: 登录表单应可见
```

| 规则 | 说明 |
|------|------|
| 推断断言必填 | AI 推断的断言必须标注 confidence |
| 手写断言不标注 | 用户手动编写的断言不标注 confidence（视为确定性断言） |
| 值域限制 | confidence 仅接受 `high` / `medium` / `low` |

### 8.2 inferredFrom 字段标注规则

每条推断断言必须标注 `inferredFrom` 字段，描述推断来源：

| 推断来源格式 | 说明 | 示例 |
|-------------|------|------|
| `操作后[推断策略]` | 操作触发 + 推断策略 | `"navigate后[data-testid]"` |
| `操作后URL实际跳转` | click 后 URL 变化 | `"click后URL实际跳转"` |
| `操作值验证` | type/select 值验证 | `"type操作值验证"` |
| `页面结构动态推断` | 无映射文件的推断 | `"页面结构动态推断[h1]"` |

---

## 9. 推断引擎执行流程

```
操作序列（来自 Codegen 录制 + 选择器优化）
    │
    ▼
[1] 逐步骤检测触发条件
    │   ├─ navigate → 检测 A1 + A2
    │   ├─ click → 检测 A1 + A2 + A4
    │   ├─ type → 检测 A4 + A6
    │   ├─ select → 检测 A6
    │   ├─ wait → 检测 A1
    │
    ▼
[2] 查找 pageMapFile 映射（如有）
    │   ├─ 有映射 → 使用映射选择器（置信度 high）
    │   ├─ 无映射 → 使用页面结构动态推断优先级
    │
    ▼
[3] 生成推断断言 + 标注 confidence + inferredFrom
    │
    ▼
[4] 生成断言推断摘要表格
    │
    ▼
输出推断断言列表 → Step 5d（步骤优化）
```

---

## 10. 推断摘要展示格式

断言推断完成后，在 Step 6 中按以下格式展示：

```
2️⃣ 断言推断
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| # | 类型 | target                  | expected      | 置信度  | 推断来源              |
|---|------|-------------------------|---------------|---------|----------------------|
| 1 | A1   | .auth-form              | visible       | ✅ 高   | navigate后[data-testid] |
| 2 | A2   | current-url             | /home         | ✅ 高   | navigate操作目标路径    |
| 3 | A4   | .search-bar input       | 手机           | ✅ 高   | type操作输入值验证      |
| 4 | A6   | input[name="username"]  | testuser      | ✅ 高   | type操作值验证          |
| 5 | A1   | body                    | visible       | ❌ 低   | 页面结构动态推断[body]  |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计：推断 5 条断言 | 高置信度 4 条 | 中置信度 0 条 | 低置信度 1 条（建议删除）
💡 建议：删除 #5 低置信度断言（body 可见断言信息量少）
```

---

## 11. 版本记录

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-07-20 | 初始版本：A1/A2/A4/A6 推断规则、置信度评分、pageMapFile 格式、推断标注格式 |
