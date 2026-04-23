# Instructions for asdm-db-model action

## Purpose
本指令指导 AI 模型从 PRD 文档中提取数据需求，构建需求数据模型。通过分析 PRD 文档中的功能描述和业务需求，识别数据实体、属性和关系，生成结构化的需求数据模型。

## Language Detection

在生成任何内容之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置确定主要语言
2. **应用语言一致性**：确保所有生成内容使用检测到的语言
3. **支持的语言**：中文 (zh)、英文 (en)

## Context Injection

在执行需求数据建模前，AI 模型应读取项目上下文：

### Context Files to Read (Required)

1. **index.md** (Required - MUST be read first)
   - Path: `.asdm/contexts/index.md`
   - Purpose: 了解工作空间整体结构

2. **Feature PRD 文档** (Required)
   - Path: `.asdm/workspace/features/<feature-id>/feature-prd.md`
   - Purpose: 获取功能需求详细描述

3. **数据模型规范模板** (Required)
   - Path: `.asdm/toolsets/database-design/spec/data-model-spec.md`
   - Purpose: 遵循规范模板生成数据模型

### Progressive Context Loading

分阶段读取上下文：

| 阶段 | 读取内容 | 说明 |
|------|----------|------|
| 初始阶段 | index.md | 必读，了解项目结构 |
| 需求阶段 | Feature PRD | 提取数据需求 |
| 建模阶段 | 按需加载 | 根据需求复杂程度加载额外上下文 |

## Steps to Model Data Requirements

### 1. Receive Modeling Parameters

接收以下参数：

- **Feature ID**：功能唯一标识
- **PRD 文档路径**：Feature PRD 文档路径（可选，默认自动查找）
- **需求描述**：需求描述文本（可选，如果未提供 PRD 路径）

如果参数不完整：
- 提示用户提供缺失的参数
- 列出可用的 Feature PRD 文档供选择
- 等待用户输入

### 2. Read Feature PRD Document

读取 PRD 文档内容：

使用 `read_file` 工具读取：
- 路径：`.asdm/workspace/features/<feature-id>/feature-prd.md`
- 如果文件不存在，尝试根据 Feature ID 查找

提取以下关键信息：
- 功能概述
- 用户故事
- 功能需求描述
- 业务规则
- 涉及的数据实体提及

### 3. Identify Data Entities

从 PRD 文档中识别数据实体：

#### 3.1 实体识别原则

- **名词识别**：PRD 中的主要名词通常是数据实体
- **业务对象**：用户、订单、商品、会员等
- **业务事件**：订单创建、支付完成、退款申请等
- **业务产物**：合同、发票、报告等

#### 3.2 实体提取步骤

```
1. 扫描 PRD 全文，标记所有实体候选词
2. 结合业务场景筛选有效实体
3. 排除通用词汇（如"系统"、"模块"）
4. 为每个实体命名（使用业务术语）
```

### 4. Define Entity Attributes

为每个数据实体定义属性：

#### 4.1 属性识别

从 PRD 描述中识别每个实体的属性：
- 基本属性：实体固有的特征
- 业务属性：与业务规则相关的属性
- 关联属性：与其他实体的关联关系

#### 4.2 属性定义格式

```
属性名:
  - 数据类型: string/varchar/integer/decimal/datetime/boolean
  - 是否必填: required/optional
  - 默认值: (如果有)
  - 说明: 属性业务含义
```

#### 4.3 常见属性类型

| 属性类型 | 示例 | 建议数据类型 |
|----------|------|--------------|
| 标识属性 | ID、编号、流水号 | varchar/bigint |
| 名称属性 | 姓名、标题、名称 | varchar |
| 状态属性 | 状态、类型 | varchar/enum |
| 数量属性 | 数量、金额、积分 | decimal/integer |
| 时间属性 | 创建时间、有效期 | datetime |
| 关系属性 | 用户ID、订单ID | bigint/varchar |

### 5. Define Entity Relationships

定义实体之间的关系：

#### 5.1 关系类型

- **一对一 (1:1)**：一个实体对应另一个实体
- **一对多 (1:N)**：一个实体对应多个实体
- **多对多 (M:N)**：多个实体对应多个实体（需中间表）

#### 5.2 关系定义格式

```
关系名:
  - 类型: 1:1 / 1:N / M:N
  - 源实体: <entity_a>
  - 源字段: <field_in_a>
  - 目标实体: <entity_b>
  - 目标字段: <field_in_b>
  - 说明: 业务含义
```

### 6. Generate Data Model Document

按照 `spec/data-model-spec.md` 模板生成数据模型文档：

#### 6.1 文档结构

```
# 数据需求模型

## 模型概述
[功能数据需求概述]

## 数据实体清单
[所有识别的数据实体]

## 实体详细定义
[每个实体的完整属性定义]

## 实体关系图
[实体之间的关系描述]

## 数据字典
[统一的字段类型定义]
```

#### 6.2 E-R 图描述

使用文本方式描述实体关系图：
```
┌─────────┐       ┌─────────┐       ┌─────────┐
│ 用户表  │──1:N──│ 订单表  │──N:1──│ 商品表  │
└─────────┘       └─────────┘       └─────────┘
```

### 7. Save Data Model

保存数据模型文档：

- **路径**：`.asdm/workspace/database-design/analysis/<feature-id>/data-model.md`
- **格式**：Markdown
- **时间戳**：在文件头部添加建模时间

### 8. Update Feature PRD

可选：更新 Feature PRD 文档，添加数据模型引用：

- 在 PRD 文档末尾添加数据模型链接
- 标注数据模型版本号

## Execution Guidelines

### When to Use This Action

使用此 action 的场景：
- 新功能开发时，需要将需求转化为数据模型
- PRD 评审时需要明确数据支撑
- 数据库变更设计的前置步骤
- 团队需要统一数据实体定义

### Modeling Guidelines

数据建模时：
1. **业务导向**：以业务需求为出发点，不是技术实现
2. **实体完整性**：确保覆盖所有业务场景所需数据
3. **关系清晰**：明确实体间的关系和业务含义
4. **命名规范**：使用业务术语命名，便于沟通

### Data Type Guidelines

选择数据类型时：
1. **够用原则**：选择能容纳数据的最简单类型
2. **一致性**：相同业务含义的字段使用相同类型
3. **扩展性**：考虑未来可能的变更需求
4. **数据库特性**：考虑目标数据库的类型支持

## Usage

使用本指令，AI 模型应：
1. 检测响应语言
2. 接收建模参数
3. 读取 Feature PRD 文档
4. 识别数据实体
5. 定义实体属性
6. 定义实体关系
7. 生成数据模型文档
8. 保存文档到指定路径

## Output Summary

完成建模后，将生成以下文件：
- **数据需求模型文档**：`.asdm/workspace/database-design/analysis/<feature-id>/data-model.md`

模型包含：
- 数据实体清单
- 实体属性定义
- 实体关系图（E-R 图）
- 数据字典

所有文件保存在 `.asdm/workspace/database-design/analysis/<feature-id>/` 目录。
