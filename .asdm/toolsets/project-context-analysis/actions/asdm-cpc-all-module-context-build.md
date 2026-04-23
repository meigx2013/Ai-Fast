# Instructions for asdm-cpc-all-module-context-build action

**说明**：`cpc` 是 `Complex Project Context` 的简写，用于复杂项目的上下文批量构建。

## Purpose
此指令引导 AI 模型批量为所有模块生成上下文，支持选择性生成、进度跟踪和错误恢复。

## Language Detection

在生成上下文文件之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置以确定主要语言
2. **应用语言一致性**：确保所有生成的上下文文件使用检测到的语言

**重要**：语言检测是上下文生成前的第一步，所有输出必须一致使用检测到的语言。

## Context Injection

在执行全量上下文构建前，应加载以下上下文：

1. **模块上下文索引数据**（必需）
   - 路径：`.asdm/contexts/module-context-index.json`
   - 目的：获取所有模块信息和生成状态

3. **SubAgent 构建指令**（必需）
   - SubAgent 名称：asdm-module-context-build
   - 目的：调用单个模块上下文构建流程

## Steps to Build Full Context

### 1. 加载模块索引

分析.asdm/contexts/module-context-index.json中模块上下文索引数据：

**分析内容**：
- 获取所有模块列表

**状态定义**：
- `已生成`：模块上下文已生成，包含上下文路径列表
- `未生成`：尚未生成上下文
- `生成中`：正在生成上下文（检测到 `.building` 标记文件）

### 2. 确定生成策略

根据参数确定生成范围和执行顺序：

#### 参数选项

**默认模式**（skip-generated）：只生成未生成的模块


**全量模式**（all）：重新生成所有模块的上下文
```bash
/asdm-cpc-all-module-context-build all
```

**选择模式**（selective）：交互式选择要生成的模块
```bash
/asdm-cpc-all-module-context-build selective
```

#### 执行顺序

按.asdm/contexts/module-context-index.json中的模块顺序执行，如果模块中包含子模块，则先调asdm-module-context-build用生成子模块上下文，再调用asdm-module-context-build生成当前模块上下文。

### 3. 批量生成模块上下文

如果当前模块的上下文生成状态不是**已生成**，则依次调用 SubAgent `asdm-module-context-build` 进行模块的上下文分析。

**重要**：必须**顺序执行**，每个模块分析完成后再处理下一个模块，不能并行处理。

#### 调用接口规范

**调用方式**：
```
使用 Task 工具调用 SubAgent
SubAgent 名称：asdm-module-context-build
```

**传递参数**：
- 模块名称：`<module-name>`
- 模块路径：`<module-path>`
- 是否为子模块：true/false

**期望返回**：
- 模块名称
- 模块路径
- 模块上下文路径列表
- 模块上下文所在相对目录
- 处理状态（成功/失败）
- 错误信息（如果失败）

### 4. 最终汇总和报告

完成所有模块生成后进行最终汇总。

**注意**：模块上下文索引文件 `module-context-index.json` 已在每个模块处理完成后实时更新，此步骤仅需输出最终报告。

#### 验证更新结果

确认 `module-context-index.json` 已包含所有已处理模块的信息：
- 模块名称和路径
- 模块上下文路径列表
- 处理状态
- 生成时间

### 5. 输出生成报告

输出完整的生成摘要报告：

```
========================================
批量上下文生成完成！
========================================

生成统计：
- 总模块数：<总数> 个
- 成功生成：<X> 个
- 生成失败：<Y> 个
- 跳过模块：<Z> 个（已生成）
- 总耗时：<N> 分 <M> 秒

成功生成的模块：
✓ <module-1> (<代码行数> 行, <耗时>)
✓ <module-2> (<代码行数> 行, <耗时>)
✓ <module-3> (<代码行数> 行, <耗时>)
...

失败的模块：
✗ <module-name> - 错误：<错误信息>
...

生成的文件：
- .asdm/contexts/<module-name>/* (各模块上下文)

下一步操作：
- 查看模块索引：查看 .asdm/contexts/module-context-index.json
- 查看模块详情：查看各模块的上下文文件
- 重试失败模块：重新运行此指令
- 查看错误日志：打开 .asdm/contexts/.build-errors.log
```