# Web Auto Tester - 步骤优化引擎规范

**Document Version**: 1.0
**Last Updated**: 2026-07-20
**Toolset ID**: web-auto-tester
**Related Spec**: `auto-test-dsl-spec.md`（Step 定义）

---

## 1. 概述

步骤优化引擎在录制后处理阶段（Step 5d）对录制的操作步骤进行优化，提升用例可读性、减少冗余等待、增强步骤组合的语义表达。

核心原则：
- **语义增强**：通过注释标记增强步骤组合的语义，不改变 DSL Step 结构
- **等待优化**：将固定时间等待替换为智能元素等待，提升执行稳定性
- **冗余去除**：去除不必要的重复等待，精简用例

---

## 2. 表单填写组合并规则

### 2.1 触发条件

- 连续 ≥ 2 个 `type` 操作（相邻步骤，中间无其他操作）
- 连续的 type 操作属于同一表单（基于选择器路径分析）

### 2.2 合并格式

合并不改变 DSL Step 结构，仅添加注释标记 `# [form-fill-group]` 标注连续 type 步骤属于同一表单填写组：

```yaml
# 原始录制步骤（无注释标记）
- action: type
  target: input[name="username"]
  value: testuser
- action: type
  target: input[name="password"]
  value: password123

# 优化后（添加注释标记）
# [form-fill-group] 表单填写组：登录表单
- action: type
  target: input[name="username"]
  value: testuser
- action: type
  target: input[name="password"]
  value: password123
```

### 2.3 注释标记规则

| 规则 | 说明 |
|------|------|
| 标记位置 | 在连续 type 组的第一个步骤上方添加注释行 |
| 标记格式 | `# [form-fill-group] 表单填写组：{表单描述}` |
| 表单描述 | 根据选择器路径推断表单名称（如"登录表单"、"搜索表单"） |
| 不改变结构 | 注释为 YAML 注释，不影响 DSL Step 的 action/target/value 结构 |
| 分组条件 | 相邻 type 步骤间无 click/navigate/wait 等非 type 操作时合并 |

### 2.4 YAML 注释标记示例

```yaml
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
        value: testuser
      - action: type
        target: input[name="password"]
        value: password123
      - action: click
        target: button[type="submit"]
  - name: 搜索商品
    steps:
      # [form-fill-group] 表单填写组：搜索表单
      - action: type
        target: .search-bar input
        value: 手机
      - action: click
        target: .search-bar .search-btn
```

---

## 3. 智能等待替代规则

### 3.1 场景一：固定时间等待 → 元素等待

**适用场景**：Codegen 录制的 `wait timeout:XXXms`（固定时间等待）

**替代规则**：
- `wait timeout:500ms` → `wait target:{selector} timeout:2`（等待元素出现，最长 2 秒）
- selector 取下一个断言步骤的 target，或当前步骤后续需要交互的元素

**示例**：

```yaml
# 原始录制
- action: wait
  timeout: 500
- action: click
  target: .submit-btn

# 优化后
- action: wait
  target: .submit-btn
  timeout: 2
- action: click
  target: .submit-btn
```

### 3.2 场景二：click 提交按钮后补充 wait

**适用场景**：click 提交按钮（type=submit / 语义为提交）后无 wait 步骤

**补充规则**：
- click 提交按钮后自动补充 `wait target:{预期结果元素} timeout:5`
- 预期结果元素根据断言推断引擎的 A1 推断结果确定

**示例**：

```yaml
# 原始录制
- action: click
  target: button[type="submit"]
- action: assert
  assertions:
    - type: A2
      target: current-url
      expected: /dashboard

# 优化后（补充 wait）
- action: click
  target: button[type="submit"]
- action: wait
  target: .dashboard-content
  timeout: 5
- action: assert
  assertions:
    - type: A2
      target: current-url
      expected: /dashboard
```

### 3.3 场景三：navigate 后补充 wait 核心元素

**适用场景**：navigate 操作后无 wait 步骤，直接进行 click/type 操作

**补充规则**：
- navigate 后自动补充 `wait target:{页面核心元素} timeout:3`
- 页面核心元素根据断言推断引擎的 A1 推断结果确定

**示例**：

```yaml
# 原始录制
- action: navigate
  target: /products
- action: type
  target: .search-bar input
  value: 手机

# 优化后（补充 wait）
- action: navigate
  target: /products
- action: wait
  target: .search-bar
  timeout: 3
- action: type
  target: .search-bar input
  value: 手机
```

---

## 4. 冗余等待去除规则

