# Web Smoke Tester Toolset Installation

**Toolset ID:** `web-smoke-tester`

## Overview

Web Smoke Tester 提供模拟测试人员进行 WEB 系统冒烟测试的能力，支持自然语言描述测试步骤，执行单个业务场景测试并以表格形式输出结果。

## AI Guided Installation

使用 AI 引导安装时，将以下提示复制到 AI 编码工具的聊天窗口：

```shell
Follow instructions in .asdm/toolsets/web-smoke-tester/INSTALL.md
```

## Installation Steps

### 1. Detect the current Agentic Engine provider

检测当前 AI 编码助手的提供者：

- 若 `.claude` 目录存在 → `Claude Code`
- 若 `.github` 目录存在 → `GitHub Copilot`
- 若 `.codebuddy` 目录存在 → `Tencent CodeBuddy` / `Qoder`
- 若 `.qoder` 目录存在 → `Qoder`
- 若均未找到 → 提示用户手动选择

### 2. Register shortcut commands for Web Smoke Tester

在 Agentic Engine 的命令入口中注册快捷命令。**不再复制 action 文件内容**，而是注入一个引用指引，让 AI 读取 toolset 中的原始 action 文件。

#### For Claude Code (`.claude/commands/`):

```bash
mkdir -p .claude/commands/

# smoke-test-run command
cat > .claude/commands/smoke-test-run.md << 'EOF'
---
description: "执行单个业务场景的 WEB 冒烟测试"
argument-hint: "自然语言描述测试步骤，如：打开首页→登录→搜索商品→加入购物车"
---

Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-run.md
EOF

# smoke-test-list command
cat > .claude/commands/smoke-test-list.md << 'EOF'
---
description: "列出所有已执行的冒烟测试场景记录"
argument-hint: "[可选：按状态筛选 pass|fail|all]"
---

Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-list.md
EOF

# smoke-test-report command
cat > .claude/commands/smoke-test-report.md << 'EOF'
---
description: "生成冒烟测试汇总报告"
argument-hint: "[可选：报告标题]"
---

Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-report.md
EOF

# smoke-test-clear command
cat > .claude/commands/smoke-test-clear.md << 'EOF'
---
description: "清空所有冒烟测试记录"
argument-hint: ""
---

Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-clear.md
EOF
```

#### For GitHub Copilot (`.github/prompts/`):

```bash
mkdir -p .github/prompts/

# smoke-test-run prompt
cat > .github/prompts/smoke-test-run.prompt.md << 'EOF'
---
agent: 'agent'
description: '执行单个业务场景的 WEB 冒烟测试'
argument-hint: '自然语言描述测试步骤，如：打开首页→登录→搜索商品→加入购物车'
---

Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-run.md
EOF

# smoke-test-list prompt
cat > .github/prompts/smoke-test-list.prompt.md << 'EOF'
---
agent: 'agent'
description: '列出所有已执行的冒烟测试场景记录'
argument-hint: '按状态筛选 pass|fail|all'
---

Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-list.md
EOF

# smoke-test-report prompt
cat > .github/prompts/smoke-test-report.prompt.md << 'EOF'
---
agent: 'agent'
description: '生成冒烟测试汇总报告'
argument-hint: '输入报告标题'
---

Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-report.md
EOF

# smoke-test-clear prompt
cat > .github/prompts/smoke-test-clear.prompt.md << 'EOF'
---
agent: 'agent'
description: '清空所有冒烟测试记录'
argument-hint: ''
---

Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-clear.md
EOF
```

#### For Tencent CodeBuddy / Qoder (`.codebuddy/commands/`):

```bash
mkdir -p .codebuddy/commands/

# smoke-test-run command
cat > .codebuddy/commands/smoke-test-run.md << 'EOF'
Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-run.md
EOF

# smoke-test-list command
cat > .codebuddy/commands/smoke-test-list.md << 'EOF'
Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-list.md
EOF

# smoke-test-report command
cat > .codebuddy/commands/smoke-test-report.md << 'EOF'
Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-report.md
EOF

# smoke-test-clear command
cat > .codebuddy/commands/smoke-test-clear.md << 'EOF'
Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-clear.md
EOF
```

### 3. Manual Usage for Other Providers

如果你的 AI 编码助手不在上述检测范围内，可以直接在聊天窗口中输入指引：

```
Follow .asdm/toolsets/web-smoke-tester/actions/smoke-test-run.md
```

## Available Commands

安装后可使用以下命令：

| 命令 | 说明 | 示例 |
|------|------|------|
| `/smoke-test-run` | 执行单个场景冒烟测试 | `/smoke-test-run 打开首页→登录admin/123456→点击用户管理→新增用户` |
| `/smoke-test-list` | 列出测试记录 | `/smoke-test-list` |
| `/smoke-test-list` | 按状态筛选记录 | `/smoke-test-list fail` |
| `/smoke-test-report` | 生成汇总报告 | `/smoke-test-report` |
| `/smoke-test-report` | 指定报告标题 | `/smoke-test-report 用户模块冒烟测试报告` |
| `/smoke-test-clear` | 清空测试记录 | `/smoke-test-clear` |

## Key Documents

AI 执行操作时会自动读取以下文档：

| 文档 | 路径 | 用途 |
|------|------|------|
| 共享规范 | `.asdm/toolsets/web-smoke-tester/spec/smoke-test-shared-spec.md` | 数据模型、存储、输出格式等基础规范 |
| Pipeline 规范 | `.asdm/toolsets/web-smoke-tester/spec/smoke-test-pipeline-spec.md` | 测试步骤解析、执行、断言流程规范 |
| 报告规范 | `.asdm/toolsets/web-smoke-tester/spec/smoke-test-report-spec.md` | 测试结果表格格式、汇总统计规范 |

## Verification

安装后验证：

1. 快捷命令已创建在对应 provider 目录中
2. 命令文件内容为 `Follow .asdm/toolsets/web-smoke-tester/actions/{action-name}.md` 引用格式
3. toolset 文件位于 `.asdm/toolsets/web-smoke-tester/`

## Notes

- 命令文件仅包含引用指引，不包含 action 完整内容，避免重复和版本不一致
- AI 执行时会读取 action 文件，action 文件会进一步引用 specs 文档
- 更新 action 或 specs 时无需重新安装，AI 每次执行都会读取最新版本

## License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.
