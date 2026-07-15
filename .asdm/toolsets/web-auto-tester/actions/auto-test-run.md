# ASDM Action: Auto Test Run

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
  "name": "auto-test-run",
  "displayName": "执行自动化测试",
  "description": "执行 YAML DSL 测试用例，支持 Playwright/Selenium 双框架，7 阶段执行流程（加载→上下文→执行→断言→截图→记录→输出），自动生成结果 JSON 和失败截图",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.1"
  },
  "scenario": "auto-test-execution"
}
```

## Purpose

本 action 是 Web Auto Tester 的核心命令。用户指定 YAML DSL 用例文件或用例目录，AI 按照 7 阶段执行规范自动加载用例、准备上下文、选择引擎、逐步执行、断言判定、截图采集、记录结果，并以表格形式输出测试摘要。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有生成的文件、注释和文档均使用中文。

## Context Injection

在执行测试前，AI Agent **必须**读取并理解以下规范文件：

### Required Context Files

1. **YAML DSL 规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
   - Purpose: 了解用例格式定义、Schema 校验规则、操作类型映射、断言类型

2. **执行引擎规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
   - Purpose: 了解 7 阶段执行流程、操作映射、断言判定、截图策略、结果记录规则

3. **目标用例文件** (Required)
   - Path: 用户指定或 `.asdm/workspace/auto-test/cases/*.yaml`
   - Purpose: 加载并执行测试用例

## Steps

### Step 1: 用例加载（Phase 1）

1. 根据用户输入参数 `case` 定位用例文件：
   - 指定文件路径 → 直接加载该 YAML 文件
   - 指定目录路径 → 加载目录下所有 `.yaml` 文件
   - 未指定 → 加载 `.asdm/workspace/auto-test/cases/` 下所有 `.yaml` 文件
2. 解析 YAML 内容为结构化对象
3. 执行 Schema 校验（参照 `auto-test-dsl-spec.md` §10 校验规则）：
   - `name` 非空 ✅
   - `stages` 数组长度 ≥ 1 ✅
   - 每个 Stage: `name` 非空 + `steps` ≥ 1 ✅
   - 每个 Step: `action` 必填 + `target` 必填 ✅
   - type/select 操作: `value` 必填 ✅
   - assert 操作: `assertions` ≥ 1 ✅
4. 校验失败 → 报错并终止，提示用户修正用例

### Step 2: 上下文准备（Phase 2）

1. 读取用例 `metadata` 字段，初始化执行上下文：
   - `targetUrl` → 测试目标 URL（默认 `http://localhost:3000`）
   - `timeout` → 全局超时秒数（默认 30）
   - `browser` → 浏览器类型（默认 chromium）
   - `viewport` → 视口尺寸（默认 1280×720）
2. 确定执行框架：
   - 读取 `framework` 字段（默认 playwright）
   - 若 selenium → 检查 A5/A8 断言 → 降级判断
3. 处理认证配置（如有 `metadata.auth`）

### Step 3: 执行引擎（Phase 3）

1. 根据 framework 选择引擎适配（参照 `auto-test-execution-spec.md` §3 操作映射表）
2. 逐阶段逐步骤执行：
   - Playwright: 按 API 映射执行操作
   - Selenium: 按 API 映码执行操作（css= 前缀选择器处理）
3. 每步执行后收集结果：
   - `actual`：实际观察到的结果
   - `duration`：步骤耗时估算
   - 异常捕获并记录

### Step 4: 断言判定（Phase 4）

1. 对 `action: assert` 步骤执行断言判定（参照 `auto-test-execution-spec.md` §4）
2. 8 种断言类型（A1~A8）按类型映射执行
3. 结果映射：完全匹配→pass，不匹配→fail，异常→error，前置失败→skip
4. 记录断言详情（target/expected/actual/message）

### Step 5: 截图采集（Phase 5）

1. 根据 capture 策略采集截图（参照 `auto-test-execution-spec.md` §5）：
   - `on-fail` → 仅失败步骤截图
   - `full` → 全步骤截图
   - `always` → 标记步骤强制截图
2. 截图命名规则：`ATR-{resultId}-S{stepIndex}-{strategy}.png`
3. 保存到 `.asdm/workspace/auto-test/screenshots/`

### Step 6: 结果记录（Phase 6）

1. 生成 `AutoTestResult` JSON（参照 `auto-test-execution-spec.md` §6）
2. 生成结果 ID：`ATR-{YYYYMMDD}-{NNN}`
3. 计算整体状态：pass/fail/error/skip
4. 持久化到 `.asdm/workspace/auto-test/results/ATR-{YYYYMMDD}-{NNN}.json`

### Step 7: 报告输出（Phase 7）

1. 输出简要摘要表格（P4 阶段实现完整 HTML 报告）
2. 输出结构化结果摘要 JSON

## Execution Guidelines

### 快速失败策略

- 某步骤 fail/error → 后续步骤标记为 skip
- Stage 间不中断（即使某 Stage 失败，下个 Stage 继续执行）

### 超时控制

- 每个步骤使用 `timeout` 字段或全局超时
- 超时 → 步骤标记为 error

### 框架降级

- Selenium 用例含 A5/A8 → 降级为 Playwright 并提示
- 降级提示：`"⚠️ 框架降级提示：用例 {name} 指定 selenium 框架，但包含 Playwright 专有特性（A5/A8），已自动降级为 Playwright 执行引擎"`

### 环境检测

- 执行前检测目标系统是否可访问
- 不可访问 → 用例标记为 error，提示用户

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| case | string | ✅ | 用例文件路径、目录路径，或留空使用默认 cases/ 目录 |
| framework | string | ❌ | 框架偏好，覆盖用例设置（playwright/selenium） |
| capture | string | ❌ | 截图策略，覆盖用例设置（on-fail/full） |

### 命令示例

```
/auto-test-run case=user-login-test.yaml
/auto-test-run case=.asdm/workspace/auto-test/cases/
/auto-test-run
/auto-test-run case=admin-login-test.yaml framework=playwright capture=full
```

## Output

### 简要摘要输出

```markdown
### 🧪 自动化测试结果：{testCaseName}

| 步骤 | 操作 | 目标 | 预期结果 | 实际结果 | 状态 |
|:----:|------|------|---------|---------|:----:|
| 1 | navigate | /login | 登录页面正常加载 | 登录页面正常加载 | ✅ |
| 2 | assert | .auth-form | visible | visible | ✅ |
| ... | ... | ... | ... | ... | ... |

**用例状态**：✅ 通过 | **步骤**：7/7 通过 | **耗时**：8.5s
**执行框架**：playwright | **结果文件**：ATR-20260714-001.json
```

### 结构化输出

```json
{
  "phase": "auto-test-run",
  "status": "success",
  "result_id": "ATR-20260714-001",
  "test_case_name": "user-login-test",
  "test_case_status": "pass",
  "total_steps": 7,
  "passed_steps": 7,
  "failed_steps": 0,
  "duration_ms": 8500,
  "framework": "playwright",
  "result_path": ".asdm/workspace/auto-test/results/ATR-20260714-001.json",
  "timestamp": "ISO 8601 datetime"
}
```

## Configuration

Refer to:
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — YAML DSL 用例格式定义、Schema 校验、操作映射
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 7 阶段执行规范、断言判定、截图策略、结果记录