### 4.1 条件一：连续 ≥ 2 个 wait 同一 target

**规则**：连续 ≥ 2 个 `wait` 操作等待同一 target 时，仅保留第一个 wait

**示例**：

```yaml
# 原始录制（冗余等待）
- action: wait
  target: .product-list
  timeout: 3
- action: wait
  target: .product-list
  timeout: 5

# 优化后（仅保留第一个）
- action: wait
  target: .product-list
  timeout: 5
```

**说明**：保留第一个但使用较大的 timeout 值

### 4.2 条件二：wait 后紧跟 assert 同一 target

**规则**：`wait` 某元素后紧接着 `assert` 该同一元素时，去除 wait（assert 本身隐含等待）

**示例**：

```yaml
# 原始录制（冗余等待）
- action: wait
  target: .auth-form
  timeout: 3
- action: assert
  assertions:
    - type: A1
      target: .auth-form
      expected: visible

# 优化后（去除冗余 wait）
- action: assert
  assertions:
    - type: A1
      target: .auth-form
      expected: visible
```

---

## 5. Stage 划分策略

### 5.1 划分规则

按 `navigate` 操作划分 Stage（与当前执行引擎一致）：

| 规则 | 说明 |
|------|------|
| 每个 navigate 操作开始一个新 Stage | navigate 是页面切换的标志 |
| 第一个 Stage 包含首次 navigate 及后续操作 | |
| 最后一个 Stage 包含最终验证操作 | |
| 无 navigate 的连续操作归入同一 Stage | |

### 5.2 Stage 命名推断

| 推断规则 | 示例 |
|----------|------|
| navigate 目标路径推断 | `/login` → "登录页面访问" |
| 操作语义推断 | 连续 type → "输入凭证" |
| 断言语义推断 | A2 URL 跳转 → "登录验证" |
| 默认命名 | "阶段{序号}" |

### 5.3 Stage 划分示例

```yaml
stages:
  - name: 登录页面访问       # Stage 1：navigate /login
    steps:
      - action: navigate
        target: /login
      - action: wait
        target: .auth-form
        timeout: 3
  - name: 输入凭证           # Stage 2：表单操作（同页面）
    steps:
      # [form-fill-group] 表单填写组：登录表单
      - action: type
        target: input[name="username"]
        value: testuser
      - action: type
        target: input[name="password"]
        value: password123
      - action: click
        target: button[type="submit"]
  - name: 登录验证           # Stage 3：navigate /home（URL跳转）
    steps:
      - action: wait
        target: .header-user
        timeout: 5
      - action: assert
        assertions:
          - type: A2
            target: current-url
            expected: /home
```

---

## 6. 步骤优化摘要展示格式

步骤优化完成后，在 Step 6 中按以下格式展示：

```
3️⃣ 步骤优化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| # | 优化类型             | 数量 | 说明                          |
|---|---------------------|------|-------------------------------|
| 1 | 表单填写组合并        | 2组  | 登录表单、搜索表单              |
| 2 | 智能等待替代          | 3处  | 1处固定→元素, 2处补充wait       |
| 3 | 冗余等待去除          | 1处  | 重复wait同一target             |
| 4 | Stage 划分           | 3个  | 登录页面访问→输入凭证→登录验证   |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计：原始步骤 12 → 优化后步骤 10 | 减少 2 步 | 增强注释 2 处
```

---

## 7. 优化引擎执行流程

```
操作序列（来自 Codegen 录制 + 选择器优化 + 断言推断）
    │
    ▼
[1] 表单填写组合并检测
    │   ├─ 识别连续 ≥2 个 type 操作
    │   ├─ 添加 # [form-fill-group] 注释标记
    │
    ▼
[2] 智能等待替代检测
    │   ├─ 固定时间等待 → 元素等待
    │   ├─ click 提交按钮后补充 wait
    │   ├─ navigate 后补充 wait 核心元素
    │
    ▼
[3] 冗余等待去除检测
    │   ├─ 连续 ≥2 个 wait 同一 target → 仅保留首个
    │   ├─ wait 后紧跟 assert 同一 target → 去除 wait
    │
    ▼
[4] Stage 划分
    │   ├─ 按 navigate 划分 Stage
    │   ├─ 推断 Stage 名称
    │
    ▼
[5] 生成步骤优化摘要表格
    │
    ▼
输出优化后步骤序列 → Step 5e（数据参数化）
```

---

## 8. 版本记录

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-07-20 | 初始版本：表单填写组合并、智能等待替代、冗余等待去除、Stage 划分策略 |
