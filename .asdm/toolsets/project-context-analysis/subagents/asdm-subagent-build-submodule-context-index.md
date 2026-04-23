---
name: asdm-subagent-build-submodule-context-index
description: 用于独立生成子模块的上下文创建索引
model: auto
tools: list_dir, search_file, search_content, read_file, read_lints, replace_in_file, write_to_file, execute_command, mcp_get_tool_description, mcp_call_tool, delete_file, preview_url, web_fetch, use_skill, web_search, automation_update
agentMode: agentic
enabled: true
enabledAutoRun: true
---

# Instructions for asdm-subagent-build-submodule-context-index (Complex Project Context)

## Purpose
此指令用于根据已生成的模块索引文件，创建模块上下文索引文件，并根据模块复杂度决定是否需要细化到子目录级别。

**说明** cpc 是 complex project context 的简写。

## SubAgent输入输出

### 输入参数

调用此 SubAgent 时，需要传递以下参数：

1. **Module Json**（必需）
   - 参数名：`<module-json>`
   - 类型：JSON
   - 说明：需要细化索引的模块信息
   - 根据输入解析当前模块的相对路径 <module-path> ，后续根据此参数进行模块复杂度及子模块分析。

   ```json
   {
      "name": "模块名称",
      "path": "模块工作区相对路径",
      "description": "模块业务功能描述",
      "status": "未生成",
      "codeStats": {
         "totalFiles": 0,
         "totalLines": 0,
         "mainFileTypes": ["技术栈"]
      }
   }
   ```

### 输出结果

**重要说明**：SubAgent **不会直接写入文件**，而是将所有结果返回给主会话，由主会话负责更新 module-context-index.json 文件。

SubAgent 执行完成后，必须将以下信息返回给**主会话**：

1. **模块名称**：处理的模块名称
2. **模块路径**：模块的相对路径
3. **复杂度评分**：
   - 总分
   - 是否需要细化（needBreakdown）
4. **子模块信息**（如果需要细化）：
   - 子模块名称列表
   - 每个子模块的路径
   - 子模块文件数量 totalFiles
   - 子模块代码行数 totalLines
   - 主要文件类型（mainFileTypes）
5. **处理状态**：
   - 成功/失败
   - 错误信息（如果失败）

**重要说明**：SubAgent 在执行时必须重新计算子模块的文件数量和代码行数，不能直接使用 传入的JSON 中的模块数据进行主观判断，确保子模块统计数据准确。


## 执行步骤

### 1. 验证输入参数并初始化

验证输入参数的有效性：

1. **读取输入的模块JSON信息**：
   - 解析 JSON 内容
   - 提取当前模块的基本信息

2. **初始化输出数据结构**：
   - 准备存储模块统计数据的数据结构
   - 准备存储子模块信息的数组

### 2. 统计子模块代码量和文件数量

为每个识别的子模块的统计代码量：

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

4. **记录子模块统计内容**

### 2. 模块复杂度评估

根据输入的JSON对当前模块进行复杂度评估：

#### 复杂度评估建议

1. **保守策略**：
   - 总分阈值设置为 55
   - 优先处理高复杂度模块
   - 避免过度细化

2. **激进策略**：
   - 总分阈值设置为 45
   - 尽可能细化所有模块
   - 生成详细的子模块信息

3. **平衡策略**（默认）：
   - 总分阈值设置为 50
   - 细化中等和高复杂度模块
   - 平衡效率和详细程度


#### 复杂度评分标准

设计多维度复杂度评分系统（总分 100 分）：

```json
{
    "complexityScore": {
        "fileCount": {
            "weight": 25,
            "thresholds": {
                "small": 50,
                "medium": 100,
                "large": 200,
                "huge": 500
            },
            "scores": {
                "small": 10,
                "medium": 20,
                "large": 25,
                "huge": 30
            }
        },
        "codeLines": {
            "weight": 45,
            "thresholds": {
                "small": 10000,
                "medium": 20000,
                "large": 30000,
                "huge": 50000
            },
            "scores": {
                "small": 10,
                "medium": 20,
                "large": 25,
                "huge": 30
            }
        },
        "contentType": {
            "weight": 10,
            "types": {
                "single": 5,
                "mixed": 10,
                "diverse": 15,
                "complex": 20
            }
        },
        "directoryDepth": {
            "weight": 10,
            "description": "基于分支复杂度而非简单深度，避免Java标准目录结构误判",
            "calculation": {
                "method": "branchFactor",
                "description": "计算平均分支因子，忽略单分支路径（如 src/main/java）"
            },
            "thresholds": {
                "simple": 1.5,
                "moderate": 2.5,
                "complex": 3.5
            },
            "scores": {
                "simple": 3,
                "moderate": 7,
                "complex": 10
            }
        },
        "moduleType": {
            "weight": 10,
            "types": {
                "infrastructure": 3,
                "api": 5,
                "service": 7,
                "frontend": 10,
                "aggregation": 10
            }
        }
    }
}
```

#### 评分计算方法

1. **文件数量评分**（30分）：
   ```
   small (< 20 files): 10分
   medium (20-50 files): 20分
   large (50-100 files): 25分
   huge (> 100 files): 30分
   ```

