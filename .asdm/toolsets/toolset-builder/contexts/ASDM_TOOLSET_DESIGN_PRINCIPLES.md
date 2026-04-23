# ASDM Toolset 设计原理

本文档基于 `prd-builder` 工具集分析，总结 ASDM Toolset 的设计原理，为后续开发新工具集提供参考。

**目标读者**：Toolset 开发者、技术架构师、AI 辅助开发工程师
**文档版本**：v1.0
**最后更新**：2026-03-31

---

## 1. Toolset 整体架构

### 1.1 目录结构

```
.asdm/toolsets/<toolset-id>/
├── README.md                    # 工具集说明文档
├── INSTALL.md                   # 安装指南
├── actions/                     # 动作指令目录
│   ├── <action-name>.md         # 各动作的具体指令
└── spec/                        # 规范模板目录
    ├── <spec-name>-spec.md       # 各类型文档的模板
    └── <spec-name>.md           # 列表类模板
```

**说明**：Skill 和 MCP 不在 toolset 目录内，它们是全局可用的能力扩展，由用户级或项目级配置管理（位于 `.codebuddy/` 目录）。Toolset 开发者只需知道如何使用这些扩展，无需开发它们。

### 1.2 核心组件

| 组件 | 作用 |
|------|------|
| README.md | 工具集概述、功能说明、使用方法 |
| INSTALL.md | 安装步骤、支持的 AI 助手适配 |
| actions/ | 定义 AI 执行的具体动作流程 |
| spec/ | 定义输出文档的结构模板 |

**注意**：Skill 和 MCP 是全局能力扩展，由用户级或项目级配置管理（`.codebuddy/` 目录），Toolset 开发者只需知道如何使用，无需开发。

---

## 2. Action 设计原理

### 2.1 Action 组成部分

每个 action 文件通常包含以下核心部分：

```
# Instructions for <action-name> action

## Purpose                    # 动作目的说明
## Context Loading           # 上下文注入
## Steps to XXX              # 执行步骤
## Execution Guidelines       # 执行指南
## Error Handling            # 错误处理
## Usage                     # 使用说明
## Output Summary            # 输出摘要
```

---

## 3. 上下文注入 (Context Injection)

### 3.1 渐进式上下文加载策略

**核心原则**: 避免一次性加载过多上下文，采用按需加载方式

**加载层次**:

| 阶段 | 加载内容 | 说明 |
|------|----------|------|
| 初始阶段 | index.md | 必读，了解项目整体结构 |
| 规划阶段 | 按需加载 | 根据功能需求加载相关上下文 |
| 执行阶段 | 按需加载 | 根据任务需求加载相关上下文 |

### 3.2 上下文文件类型

```
.asdm/
├── contexts/                  # 通用上下文
│   ├── index.md              # 入口文件（必读）
│   ├── standard-project-structure.md
│   ├── standard-coding-style.md
│   ├── data-models.md
│   ├── api.md
│   ├── architecture.md
│   ├── standard-security-practices.md
│   └── standard-compliance-practices.md
├── specs/                    # 技术栈特定规范
│   └── java-springboot-jpa/
│       ├── architecture-design.md
│       ├── entities.md
│       ├── repositories.md
│       └── ...
└── workspace/                # 工作区数据
    └── features/
        └── <feature-id>/
            ├── feature-prd.md
            └── task-list.md
```

### 3.3 上下文加载示例

```markdown
### Context Files to Read

1. **index.md** (Required - MUST be read first)
   - Path: `.asdm/contexts/index.md`
   - Purpose: Provides an overview of the workspace

2. **Progressive Context Reading** (Optional - On-Demand)
   - Only after reviewing index.md, if additional context is needed
   - The AI model can request specific context files based on the feature
```

### 3.4 上下文使用原则

1. **必读 index.md**: 始终首先读取项目入口文件
2. **按需加载**: 只加载当前任务需要的上下文
3. **避免过载**: 不一次性加载所有上下文文件
4. **相关性**: 只请求与当前任务直接相关的上下文

---

## 4. 工具使用 (Tool Usage)

### 4.1 工具调用方式

在 action 中，AI 通过以下方式使用工具：

1. **文件操作工具**
   - `write_to_file`: 创建/更新文档
   - `read_file`: 读取文档内容
   - `list_dir`: 列出目录内容
   - `delete_file`: 删除文件

2. **搜索工具**
   - `search_file`: 搜索文件
   - `search_content`: 搜索内容

3. **执行工具**
   - `execute_command`: 执行终端命令

### 4.2 工具使用场景

| 场景 | 使用的工具 |
|------|------------|
| 创建 Feature PRD | write_to_file |
| 更新 features-list.md | read_file + replace_in_file |
| 验证任务完成 | execute_command |
| 搜索现有文件 | search_file |

### 4.3 验证工具执行

**关键原则**: 验证必须通过实际执行命令来完成，而非仅展示命令

