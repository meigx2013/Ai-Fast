# Instructions for core-asset-identify action

## Purpose

本指令指导 AI 模型分析代码库中的引用关系，识别被引用次数达到阈值（默认 3 次及以上）的类和方法作为核心代码资产。这些高引用代码通常是项目的核心资产，在进行代码重构或架构调整时需要特别关注。

## Context Injection

在执行核心资产识别之前，AI 模型应读取项目上下文：

### Context Files to Read (Optional)

1. **index.md** (推荐)
   - 路径：`.asdm/contexts/index.md`
   - 目的：了解工作区整体结构

2. **架构文档** (按需)
   - 路径：`.asdm/contexts/architecture.md`
   - 目的：了解项目的架构设计

### 渐进式上下文加载策略

为避免向 AI 模型提供过多上下文，请遵循以下渐进式读取方法：

1. **初始阶段**：仅读取 `.asdm/contexts/index.md`（如果存在）
2. **按需扩展**：根据分析需要请求额外的上下文文件

## Steps to Core Asset Identification

### 1. Receive Identification Parameters

接收用户提供的分析参数：

- **分析路径**（可选）：
  - 代码库路径（支持整个工作区或指定模块）
  - 如果用户未指定，使用当前工作区根目录

- **引用阈值**（可选）：
  - 默认值为 3 次
  - 用户可自定义阈值
  - 高于阈值的引用才被识别为核心资产

### 2. Validate Input Path

验证输入路径的有效性：

- 检查指定路径是否存在
- 如果路径不存在，尝试使用相对路径或查找匹配目录
- 确保路径指向有效的代码目录

### 3. Scan Code Files

扫描代码文件，识别所有源代码：

- 使用 `search_file` 工具查找代码文件
- 支持的文件类型：
  - JavaScript/TypeScript: `.js`, `.jsx`, `.ts`, `.tsx`
  - Python: `.py`
  - Java: `.java`
  - C#: `.cs`

### 4. Identify Class and Method Definitions

识别代码中的类和方法定义：

对于每种编程语言，使用相应的模式识别定义：

**JavaScript/TypeScript**:
```javascript
class ClassName { }           // 类定义
function functionName() { }   // 函数定义
const methodName = () => { }  // 箭头函数
methodName = () => { }        // 对象方法
```

**Python**:
```python
class ClassName:              # 类定义
def function_name():          # 函数定义
```

**Java/C#**:
```java
public class ClassName { }    // 类定义
public void methodName() { }  // 方法定义
```

### 5. Track References

追踪代码中的引用关系：

对于每个识别到的类/方法，统计其在代码库中被引用的次数：

**引用识别模式**：

- **类引用**：`new ClassName()`、`import ClassName`、`ClassName.method()`
- **方法引用**：`functionName()`、`obj.methodName()`、`module.functionName()`

**统计规则**：
- 同一个文件内的引用计入
- 不同文件间的引用计入
- 注释中的引用不计入（除非明确要求）

### 6. Filter by Threshold

根据阈值过滤核心资产：

- 筛选引用次数 >= 阈值的所有类/方法
- 默认阈值为 3 次
- 按引用次数降序排列

### 7. Collect Asset Details

收集每个核心资产的详细信息：

对于每个核心资产，记录：

- **名称**：类名或方法名
- **类型**：类或方法
- **引用次数**：在代码库中被引用的总次数
- **定义位置**：首次定义的完整文件路径
- **引用位置**：列出所有引用该资产的代码位置
- **所属模块**：根据路径推断所属功能模块

### 8. Analyze Dependency Relationships

分析核心资产之间的依赖关系：

- 识别核心资产之间的相互引用
- 发现潜在的耦合问题
- 识别循环依赖（如果有）

### 9. Generate Markdown Report

生成 Markdown 格式的核心资产报告：

报告应包含以下部分：

