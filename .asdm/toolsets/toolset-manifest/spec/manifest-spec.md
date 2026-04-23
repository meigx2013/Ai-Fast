# Manifest JSON 规范说明

## 语言指南

本规范定义的 manifest.json 格式适用于多语言环境。确保生成的文件内容遵循以下原则：

1. **语言一致性**：manifest.json 中的文本内容应与工具集 README.md 保持一致的语言
2. **清晰描述**：所有字段值应清晰、准确、易于理解
3. **编码规范**：使用 UTF-8 编码

**支持语言**：
- 英文 (en)
- 中文 (zh)
- 其他基于环境检测的语言

---

## 概述

本规范定义了 ASDM 工具集 manifest.json 文件的结构和字段要求。此类文件用于描述工具集的基本信息，使 ASDM 系统能够正确识别和管理工具集。

**主要用途**：
- 工具集元数据声明
- 工具集识别和分类
- 命令列表管理
- 工具集安装和注册

---

## Document Structure

生成 manifest.json 时使用以下结构：

```json
{
  "registry_id": "<toolset-id>",
  "name": "<toolset-name>",
  "description": "<toolset-description>",
  "scenario": "<toolset-scenario>",
  "version": "<version>",
  "configType": "toolset",
  "commands": ["<action-name-1>", "<action-name-2>", "..."]
}
```

**关键元素**：
- registry_id: 工具集唯一标识符（注册ID）
- name: 工具集显示名称
- description: 工具集功能描述
- scenario: 使用场景描述
- version: 版本号
- configType: 配置类型，固定值为 "toolset"
- commands: 可用命令列表

---

## 字段定义

### registry_id

**类型**: string
**必填**: 是

工具集唯一标识符（注册ID），用于在 ASDM 系统中唯一识别该工具集。

**格式要求**：
- 仅允许小写字母 (a-z)、数字 (0-9) 和连字符 (-)
- 不能以连字符开头或结尾
- 建议长度：2-50 个字符
- 在所有工具集中必须唯一

**示例**：
```json
"registry_id": "code-review"
"registry_id": "toolset-manifest"
```

### name

**类型**: string
**必填**: 是

工具集的显示名称，用于在用户界面中展示。

**格式要求**：
- 非空字符串
- 可以包含空格和混合大小写
- 建议长度：1-100 个字符

**示例**：
```json
"name": "Code Review Toolset"
"name": "工具集清单生成器"
```

### description

**类型**: string
**必填**: 是

工具集的功能描述，简要说明工具集的用途和功能。

**格式要求**：
- 非空字符串
- 应简洁明了（1-2 句话）
- 建议长度：10-500 个字符

**示例**：
```json
"description": "Automated code review toolset for identifying code issues and ensuring code quality."
```

### scenario

**类型**: string
**必填**: 是

工具集的使用场景，描述用户何时以及为何使用该工具集。

**格式要求**：
- 非空字符串
- 描述使用场景和目标用户
- 建议长度：10-500 个字符

**示例**：
```json
"scenario": "Code quality inspection, code review and optimization suggestions."
```

### version

**类型**: string
**必填**: 是

工具集的语义化版本号。

**格式要求**：
- 必须遵循语义化版本规范 (MAJOR.MINOR.PATCH)
- 示例：0.0.1, 1.0.0, 2.1.3

**版本号规则**：
- MAJOR：主版本号，不兼容的 API 变更
- MINOR：次版本号，向后兼容的功能新增
- PATCH：补丁版本号，向后兼容的问题修复

### commands

**类型**: array[string]
**必填**: 是

工具集可用的命令列表，从 actions/ 目录中的文件名提取。

**格式要求**：
- 非空数组
- 每个元素为有效的 action 标识符
- 派生自 action 文件名（不含 .md 扩展名）

**示例**：
```json
"commands": ["asdm-generate-manifest", "asdm-validate-manifest"]
```

### configType

**类型**: string
**必填**: 是

配置类型标识，固定值为 "toolset"。

**格式要求**：
- 必须为字符串 "toolset"
- 用于标识此 manifest 为工具集配置

**示例**：
```json
"configType": "toolset"
```

---

## Section Guidelines

### 字段验证规则

#### registry_id 验证

```javascript
// 验证规则
const validateRegistryId = (id) => {
  // 必须存在
  if (!id) return { valid: false, error: 'registry_id is required' };
  
  // 仅允许小写字母、数字和连字符
  const validFormat = /^[a-z0-9]+(-[a-z0-9]+)*$/;
  if (!validFormat.test(id)) {
    return { valid: false, error: 'registry_id must contain only lowercase letters, numbers, and hyphens' };
  }
  
  // 不能以连字符开头或结尾
  if (id.startsWith('-') || id.endsWith('-')) {
    return { valid: false, error: 'registry_id cannot start or end with a hyphen' };
  }
  
  // 长度检查
  if (id.length < 2 || id.length > 50) {
    return { valid: false, error: 'registry_id length should be between 2 and 50 characters' };
  }
  
  return { valid: true };
};
```

