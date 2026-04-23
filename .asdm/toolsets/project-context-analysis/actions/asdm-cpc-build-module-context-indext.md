# Instructions for asdm-cpc-build-module-context-index (Complex Project Context)

## Purpose
此指令用于根据已生成的模块索引文件，创建模块上下文索引文件，并根据模块复杂度决定是否需要细化到子目录级别。

**说明** cpc 是 complex project context 的简写。

**重要优化**：为了减少主会话的上下文占用，具体的子模块上下文索引创建操作由专门的 subagent 异步执行。本命令负责调度和汇总结果。

## Language Detection

在生成上下文索引之前，必须检测并使用当前环境的响应语言：

1. **检测响应语言**：分析环境设置以确定主要语言：
   - 检查系统/用户语言设置或环境配置
   - 识别项目文档和注释中使用的主要语言
   - 根据工作区上下文确定语言偏好

2. **应用语言一致性**：确保所有生成的文件使用检测到的语言：
   - 所有 markdown 文件、注释和文档使用相同语言
   - 保持所有生成的上下文文件的语言一致性
   - 遵循检测到的语言的写作规范和格式

3. **支持的语言**：
   - 中文（zh）
   - 英文（en）
   - 其他语言根据环境检测需要

**重要**：语言检测是上下文生成前的第一步。所有输出必须在整个过程中一致使用检测到的语言。

## Command Parameters

### 输入参数

此命令需要以下输入参数：

1. **module-index 文件路径**（必需）
   - 参数名：`<module-index>`
   - 类型：文件路径
   - 说明：已生成的模块索引 JSON 文件路径
   - 示例：`.asdm/contexts/modules-index.json`
   - 验证：文件必须存在且为有效的 JSON 格式

### 输出结果

命令执行完成后将生成：

1. **module-context-index.json 文件**
   - 位置：与 `<module-index>` 文件相同目录
   - 文件名：`module-context-index.json`
   - 内容：包含模块及其子模块的上下文索引信息
   - 格式：JSON

## Execution Steps

### 1. 验证输入文件并读取模块列表

验证 module-index 文件的有效性：

1. **检查文件存在性**：
   - 使用 `read_file` 读取指定的 `<module-index>` 文件
   - 如果文件不存在，返回错误提示并退出

2. **验证 JSON 格式**：
   - 解析 JSON 内容
   - 验证必需字段是否存在（modules, summary 等）
   - 如果格式错误，返回详细错误信息

3. **提取模块列表**：
   - 从 JSON 中提取所有模块信息
   - 记录模块名称和路径
   - 统计待处理模块数量

**错误处理示例**：

```
错误：无法找到模块索引文件
路径：.asdm/contexts/modules-index.json
建议：请先运行模块索引生成命令创建索引文件
```

### 2. 依次调用 Subagent 处理每个模块

**重要**：为避免并发问题并确保主会话能够及时更新 module-context-index.json，必须依次（串行）调用 subagent。

#### 2.1 初始化 module-context-index.json

在调用任何 subagent 之前，先创建初始的 module-context-index.json 文件：

1. **复制原始数据**：
   - 以 `<module-index>` 文件的完整内容作为初始值
   - 保持原有的 JSON 结构和数据

2. **添加初始字段**：
   - 为每个模块添加空的 `sub-modules` 数组
   - 初始化 `complexityScore` 为 0
   - 初始化 `needBreakdown` 为 false

3. **保存初始文件**：
   - 使用 `write_to_file` 保存到与 `<module-index>` 相同目录
   - 文件名：`module-context-index.json`

#### 2.2 串行调用 Subagent

**执行流程**（必须串行执行，依次启动每个 subagent）：

**重要原则**：
- **必须依次启动**：不是一次性启动所有子模块的上下文分析，而是先启动第一个，等第一个 subagent 执行完成并返回结果后，再执行第二个
- **串行处理**：确保每个 subagent 完全执行完成后，再启动下一个

**具体执行步骤**：

1. **显示启动提示**：
   ```
   现在向团队成员发送处理任务
   ```

2. **启动第一个模块的 Subagent**：
   - 显示：`使用执行工具:Task`
   - 使用 `Task` 工具调用 `asdm-subagent-build-submodule-context-index` subagent
   - 将当前模块的json数据作为传递参数：
     ```json
     {
         "name": "模块名称",
         "path": "模块相对路径",
         "codeStats": {
               "totalFiles": 模块文件数量,
               "totalLines": 模块代码行数,
               "mainFileTypes": ["主要技术栈"]
         }
      }
     ```
   - **等待 subagent 执行完成并返回结果**

3. **处理第一个 Subagent 的返回结果**：
   a. **读取当前的 module-context-index.json**：
      - 使用 `read_file` 读取最新的文件内容

   b. **更新对应模块的信息**：
      - 根据返回的 `moduleName` 找到对应模块
      - 更新模块的 `codeStats`（重新计算的统计数据）
      - 更新模块的 `complexityScore`（复杂度评分）
      - 更新模块的 `needBreakdown` 标志
      - 更新模块的 `sub-modules` 数组（子模块信息）
      - 每个子模块信息包括：子模块名称，子模块相对路径（WORKSPACE相对路径），描述，代码状态，文件夹深度等。

   c. **保存更新后的文件**：
      - 使用 `write_to_file` 将信息写入到生成的**module-context-index.json**文件中
      - 保持 JSON 格式化（缩进 4 空格）

