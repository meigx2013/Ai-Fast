# ASDM Action: Auto Test Clean

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456795",
  "name": "auto-test-clean",
  "displayName": "清理测试资源",
  "description": "清理测试工作区中的过期资源（results/reports/screenshots/all），清理前列出文件数量和大小，用户确认后执行删除，保留目录结构和 .gitkeep",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.2"
  },
  "scenario": "auto-test-cleanup"
}
```

## Purpose

本 action 是 Web Auto Tester 的清理命令。用户指定清理范围（results/reports/screenshots/all），AI 列出将要删除的文件数量和大小，用户确认后执行删除，保留目录结构（子目录本身和 .gitkeep 文件不被删除），输出清理确认信息。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有清理提示、确认信息和摘要均使用中文。

## Context Injection

在执行清理前，AI Agent **必须**读取以下工作区信息：

### Required Context

1. **工作区目录结构** (Required)
   - Path: `.asdm/workspace/auto-test/`
   - Purpose: 了解 results/、reports/、screenshots/ 目录下的文件情况

2. **清理范围确认** (Required)
   - 用户参数 `scope`：results / reports / screenshots / all
   - 未指定 → 交互式询问用户选择清理范围

## Steps

### Step 1: 确认清理范围

1. 解析用户输入参数 `scope`：
   - `scope=results` → 清理 `.asdm/workspace/auto-test/results/` 目录下的文件
   - `scope=reports` → 清理 `.asdm/workspace/auto-test/reports/` 目录下的文件（含 allure-results/ 和 allure-report/ 子目录内容）
   - `scope=screenshots` → 清理 `.asdm/workspace/auto-test/screenshots/` 目录下的文件
   - `scope=all` → 清理以上三个目录的所有文件
   - 未指定 → 列出各目录文件情况并询问用户选择

2. 输出清理范围确认：

```markdown
### 清理范围确认

> 清理范围：{scope}

**将清理以下目录**：
- results/：执行结果 JSON 文件
- reports/：HTML 报告文件 + Allure 报告目录（如 scope 包含 reports）
- screenshots/：截图 PNG 文件（如 scope 包含 screenshots）
```

### Step 2: 列出将要删除的文件数量和大小

1. 扫描清理范围内的每个目录：
   - 统计文件数量（不包括 .gitkeep 和子目录本身）
   - 计算文件总大小（KB 或 MB）
   - 列出文件列表摘要

2. 输出文件统计信息：

```markdown
### 文件统计

| 目录 | 文件数量 | 总大小 | 示例文件 |
|------|:-------:|:------:|---------|
| results/ | {count} | {size} | ATR-*.json |
| reports/ | {count} | {size} | report-*.html |
| screenshots/ | {count} | {size} | *.png |
| **合计** | **{totalCount}** | **{totalSize}** | — |
```

3. 详细文件列表（如文件数 <= 20 则列出全部，否则列出前 10 + 总数）：

```markdown
#### results/ 文件列表
- ATR-20260714-001.json (12.5 KB)
- ATR-20260714-002.json (8.3 KB)
- ...共 {count} 个文件

#### reports/ 文件列表
- report-20260714-001.html (156 KB)
- allure-results/ (3 个文件, 45 KB)
- ...共 {count} 个文件

#### screenshots/ 文件列表
- ATR-20260714-S03-fail.png (128 KB)
- ATR-20260714-S05-marked.png (96 KB)
- ...共 {count} 个文件
```

### Step 3: 用户确认后执行删除

1. **确认机制**：
   - 用户参数 `confirm=true` → 直接执行删除
   - 用户参数 `confirm=false` 或未指定 → 输出确认提示，等待用户回复确认

   ```
   ⚠️  即将删除 {totalCount} 个文件，释放 {totalSize} 空间。
   此操作不可撤销。请回复 "确认" 或 "取消"。
   ```

2. **用户确认后** → 执行删除操作：
   - 删除指定范围内的文件（仅删除文件，不删除目录）
   - 保留 .gitkeep 文件
   - 保留子目录结构（不删除空目录本身）

3. **删除规则**：
   - results/ → 删除所有 `ATR-*.json` 文件
   - reports/ → 删除所有 `report-*.html` 文件 + `allure-results/` 内文件 + `allure-report/` 内文件
   - screenshots/ → 删除所有 `*.png` 文件
   - all → 删除以上所有文件
   - **不删除**：.gitkeep 文件、目录本身、子目录结构

### Step 4: 保留目录结构

确保清理后目录结构完整保留：

1. **不删除的项**：
   - 目录本身（results/, reports/, screenshots/, cases/）
   - `.gitkeep` 文件（所有子目录的 .gitkeep）
   - `cases/` 目录及其内容（测试用例文件不属于清理范围）

2. **清理后目录状态**：

```
.asdm/workspace/auto-test/
├── cases/          ← 不清理（保留用例文件）
│   ├── .gitkeep
│   ├── user-login-test.yaml
│   └── ...
├── results/        ← 清理后仅保留 .gitkeep
│   └── .gitkeep
├── reports/        ← 清理后仅保留 .gitkeep（含 allure 子目录结构）
│   └── .gitkeep
│   ├── allure-results/  ← 清理内容，保留目录
│   │   └── .gitkeep
│   └── allure-report/   ← 清理内容，保留目录
│       └── .gitkeep
├── screenshots/    ← 清理后仅保留 .gitkeep
│   └── .gitkeep
```

3. **目录完整性检查**：
   - 清理后验证每个必要子目录仍存在
   - 如子目录被意外删除 → 重新创建并添加 .gitkeep

### Step 5: 输出清理确认信息

1. 输出清理完成摘要：

```markdown
### 🧹 清理完成

