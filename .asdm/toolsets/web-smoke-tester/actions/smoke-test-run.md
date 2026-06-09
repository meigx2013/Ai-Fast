# ASDM Action: Smoke Test Run

## Metadata

```json
{
  "guid": "f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b01",
  "name": "smoke-test-run",
  "displayName": "执行冒烟测试",
  "description": "执行单个业务场景的 WEB 冒烟测试，斜杠命令后携带自然语言操作步骤",
  "toolset": {
    "guid": "e7f8a9b0-c1d2-3e4f-5a6b-7c8d9e0f1a02",
    "id": "web-smoke-tester",
    "name": "Web Smoke Tester",
    "version": "1.0.0"
  },
  "scenario": "smoke-test-execution"
}
```

## Process

本 action 是 Web Smoke Tester 的核心命令。用户在斜杠命令后以自然语言描述业务场景的详细操作步骤，AI 将自动解析步骤、执行测试、生成测试记录并以表格形式输出结果。

### Purpose

- 模拟测试人员进行 WEB 系统冒烟测试
- 将自然语言操作步骤转化为结构化测试执行
- 每个场景生成一条测试记录，以表格形式展示结果
- 支持快速验证系统核心功能是否可用

### Steps

1. **解析用户输入**：将斜杠命令后的自然语言步骤解析为 `SmokeTestStep[]`
2. **加载上下文**：读取项目结构、目标系统 URL、已有测试记录
3. **生成场景名称**：从用户输入中提取核心业务关键词作为 `scenarioName`
4. **逐步执行测试**：按步骤顺序模拟操作，收集实际结果
5. **断言判定**：对比预期结果与实际结果，判定每步 pass/fail
6. **生成记录**：创建 `SmokeTestRecord`，计算场景整体状态
7. **持久化存储**：将记录写入 `.smoke-tester/records/{id}.json`
8. **输出结果**：以 Markdown 表格形式输出单场景测试结果

### Input

斜杠命令后的参数，即自然语言描述的业务场景操作步骤：

**格式示例**：

```
/smoke-test-run 打开 /login→输入用户名admin→输入密码123456→点击登录→验证跳转到/dashboard
```

```
/smoke-test-run 1.打开用户管理页面 2.点击新增用户 3.输入姓名张三 4.点击保存 5.验证用户列表出现张三
```

```
/smoke-test-run 首先访问商品列表页，然后搜索"手机"，选择第一个商品加入购物车，验证购物车数量+1
```

### 解析规则

遵循 [smoke-test-shared-spec.md](../spec/smoke-test-shared-spec.md) 中的自然语言步骤解析规则：
- 支持 `→`、序号、自然段落等多种分隔格式
- 自动识别操作类型（打开、输入、点击、验证等）
- 自动推断预期结果
- 提取操作目标和输入值

### 执行策略

遵循 [smoke-test-pipeline-spec.md](../spec/smoke-test-pipeline-spec.md) 中的执行策略：
- **代码分析执行**（推荐）：AI 阅读源码推演操作结果
- **浏览器执行**：如可用，启动浏览器实际操作
- 顺序执行，快速失败（某步 fail 后后续标记 skip）
- 每步默认超时 30 秒

### Output

#### 执行结果输出

```markdown
### 🧪 冒烟测试结果：{scenarioName}

| 步骤 | 操作 | 目标 | 预期结果 | 实际结果 | 状态 |
|:----:|------|------|---------|---------|:----:|
| 1 | {action} | {target} | {expected} | {actual} | ✅/❌ |
| 2 | {action} | {target} | {expected} | {actual} | ✅/❌ |
| ... | ... | ... | ... | ... | ... |

**场景状态**：✅ 通过 / ❌ 失败 / ⚠️ 异常 | **步骤**：{passedSteps}/{totalSteps} 通过 | **耗时**：{duration}s
**失败原因**：{errorMessage}（仅失败时显示）
```

#### 结构化输出

```json
{
  "phase": "smoke-test-run",
  "status": "success",
  "record_id": "STR-20260609-001",
  "scenario_name": "用户登录",
  "scenario_status": "pass|fail|error|skip",
  "total_steps": 5,
  "passed_steps": 5,
  "failed_steps": 0,
  "duration": 8,
  "record_path": ".smoke-tester/records/STR-20260609-001.json",
  "timestamp": "ISO 8601 datetime"
}
```

## Configuration

Refer to:
- [smoke-test-shared-spec.md](../spec/smoke-test-shared-spec.md) — 数据模型、存储、输出格式
- [smoke-test-pipeline-spec.md](../spec/smoke-test-pipeline-spec.md) — 执行流程、断言机制、异常处理
- [smoke-test-report-spec.md](../spec/smoke-test-report-spec.md) — 报告格式（单场景输出部分）