4. **继续处理下一个模块**：
   - 显示：`使用执行工具:Task`
   - 启动下一个模块的 subagent
   - 传递参数（使用下一个模块的信息）
   - **等待 subagent 执行完成并返回结果**
   - 重复步骤 3 处理返回结果

5. **重复直到所有模块处理完成**：
   - 按照模块列表顺序，依次处理每个模块
   - 每次只启动一个 subagent
   - 每次都等待当前 subagent 完成后再启动下一个

#### 2.3 执行示例

```
模块列表：[aise-api, aise-auth, aise-common, aise-gateway, aise-manager, aise-modules, aise-ui]

串行执行顺序：
1. 显示：现在向团队成员发送处理任务
2. 显示：使用执行工具:Task
3. 启动 subagent 处理 aise-api
4. 等待 aise-api 的 subagent 执行完成并返回结果
5. 更新 module-context-index.json（更新 aise-api 模块信息）
6. 显示：使用执行工具:Task
7. 启动 subagent 处理 aise-auth
8. 等待 aise-auth 的 subagent 执行完成并返回结果
9. 更新 module-context-index.json（更新 aise-auth 模块信息）
10. 显示：使用执行工具:Task
11. 启动 subagent 处理 aise-common
12. 等待 aise-common 的 subagent 执行完成并返回结果
13. 更新 module-context-index.json（更新 aise-common 模块信息）
14. ... 按照相同模式依次处理剩余模块（aise-gateway, aise-manager, aise-modules, aise-ui）

关键点：
- 每次只启动一个 subagent
- 必须等待当前 subagent 完全执行完成并返回结果
- 处理完返回结果后，再启动下一个 subagent
- 不允许并发启动多个 subagent
```

#### 2.4 结果验证

每次更新文件后，验证以下内容：

1. **JSON 格式正确**：确保文件可以正常解析
2. **模块信息完整**：确保所有字段都已更新
3. **数据一致性**：确保统计数据和子模块信息匹配

### 3. 最终汇总统计信息

在所有模块处理完成后，进行最终的统计信息汇总：

1. **读取完整的 module-context-index.json**：
   - 使用 `read_file` 读取包含所有模块更新信息的文件

2. **重新计算汇总统计**：
   - 统计总分 >= 50 的模块数量（需要细化的模块）
   - 统计总分 < 50 的模块数量（不需要细化的模块）
   - 统计所有模块的总文件数和总代码行数
   - 统计所有子模块的总数

3. **更新 summary 字段**：
   ```json
   {
       "summary": {
           "totalModules": 模块总数,
           "generated": 已创建上下文模块数量,
           "pending": 未创建上下文模块数量,
           "building": 创建中上下文模块数量,
           "totalCodeLines": 工作区代码总行数,
           "totalFiles": 工作区总代码文件数,
           "breakdownModules": 需要细化的模块数量（总分 >= 50）
       }
   }
   ```

4. **保存最终的 JSON 文件**：
   - 使用 `write_to_file` 保存最终的统计信息
   - 保持 JSON 格式化（缩进 4 空格）

## Subagent 工作流程说明

### 串行执行优势

使用串行 subagent 的优势：

1. **减少主会话上下文占用**：
   - 每个模块的分析在独立会话中完成
   - 主会话只需要处理当前模块的结果

2. **避免并发写入冲突**：
   - 确保每次只有一个 subagent 在处理
   - 主会话可以安全地更新 module-context-index.json

3. **隔离错误**：
   - 单个模块处理失败不影响其他模块
   - 更容易定位和修复问题
   - 可以在处理每个模块后进行验证

## Error Handling

### 常见错误及处理

1. **输入文件不存在**：
   ```
   错误：模块索引文件不存在
   路径：<指定路径>
   建议：请先运行模块索引生成命令
   ```

2. **JSON 格式错误**：
   ```
   错误：模块索引文件格式无效
   路径：<文件路径>
   详情：<错误详情>
   建议：请检查 JSON 格式是否正确
   ```

3. **模块路径不存在**：
   ```
   警告：模块路径不存在，跳过处理
   模块：<模块名>
   路径：<模块路径>
   ```

4. **权限不足**：
   ```
   错误：无法访问目录
   路径：<目录路径>
   建议：请检查文件系统权限
   ```

## Next Steps

生成 module-context-index.json 后，可以：

1. **查看索引信息**：
   - 打开 module-context-index.json 文件
   - 查看模块复杂度评估结果
   - 了解子模块分布

2. **生成模块上下文**：
   - 运行 `/asdm-module-context-build` 命令
   - 为每个模块（或子模块）生成详细上下文
   - 基于 module-context-index.json 的细化信息

3. **调整细化策略**：
   - 根据复杂度评估结果
   - 手动调整 sub-modules 配置
   - 优化上下文生成粒度
