# ASDM Action: Smoke Test Clear

## Metadata

```json
{
  "guid": "f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b04",
  "name": "smoke-test-clear",
  "displayName": "清空测试记录",
  "description": "清空所有冒烟测试记录，删除 .smoke-tester/records/ 下所有 JSON 文件",
  "toolset": {
    "guid": "e7f8a9b0-c1d2-3e4f-5a6b-7c8d9e0f1a02",
    "id": "web-smoke-tester",
    "name": "Web Smoke Tester",
    "version": "1.0.0"
  },
  "scenario": "smoke-test-management"
}
```

## Process

本 action 清空所有冒烟测试记录。删除 `.smoke-tester/records/` 目录下所有 JSON 文件，以及 `latest-report.json` 报告文件。通常在开始新一轮测试前使用。

### Purpose

- 清空历史测试记录，准备新一轮测试
- 释放存储空间
- 确保测试记录从零开始计数

### Steps

1. **确认操作**：向用户确认是否清空所有记录（此操作不可逆）
2. **删除记录文件**：删除 `.smoke-tester/records/` 下所有 `.json` 文件
3. **删除报告文件**：删除 `.smoke-tester/latest-report.json`（如存在）
4. **保留目录**：保留 `.smoke-tester/records/` 目录结构
5. **输出确认**：显示已清空的记录数量

### Input

无需参数。

### Usage

```
/smoke-test-clear
```

### Output

#### 成功清空

```markdown
🗑️ 已清空所有冒烟测试记录。

- 删除测试记录：{count} 条
- 删除报告文件：latest-report.json
- 记录序号将从 STR-{date}-001 重新开始
```

#### 无记录可清空

```markdown
🗑️ 无测试记录需要清空。
```

#### 结构化输出

```json
{
  "phase": "smoke-test-clear",
  "status": "success",
  "records_deleted": 5,
  "report_deleted": true,
  "timestamp": "ISO 8601 datetime"
}
```

## Configuration

Refer to:
- [smoke-test-shared-spec.md](../spec/smoke-test-shared-spec.md) — 存储机制、目录结构