```markdown
### 9. Validate Task Completion
**CRITICAL**: Validation must be performed by **executing** the validation commands, not just displaying them to the user.

#### 9.2 Execute Validation Commands
**REQUIRED**: Execute each validation command using the terminal:
- For compilation checks: Run the compiler command (e.g., `mvn compile`)
- For test execution: Run the test command (e.g., `mvn test`)
- For code quality: Run linters (e.g., `eslint`, `checkstyle`)
```

---

## 5. 执行步骤设计 (Execution Steps)

### 5.1 步骤结构

每个 action 的执行步骤通常遵循以下模式：

```markdown
## Steps to <Action Name>

### 1. <Step Name>
具体操作说明

### 2. <Step Name>
具体操作说明

### 3. <Step Name>
具体操作说明
```

### 5.2 规划阶段执行步骤 (asdm-prd-planning)

```
1. 初始化 Features 目录
2. 生成唯一 Feature ID
3. 创建 Feature 目录
4. 生成 Feature PRD
5. 更新 Feature 列表
6. 审查验证
```

### 5.3 分解阶段执行步骤 (asdm-prd-breakdown)

```
1. 识别 Feature 并验证存在
2. 加载 Feature 上下文
3. 生成任务列表（如不存在）
4. 选择要分解的任务
5. 生成 Task PRD
6. 更新任务列表状态
7. 审查验证
```

### 5.4 执行阶段执行步骤 (asdm-prd-execution)

```
1. 识别 Feature 并验证存在
2. 加载 Feature 上下文
3. 展示可用任务
4. 选择执行的任务
5. 检查 Task PRD 存在性
6. 确认任务执行
7. 更新状态为 IN PROGRESS
8. 执行任务
9. 验证任务完成
10. 更新状态为 DONE/FAILED
11. 展示执行摘要
```

### 5.5 步骤设计原则

1. **线性流程**: 步骤按逻辑顺序排列
2. **可验证**: 每个步骤可验证其完成状态
3. **可回退**: 错误时可回退到上一步
4. **用户交互**: 关键步骤需要用户确认

---

## 6. 退出条件设计 (Exit Conditions)

### 6.1 正常退出条件

| 阶段 | 退出条件 |
|------|----------|
| 规划阶段 | Feature PRD 生成完成，features-list.md 更新完成 |
| 分解阶段 | 所有选择的任务 PRD 生成完成 |
| 执行阶段 | 任务执行完成，验证通过，状态更新为 DONE |

### 6.2 异常退出条件

| 场景 | 处理方式 |
|------|----------|
| Feature 不存在 | 提示用户先执行规划阶段 |
| Task PRD 不存在 | 提示用户执行分解阶段 |
| 验证失败 | 不标记为 DONE，修复后重试 |
| 任务数量超限 | 提示用户拆分功能 |

### 6.3 任务数量限制

```markdown
### 3.1 Validate Task Count
After generating the task list, validate the task count:
- If task count is **10 or fewer**: Proceed to step 4
- If task count is **more than 10**:
  - **Stop** the breakdown process
  - Explain to the user that the feature is too large
  - Ask the user to break down the feature into smaller sub-features
```

### 6.4 状态管理

```markdown
## Status Management

Task statuses:
- **TODO**: Task not yet started
- **IN PROGRESS**: Task currently being worked on
- **DONE**: Task completed successfully
- **BLOCKED**: Task blocked by dependencies or issues
- **CANCELLED**: Task cancelled

Status transitions:
- TODO → IN PROGRESS: When task execution begins
- IN PROGRESS → DONE: When task completes successfully
- IN PROGRESS → BLOCKED: When task encounters blocking issues
```

---

## 7. 模板设计 (Spec Templates)

### 7.1 Feature PRD 模板

包含以下章节：
- Overview (概述)
- User Stories (用户故事)
- Functional Requirements (功能需求)
- Non-Functional Requirements (非功能需求)
- Technical Requirements (技术需求)
- Success Criteria (成功标准)
- Task Breakdown Principles (任务分解原则)
- Implementation Notes (实施说明)
- Risks and Mitigations (风险与缓解)
- Appendix (附录)

### 7.2 Task PRD 模板

包含以下章节：
- Task Overview (任务概述)
- Detailed Requirements (详细需求)
- Implementation Approach (实施方法)
- Acceptance Criteria (验收标准)
- Dependencies (依赖关系)
- Estimated Effort (预估工作量)
- Testing Strategy (测试策略)
- Implementation Notes (实施说明)
- Risks and Mitigations (风险与缓解)
- Deliverables (交付物)

### 7.3 列表类模板

- **features-list.md**: 功能列表（ID、名称、状态、优先级、进度等）
- **task-list.md**: 任务列表（ID、名称、状态、依赖、工作量等）

---

## 8. 安装机制 (Installation)

### 8.1 支持的 AI 助手

| AI 助手 | 配置目录 | 配置文件格式 |
|---------|----------|--------------|
| Claude Code | .claude/commands/ | Markdown + Frontmatter |
| GitHub Copilot | .github/prompts/ | .prompt.md + YAML |
| Tencent CodeBuddy | .codebuddy/commands/ | Markdown |

### 8.2 安装步骤

1. 创建 `.asdm/workspace/features` 目录
2. 检测当前 AI 助手类型
3. 在对应目录创建快捷命令
4. 复制 action 文件到命令目录