#### version 验证

```javascript
// 验证规则
const validateVersion = (version) => {
  // 必须存在
  if (!version) return { valid: false, error: 'version is required' };
  
  // 遵循语义化版本
  const semverRegex = /^\d+\.\d+\.\d+$/;
  if (!semverRegex.test(version)) {
    return { valid: false, error: 'version must follow semantic versioning (MAJOR.MINOR.PATCH)' };
  }
  
  return { valid: true };
};
```

### JSON 格式验证

生成的 JSON 必须通过以下验证：

1. **语法正确性**：使用 JSON.parse() 验证 JSON 格式
2. **必需字段**：确保所有必填字段都存在
3. **类型正确性**：每个字段的类型必须正确
4. **无多余字段**：不应包含未定义的字段

---

## Usage Guidelines

生成 manifest.json 的步骤：

1. **读取源文件**
   - 从工具集目录的 README.md 提取基本信息
   - 扫描 actions/ 目录收集所有 .md 文件

2. **提取元数据**
   - 解析 registry_id, name, description, version
   - 从 README.md 的头部元数据中提取

3. **收集命令列表**
   - 列出 actions/ 目录下的所有 .md 文件
   - 排除 .gitkeep 等非 action 文件
   - 提取文件名作为命令名称

4. **确认场景信息**
   - 如 README.md 中有 scenario，使用并确认
   - 如无，引导用户输入场景描述

5. **生成 JSON 文件**
   - 构建完整的 JSON 对象
   - 验证 JSON 格式
   - 保存到 manifest.json

6. **输出摘要**
   - 展示生成的文件内容
   - 列出提取的元数据
   - 确认命令列表

---

## Output Format

manifest.json 应输出为：

**格式**: JSON
**位置**: `.asdm/toolsets/<toolset-id>/manifest.json`
**编码**: UTF-8

**格式详情**：
- 使用标准 JSON 格式
- 不使用注释
- 字段顺序保持一致
- 字符串值使用双引号

**示例**：
```json
{
  "registry_id": "toolset-manifest",
  "name": "Toolset Manifest File Add",
  "description": "为缺少 manifest.json 文件的工具集自动获取信息创建 manifest 文件。",
  "scenario": "为新创建或缺少 manifest.json 的工具集快速生成清单文件。",
  "version": "0.0.1",
  "configType": "toolset",
  "commands": ["asdm-generate-manifest"]
}
```

---

## Best Practices

使用本规范时：

1. **保持唯一性**：确保 registry_id 在所有工具集中唯一
2. **版本递增**：每次更新 manifest.json 时递增版本号
3. **描述准确**：description 应准确反映工具集功能
4. **命令同步**：当 actions/ 目录变更时，及时更新 commands 列表
5. **场景明确**：scenario 应清晰描述工具集的使用场景
6. **配置类型固定**：configType 必须始终为 "toolset"

### 常见错误避免

- **registry_id 不规范**：使用小写字母、数字和连字符
- **版本号错误**：遵循 MAJOR.MINOR.PATCH 格式
- **命令列表过时**：添加或删除 action 后更新 commands
- **描述过于笼统**：description 应具体说明功能
- **configType 错误**：必须为 "toolset"，不可更改

---

## Related Documents

本规范与以下文档配合使用：

- **README.md**：工具集文档，提取元数据的主要来源
- **INSTALL.md**：安装说明
- **actions/*.md**：各个 action 的定义文件

本规范被以下内容引用：

- **Action: asdm-generate-manifest**：生成 manifest.json
- **Toolset: toolset-builder**：工具集构建器使用此规范

---

## Checklist

生成 manifest.json 前检查：

- [ ] registry_id 符合命名规范（小写字母、数字、连字符）
- [ ] registry_id 唯一，未与其他工具集冲突
- [ ] name 非空且长度合理
- [ ] description 准确描述工具集功能
- [ ] scenario 描述清晰的使用场景
- [ ] version 遵循语义化版本格式
- [ ] configType 值为 "toolset"
- [ ] commands 列表包含所有 action 文件
- [ ] JSON 格式正确，可通过 JSON.parse() 验证

验证具体字段时：

- [ ] registry_id 长度在 2-50 个字符之间
- [ ] registry_id 不以连字符开头或结尾
- [ ] version 格式为 MAJOR.MINOR.PATCH
- [ ] commands 为非空数组
- [ ] configType 必须为字符串 "toolset"
