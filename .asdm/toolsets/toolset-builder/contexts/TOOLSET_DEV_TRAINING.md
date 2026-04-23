# ASDM Toolset 开发培训材料

**培训日期**：2026年4月1日
**培训对象**：开发团队成员
**培训目标**：掌握 ASDM Toolset 的开发方法，能够编写 README.md 引导 AI 生成完整工具集
**文档版本**：v1.0
**最后更新**：2026-03-31

---

## 1. 培训概述

### 1.1 什么是 ASDM Toolset？

ASDM（Agentic Software Development Manager）Toolset 是一套用于 AI 辅助软件开发的工具集。它的核心思想是：

- **自动化**：通过 AI 自动完成繁琐的开发任务
- **规范化**：使用统一的模板和流程确保开发质量
- **可追踪**：记录所有开发活动，便于审计和回溯

### 1.2 开发人员 vs AI 职责

| 角色 | 职责 |
|------|------|
| **开发人员** | 编写 README.md，描述工具集的功能和使用方式 |
| **AI** | 根据 README.md 自动生成 actions、spec 等完整实现 |

**核心原则**：开发人员只需描述"做什么"，AI 会负责实现"怎么做"。

---

## 2. 开发模式

### 2.1 开发流程

```
开发人员                          AI
   |                              |
   |  编写 README.md             |
   |--------->                    |
   |                              |
   |         读取 README.md      |
   |<---------                    |
   |                              |
   |         生成 actions/        |
   |<---------                    |
   |                              |
   |         生成 spec/           |
   |<---------                    |
   |                              |
   |  验证工具集                   |
```

### 2.2 开发人员工作内容

开发人员需要完成的工作：

1. **编写 README.md**：描述工具集的功能、用法和结构
2. **提供示例**：说明期望的输入输出
3. **验证结果**：检查 AI 生成的工具集是否符合要求

**注意**：开发人员**不需要**编写：
- Action 指令文件（由 AI 生成）
- Spec 模板文件（由 AI 生成）
- 安装脚本（由 AI 生成）

---

## 3. README.md 编写指南

### 3.1 README.md 核心内容

```markdown
# <Toolset Name>

## Overview
简要说明工具集的功能和用途

## Features
列出工具集的主要功能

## Directory Structure
说明工具集的目录结构

## Actions
描述每个 action 的输入、输出和用途

## Usage
说明如何使用这个工具集
```

### 3.2 功能描述规范

每个功能应包含：

- **功能名称**：简洁的功能描述
- **输入**：需要用户提供什么信息
- **输出**：工具会生成什么结果
- **使用场景**：什么情况下使用此功能

**示例**：
```markdown
### Feature: 功能规划

**输入**：功能描述（如"实现用户登录功能"）
**输出**：Feature PRD 文档、任务列表
**使用场景**：需要规划新功能的开发任务时使用
```

### 3.3 Action 描述规范

不需要详细说明实现步骤，只需说明：

```markdown
### Action: asdm-prd-planning

**用途**：根据功能描述生成 Feature PRD 和任务列表

**输入参数**：
- feature-description：功能描述

**输出**：
- Feature PRD 文档
- 任务列表

**使用示例**：
/asdm-prd-planning 实现用户认证功能
```

---

## 4. 目录结构说明

### 4.1 期望的目录结构

开发人员应了解工具集的最终结构：

```
.asdm/toolsets/<toolset-id>/
├── README.md                    # 工具集说明文档（开发人员编写）
├── INSTALL.md                   # 安装指南（AI 生成）
├── actions/                     # 动作指令目录（AI 生成）
│   ├── action-a.md
│   └── action-b.md
└── spec/                        # 规范模板目录（AI 生成）
    ├── template-a-spec.md
    └── template-b.md
```

**说明**：Skill 和 MCP 是全局能力扩展，位于 `.codebuddy/` 目录，Toolset 中不需要包含。

### 4.2 目录作用（供理解）

| 目录 | 作用 | 生成者 |
|------|------|--------|
| README.md | 工具集入口说明 | 开发人员 |
| INSTALL.md | 安装步骤 | AI |
| actions/ | AI 执行的动作指令 | AI |
| spec/ | 输出文档的模板 | AI |

**注意**：Skill 和 MCP 是全局能力扩展，位于 `.codebuddy/` 目录，Toolset 中不需要包含，开发时只需声明使用。

