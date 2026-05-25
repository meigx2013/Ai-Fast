# Basic Tools Toolset Installation

**Toolset ID:** `basic-tools`

## Overview
Basic Tools 提供一组基础开发工具，包括日常 git 操作（生成 git commit message、执行 git commit）和以开发模式启动项目。

## AI Guided Installation
使用 AI 引导安装时，将以下提示复制到 AI 编码工具的聊天窗口：

```shell
Follow instructions in .asdm/toolsets/basic-tools/INSTALL.md
```

## Installation Steps

### 1. Detect the current Agentic Engine provider

检测当前 AI 编码助手的提供者：

- 若 `.claude` 目录存在 → `Claude Code`
- 若 `.github` 目录存在 → `GitHub Copilot`
- 若 `.codebuddy` 目录存在 → `Tencent CodeBuddy` / `Qoder`
- 若 `.qoder` 目录存在 → `Qoder`
- 若均未找到 → 提示用户手动选择

### 2. Register shortcut commands for Basic Tools

在 Agentic Engine 的命令入口中注册快捷命令。**不再复制 action 文件内容**，而是注入一个引用指引，让 AI 读取 toolset 中的原始 action 文件。这样做的好处：
- 避免内容重复，更新 action 时无需同步多处
- AI 直接读取最新版本，不会因缓存导致使用旧版指令

#### For Claude Code (`.claude/commands/`):

```bash
mkdir -p .claude/commands/

# asdm-start-project command
cat > .claude/commands/asdm-start-project.md << 'EOF'
---
description: "检测工作区上下文并以开发模式启动项目"
argument-hint: "[可选：指定环境]"
---

Follow .asdm/toolsets/basic-tools/actions/asdm-start-project.md
EOF

# asdm-git-commit-message command
cat > .claude/commands/asdm-git-commit-message.md << 'EOF'
---
description: "基于当前变更生成标准 git commit message"
argument-hint: "[可选：自定义 scope 或上下文]"
---

Follow .asdm/toolsets/basic-tools/actions/asdm-git-commit-message.md
EOF

# asdm-git-commit command
cat > .claude/commands/asdm-git-commit.md << 'EOF'
---
description: "使用生成的 commit message 提交变更到当前分支"
argument-hint: "[可选：指定要提交的文件]"
---

Follow .asdm/toolsets/basic-tools/actions/asdm-git-commit.md
EOF
```

#### For GitHub Copilot (`.github/prompts/`):

```bash
mkdir -p .github/prompts/

# asdm-start-project prompt
cat > .github/prompts/asdm-start-project.prompt.md << 'EOF'
---
agent: 'agent'
description: '检测工作区上下文并以开发模式启动项目'
argument-hint: '输入可选环境或留空'
---

Follow .asdm/toolsets/basic-tools/actions/asdm-start-project.md
EOF

# asdm-git-commit-message prompt
cat > .github/prompts/asdm-git-commit-message.prompt.md << 'EOF'
---
agent: 'agent'
description: '基于当前变更生成标准 git commit message'
argument-hint: '输入可选的 scope 或上下文'
---

Follow .asdm/toolsets/basic-tools/actions/asdm-git-commit-message.md
EOF

# asdm-git-commit prompt
cat > .github/prompts/asdm-git-commit.prompt.md << 'EOF'
---
agent: 'agent'
description: '使用生成的 commit message 提交变更到当前分支'
argument-hint: '输入可选的要提交的文件'
---

Follow .asdm/toolsets/basic-tools/actions/asdm-git-commit.md
EOF
```

#### For Tencent CodeBuddy / Qoder (`.codebuddy/commands/`):

```bash
mkdir -p .codebuddy/commands/

# asdm-start-project command
cat > .codebuddy/commands/asdm-start-project.md << 'EOF'
Follow .asdm/toolsets/basic-tools/actions/asdm-start-project.md
EOF

# asdm-git-commit-message command
cat > .codebuddy/commands/asdm-git-commit-message.md << 'EOF'
Follow .asdm/toolsets/basic-tools/actions/asdm-git-commit-message.md
EOF

# asdm-git-commit command
cat > .codebuddy/commands/asdm-git-commit.md << 'EOF'
Follow .asdm/toolsets/basic-tools/actions/asdm-git-commit.md
EOF
```

### 3. Manual Usage for Other Providers

如果你的 AI 编码助手不在上述检测范围内，可以直接在聊天窗口中输入指引：

```
Follow .asdm/toolsets/basic-tools/actions/asdm-start-project.md
```

或

```
Follow .asdm/toolsets/basic-tools/actions/asdm-git-commit-message.md
```

或

```
Follow .asdm/toolsets/basic-tools/actions/asdm-git-commit.md
```

## Available Commands

安装后可使用以下命令：

| 命令 | 说明 | 示例 |
|------|------|------|
| `/asdm-start-project` | 以开发模式启动项目 | `/asdm-start-project` |
| `/asdm-start-project` | 指定环境启动 | `/asdm-start-project sit` |
| `/asdm-git-commit-message` | 基于当前变更生成 commit message | `/asdm-git-commit-message` |
| `/asdm-git-commit-message` | 指定 scope 生成 | `/asdm-git-commit-message scope:api` |
| `/asdm-git-commit` | 提交变更 | `/asdm-git-commit` |
| `/asdm-git-commit` | 提交指定文件 | `/asdm-git-commit src/main.ts` |

## Key Documents

AI 执行操作时会自动读取以下文档：

| 文档 | 路径 | 用途 |
|------|------|------|
| git commit message 规范 | `.asdm/toolsets/basic-tools/spec/git-commit-message-spec.md` | 标准 commit message 格式规范 |
| git commit 规范 | `.asdm/toolsets/basic-tools/spec/git-commit-spec.md` | commit 操作行为规范 |

## Verification

安装后验证：

1. 快捷命令已创建在对应 provider 目录中
2. 命令文件内容为 `Follow .asdm/toolsets/basic-tools/actions/{action-name}.md` 引用格式
3. toolset 文件位于 `.asdm/toolsets/basic-tools/`

## Notes

- 命令文件仅包含引用指引，不包含 action 完整内容，避免重复和版本不一致
- AI 执行时会读取 action 文件，action 文件会进一步引用 specs 文档
- 更新 action 或 specs 时无需重新安装，AI 每次执行都会读取最新版本

## License
Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.
