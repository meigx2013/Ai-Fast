# FT-003 Code Research — release-note

> 代码库路径：`.asdm/toolsets/release-note/`
> 扫描日期：2026-07-13

---

## 1. 目录结构与关键文件

```
.asdm/toolsets/release-note/
├── manifest.json                              # 工具集元数据注册文件
├── README.md                                  # 工具集入口说明文档
├── INSTALL.md                                 # 工具集安装指南
├── COMPLETION_REPORT.md                       # 完成度验证报告
├── actions/
│   └── asdm-generate-release-note.md          # 斜杠命令指令定义
└── spec/
    └── release-note-spec.md                   # 输出产物规范模板
```

---

## 2. 现有实现分析

### 2.1 manifest.json 格式

manifest.json 是 ASDM 工具集的标准元数据注册文件，关键字段：

| 字段 | 说明 | 示例值 |
|------|------|--------|
| guid | UUID v4，全局唯一标识 | `12f55022-ccab-46e0-8bb5-3ebb5fdaee0f` |
| registry_id | 工具集注册 ID（toolset-id） | `release-note` |
| name | 人类可读名称 | `Release Note Toolset` |
| description | 功能简要描述 | 生成 Release Note |
| version | 语义化版本号 | `0.0.1` |
| configType | 配置类型 | `toolset` |
| commands | 斜杠命令列表（与 actions/ 下文件名对应） | `["asdm-generate-release-note"]` |

### 2.2 Action 文件格式

每个 action 文件遵循标准章节结构：

| 章节 | 作用 |
|------|------|
| Metadata（JSON块） | guid/name/displayName/description/toolset{guid/id/name/version}/scenario |
| Purpose | 一段话描述指令目的 |
| Language Setting | 默认输出语言设置 |
| Context Injection | Required/Recommended/Optional 上下文文件路径 |
| Steps | 分步骤详细执行流程 |
| Execution Guidelines | 使用时机、分类规则、注意事项、错误处理 |
| Usage | 参数输入方式示例 |
| Output Summary | 产出物路径和命名规则 |

### 2.3 Spec 文件格式

| 章节 | 作用 |
|------|------|
| Language Guidelines | 文档语言规范 |
| Overview | spec 用途和场景说明 |
| Document Structure | 完整 Markdown 模板代码块 |
| Section Guidelines | 逐章节编写指南 |
| Usage Guidelines | 使用流程 |
| Output Format | 格式、存储位置、命名规则 |
| Best Practices | 编写最佳实践 |
| Related Documents | 关联文档引用 |
| Checklist | 生成前检查清单 |

### 2.4 README.md 和 INSTALL.md

README.md 包含：Header 元数据（toolset-id/name/version/description）→ Overview → Features → Workflow → Structure → Spec Documents → Workspace → Copyright

INSTALL.md 包含：Overview → Installation Steps（创建工作区→检测AI提供商→注册命令）→ Verification → Usage Examples → Notes

### 2.5 一致性约束

- manifest.json ↔ README.md：registry_id=toolset-id，name=toolset-name
- manifest.json ↔ action Metadata：action 的 toolset.guid = manifest 的 guid
- manifest.json commands ↔ actions/ 文件：commands 数组值 = actions/ 文件名（去掉 .md）
- README Features ↔ actions 文件：1:1 关系

---

## 3. 关键发现与缺失项

| 编号 | 发现/缺失项 | 说明 |
|------|------------|------|
| note-G1 | **manifest.json 是标准要求** | smoke-tester 缺少此文件，auto-tester 必须包含 |
| note-G2 | **一致性约束严格** | guid/id/name/version 在 manifest/README/action 三处必须一致 |
| note-G3 | **多平台命令注册差异** | Claude(CLAUDE)需frontmatter, Copilot(GITHUB)需frontmatter, CodeBuddy仅需Follow行 |
| note-G4 | **工作区约定** | 运行时输出存放在 `.asdm/workspace/{toolset-id}/` 下 |

---

## 4. 新工具集应遵循的模式

### 4.1 目录结构模板

```
.asdm/toolsets/{toolset-id}/
├── manifest.json
├── README.md
├── INSTALL.md
├── actions/
│   └── asdm-{command-name}.md    # 每个命令一个文件
└── spec/
    └── {output-spec-name}.md      # 每个输出规范一个文件
```

### 4.2 命令注册模式

CodeBuddy 格式（本项目使用）：
- `.codebuddy/commands/{command-name}.md` 仅包含 `Follow .asdm/toolsets/{toolset-id}/actions/{action-name}.md`

---

## 5. 与其他代码库的交互接口

- **`.codebuddy/commands/`**：命令快捷入口指向 actions/ 文件
- **`.asdm/workspace/`**：工作区存储目录
- **无跨代码库 API 调用**
