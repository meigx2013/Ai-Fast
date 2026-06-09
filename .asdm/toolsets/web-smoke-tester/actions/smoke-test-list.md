# ASDM Action: Smoke Test List

## Metadata

```json
{
  "guid": "f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b02",
  "name": "smoke-test-list",
  "displayName": "列出测试记录",
  "description": "列出所有已执行的冒烟测试场景记录，支持按状态筛选",
  "toolset": {
    "guid": "e7f8a9b0-c1d2-3e4f-5a6b-7c8d9e0f1a02",
    "id": "web-smoke-tester",
    "name": "Web Smoke Tester",
    "version": "1.0.0"
  },
  "scenario": "smoke-test-query"
}
```

## Process

本 action 列出 `.smoke-tester/records/` 中所有已执行的冒烟测试场景记录，以表格形式展示。支持按状态筛选。

### Purpose

- 快速查看所有冒烟测试执行记录
- 按状态筛选（pass / fail / error / skip / all）
- 了解当前测试覆盖和通过情况

### Steps

1. **读取记录目录**：扫描 `.smoke-tester/records/` 下所有 JSON 文件
2. **解析记录**：读取每条 `SmokeTestRecord`
3. **筛选（可选）**：若用户指定状态参数，按该状态过滤
4. **排序**：按执行时间正序排列
5. **输出**：以 Markdown 表格形式输出

### Input

- 无参数：列出所有记录
- `pass`：仅显示通过的记录
- `fail`：仅显示失败的记录
- `error`：仅显示异常的记录
- `skip`：仅显示跳过的记录
- `all`：显示所有记录（等同无参数）

### Usage

```
/smoke-test-list
/smoke-test-list fail
/smoke-test-list all
```

### Output

#### 有记录时

```markdown
## 📋 冒烟测试记录列表

> 共 {total} 条记录 | ✅ {passed} 通过 | ❌ {failed} 失败 | ⚠️ {error} 异常 | ⏭️ {skipped} 跳过

| # | 场景名称 | 状态 | 步骤通过 | 耗时 | 执行时间 | 失败原因 |
|:-:|---------|:----:|:-------:|:----:|---------|---------|
| 1 | {name} | {status_emoji} | {passed}/{total} | {duration}s | {startTime} | {errorMessage} |
| 2 | {name} | {status_emoji} | {passed}/{total} | {duration}s | {startTime} | - |
```

#### 无记录时

```markdown
## 📋 冒烟测试记录列表

> 暂无测试记录。使用 `/smoke-test-run` 执行冒烟测试。
```

#### 结构化输出

```json
{
  "phase": "smoke-test-list",
  "status": "success",
  "filter": "all|pass|fail|error|skip",
  "total_records": 5,
  "filtered_records": 3,
  "records": [
    {
      "id": "STR-20260609-001",
      "scenarioName": "用户登录",
      "status": "pass",
      "passedSteps": 5,
      "totalSteps": 5,
      "duration": 8,
      "startTime": "2026-06-09T10:30:00+08:00"
    }
  ],
  "timestamp": "ISO 8601 datetime"
}
```

## Configuration

Refer to:
- [smoke-test-shared-spec.md](../spec/smoke-test-shared-spec.md) — 数据模型、状态标识、输出格式
- [smoke-test-report-spec.md](../spec/smoke-test-report-spec.md) — 列表输出格式、筛选规则
