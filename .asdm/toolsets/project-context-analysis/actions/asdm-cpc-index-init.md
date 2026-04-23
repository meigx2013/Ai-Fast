# Instructions for asdm-cpc-index-init action (Complex Project Context)

## Purpose
此指令引导 AI 模型初始化复杂项目上下文索引，分析工作区工程结构，生成模块索引表和入口文件。cpc 是 complex project context 的简写。

## Language Detection

在生成上下文文件之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置以确定主要语言：
   - 检查系统/用户语言设置或环境配置
   - 识别项目文档和注释中使用的主要语言
   - 根据工作区上下文确定语言偏好

2. **应用语言一致性**：确保所有生成的上下文文件使用检测到的语言：
   - 所有 markdown 文件、注释和文档使用相同语言
   - 保持所有生成的上下文文件的语言一致性
   - 遵循检测到的语言的写作规范和格式

3. **支持的语言**：
   - 中文（zh）
   - 英文（en）
   - 其他语言根据环境检测需要

**重要**：语言检测是上下文生成前的第一步。所有输出必须在整个过程中一致使用检测到的语言。

## Context Injection

在执行索引初始化前，应加载以下上下文：

1. **工具集 README**（可选）
   - 路径：`.asdm/toolsets/project-context-analysis/README.md`
   - 目的：了解工具集的整体架构和用途

2. **模块索引模板**
   - 路径：`.asdm/toolsets/project-context-analysis/spec/module-index.md`
   - 目的：参考索引文件的格式和结构

## Steps to Initialize Context Index

### 1. 创建上下文目录

创建 `.asdm/contexts/` 目录（如果不存在）。

### 2. 扫描工作区结构

分析当前工作区的工程结构，识别所有模块：

1. **识别模块目录**：
   - 扫描工作区根目录下的子目录
   - 识别 Java/Maven 多模块项目中的子模块（包含 pom.xml 的目录）
   - 识别前端项目中的模块（包含 package.json 的目录）
   - 识别其他类型的模块（src 目录、独立功能模块等）

2. **排除目录**：
   - 构建产物：target/、dist/、build/、out/
   - 版本控制：.git/、.svn/
   - 依赖目录：node_modules/、.venv/
   - IDE 配置：.idea/、.vscode/、.settings/
   - 临时文件：tmp/、temp/、.tmp/
   - 隐藏目录：以 `.` 开头的目录（除了 .asdm）

### 3. 统计模块代码量

为每个识别的模块统计代码量：

1. **统计规则**：
   - 统计主要代码文件：.java、.ts、.tsx、.js、.jsx、.py、.go、.xml、.yml、.yaml 等
   - 统计配置文件：.properties、.json、.toml 等
   - 排除生成的代码和第三方库

2. **统计维度**：
   - 文件数量
   - 代码行数（LOC）
   - 主要文件类型

3. **使用工具**：
   - 使用文件搜索工具（search_file）统计各类文件
   - 使用目录列表（list_dir）了解结构
   - 使用内容搜索（search_content）分析代码特征

### 4. 检查上下文生成状态

为每个模块检查上下文生成状态：

- **未生成**：`.asdm/contexts/<module-name>/` 目录不存在
- **生成中**：`.asdm/contexts/<module-name>/.building` 文件存在
- **已生成**：`.asdm/contexts/<module-name>/index.md` 文件存在

### 5. 生成模块索引数据

创建 `modules-index.json` 文件，包含以下信息：

```json
{
    "version": "1.0.0",
    "generatedAt": "2026-04-01T15:00:00Z",
    "projectName": "项目名称",
    "modules": [
        {
            "name": "模块名称",
            "path": "模块相对路径",
            "status": "未生成|生成中|已生成",
            "codeStats": {
                "totalFiles": 文件总数,
                "totalLines": 代码行总数,
                "mainFileTypes": ["主要文件类型列表"]
            },
            "contextPath": "上下文目录路径（如已生成）",
            "lastUpdated": "最后更新时间（如已生成）"
        }
    ],
    "summary": {
        "totalModules": 模块总数,
        "generated": 已生成数量,
        "pending": 未生成数量,
        "building": 生成中数量
    }
}
```

### 6. 生成入口索引文件

创建 `index.md` 文件，包含以下内容：

1. **项目概览**：
   - 项目名称和描述
   - 技术栈信息
   - 模块总数和代码量统计

2. **模块索引表**：
   - 模块名称
   - 模块路径
   - 代码量统计
   - 上下文生成状态
   - 上下文链接（如已生成）

3. **快速导航**：
   - 按模块名称排序的导航链接
   - 按模块类型分组的导航

4. **使用指南**：
   - 如何生成单个模块上下文
   - 如何批量生成上下文
   - 如何更新上下文

### 7. 输出生成摘要

向用户展示生成结果：

```
上下文索引初始化完成！

项目统计：
- 模块总数：X 个
- 已生成上下文：Y 个
- 未生成上下文：Z 个
- 总代码量：N 行

已生成的文件：
- .asdm/contexts/index.md
- .asdm/contexts/modules-index.json

下一步操作：
- 运行 /asdm-cpc-nodule-build <模块名> 为单个模块生成上下文
- 运行 /asdm-cpc-all-build 批量生成所有模块上下文
```

## Execution Guidelines

### When to Use This Action

使用此操作当：

- 首次在项目中进行上下文管理
- 项目结构发生变化（新增或删除模块）
- 需要查看所有模块的上下文生成状态
- 需要更新模块索引信息

### Module Recognition Guidelines

模块识别规则：

1. **Java/Maven 项目**：
   - 查找根 pom.xml 中的 `<modules>` 定义
   - 识别包含子 pom.xml 的目录作为模块
   - 排除 parent pom 所在的根目录

2. **前端项目**：
   - 识别 monorepo 结构中的 packages/* 目录
   - 识别包含独立 package.json 的目录
   - 排除公共依赖目录

3. **其他项目**：
   - 识别具有独立功能的目录
   - 参考项目的模块化设计
   - 根据目录命名约定判断

### Code Statistics Guidelines

代码统计建议：

- 使用近似统计，避免精确计数造成性能问题
- 重点统计源代码文件，忽略配置和文档文件
- 提供按文件类型的统计分布
- 对于大型文件，可以使用采样统计

### Error Handling

错误处理：

- 如果无法识别模块，使用目录名称作为模块名
- 如果统计失败，标记为 "未知" 并继续
- 如果文件写入失败，报告错误并提供解决方案

## Usage

要使用此指令，AI 模型应该：

1. 检测响应语言
2. 创建上下文目录
3. 扫描工作区识别模块
4. 统计各模块代码量
5. 检查上下文生成状态
6. 生成 modules-index.json 文件
7. 生成 index.md 入口文件
8. 输出生成摘要

## Output Summary

完成此操作后，将生成以下文件：

- `.asdm/contexts/index.md` - 项目上下文入口索引
- `.asdm/contexts/modules-index.json` - 模块索引数据文件

这些文件为后续的模块上下文生成提供基础数据支持。