2. **代码行数评分**（30分）：
   ```
   small (< 5000 lines): 10分
   medium (5000-15000 lines): 20分
   large (15000-30000 lines): 25分
   huge (> 30000 lines): 30分
   ```

3. **内容类型评分**（20分）：
   ```
   single: 单一技术栈（如纯Java） - 5分
   mixed: 混合技术（如Java + XML） - 10分
   diverse: 多种技术（如Java + XML + YML） - 15分
   complex: 复杂混合（前端 + 配置 + 脚本） - 20分
   ```

4. **目录分支复杂度评分**（10分）：
   ```
   计算方法：
   - 遍历模块目录树，统计每个非叶子目录的子目录数量
   - 计算平均分支因子 = 所有非叶子目录的子目录数之和 / 非叶子目录总数
   - 忽略单分支路径（只有一个子目录的目录）
   
   评分标准：
   simple (平均分支因子 ≤ 1.5): 3分 - 结构简单，多为单分支
   moderate (平均分支因子 1.5-2.5): 7分 - 结构中等，部分多分支
   complex (平均分支因子 > 2.5): 10分 - 结构复杂，大量多分支
   
   示例：
   - Java标准结构 src/main/java/org/apache/fineract: 平均分支因子 = 1.0, 评分 3分
   - 多模块项目 aise-common/(core,security,log...): 平均分支因子 = 3.0, 评分 10分
   ```

5. **模块类型评分**（10分）：
   ```
   infrastructure: 基础设施 - 3分
   api: API接口 - 5分
   service: 业务服务 - 7分
   frontend: 前端应用 - 10分
   aggregation: 聚合模块 - 10分
   ```

#### 目录分支复杂度计算详解

**计算步骤**：

1. **遍历目录树**：
   - 使用 `list_dir` 递归遍历模块目录
   - 记录每个目录的子目录数量（不包括文件）
   - 过滤掉隐藏目录和配置目录

2. **计算分支因子**：
   ```
   对于每个非叶子目录：
   - 统计直接子目录数量（不包括孙子目录）
   - 记录子目录数 = count(subdirectories)
   
   平均分支因子 = Σ(每个非叶子目录的子目录数) / 非叶子目录总数
   ```

3. **处理特殊情况**：
   - **单分支路径**：如果目录只有一个子目录，视为"传递性"路径，不影响复杂度
   - **多分支路径**：如果目录有多个子目录，视为"决策点"，增加复杂度
   - **忽略的目录**：target, build, node_modules, .git, test, tests 等

4. **示例计算**：

   **示例1：Java标准结构**
   ```
   aise-auth/
   ├── src/                    (1个子目录: main)
   │   └── main/              (1个子目录: java)
   │       └── java/          (1个子目录: com)
   │           └── com/       (1个子目录: leaniss)
   │               └── leaniss/ (1个子目录: auth)
   │                   └── auth/ (多个子目录: controller, service...)
   
   非叶子目录数: 6
   子目录总数: 6
   平均分支因子: 6/6 = 1.0
   评分: 3分 (simple)
   ```

   **示例2：多模块项目**
   ```
   aise-common/
   ├── aise-common-core/      (有子目录)
   ├── aise-common-security/  (有子目录)
   ├── aise-common-log/       (有子目录)
   ├── aise-common-redis/     (有子目录)
   └── ... (共8个子模块)
   
   非叶子目录数: 1 (根目录)
   子目录总数: 8
   平均分支因子: 8/1 = 8.0
   评分: 10分 (complex)
   ```

   **示例3：前端项目**
   ```
   aise-ui/src/
   ├── views/        (有子目录)
   ├── components/   (有子目录)
   ├── api/          (有子目录)
   ├── layout/       (有子目录)
   ├── utils/        (有子目录)
   ├── store/        (有子目录)
   └── assets/       (有子目录)
   
   非叶子目录数: 1 (src目录)
   子目录总数: 7
   平均分支因子: 7/1 = 7.0
   评分: 10分 (complex)
   ```

#### 复杂度判断阈值

根据总分判断是否需要细化：

- **总分 < 50分**：低复杂度，不需要遍历子目录
- **总分 50-70分**：中等复杂度，建议遍历主要子目录
- **总分 > 70分**：高复杂度，必须遍历所有子目录

**重要原则**：
- 分解的目的在于更好地组织和管理复杂性
- 如果识别出的子模块数量 ≤ 1，则不应进行分解
- 单一子模块的分解没有实际意义，表明模块结构相对简单

### 3. 遍历子目录

根据复杂度评估结果，遍历 <module-path> 模块的子目录：

#### 低复杂度模块（总分 < 40）

处理策略：
- 不遍历子目录
- 保持原有模块结构
- sub-modules 字段为空数组

#### 中等复杂度模块（总分 40-60）

处理策略：
- 遍历第一层子目录
- 只统计主要功能目录
- 忽略配置目录和测试目录

遍历步骤：
1. 使用 `list_dir` 列出模块根目录
2. 过滤出代码目录（排除：test, tests, config, resources 等）
3. 使用 `search_file` 统计每个子目录的文件数量
4. 将符合条件的子目录添加到 sub-modules

