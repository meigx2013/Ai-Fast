---
name: asdm-module-context-build
description: 用于独立生成制定模块上下文的Submodule
model: auto
tools: list_dir, search_file, search_content, read_file, read_lints, replace_in_file, write_to_file, execute_command, mcp_get_tool_description, mcp_call_tool, delete_file, preview_url, web_fetch, use_skill, web_search, automation_update
agentMode: agentic
enabled: true
enabledAutoRun: true
---

# asdm-module-context-build 操作指令

## 目的
本指令指导 AI 模型使用 Context Builder 工具集为当前工作区生成上下文。

## SubAgent输入输出

### 输入参数

调用此 SubAgent 时，需要传递以下参数：

1. **Module Name**（必需）
   - 参数名：`<module-name>`
   - 参数描述：模块名称
   - 类型：字符串
   - 说明：需要生成上下文的模块名称

2. **Module Path**（必需）
   - 参数名：`<module-path>`
   - 参数描述：子模块路径
   - 类型：字符串
   - 说明：具体分析的子模块在当前工作区的相对路径

### 输出结果

**重要说明**：SubAgent **不会直接写入文件**，而是将所有结果返回给主会话，由主会话负责更新 module-context-index.json 文件。

SubAgent 执行完成后，必须将以下信息返回给**主会话**：

1. **模块名称**：处理的模块名称
2. **模块路径**：模块的相对路径
3. **模块上下文路径列表**：
   - **<module-name>-structure.md** - 标准模块结构
   - **<module-name>-standard-coding-style.md** - 标准编码风格
   - **<module-name>-data-models.md** - 数据模型和关系的上下文文件
   - **<module-name>-deployment.md** - 部署配置
   - **<module-name>-api.md** - API 定义和文档的上下文文件
   - **<module-name>-architecture.md** - 架构概述
4. **模块上下文所在相对目录**：.asdm/contexts/**<module-name>**/
5. **处理状态**：
   - 成功/失败
   - 错误信息（如果失败）

## 生成上下文的步骤

### 1. 初始化子模块的上下文目录

- 读取文件: .asdm/contexts/module-context-index.json，判断当前模块是模块还是模块的子模块。
- 设定当前回话参数：<context-path> 为模块上下文的工作区相对路径。
- 如果传入目录是模块则判断 `.asdm/contexts/<module-name>/` 目录是否存在，如果不存在则在工作区根目录创建它, <context-path> 参数为 `.asdm/contexts/<module-name>/` 目录 。
- 如果当前需要生成的是模块的子模块的上下文，则判断 `.asdm/contexts/<module-name>/<module-name>/` 目录是否存在，如果不存在则在工作区根目录创建它，重置 <context-path> 参数为 `.asdm/contexts/<module-name>/<module-name>/` 目录。
- 以下使用 <context-path> 参数作为上下文路径。

### 2. 遵从的上下文规范
上下文生成时需要根据生成的上下文内容，遵从 `.asdm/toolsets/project-context-analysis/spec/*.md` 目录中的规范，但根据实际工作区分析进行定制。
**重要提示**：将所有规范内容翻译并适配到检测到的语言，确保所有文本、示例和解释的自然和准确的本地化。

### 3. 生成上下文文件 (index.md)
按照 <module-path> 实际内容生成如下上下文具体文件，并保存在<context-path>上下文目录中：

1. **必须**生成此类上下文文件，**<module-name>--structure.md** - 标准结构
3. **必须**生成此类上下文文件，**<module-name>-standard-coding-style.md** - 标准编码风格
4. 如果此模块下内容涉及数据模型相关内容，则生成：**<module-name>-data-models.md** - 数据模型和关系的上下文文件
5. 如果此模块下内容涉及独立部署相关内容，则生成：**<module-name>-deployment.md** - 部署配置
6. 如果此模块下内容涉及接口相关内容，则生成：**<module-name>-api.md** - API 定义和文档的上下文文件
7. 此文件只针对WORKSPACE工程内容生成，**<module-name>-architecture.md** - 架构概述

根据生成的具体上下文和  <module-path>  模块内容，生成 **index.md**：
8. **index.md** - 模块区索引和指南
   - 提供整个模块的概述
   - 包含指向其他上下文文件的导航链接（后续生成）
   - 总结工作区结构和关键组件

**重要提示**：此步骤仅生成 index.md，以避免过多的 token 使用并保持高质量生成。

### 4. 分析当前工作区
在生成上下文之前，根据当前模块内容，按实际情况分析当前工作区以了解：
- 技术栈和框架
- 项目结构和组织
- 现有代码模式和约定
- 数据模型和数据库架构
- API 端点和文档
- 部署配置和环境

### 5. 包含 Mermaid 图表
在适用的情况下，包含 mermaid 图表用于：
- 实体关系图
- 类图
- 时序图
- 部署图
- 架构图

### 7. 提供示例数据
对于 API 定义，包含示例请求/响应数据。

### 8. 链接到源代码
包含相关源代码文件的链接以便详细参考。

## 使用方法
要使用此指令，只需按照上述步骤操作。AI 模型应分析工作区并生成全面的上下文文件，这些文件可通过上下文注入供其他工具集使用。