---

## 5. Skill 和 MCP 扩展说明

### 5.1 什么是 Skill 和 MCP？

**Skill**（技能）和 **MCP**（Model Context Protocol）是 AI 助手的全局能力扩展，**不属于 Toolset 目录**。

- **Skill**：提供特定领域的专业能力（如 PDF 处理、Excel 操作、Docker 操作）
- **MCP**：提供外部服务连接能力（如数据库、云存储、云函数、部署服务）

**配置位置**：用户级或项目级配置，通常位于 `.codebuddy/` 目录

### 5.2 在 README 中声明使用的扩展

Toolset 开发者在 README.md 中**只需声明**需要使用的 Skill/MCP：

```markdown
## Features

### 1. PDF 处理 (generate-pdf)

**输入**：文档内容
**输出**：PDF 文件

**使用 Skill**：`pdf` - 用于 PDF 文件处理
**使用 MCP**：`storage` - 用于文档存储
```

### 5.3 使用场景

| 场景 | 使用方式 |
|------|----------|
| 处理 PDF/Excel/Word 文件 | 使用 Skill: `pdf`, `xlsx`, `docx` |
| 处理 JSON/YAML/XML | 使用 Skill: `json`, `yaml`, `xml` |
| 连接数据库 | 使用 MCP: `database` |
| 调用云函数 | 使用 MCP: `function` |
| 上传下载云存储 | 使用 MCP: `storage` |
| 部署服务 | 使用 MCP: `deployment` |

### 5.4 注意事项

1. **不需要开发**：Skill 和 MCP 由平台提供，Toolset 开发者只需使用
2. **只需要声明**：在 README.md 中说明需要使用的扩展名称
3. **全局可用**：这些扩展对所有 Toolset 都是可用的

---

## 6. 编写示例

### 6.1 简单工具集 README 示例

```markdown
# Code Review Toolset

## Overview
自动化代码审查工具集，帮助团队进行代码质量检查。

## Features

### 1. 代码扫描 (code-scan)
扫描代码库，识别潜在的代码问题。

**输入**：扫描路径、规则集
**输出**：问题列表报告

### 2. 审查报告 (generate-report)
生成结构化的代码审查报告。

**输入**：扫描结果
**输出**：Markdown 格式报告

## Directory Structure

```
.asdm/toolsets/code-review/
├── README.md          # 本文件
├── INSTALL.md         # 安装指南
├── actions/           # 动作指令
│   ├── code-scan.md
│   └── generate-report.md
└── spec/              # 规范模板
    ├── report-spec.md
    └── issue-list.md
```

## Actions

### code-scan
扫描代码库中的代码问题。

### generate-report
根据扫描结果生成审查报告。

## Usage

1. 安装工具集
2. 使用 /code-scan 进行代码扫描
3. 使用 /generate-report 生成报告
```

---

## 6. 编写示例（续）

### 6.2 多阶段工具集 README 示例

```markdown
# PRD Builder

## Overview
功能需求规划和任务执行工具集，用于管理系统化的开发流程。

## Features

### 1. 规划阶段 (asdm-prd-planning)
根据功能描述生成 Feature PRD 和任务列表。

**输入**：功能描述文本
**输出**：
- `.asdm/workspace/features/<id>/feature-prd.md`
- `.asdm/workspace/features/<id>/task-list.md`

### 2. 分解阶段 (asdm-prd-breakdown)
将任务分解为详细的 Task PRD。

**输入**：Feature ID
**输出**：每个任务的 PRD 文档

### 3. 执行阶段 (asdm-prd-execution)
执行任务并更新状态。

**输入**：Task ID
**输出**：更新的任务状态

## Directory Structure

```
.asdm/toolsets/prd-builder/
├── README.md
├── INSTALL.md
├── actions/
│   ├── asdm-prd-planning.md
│   ├── asdm-prd-breakdown.md
│   └── asdm-prd-execution.md
└── spec/
    ├── feature-prd-spec.md
    ├── task-prd-spec.md
    ├── feature-list.md
    └── task-list.md