> 清理范围：{scope} | 删除文件：{deletedCount} | 释放空间：{freedSize}

**清理详情**：
- results/：删除 {count} 个文件，释放 {size}
- reports/：删除 {count} 个文件，释放 {size}
- screenshots/：删除 {count} 个文件，释放 {size}

**保留内容**：
- ✅ 目录结构完整保留
- ✅ .gitkeep 文件保留
- ✅ cases/ 用例文件未受影响
```

2. 输出结构化 JSON：

```json
{
  "phase": "auto-test-clean",
  "status": "success",
  "scope": "all",
  "deleted_files": {
    "results": {"count": 5, "size_kb": 102.5},
    "reports": {"count": 3, "size_kb": 456.0},
    "screenshots": {"count": 8, "size_kb": 896.0}
  },
  "total_deleted": 16,
  "total_freed_kb": 1454.5,
  "preserved": {
    "directories": ["cases", "results", "reports", "screenshots"],
    "gitkeep_files": 4,
    "cases_dir_intact": true
  },
  "timestamp": "ISO 8601 datetime"
}
```

## Execution Guidelines

### 安全确认机制

- `confirm=true` → 直接执行，不等待用户回复（CI 环境适用）
- `confirm=false` 或未指定 → 必须等待用户确认后才执行删除
- 用户回复"确认" / "是" / "yes" / "ok" → 执行删除
- 用户回复"取消" / "否" / "no" / "cancel" → 取消清理
- 5 分钟无回复 → 自动取消清理

### 不可删除项

以下项在任何清理范围下均不删除：
- `.gitkeep` 文件
- 目录本身（仅删除目录内的文件）
- `cases/` 目录及其内容（测试用例）
- YAML 用例文件（*.yaml）

### 错误处理

| 错误场景 | 处理 |
|----------|------|
| 目录不存在 → 创建目录并添加 .gitkeep | 自动修复 |
| 文件删除失败 → 跳过并记录 | 继续清理其他文件 |
| 权限不足 → 提示用户检查权限 | 中止清理 |
| 清理范围参数错误 → 提示有效选项 | 重新询问 |

### 清理策略建议

| 策略 | 说明 | 适用场景 |
|------|------|----------|
| 定期清理 results | 保留最近结果，清理过期结果 | 每周/每月 |
| 清理 screenshots | 截图体积大，优先清理 | 空间紧张时 |
| 清理 reports | HTML 报告可重新生成 | 报告积累过多时 |
| scope=all | 完全重置工作区 | 版本发布前/重大重构后 |

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| scope | string | ❌ | 清理范围：results / reports / screenshots / all，未指定则交互式选择 |
| confirm | string | ❌ | 确认标志：true（直接执行）/ false（需确认），默认 false |

### 命令示例

```
/auto-test-clean
/auto-test-clean scope=results
/auto-test-clean scope=all confirm=true
/auto-test-clean scope=screenshots confirm=true
/auto-test-clean scope=reports
```

## Output

### 清理统计摘要

```markdown
### 🧹 清理完成

> 清理范围：{scope} | 删除 {deletedCount} 个文件 | 释放 {freedSize} 空间

**清理前**：
| 目录 | 文件数 | 大小 |
|------|:------:|:----:|
| results/ | {beforeCount} | {beforeSize} |
| reports/ | {beforeCount} | {beforeSize} |
| screenshots/ | {beforeCount} | {beforeSize} |

**清理后**：
| 目录 | 文件数 | 大小 |
|------|:------:|:----:|
| results/ | 1 (.gitkeep) | 0 KB |
| reports/ | 1 (.gitkeep) | 0 KB |
| screenshots/ | 1 (.gitkeep) | 0 KB |

**未受影响**：
- ✅ cases/ 目录（{casesCount} 个用例）
```

### 交互式确认提示

```markdown
⚠️  即将清理 {scope} 范围内的文件：

| 目录 | 将删除文件数 | 将释放空间 |
|------|:----------:|:---------:|
| results/ | {count} | {size} |
| reports/ | {count} | {size} |
| screenshots/ | {count} | {size} |
| **合计** | **{total}** | **{totalSize}** |

此操作不可撤销。请回复 "确认" 继续或 "取消" 中止。
```

## Configuration

Refer to:
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — AutoTestResult 数据模型、结果文件命名规则 ATR-{YYYYMMDD}-{NNN}
- [auto-test-report-spec.md](../spec/auto-test-report-spec.md) — 报告文件命名规则、Allure 目录结构
