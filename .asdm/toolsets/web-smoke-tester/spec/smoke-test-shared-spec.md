# Web Smoke Tester 共享规范

**Document Version**: 1.0
**Last Updated**: 2026-06-09

## Overview

本文档定义 Web Smoke Tester 工具集的共享规范，包括数据模型、存储机制和输出格式等基础约定。所有 action 和 spec 均依赖本规范。

## 数据模型

### 测试场景记录 (SmokeTestRecord)

每执行一个冒烟测试场景，生成一条 `SmokeTestRecord` 记录：

```typescript
interface SmokeTestRecord {
  id: string;                    // 唯一标识，格式：STR-{YYYYMMDD}-{NNN}，如 STR-20260609-001
  scenarioName: string;          // 场景名称，从用户输入中提取的核心业务名称
  scenarioDescription: string;   // 场景描述，用户的原始输入文本
  steps: SmokeTestStep[];        // 测试步骤列表
  status: 'pass' | 'fail' | 'error' | 'skip';  // 场景整体状态
  totalSteps: number;            // 总步骤数
  passedSteps: number;           // 通过步骤数
  failedSteps: number;           // 失败步骤数
  duration: number;              // 执行耗时（秒）
  startTime: string;             // ISO 8601 开始时间
  endTime: string;               // ISO 8601 结束时间
  errorMessage?: string;         // 失败原因（仅 fail/error 时）
  tags?: string[];               // 标签（如模块名、优先级等）
}
```

### 测试步骤 (SmokeTestStep)

```typescript
interface SmokeTestStep {
  stepIndex: number;             // 步骤序号，从 1 开始
  action: string;                // 操作描述（如"打开登录页面"）
  target: string;                // 操作目标（如 URL、按钮名称、输入框名称）
  inputValue?: string;           // 输入值（如用户名、密码）
  expected: string;              // 预期结果
  actual?: string;               // 实际结果
  status: 'pass' | 'fail' | 'skip' | 'pending';  // 步骤状态
  duration: number;              // 步骤耗时（秒）
  errorMessage?: string;         // 失败原因
}
```

### 测试报告 (SmokeTestReport)

```typescript
interface SmokeTestReport {
  title: string;                 // 报告标题
  generatedAt: string;           // ISO 8601 生成时间
  totalScenarios: number;        // 总场景数
  passedScenarios: number;       // 通过场景数
  failedScenarios: number;       // 失败场景数
  errorScenarios: number;        // 错误场景数
  skippedScenarios: number;      // 跳过场景数
  passRate: string;              // 通过率，格式 "85.7%"
  totalDuration: number;         // 总耗时（秒）
  records: SmokeTestRecord[];    // 所有测试记录
}
```

## 存储机制

### 存储位置

测试记录存储在 workspace 根目录下的文件中：

```
.smoke-tester/
├── records/
│   ├── STR-20260609-001.json    ## 单条测试记录
│   ├── STR-20260609-002.json
│   └── ...
└── latest-report.json           ## 最近一次汇总报告
```

### 存储规则

1. **每条记录一个文件**：每执行一个场景，生成一个 JSON 文件
2. **文件命名**：`{record.id}.json`，如 `STR-20260609-001.json`
3. **原子写入**：先写临时文件，再 rename，避免写一半损坏
4. **日期隔离**：ID 中的日期使用当天日期，序号当天自增
5. **清空操作**：`smoke-test-clear` 删除 `records/` 下所有 JSON 文件

### ID 生成规则

- 格式：`STR-{YYYYMMDD}-{NNN}`
- 日期部分：使用执行当天的日期
- 序号部分：当天的已有记录数 + 1，三位数字补零
- 示例：当天已有 5 条记录，下一条为 `STR-20260609-006`

## 输出格式

### 单场景执行结果（即时输出）

每次执行 `/smoke-test-run` 后，立即以 Markdown 格式输出该场景的测试结果：

