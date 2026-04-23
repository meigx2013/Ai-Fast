# asdm-prd-breakdown 操作指令

## 目的

本指令指导 AI 模型为功能分解任务。它首先生成任务列表，然后为列表中的每个任务创建详细的 Task PRD 文档。

## 语言检测

在生成任何 Task PRD 文档之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置以确定主要语言
2. **应用语言一致性**：确保所有生成的文档使用检测到的语言
3. **支持的语言**：英语 (en)、中文 (zh)

**重要提示**：语言检测是第一个步骤。

## 上下文注入

### 核心原则

```
┌─────────────────────────────────────────────────────────────┐
│  L1 索引（必须）→ L2 索引（按需）→ 源码（按需）              │
│                                                             │
│  不一次性加载所有上下文，按任务需要逐步加载                   │
└─────────────────────────────────────────────────────────────┘
```

### 加载顺序

| 阶段 | 加载内容 | 必须 |
|------|----------|------|
| 1. 初始 | `.asdm/contexts/index.md` + Feature PRD | ✅ |
| 2. 任务分析 | 根据任务涉及的领域加载 L2 | 按需 |
| 3. 任务分解 | 根据需要读源码 | 按需 |

### 步骤 1: 读取 L1 项目顶层索引（必须）

**必须首先读取**：

1. **`.asdm/contexts/index.md`** - 项目全局结构
2. **Feature PRD** - 功能需求文档
   - 路径：`.asdm/workspace/features/<feature-id>-<feature-name>/feature-prd.md`

### 步骤 2: 加载 Feature 相关文档

1. **Task List**（如已存在）
   - 路径：`.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`

2. **Task PRD**（如已存在）
   - 路径：`.asdm/workspace/features/<feature-id>-<feature-name>/<task-id>-<task-name>-prd.md`

### 步骤 3: 根据任务加载 L2 索引（按需）

根据任务涉及的领域，按需读取领域索引：

- **如果任务涉及用户模块**：
  - 读取：`.asdm/contexts/domains/user-domain.md`

- **如果任务涉及数据库变更**：
  - 读取相关的领域索引
  - 根据索引路径直接读 Entity/Repository 源码

- **如果任务涉及 API 变更**：
  - 读取相关的领域索引
  - 根据索引路径直接读 Controller/Service 源码

### 步骤 4: 按需访问源码（按需）

根据 L2 索引提供的文件路径，直接读取相关源码：

- 根据 L2 索引的"子模块"和"关键文件"信息
- 读取相关的核心类/接口定义
- **源码是权威来源，以源码为准**

### 安全和合规上下文（MUST LOAD）

对于涉及用户数据、认证或 API 的任务，**必须读取**：

- `.asdm/contexts/security-practices.md`（如存在）
- `.asdm/contexts/compliance-practices.md`（如存在）

### 错误处理

如果上下文文件不存在：

```markdown
1. 如果 `.asdm/contexts/index.md` 不存在：
   → 提示用户先执行 `/asdm-context-init`

2. 如果 `.asdm/contexts/domains/<领域>-domain.md` 不存在：
   → 直接扫描该领域的目录结构
   → 根据实际代码分析

3. 如果找不到需要的上下文：
   → 直接扫描源码目录
   → 基于实际代码进行分析
```

## 任务分解步骤

### 1. 识别功能并验证存在

识别要分解任务的功能：
- 从用户获取功能 ID 或名称
- 验证功能目录存在：`.asdm/workspace/features/<feature-id>-<feature-name>/`
- 如果功能不存在，提示用户先使用 `/asdm-prd-planning`

### 2. 加载功能上下文

加载必要的上下文文件：
- 读取 Feature PRD
- 检查 Task List 是否存在
- 按需加载 L2 索引和源码

### 3. 生成任务列表（如不存在）

如果任务列表不存在，基于 Feature PRD 生成任务列表：

- 路径：`.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`
- 遵循模板结构
- 任务数量验证（见 3.1）

### 3.1 验证任务数量

生成任务列表后，验证任务数量：

- 任务数量 **≤ 10**：继续步骤 4
- 任务数量 **> 10**：
  - **停止**分解过程
  - 解释功能过大，需要拆分
  - 请用户将功能拆分为更小的子功能

### 4. 选择要分解的任务

确定要分解的任务：
- 如果用户指定任务 ID，只分解指定任务
- 如果用户未指定，分解所有状态为 `TODO` 或 `IN PROGRESS` 的任务

### 5. 生成 Task PRD

为每个选定任务生成详细的 Task PRD 文档：

- 路径：`.asdm/workspace/features/<feature-id>-<feature-name>/<task-id>-<task-name>-prd.md`
- 遵循模板结构
- **必须包含**：安全要求、合规要求、测试要求

### 6. 更新任务列表状态

更新任务列表以反映分解状态：
- 路径：`.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`

### 7. 审查和验证

审查所有生成的文档：
- 完整性和准确性
- 语言一致性
- 正确的结构和格式
- 清晰且可操作的需求

## 使用方法

AI 模型应：

1. 从用户获取功能信息
2. 检测响应语言
3. 验证功能存在
4. 加载上下文（index.md → Feature PRD → 按需加载 L2/源码）
5. 生成/验证任务列表
6. 选择要分解的任务
7. 生成 Task PRD 文档
8. 更新任务列表
9. 展示生成结果供用户审查
10. 等待用户批准或反馈

## 输出摘要

完成后将生成：

### 生成的文档

- **任务列表**（如不存在）：功能的完整任务列表
- **Task PRD 文档**：每个选定任务的详细 PRD

### 更新的文档

- **任务列表**：更新以反映当前任务状态

## 错误处理

| 场景 | 解决方案 |
|------|----------|
| 功能不存在 | 提示使用 `/asdm-prd-planning` |
| 任务列表不存在 | 自动生成 |
| Task PRD 已存在 | 询问用户是否覆盖 |
| 上下文不足 | 直接分析源码 |
| 任务数量超限 | 停止并请用户拆分 |