```markdown
# 核心资产识别报告

**分析路径**：[路径]
**引用阈值**：>= [N] 次
**分析时间**：[时间戳]

## 统计概览

| 指标 | 数值 |
|------|------|
| 核心类数量 | X |
| 核心方法数量 | X |
| 总引用次数 | X |

## 高引用类（>= N 次引用）

| 类名 | 引用次数 | 定义位置 | 所属模块 |
|------|----------|----------|----------|
| ClassName | 15 | path/to/File.java | 用户模块 |
| ... | ... | ... | ... |

## 高引用方法（>= N 次引用）

| 方法名 | 引用次数 | 定义位置 | 所属模块 |
|--------|----------|----------|----------|
| methodName | 12 | path/to/File.js | 工具模块 |
| ... | ... | ... | ... |

## 依赖关系分析

### 核心依赖图

[核心资产间的依赖关系描述]

### 耦合风险

[潜在的耦合问题和循环依赖]
```

### 10. Save Report

保存分析报告到指定目录：

- **报告路径**：`.asdm/workspace/code-analyzer/analysis-reports/core-assets/<timestamp>-core-assets.md`
- 如果目录不存在，先创建目录结构
- 确保文件保存成功

### 11. Display Summary to User

向用户展示分析结果摘要：

- 报告保存位置
- 识别的核心类数量和方法数量
- 引用次数最高的资产
- 潜在的耦合风险提示

## Execution Guidelines

### When to Use This Action

在以下情况下使用此动作：

- 识别代码库核心依赖，避免破坏性修改
- 重构前评估影响范围
- 发现潜在的耦合问题和循环依赖
- 确定代码库中需要重点保护的资产

### Identification Guidelines

识别核心资产时：

- 优先识别公共类和导出函数
- 注意区分定义和引用
- 考虑继承层次中的父类引用
- 识别工具类和辅助函数的高频使用

### Analysis Guidelines

分析依赖关系时：

- 识别单向依赖和双向依赖
- 发现循环依赖并警告
- 评估模块间的耦合度
- 建议合理的依赖方向

## Usage

使用本指令，AI 模型应：

1. 检测响应语言（中文）
2. 接收用户提供的分析路径和阈值参数
3. 读取项目上下文（如有）
4. 验证输入路径有效性
5. 扫描并识别所有代码文件
6. 识别类和方法定义
7. 追踪并统计引用关系
8. 根据阈值过滤核心资产
9. 分析依赖关系
10. 生成并保存报告
11. 向用户展示分析结果摘要

## Output Summary

完成分析后，将生成以下内容：

- **核心资产报告**：Markdown 格式，包含资产列表和依赖分析
- **保存位置**：`.asdm/workspace/code-analyzer/analysis-reports/core-assets/`

### 报告内容

报告包含：

- 分析概览（时间、路径、阈值、统计）
- 高引用类列表（按引用次数排序）
- 高引用方法列表（按引用次数排序）
- 依赖关系分析和耦合风险提示

### 示例输出

```
# 核心资产识别报告

**分析路径**：./src
**引用阈值**：>= 3 次
**分析时间**：2026-04-09 10:14:30

## 统计概览

| 指标 | 数值 |
|------|------|
| 核心类数量 | 8 |
| 核心方法数量 | 15 |
| 总引用次数 | 127 |

## 高引用类（>= 3 次引用）

| 类名 | 引用次数 | 定义位置 | 所属模块 |
|------|----------|----------|----------|
| UserService | 18 | auth/UserService.js | 认证模块 |
| DataStore | 15 | core/DataStore.ts | 核心模块 |
| ... | ... | ... | ... |

## 依赖关系分析

### 耦合风险

- `AuthModule` 和 `UserModule` 存在循环依赖
- `DataStore` 被所有模块高频引用，是关键依赖点
```

## Error Handling

### Error 1: Path Not Found

如果指定路径不存在：
- 尝试使用相对路径
- 列出可用的子目录供用户选择
- 使用工作区根目录作为默认值

### Error 2: No Definitions Found

如果目录中没有找到类或方法定义：
- 检查文件类型是否被支持
- 提示用户确认代码文件的存在
- 降低分析深度，跳过空目录

### Error 3: Too Many Results

如果识别的核心资产过多（>100）：
- 按引用次数从高到低排序
- 分页展示结果
- 提供筛选建议（如提高阈值）

## Validation

生成报告后，验证：

- [ ] 报告文件已成功创建
- [ ] 统计数字准确无误
- [ ] 资产列表按引用次数正确排序
- [ ] 依赖分析逻辑合理
- [ ] 报告语言一致（中文）
