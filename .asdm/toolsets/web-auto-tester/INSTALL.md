# Web Auto Tester Toolset Installation

**Toolset ID:** `web-auto-tester`

## Overview

本文档提供了 Web Auto Tester 工具集的安装和设置说明。该工具集通过 YAML DSL 用例驱动 Web 系统自动化测试，支持三种用例生成方式（需求文档 AI 生成、Playwright Codegen 录制、手动编写），以 Playwright 为主框架、Selenium 为可选辅框架，提供 HTML 报告能力。本工具集为独立工具集，不与 web-smoke-tester 形成互补关系，不提供 CI/CD 集成功能。

## AI Guided Installation

要使用 AI 引导安装此工具集，请将以下提示复制并粘贴到 AI 编码工具的聊天窗口中：

```shell
Follow instructions in .asdm/toolsets/web-auto-tester/INSTALL.md
```

## Installation Steps

### 1. Create workspace directories

创建 Web Auto Tester 工具集的工作区目录：

```bash
mkdir -p .asdm/workspace/auto-test/cases
mkdir -p .asdm/workspace/auto-test/results
mkdir -p .asdm/workspace/auto-test/reports
mkdir -p .asdm/workspace/auto-test/screenshots

# 创建 .gitkeep 保持目录结构
touch .asdm/workspace/auto-test/cases/.gitkeep
touch .asdm/workspace/auto-test/results/.gitkeep
touch .asdm/workspace/auto-test/reports/.gitkeep
touch .asdm/workspace/auto-test/screenshots/.gitkeep
```

### 2. Detect the current `Agentic Engine` provider

检测当前 AI 编码助手提供商（如 Claude Code、GitHub Copilot、Tencent CodeBuddy）。使用以下规则检测提供商：

- 如果 `.claude` 目录存在，使用 `Claude Code`
- 如果 `.github` 目录存在，使用 `GitHub Copilot`
- 如果 `.codebuddy` 目录存在，使用 `Tencent CodeBuddy`
- 如果当前工作区中未找到上述目录，提示用户手动选择提供商

### 3. Create shortcuts commands for Web Auto Tester (toolset ID: `web-auto-tester`) in provider's entry point

根据检测到的提供商，在对应位置创建快捷命令。所有提供商的安装流程一致 — Claude 和 GitHub 使用 `cat` 拼接提供商特定的 frontmatter 与实际指令内容：

#### For Claude Code (`.claude/commands/`)

Claude Code 使用带有 Frontmatter 元数据的 Markdown 文件作为斜杠命令。通过拼接 Claude 特定的 frontmatter 与指令内容来创建命令：

```bash
mkdir -p .claude/commands/

# 需求文档生成用例
cat > .claude/commands/auto-test-generate.md << 'EOF'
---
description: "从 Markdown 需求文档自动生成 YAML DSL 测试用例"
argument-hint: "[document] [framework=playwright] [outputDir=cases]"
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-generate.md >> .claude/commands/auto-test-generate.md

# 录制生成用例
cat > .claude/commands/auto-test-record.md << 'EOF'
---
description: "通过 Playwright Codegen 录制操作生成 YAML DSL 测试用例"
argument-hint: "[url] [browser=chromium]"
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-record.md >> .claude/commands/auto-test-record.md

# 执行测试
cat > .claude/commands/auto-test-run.md << 'EOF'
---
description: "执行 YAML DSL 测试用例，生成执行结果 JSON"
argument-hint: "[case] [framework] [capture] [env]"
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-run.md >> .claude/commands/auto-test-run.md

# 列出用例与结果
cat > .claude/commands/auto-test-list.md << 'EOF'
---
description: "列出测试用例和执行结果"
argument-hint: "[type=all] [filter]"
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-list.md >> .claude/commands/auto-test-list.md

# 生成报告
cat > .claude/commands/auto-test-report.md << 'EOF'
---
description: "生成 HTML 测试报告（可选 Allure 导出）"
argument-hint: "[result] [format=html]"
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-report.md >> .claude/commands/auto-test-report.md

# 清理资源
cat > .claude/commands/auto-test-clean.md << 'EOF'
---
description: "清理测试工作区资源"
argument-hint: "[scope] [confirm=false]"
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-clean.md >> .claude/commands/auto-test-clean.md
```

#### For GitHub Copilot (`.github/prompts/`)

GitHub Copilot 使用 `.prompt.md` 文件和 YAML frontmatter。通过拼接 GitHub 特定的 frontmatter 与指令内容来创建提示文件：