#### 高复杂度模块（总分 > 60）

处理策略：
- 递归遍历所有子目录
- 统计每个子目录的详细信息
- 构建完整的子模块树

遍历步骤：
1. 使用 `search_file` 递归搜索所有代码文件
2. 分析文件路径，提取目录结构
3. 统计每个目录的文件数和代码量
4. 构建子模块层级关系

#### 子目录过滤规则

在遍历子目录时，应忽略以下目录：

**配置和资源目录**：
- config, configuration, conf
- resources, static, public
- test, tests, __tests__
- docs, documentation

**构建和工具目录**：
- build, dist, target
- node_modules, vendor
- .git, .svn, .idea

**其他**：
- 目录名以点开头的隐藏目录
- 空目录

### 4. 生成子模块信息

为每个需要细化的模块生成子模块信息：

#### 子模块数据结构

```json
{
    "sub-modules": [
        {
            "name": "子模块名称",
            "relativePath": "针对当前工作区的完整相对路径",
            "description": "功能描述",
            "codeStats": {
                "totalFiles": 0,
                "totalLines": 0,
                "mainFileTypes": []
            },
            "complexityScore": 0,
            "needBreakdown": true,
            "contentType": "内容类型",
            "depth": 文件目录相对深度
        }
    ]
}
```

#### 子模块信息提取

1. **提取子模块名称**：
   - 从目录名生成子模块名称
   - 规范化命名（如：src/main/java -> java-source）

2. **统计代码信息**：
   - 使用 `search_file` 查找代码文件
   - 统计文件数量
   - 估算代码行数（可选）

3. **识别内容类型**：
   - 根据文件扩展名判断
   - 标记主要技术栈

4. **计算目录深度**：
   - 相对于模块根目录的深度
   - 用于后续上下文生成

### 5. 构建返回结果

**重要**：SubAgent 不直接写入文件，而是将处理结果构建为返回数据结构，由主会话负责更新 module-context-index.json 文件。

1. **构建返回数据结构**：
   ```json
   {
       "moduleName": "模块名称",
       "modulePath": "模块路径",
       "codeStats": {
           "totalFiles": 实际文件数量,
           "totalLines": 实际代码行数,
           "mainFileTypes": ["文件类型列表"]
       },
       "complexityScore": {
           "totalScore": 复杂度总分,
           "details": {
               "fileCountScore": 文件数量评分,
               "codeLinesScore": 代码行数评分,
               "contentTypeScore": 内容类型评分,
               "directoryDepthScore": 目录分支复杂度评分,
               "moduleTypeScore": 模块类型评分
           }
       },
       "needBreakdown": true/false,
       "subModules": [
           {
            "name": "子模块名称",
            "relativePath": "针对当前工作区的相对路径",
            "description": "功能描述",
            "codeStats": {
                "totalFiles": 子模块文件总数,
                "totalLines": 子模块子模块代码行数,
                "mainFileTypes": []
            },
            "complexityScore": 0,
            "needBreakdown": true,
            "contentType": "内容类型",
            "depth": 文件目录相对深度
         }
       ],
       "status": "success/failed",
       "errorMessage": "错误信息（如果失败）"
   }
   ```

2. **返回给主会话**：
   - 使用会话输出将完整的 JSON 数据返回给主会话
   - 主会话将根据 moduleName 更新对应的模块信息
   - 主会话负责写入 module-context-index.json 文件


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

## 返回结果给主会话

**重要**：SubAgent 执行完成后，**不会写入任何文件**，而是将所有结果返回给主会话。主会话将负责更新 module-context-index.json 文件。

### 返回数据结构

```json
{
    "moduleName": "模块名称",
    "modulePath": "模块路径",
    "codeStats": {
        "totalFiles": 实际文件数量,
        "totalLines": 实际代码行数,
        "mainFileTypes": ["文件类型列表"]
    },
    "complexityScore": {
        "totalScore": 复杂度总分,
        "details": {
            "fileCountScore": 文件数量评分,
            "codeLinesScore": 代码行数评分,
            "contentTypeScore": 内容类型评分,
            "directoryDepthScore": 目录分支复杂度评分,
            "moduleTypeScore": 模块类型评分
        }
    },
    "needBreakdown": true/false,
    "subModules": [
        {
            "sm-name": "子模块名称",
            "relativePath": "子模块相对路径",
            "description": "子模块描述",
            "codeStats": {
                "totalFiles": 子模块文件数,
                "totalLines": 子模块代码行数
            },
            "depth": 子模块深度
        }
    ],
    "status": "success/failed",
    "errorMessage": "错误信息（如果失败）"
}
```

### 返回方式

使用会话输出将完整的 JSON 数据返回给主会话。主会话将：

1. 接收 SubAgent 的返回结果
2. 读取当前的 module-context-index.json 文件
3. 根据 moduleName 更新对应模块的信息
4. 保存更新后的 module-context-index.json 文件

**注意**：SubAgent 不应使用 `write_to_file` 或 `replace_in_file` 工具直接修改 module-context-index.json 文件。所有文件更新操作由主会话负责。