```markdown
### 🧪 冒烟测试结果：{scenarioName}

| 步骤 | 操作 | 目标 | 预期结果 | 实际结果 | 状态 |
|:----:|------|------|---------|---------|:----:|
| 1 | 打开页面 | /login | 显示登录表单 | 登录表单正常显示 | ✅ |
| 2 | 输入用户名 | 用户名输入框 | 可输入文本 | 输入 admin 成功 | ✅ |
| 3 | 点击登录 | 登录按钮 | 跳转首页 | 页面未跳转 | ❌ |

**场景状态**：❌ 失败 | **步骤**：2/3 通过 | **耗时**：12.5s
**失败原因**：步骤3 - 登录按钮点击后页面未跳转，可能存在前端路由异常
```

### 场景记录汇总表格

执行 `/smoke-test-list` 或 `/smoke-test-report` 时，以表格形式汇总：

```markdown
| # | 场景名称 | 状态 | 步骤通过 | 耗时 | 时间 | 失败原因 |
|:-:|---------|:----:|:-------:|:----:|------|---------|
| 1 | 用户登录 | ✅ 通过 | 5/5 | 8.2s | 2026-06-09 10:30 | - |
| 2 | 商品搜索 | ❌ 失败 | 3/4 | 15.1s | 2026-06-09 10:32 | 步骤4-搜索结果未返回 |
| 3 | 购物车添加 | ✅ 通过 | 3/3 | 6.7s | 2026-06-09 10:35 | - |
```

### 状态标识

| 状态 | 标识 | 说明 |
|------|:----:|------|
| pass | ✅ | 所有步骤均通过 |
| fail | ❌ | 一个或多个步骤断言失败 |
| error | ⚠️ | 执行过程出现异常（网络错误、页面崩溃等） |
| skip | ⏭️ | 场景被跳过（前置条件不满足等） |

## 自然语言步骤解析规则

用户在斜杠命令后以自然语言描述测试步骤，AI 需将其解析为结构化的 `SmokeTestStep[]`：

### 输入格式

支持以下格式（可混用）：

1. **箭头分隔**：`打开首页→登录→搜索商品→加入购物车`
2. **序号分隔**：`1.打开首页 2.登录 3.搜索商品 4.加入购物车`
3. **自然段落**：`首先打开首页，然后登录系统，接着搜索商品，最后加入购物车`
4. **详细步骤**：`打开 /login 页面，输入用户名 admin 和密码 123456，点击登录按钮，验证跳转到首页`

### 解析原则

1. 每个动作拆解为一个步骤
2. 自动推断预期结果（如"点击登录按钮"的预期是"成功跳转"或"显示登录成功提示"）
3. 对于带参数的操作（如输入用户名），自动提取参数值
4. 对于导航操作（如"打开首页"），自动提取目标 URL 或页面名称
5. 步骤间的因果关系：前一步的输出是后一步的输入

### 解析示例

**输入**：`打开 /login 页面，输入用户名 admin 和密码 123456，点击登录按钮，验证跳转到首页`

**解析结果**：

```json
[
  { "stepIndex": 1, "action": "打开页面", "target": "/login", "expected": "登录页面正常加载" },
  { "stepIndex": 2, "action": "输入文本", "target": "用户名输入框", "inputValue": "admin", "expected": "输入框显示 admin" },
  { "stepIndex": 3, "action": "输入文本", "target": "密码输入框", "inputValue": "123456", "expected": "密码框显示掩码" },
  { "stepIndex": 4, "action": "点击按钮", "target": "登录按钮", "expected": "页面跳转到首页" },
  { "stepIndex": 5, "action": "验证页面", "target": "首页", "expected": "首页内容正常展示" }
]
```

## 术语表

| 术语 | 说明 |
|------|------|
| 冒烟测试 | 验证系统核心功能是否可用的快速测试，不覆盖边界和异常 |
| 场景 (Scenario) | 一个完整的业务操作链路，如"用户登录" |
| 步骤 (Step) | 场景中的单个操作，如"输入用户名" |
| 断言 (Assertion) | 对操作结果的验证，如"页面跳转成功" |
| Pipeline | 从自然语言到测试执行的完整流水线 |
