# ASDM Action: Smoke Test Report

## Metadata

```json
{
  "guid": "f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b03",
  "name": "smoke-test-report",
  "displayName": "生成测试报告",
  "description": "基于所有已执行的冒烟测试记录，生成包含汇总统计和场景明细的完整测试报告",
  "toolset": {
    "guid": "e7f8a9b0-c1d2-3e4f-5a6b-7c8d9e0f1a02",
    "id": "web-smoke-tester",
    "name": "Web Smoke Tester",
    "version": "1.0.0"
  },
  "scenario": "smoke-test-report"
}
```

## Process

本 action 读取所有冒烟测试记录，生成完整的测试报告，包含汇总统计、场景结果明细、失败分析和测试结论。同时将报告持久化为文件。

### Purpose

- 生成结构化的冒烟测试汇总报告
- 提供通过率、耗时等关键统计指标
- 聚焦失败场景，辅助问题定位
- AI 自动生成测试结论和风险建议

### Steps

1. **读取所有记录**：扫描 `.smoke-tester/records/` 下所有 JSON 文件
2. **计算统计**：汇总通过/失败/异常/跳过数量，计算通过率和总耗时
3. **生成报告**：按报告规范格式化输出
4. **分析失败**：提取失败场景的根因和详细信息
5. **生成结论**：AI 根据测试结果生成测试结论和建议
6. **持久化报告**：写入 `.smoke-tester/latest-report.json` 和 `report-{timestamp}.md`

### Input

- 可选：报告标题（默认为"冒烟测试报告"）

### Usage

```
/smoke-test-report
/smoke-test-report 用户模块冒烟测试报告
```

### Output

#### 完整报告格式

遵循 [smoke-test-report-spec.md](../spec/smoke-test-report-spec.md) 中的完整测试报告格式，包括：

1. **报告头部**：标题、生成时间、汇总统计、通过率
2. **汇总统计表**：各指标数值一览
3. **场景结果明细**：每个场景的详细步骤表格
4. **失败场景分析**：失败和异常场景的根因分析
5. **测试结论**：AI 生成的整体评估和后续建议

#### 结构化输出

```json
{
  "phase": "smoke-test-report",
  "status": "success",
  "title": "冒烟测试报告",
  "total_scenarios": 8,
  "passed_scenarios": 6,
  "failed_scenarios": 1,
  "error_scenarios": 1,
  "skipped_scenarios": 0,
  "pass_rate": "75.0%",
  "total_duration": 68,
  "report_files": [
    ".smoke-tester/latest-report.json",
    ".smoke-tester/report-20260609-103500.md"
  ],
  "timestamp": "ISO 8601 datetime"
}
```

#### 无记录时

```markdown
# 🧪 冒烟测试报告

> 暂无测试记录，无法生成报告。请先使用 `/smoke-test-run` 执行冒烟测试。
```

## Configuration

Refer to:
- [smoke-test-shared-spec.md](../spec/smoke-test-shared-spec.md) — 数据模型、状态标识
- [smoke-test-report-spec.md](../spec/smoke-test-report-spec.md) — 完整报告格式、统计规则、报告文件规范