```

## Workflow

1. 使用 `/asdm-prd-planning <功能描述>` 规划功能
2. 使用 `/asdm-prd-breakdown <feature-id>` 分解任务
3. 使用 `/asdm-prd-execution <task-id>` 执行任务

## Success Criteria

- Feature PRD 包含完整的用户故事和验收标准
- 任务数量不超过 10 个
- 每个任务 PRD 包含验证步骤
```

---

## 7. AI 生成内容说明

### 7.1 AI 会自动生成的内容

当 AI 读取 README.md 后，会自动生成：

| 文件 | 说明 |
|------|------|
| INSTALL.md | 安装步骤，支持多种 AI 助手 |
| actions/*.md | 每个 action 的详细指令 |
| spec/*.md | 输出文档的模板 |

### 7.2 AI 生成 Action 包含的内容

AI 生成的 Action 文件会包含：

```markdown
# Instructions for <action-name> action

## Purpose              # 动作目的
## Context Loading      # 上下文加载策略
## Steps to XXX         # 详细执行步骤
## Execution Guidelines # 执行指南
## Error Handling       # 错误处理
## Usage               # 使用说明
## Output Summary       # 输出摘要
```

---

## 8. 验证和迭代

### 8.1 验证工具集

编写完 README.md 后，AI 生成工具集，需要验证：

1. **功能完整性**：所有描述的功能都有对应的 Action
2. **目录结构**：目录结构符合预期
3. **使用可行性**：可以正常安装和使用

### 8.2 迭代优化

如果验证发现问题：

1. **修改 README.md**：补充遗漏的功能或修改描述
2. **重新生成**：让 AI 重新生成工具集
3. **验证结果**：再次验证

---

## 9. 开发实践

### 9.1 开发流程

1. **确定工具集目标**
   - 明确要解决什么问题
   - 列出需要的功能

2. **编写 README.md**
   - 按照模板格式编写
   - 描述清楚每个功能的输入输出

3. **AI 生成实现**
   - 提供 README.md 给 AI
   - 让 AI 生成完整工具集

4. **验证和优化**
   - 检查生成结果
   - 如有问题，修改 README.md 重新生成

### 9.2 检查清单

编写 README.md 时检查：

- [ ] 有清晰的功能概述
- [ ] 每个功能都有输入/输出说明
- [ ] 目录结构描述完整
- [ ] 使用示例清晰
- [ ] 成功标准明确

---

## 10. 练习题

### 练习 1：编写工具集 README

**题目**：为一个名为 `api-doc-generator` 的工具集编写 README.md。

**功能要求**：
1. 根据代码注解生成 API 文档
2. 支持多种输出格式（Markdown、HTML）
3. 支持导出和分享

### 练习 2：描述工作流

**题目**：为一个 CI/CD 工具集编写 README.md，包含以下阶段：
1. 构建阶段
2. 测试阶段
3. 部署阶段

### 练习 3：定义验收标准

**题目**：为一个数据库迁移工具集编写 README.md，定义：
- 迁移成功的标准
- 迁移失败的处理方式

---

## 11. 常见问题

### Q1: README.md 需要写多详细？

A：只需描述清楚"做什么"，不需要说明"怎么做"。AI会根据描述自动实现。

### Q2: 如何确保 AI 正确理解需求？

A：
- 使用清晰的功能描述
- 明确输入输出格式
- 提供使用示例

### Q3: AI 生成的结果不符合预期怎么办？

A：
1. 修改 README.md 中的描述
2. 让 AI 重新生成
3. 重复直到满意

---

## 12. 参考资料

- **现有工具集示例**：`.asdm/toolsets/prd-builder/README.md`
- **设计原理文档**：`ASDM_TOOLSET_DESIGN_PRINCIPLES.md`

---

## 13. 下一步

1. **阅读现有 README**：了解现有的工具集描述风格
2. **尝试编写 README**：为一个简单工具集编写 README
3. **让 AI 生成工具集**：验证开发模式是否可行

---

## 14. 培训反馈

如果您参加完本次培训，请提供以下反馈：

1. **培训内容**：清晰程度如何？
2. **实践环节**：是否需要更多练习？
3. **时间安排**：培训时间是否合理？
4. **改进建议**：您对培训有什么建议？

---

*培训材料基于 ASDM_TOOLSET_DESIGN_PRINCIPLES.md 生成*
*如有问题，请联系培训讲师*
*版本: v1.0*
*最后更新: 2026-03-31*
