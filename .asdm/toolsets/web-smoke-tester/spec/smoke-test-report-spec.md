# Web Smoke Tester 报告规范

**Document Version**: 1.0
**Last Updated**: 2026-06-09

## Overview

本文档定义冒烟测试结果报告的输出格式和汇总统计规则。包括单场景即时输出、多场景列表输出和完整测试报告格式。

## 报告类型

### 1. 单场景即时结果

执行 `/smoke-test-run` 后立即输出，格式如下：

```markdown
### 🧪 冒烟测试结果：{scenarioName}

| 步骤 | 操作 | 目标 | 预期结果 | 实际结果 | 状态 |
|:----:|------|------|---------|---------|:----:|
| 1 | {action} | {target} | {expected} | {actual} | {status} |
| 2 | {action} | {target} | {expected} | {actual} | {status} |

**场景状态**：{status_emoji} {status_text} | **步骤**：{passedSteps}/{totalSteps} 通过 | **耗时**：{duration}s
{失败原因行（仅 fail/error 时显示）}
```

### 2. 场景列表输出

执行 `/smoke-test-list` 时输出，格式如下：

```markdown
## 📋 冒烟测试记录列表

> 共 {total} 条记录 | ✅ {passed} 通过 | ❌ {failed} 失败 | ⚠️ {error} 异常 | ⏭️ {skipped} 跳过

| # | 场景名称 | 状态 | 步骤通过 | 耗时 | 执行时间 | 失败原因 |
|:-:|---------|:----:|:-------:|:----:|---------|---------|
| 1 | {name} | {status} | {passed}/{total} | {duration}s | {startTime} | {errorMessage} |
```

### 3. 完整测试报告

执行 `/smoke-test-report` 时输出，格式如下：

```markdown
# 🧪 {title}

> **生成时间**：{generatedAt}
> **场景总数**：{totalScenarios} | **通过**：{passedScenarios} | **失败**：{failedScenarios} | **异常**：{errorScenarios}
> **通过率**：{passRate} | **总耗时**：{totalDuration}s

---

## 汇总统计

| 指标 | 数值 |
|------|------|
| 场景总数 | {totalScenarios} |
| ✅ 通过 | {passedScenarios} |
| ❌ 失败 | {failedScenarios} |
| ⚠️ 异常 | {errorScenarios} |
| ⏭️ 跳过 | {skippedScenarios} |
| 通过率 | {passRate} |
| 总耗时 | {totalDuration}s |

---

## 场景结果明细

### 场景 1：{scenarioName} — {status_emoji}

| 步骤 | 操作 | 目标 | 预期结果 | 实际结果 | 状态 |
|:----:|------|------|---------|---------|:----:|
| 1 | {action} | {target} | {expected} | {actual} | {status} |

> 耗时：{duration}s | 执行时间：{startTime}

---

### 场景 2：{scenarioName} — {status_emoji}

（同上格式）

---

## 失败场景分析

> 仅列出失败和异常的场景

### ❌ {scenarioName}

**失败原因**：{errorMessage}

**失败步骤详情**：

| 步骤 | 操作 | 预期结果 | 实际结果 | 失败原因 |
|:----:|------|---------|---------|---------|
| {stepIndex} | {action} | {expected} | {actual} | {errorMessage} |

---

## 测试结论

{AI 根据测试结果自动生成结论，包括：}
- 核心功能可用性评估
- 主要风险点
- 建议的后续测试方向
```

## 统计规则

### 通过率计算

```
passRate = (passedScenarios / totalScenarios) × 100%
```

- 四舍五入保留一位小数
- 示例：7 通过 / 8 总计 = 87.5%

### 状态统计

| 统计项 | 计算规则 |
|-------|---------|
| totalScenarios | 所有记录数 |
| passedScenarios | status = 'pass' 的记录数 |
| failedScenarios | status = 'fail' 的记录数 |
| errorScenarios | status = 'error' 的记录数 |
| skippedScenarios | status = 'skip' 的记录数 |

### 耗时统计

| 统计项 | 计算规则 |
|-------|---------|
| totalDuration | 所有记录的 duration 之和 |
| 单场景 duration | endTime - startTime |

## 筛选规则

### `/smoke-test-list` 筛选

| 参数 | 筛选行为 |
|------|---------|
| 无参数 | 显示所有记录 |
| `pass` | 仅显示 status = 'pass' 的记录 |
| `fail` | 仅显示 status = 'fail' 的记录 |
| `error` | 仅显示 status = 'error' 的记录 |
| `skip` | 仅显示 status = 'skip' 的记录 |
| `all` | 显示所有记录（等同无参数） |

## 报告文件

执行 `/smoke-test-report` 时，除了在聊天中输出报告，还在 `.smoke-tester/` 目录下生成报告文件：

- `latest-report.json`：最新报告的结构化数据（SmokeTestReport 格式）
- `report-{YYYYMMDD-HHmmss}.md`：带时间戳的 Markdown 报告文件

## 空结果处理

当没有测试记录时：

### 列表输出

```markdown
## 📋 冒烟测试记录列表

> 暂无测试记录。使用 `/smoke-test-run` 执行冒烟测试。
```

### 报告输出

```markdown
# 🧪 冒烟测试报告

> 暂无测试记录，无法生成报告。请先使用 `/smoke-test-run` 执行冒烟测试。
```