```bash
mkdir -p .github/prompts/

# 需求文档生成用例
cat > .github/prompts/auto-test-generate.prompt.md << 'EOF'
---
agent: 'agent'
description: '从 Markdown 需求文档自动生成 YAML DSL 测试用例'
argument-hint: '[document] [framework=playwright] [outputDir=cases]'
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-generate.md >> .github/prompts/auto-test-generate.prompt.md

# 录制生成用例
cat > .github/prompts/auto-test-record.prompt.md << 'EOF'
---
agent: 'agent'
description: '通过 Playwright Codegen 录制操作生成 YAML DSL 测试用例'
argument-hint: '[url] [browser=chromium]'
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-record.md >> .github/prompts/auto-test-record.prompt.md

# 执行测试
cat > .github/prompts/auto-test-run.prompt.md << 'EOF'
---
agent: 'agent'
description: '执行 YAML DSL 测试用例，生成执行结果 JSON'
argument-hint: '[case] [framework] [capture] [env]'
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-run.md >> .github/prompts/auto-test-run.prompt.md

# 列出用例与结果
cat > .github/prompts/auto-test-list.prompt.md << 'EOF'
---
agent: 'agent'
description: '列出测试用例和执行结果'
argument-hint: '[type=all] [filter]'
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-list.md >> .github/prompts/auto-test-list.prompt.md

# 生成报告
cat > .github/prompts/auto-test-report.prompt.md << 'EOF'
---
agent: 'agent'
description: '生成 HTML 测试报告（可选 Allure 导出）'
argument-hint: '[result] [format=html]'
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-report.md >> .github/prompts/auto-test-report.prompt.md

# 清理资源
cat > .github/prompts/auto-test-clean.prompt.md << 'EOF'
---
agent: 'agent'
description: '清理测试工作区资源'
argument-hint: '[scope] [confirm=false]'
---

EOF
cat .asdm/toolsets/web-auto-tester/actions/auto-test-clean.md >> .github/prompts/auto-test-clean.prompt.md
```

#### For Tencent CodeBuddy (`.codebuddy/commands/`)

CodeBuddy 不支持 frontmatter，直接复制指令文件即可：

```bash
mkdir -p .codebuddy/commands/

# 直接复制指令文件（无需 frontmatter）
cp .asdm/toolsets/web-auto-tester/actions/auto-test-generate.md .codebuddy/commands/
cp .asdm/toolsets/web-auto-tester/actions/auto-test-record.md .codebuddy/commands/
cp .asdm/toolsets/web-auto-tester/actions/auto-test-run.md .codebuddy/commands/
cp .asdm/toolsets/web-auto-tester/actions/auto-test-list.md .codebuddy/commands/
cp .asdm/toolsets/web-auto-tester/actions/auto-test-report.md .codebuddy/commands/
cp .asdm/toolsets/web-auto-tester/actions/auto-test-clean.md .codebuddy/commands/
```

### 4. Manual Usage for Other Providers

如果您的 AI 编码助手提供商不在自动检测逻辑中（Claude Code、GitHub Copilot 或 Tencent CodeBuddy），您仍然可以手动使用 Web Auto Tester。请按以下步骤操作：

#### 直接使用指令文件

您可以直接复制指令文件的相对路径，粘贴到 AI 编码助手的聊天窗口中使用：

1. **导航到指令文件**：

   ```bash
   cd .asdm/toolsets/web-auto-tester/actions/
   ```

2. **右键点击所需的指令文件**，复制其相对路径：
   - 需求文档生成用例：`auto-test-generate.md`
   - 录制生成用例：`auto-test-record.md`
   - 执行测试：`auto-test-run.md`
   - 列出用例与结果：`auto-test-list.md`
   - 生成报告：`auto-test-report.md`
   - 清理资源：`auto-test-clean.md`

3. **在 AI 编码助手中输入提示**：

   ```text
   Follow the instructions in {指令文件的相对路径}
   ```

## Initializing Web Auto Tester

### 执行自动化测试

安装完成后，您可以开始运行 action：

```shell
Follow the instructions in .asdm/toolsets/web-auto-tester/actions/auto-test-run.md
```

此操作将：

- 加载 YAML DSL 测试用例
- 根据 framework 字段选择执行引擎（Playwright 或 Selenium）
- 逐阶段执行步骤和断言
- 失败步骤自动截图
- 生成 AutoTestResult JSON 结果文件

### Available Commands

安装完成后，您可以使用以下命令：

1. **`/auto-test-generate`** - 从 Markdown 需求文档自动生成 YAML DSL 测试用例
2. **`/auto-test-record`** - 通过 Playwright Codegen 录制操作生成 YAML DSL 测试用例
3. **`/auto-test-run`** - 执行 YAML DSL 测试用例
4. **`/auto-test-list`** - 列出测试用例和执行结果
5. **`/auto-test-report`** - 生成 HTML 测试报告
6. **`/auto-test-clean`** - 清理测试工作区资源

