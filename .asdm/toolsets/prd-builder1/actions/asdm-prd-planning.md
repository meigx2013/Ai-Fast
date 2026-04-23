# asdm-prd-planning 操作指令

## 目的

本指令指导 AI 模型使用 Task Planner & Executor 工具集为功能规划任务。它生成功能 PRD 并创建任务计划。单个任务的 PRD 在执行阶段生成。

## 语言检测

在生成任何规划文档之前，您必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置以确定主要语言：
   - 检查系统/用户语言设置或环境配置
   - 识别项目文档和注释中使用的主要语言
   - 根据工作空间上下文确定语言偏好

2. **应用语言一致性**：确保所有生成的规划文档使用检测到的语言：
   - 在所有生成的 markdown 文件、注释和文档中使用相同的语言
   - 在所有生成的文件中保持语言一致性
   - 遵循检测到的语言的写作规范和格式

3. **支持的语言**：
   - 英语 (en)
   - 中文 (zh)
   - 根据环境检测需要的其他语言

**重要提示**：语言检测是生成任何规划文档之前的第一个步骤。所有输出必须在整个过程中始终使用检测到的语言。

## 上下文注入

在规划任何功能之前，AI 模型必须从 `.asdm/contexts/` 读取并理解项目上下文。这确保任务规划与现有的项目结构、架构和约定保持一致。

### 需要读取的上下文文件

AI 模型应按指定顺序读取以下上下文文件：

1. **index.md**（必需 - 必须首先读取）
   - 路径：`.asdm/contexts/index.md`
   - 目的：提供工作空间的概览，包括到其他上下文文件的导航链接
   - 包含：工作空间结构、关键组件和详细上下文文件的链接

2. **渐进式上下文阅读**（可选 - 按需）
   - 仅在查看 index.md 后，如果需要额外上下文时
   - AI 模型可以根据正在规划的功能请求特定的上下文文件
   - 额外上下文文件的示例：
     - `.asdm/contexts/standard-project-structure.md`
     - `.asdm/contexts/standard-coding-style.md`
     - `.asdm/contexts/data-models.md`
     - `.asdm/contexts/deployment.md`
     - `.asdm/contexts/api.md`
     - `.asdm/contexts/architecture.md`

### 渐进式上下文阅读策略

为避免让 AI 模型加载过多上下文，请遵循以下渐进式阅读方法：

1. **初始阶段**（规划开始前）：
   - 仅读取 `.asdm/contexts/index.md`
   - 用它来了解整体工作空间结构并识别相关领域

2. **规划阶段**（任务规划期间）：
   - 确定哪些额外上下文文件与该功能相关
   - 根据需要一次请求一个特定的上下文文件
   - 示例：如果功能涉及数据库变更，读取 `.asdm/contexts/data-models.md`
   - 示例：如果功能涉及 API 变更，读取 `.asdm/contexts/api.md`

3. **执行阶段**（任务执行期间）：
   - 在实现过程中可以根据需要引用或重新读取上下文文件
   - 确保与项目标准和约定保持一致

### 上下文文件使用指南

- **index.md 是强制性的**：始终首先读取此文件以建立对工作空间的理解
- **渐进式加载**：仅在特别需要该功能时才读取额外的上下文文件
- **避免过载**：不要试图一次读取所有上下文文件
- **基于相关性**：仅请求与正在规划的功能直接相关的上下文文件
- **用户控制**：如果用户想要加载额外的上下文文件，他们可以明确请求

### 与语言检测的集成

上下文注入步骤应发生在语言检测**之后**但**开始规划步骤之前**。这确保：
1. AI 模型知道使用哪种语言来理解上下文文件
2. AI 模型在创建规划文档之前理解项目上下文
3. 所有规划文档始终使用检测到的语言

**重要提示**：在开始规划步骤之前，始终读取 `.asdm/contexts/index.md`。这是理解项目的入口点，并确保所有规划与现有项目结构和约定保持一致。

## 为功能规划任务的步骤

### 1. 初始化功能目录
如果不存在，请在工作空间根目录创建 `.asdm/workspace/features/` 目录。

### 2. 生成功能 ID
使用以下格式为新功能生成唯一的功能 ID：
- 格式：`<feature-id>-<feature-name>`
- 示例：`FEAT-001-user-authentication`
- 通过检查 `.asdm/workspace/features/features-list.md` 中现有的功能来确保 ID 唯一

### 3. 创建功能目录
为该功能创建新目录：
- 路径：`.asdm/workspace/features/<feature-id>-<feature-name>/`

### 4. 生成功能 PRD
使用 `.asdm/toolsets/task-planner-executor/spec/feature-prd-spec.md` 中的模板生成功能 PRD 文档：
- 路径：`.asdm/workspace/features/<feature-id>-<feature-name>/feature-prd.md`
- 遵循规范模板结构并填写所有相关部分
- 在整个文档中使用检测到的语言

### 5. 更新功能列表
更新功能跟踪文档以包含新功能：
- 路径：`.asdm/workspace/features/features-list.md`
- 如果文件不存在，使用 `.asdm/toolsets/task-planner-executor/spec/feature-list.md` 中的模板创建它
- 遵循模板结构并填写所有相关部分
- 添加新功能，包含：
  - 功能 ID
  - 功能名称
  - 描述
  - 状态（例如："PLANNED"）
  - 创建日期
- 更新摘要表格计数

**注意**：有关字段定义、状态管理和维护程序的详细指南，请参阅 `.asdm/toolsets/task-planner-executor/spec/feature-list.md`。

### 6. 审查和验证
审查所有生成的文档：
- 完整性和准确性
- 语言一致性
- 正确的结构和格式
- 清晰且可操作的功能需求

**注意**：有关功能分解原则、任务数量限制和状态管理的详细指南，请参阅 `.asdm/toolsets/task-planner-executor/spec/feature-prd-spec.md`。

## 规划指南

**注意**：详细的规划指南可在 `.asdm/toolsets/task-planner-executor/spec/feature-prd-spec.md` 中找到，包括：
- 功能分解原则
- 任务数量限制和验证
- 任务类别
- 状态管理
- 任务数量验证和分解策略

在规划和分解功能时，请参阅规范模板以获取全面的指南。

## 使用方法

AI 模型应：
1. 从用户接收功能描述
2. 检测响应语言
3. 读取 `.asdm/contexts/index.md` 以了解工作空间上下文
4. 根据功能需求按需渐进式加载额外的上下文文件
5. 遵循上述步骤生成所有规划文档
6. 展示生成的文档供审查
7. 在进入执行阶段之前等待用户批准或反馈

## 输出摘要

完成规划阶段后，将生成以下产物：
- 功能 PRD 文档
- 更新的功能列表

这些文档是任务分解阶段（asdm-prd-breakdown 操作）的基础，在该阶段将生成全面的任务列表和单个任务 PRD。
