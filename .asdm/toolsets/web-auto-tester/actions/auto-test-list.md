# ASDM Action: Auto Test List

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456790",
  "name": "auto-test-list",
  "displayName": "列出测试用例与结果",
  "description": "列出 cases/ 目录下所有 YAML 用例或 results/ 目录下所有执行结果，支持三种展示模式和筛选过滤",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.1"
  },
  "scenario": "auto-test-query"
}
```

## Purpose

本 action 列出测试用例和执行结果，以 Markdown 表格形式展示。支持三种展示模式（cases/results/all），支持按标签、框架、状态等条件筛选过滤。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。

## Context Injection

### Required Context Files

1. **YAML DSL 规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
   - Purpose: 了解用例格式定义，用于解析 YAML 用例文件

2. **执行引擎规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
   - Purpose: 了解结果数据模型 AutoTestResult，用于解析结果 JSON 文件

## Steps

### Step 1: 确定展示模式

根据用户输入参数 `type` 确定展示模式：
- `type=cases` → 列出 cases/ 目录下所有 YAML 用例
- `type=results` → 列出 results/ 目录下所有执行结果
- `type=all` → 合并展示（默认）

### Step 2: 读取目录

1. **cases 模式**：扫描 `.asdm/workspace/auto-test/cases/` 下所有 `.yaml` 文件
2. **results 模式**：扫描 `.asdm/workspace/auto-test/results/` 下所有 `ATR-*.json` 文件
3. **all 模式**：同时扫描两个目录

### Step 3: 解析文件

1. **YAML 用例解析**：读取每个 `.yaml` 文件，提取以下信息：
   - name（用例名称）
   - framework（框架偏好）
   - tags（标签列表）
   - source（用例来源：generate/record/manual）
   - metadata.targetUrl（目标 URL）
   - stages 步骤总数
   - 文件创建时间（文件元数据或 YAML 内容无此字段时使用文件修改时间）

2. **JSON 结果解析**：读取每个 `ATR-*.json` 文件，提取以下信息：
   - id（结果 ID）
   - testCaseName（用例名称）
   - status（整体状态：pass/fail/error/skip）
   - totalSteps / passedSteps / failedSteps
   - duration（执行耗时）
   - startTime（执行时间）
   - framework（实际执行框架）

### Step 4: 篮选过滤

根据用户 `filter` 参数过滤：

| 过滤参数 | 适用模式 | 过滤规则 | 示例 |
|----------|----------|----------|------|
| tag=XXX | cases | 用例 tags 包含指定标签 | `tag=auth` |
| framework=XXX | cases/results | framework 字段匹配 | `framework=selenium` |
| status=XXX | results | status 字段匹配（pass/fail/error/skip） | `status=fail` |
| name=XXX | cases/results | name/testCaseName 包含关键词 | `name=login` |

多个过滤条件可组合使用（AND 逻辑）。

### Step 5: 排序

- **cases**：按文件名字母序排列
- **results**：按 startTime 时间倒序排列（最新结果优先）
- **all**：先显示 cases 表格，再显示 results 表格

### Step 6: 格式化输出

以 Markdown 表格形式输出结果。

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| type | string | ❌ | 列出类型：cases/results/all，默认 all |
| filter | string | ❌ | 筛选条件（tag/framework/status/name） |

### 命令示例

```
/auto-test-list
/auto-test-list type=cases
/auto-test-list type=results
/auto-test-list type=results filter=status=fail
/auto-test-list type=cases filter=tag=auth
/auto-test-list type=cases filter=framework=selenium
/auto-test-list type=all filter=name=login
```

## Output

### Cases 列表输出

```markdown
## 📋 测试用例列表

> 共 {total} 个用例 | Playwright: {pw_count} | Selenium: {sel_count}

| # | 用例名称 | 框架 | 标签 | 来源 | 步骤数 | 目标 URL | 创建时间 |
|:-:|---------|:----:|------|:----:|:------:|---------|---------|
| 1 | user-login-test | playwright | auth, user, P1 | manual | 7 | http://localhost:3000 | 2026-07-14 |
| 2 | admin-login-selenium | selenium | auth, admin | manual | 5 | http://localhost:3001 | 2026-07-14 |
```

### Results 列表输出

```markdown
## 📋 执行结果列表

> 共 {total} 条结果 | ✅ {passed} 通过 | ❌ {failed} 失败 | ⚠️ {error} 异常 | ⏭️ {skipped} 跳过

| # | 结果 ID | 用例名称 | 状态 | 步骤通过 | 耗时 | 执行框架 | 执行时间 | 失败原因 |
|:-:|---------|---------|:----:|:-------:|:----:|:-------:|---------|---------|
| 1 | ATR-20260714-001 | user-login-test | ✅ pass | 7/7 | 8.5s | playwright | 2026-07-14 10:30 | - |
| 2 | ATR-20260714-002 | admin-login-selenium | ❌ fail | 3/5 | 5.2s | selenium | 2026-07-14 10:35 | Step 4 断言失败 |
```

### 无数据时

```markdown
## 📋 测试用例列表

> 暂无测试用例。使用手动编写 YAML 或 `/auto-test-generate` / `/auto-test-record` 创建用例。

## 📋 执行结果列表

> 暂无执行结果。使用 `/auto-test-run` 执行测试用例。
```

### 结构化输出

```json
{
  "phase": "auto-test-list",
  "status": "success",
  "type": "cases|results|all",
  "filter": {
    "tag": null,
    "framework": null,
    "status": null,
    "name": null
  },
  "cases_total": 2,
  "results_total": 2,
  "cases": [
    {
      "name": "user-login-test",
      "framework": "playwright",
      "tags": ["auth", "user", "P1"],
      "source": "manual",
      "totalSteps": 7,
      "targetUrl": "http://localhost:3000"
    }
  ],
  "results": [
    {
      "id": "ATR-20260714-001",
      "testCaseName": "user-login-test",
      "status": "pass",
      "passedSteps": 7,
      "totalSteps": 7,
      "duration": 8500,
      "framework": "playwright",
      "startTime": "2026-07-14T10:30:00+08:00"
    }
  ],
  "timestamp": "ISO 8601 datetime"
}
```

## Configuration

Refer to:
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — YAML DSL 用例格式定义、数据模型 AutoTestCase
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 执行结果数据模型 AutoTestResult、ID 生成规则