### 8.3 快捷命令映射

```
/asdm-prd-planning    →  任务规划
/asdm-prd-breakdown  →  任务分解
/asdm-prd-execution  →  任务执行
```

---

## 9. Skill 与 MCP 扩展

### 9.1 什么是 Skill 和 MCP？

**Skill**（技能）和 **MCP**（Model Context Protocol）是 AI 助手的全局能力扩展，不属于 Toolset 目录。

- **Skill**：提供特定领域的专业能力（如 PDF 处理、Excel 操作）
- **MCP**：提供外部服务连接能力（如数据库、云存储、云函数）

**配置位置**：用户级或项目级配置，通常位于 `.codebuddy/` 目录

### 9.2 在 Action 中使用 Skill/MCP

Toolset 开发者在编写 Action 时，只需说明需要使用哪些 Skill 或 MCP：

```markdown
## Context Loading

### Available Skills and MCPs
The following global skills and MCP services are available:
- Skill: `pdf` - 用于 PDF 文件处理
- MCP: `database` - 用于数据库操作

## Steps to Generate Report
### 3. Generate PDF Report
Use the `pdf` skill to generate PDF report:
- Input: <report-content>
- Output: <output-path>
```

### 9.3 使用场景

| 场景 | 使用方式 |
|------|----------|
| 处理 PDF/Excel/Word 文件 | 调用对应 Skill |
| 连接数据库 | 配置 MCP database |
| 调用云函数 | 配置 MCP function |
| 上传下载云存储 | 配置 MCP storage |
| 部署服务 | 配置 MCP deployment |

### 9.4 注意事项

1. **不需要开发**：Skill 和 MCP 由平台提供，Toolset 开发者只需使用
2. **需要声明**：在 Action 中说明需要使用的 Skill/MCP 名称
3. **全局可用**：这些扩展对所有 Toolset 都是可用的

---

## 9. 安全与合规要求

### 9.1 安全性要求

对于涉及用户数据、认证或 API 的任务，必须包含：
- 身份验证和授权要求
- 输入验证标准
- 数据加密要求（静态和传输中）
- 敏感数据处理和脱敏
- API 安全措施（限流、CSRF 保护等）
- 会话安全要求
- 安全响应头配置

### 9.2 合规性要求

对于涉及用户数据、审计追踪或监管要求的任务，必须包含：
- 数据分类级别
- 适用法规要求（PIPL、GDPR、PCI DSS 等）
- 审计追踪和日志要求
- 数据保留和删除策略
- 隐私设计考虑
- 用户同意管理
- 数据可移植性和删除权

### 9.3 测试要求

必须包含测试相关要求：
- 单元测试框架（根据项目技术栈）
- 测试覆盖率目标
- 集成测试要求
- 安全和合规验证测试
- 性能和负载测试（如适用）

---

## 10. 错误处理设计

### 10.1 常见错误场景

| 错误 | 解决方案 |
|------|----------|
| Feature 不存在 | 提示先执行规划 |
| Task PRD 不存在 | 提示先执行分解 |
| 验证失败 | 修复后重试，不标记 DONE |
| 任务数量超限 | 提示拆分功能 |
| 依赖阻塞 | 更新状态为 BLOCKED |

### 10.2 恢复策略

```markdown
## Recovery Strategies

When execution fails or is blocked:

1. **Identify Root Cause**: Determine why the task failed
2. **Document Issues**: Update task list with explanation
3. **Propose Solutions**: Suggest specific actions
4. **Seek User Input**: Ask user for direction
5. **Plan Next Steps**: Define clear next steps
```

---

## 11. 设计原则总结

### 11.1 核心原则

1. **渐进式加载**: 按需加载上下文，避免信息过载
2. **确定性验证**: 验证必须通过实际执行命令完成
3. **状态追踪**: 明确的状态管理和转换规则
4. **用户交互**: 关键节点需要用户确认
5. **错误恢复**: 完善的错误处理和恢复机制

### 11.2 扩展性设计

- 可适配多种 AI 助手
- 可扩展的上下文文件
- 可自定义的模板

### 11.3 质量保证

- 任务数量限制（不超过 10 个）
- 安全和合规要求内置
- 测试要求明确
- 验收标准可测试

---

## 12. 新工具集开发建议

基于以上设计原理，开发新工具集时应：

1. **定义清晰的 Purpose**: 说明工具集的目标
2. **设计合理的 Actions**: 分解为合理的动作阶段
3. **建立上下文机制**: 定义需要加载的上下文文件
4. **明确执行步骤**: 列出详细的执行步骤
5. **设置退出条件**: 定义正常和异常退出条件
6. **提供模板**: 创建规范化的输出模板
7. **支持安装**: 提供适配主流 AI 助手的安装方式

---

*本文档基于 prd-builder v0.0.2 版本分析生成*
*最后更新: 2026-03-31*

---

## 附录：版本历史

| 版本 | 日期 | 修改内容 | 作者 |
|------|------|----------|------|
| v1.0 | 2026-03-31 | 初始版本，基于 prd-builder 工具集分析 | Team |