## Toolset Structure

工具集将在 `.asdm/workspace/auto-test/` 中创建以下结构：

```text
.asdm/workspace/auto-test/
├── cases/          # 测试用例存储
├── results/        # 执行结果存储
├── reports/        # HTML 测试报告
└── screenshots/    # 截图存储
```

## Spec Documents

工具集使用以下规范文档：

1. **`auto-test-dsl-spec.md`** - YAML DSL 用例格式规范
2. **`auto-test-execution-spec.md`** - 执行引擎 7 阶段规范
3. **`auto-test-report-spec.md`** - 报告格式规范

## Verification

安装完成后，请验证：

1. `.asdm/workspace/auto-test/` 目录及其 4 个子目录已创建（cases/results/reports/screenshots）
2. 每个子目录含 `.gitkeep` 文件
3. Web Auto Tester（toolset ID: `web-auto-tester`）的 6 个快捷命令已在对应的提供商目录中创建
4. Web Auto Tester 工具集文件位于 `.asdm/toolsets/web-auto-tester/`

**验证命令**：

```bash
# 验证工作区目录
ls .asdm/workspace/auto-test/

# 验证 .gitkeep 文件
find .asdm/workspace/auto-test -name ".gitkeep" | wc -l

# 验证快捷命令（CodeBuddy）
ls .codebuddy/commands/auto-test-*.md | wc -l
```

## Usage Examples

### Example 1: 从需求文档生成用例

```shell
/auto-test-generate document=docs/PRD.md framework=playwright
```

### Example 2: 录制操作生成用例

```shell
/auto-test-record url=http://localhost:3000 browser=chromium
```

### Example 3: 执行单个用例

```shell
/auto-test-run case=cases/user-login-test.yaml
```

### Example 4: 执行目录下所有用例

```shell
/auto-test-run case=cases/
```

### Example 5: 列出所有执行结果

```shell
/auto-test-list type=results
```

### Example 6: 列出失败结果

```shell
/auto-test-list type=results filter=status:fail
```

### Example 7: 生成 HTML 报告

```shell
/auto-test-report format=html
```

### Example 8: 清理结果和截图

```shell
/auto-test-clean scope=all confirm=true
```

## Usage

### For Supported Providers (Claude Code, GitHub Copilot, Tencent CodeBuddy)

安装完成后，您可以使用以下命令：

- `/auto-test-generate`：需求文档生成测试用例
- `/auto-test-record`：录制操作生成测试用例
- `/auto-test-run`：执行自动化测试
- `/auto-test-list`：列出用例与结果
- `/auto-test-report`：生成 HTML 报告
- `/auto-test-clean`：清理测试资源

### For Other Providers (Manual Usage)

如果您的提供商不在自动检测范围内，您可以按照上方"Manual Usage for Other Providers"部分的步骤手动使用指令文件。

## Notes

- 此安装过程假设您具有创建目录和文件的必要权限
- 命令的实际执行将由 AI 模型使用 Web Auto Tester（toolset ID: `web-auto-tester`）中提供的模板和指令来完成
- 请根据您实际使用的 AI 编码助手自定义提供商特定设置
- 工具集 ID `web-auto-tester` 应在命令和文档中一致使用
- **对于不在检测逻辑中的提供商**：用户可以手动使用指令文件，复制其相对路径并输入类似"Follow the instructions in .asdm/toolsets/web-auto-tester/actions/auto-test-run.md"的提示
- 执行测试前请确保目标 Web 系统可访问
- Playwright 执行需要安装浏览器驱动（`npx playwright install`）

## Integration with Other Toolsets

Web Auto Tester 是一个**独立**的工具集，与 `web-smoke-tester` 不形成互补关系：

- `web-smoke-tester`：冒烟测试（P0/P1 快速验证），自然语言驱动，独立运行
- `web-auto-tester`：全面功能测试（全场景覆盖），用例驱动，独立运行

两者定位不同，各自独立使用和演进。YAML DSL 格式与 smoke-tester Pipeline YAML 风格一致，数据模型继承 smoke-tester 的 ID 生成规则和断言分类骨架。

### Getting Help

如需 Web Auto Tester 相关帮助，请参考：

- [ASDM Documentation](https://asdm.ai/docs)
- 工具集 README：`.asdm/toolsets/web-auto-tester/README.md`
- 规范文档：`.asdm/toolsets/web-auto-tester/spec/`

## License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.

---

*This installation document is part of the Web Auto Tester toolset. 如需帮助，请参考 README.md 或 ASDM 文档。*
