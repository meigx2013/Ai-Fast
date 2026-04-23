# Toolset Manifest File Add Installation

**Toolset ID:** `toolset-manifest`

## Overview
This document provides instructions for installing and setting up the Toolset Manifest File Add toolset. 为缺少 manifest.json 文件的工具集自动获取信息创建 manifest 文件。

## AI Guided Installation
To install this toolset using AI Guided Installation, copy and paste the following prompt into your AI Coding tool's chat window:

```shell
Follow instructions in .asdm/toolsets/toolset-manifest/INSTALL.md
```

## Installation Steps

### 1. Create workspace directories

Create the workspace directories for the toolset:

```bash
mkdir -p .asdm/workspace/toolset-manifest/temp
mkdir -p .asdm/workspace/toolset-manifest/logs
```

### 2. Detect the current `Agentic Engine` provider

Detect the current AI coding assistant provider (e.g., Claude Code, GitHub Copilot, Tencent CodeBuddy). Using the following guidelines to detect the provider:

- If `.claude` directory exists, use `Claude Code`
- If `.github` directory exists, use `GitHub Copilot`
- If `.codebuddy` directory exists, use `Tencent CodeBuddy`
- If no such folder is found in the current workspace, give user a prompt to select a provider manually

### 3. Create shortcuts commands for Toolset Manifest File Add (toolset ID: `toolset-manifest`) in provider's entry point

Create shortcut commands in the appropriate location based on the detected provider. The installation process is consistent across all providers - we use `cat` to concatenate provider-specific frontmatter with the actual instruction content:

#### For Claude Code (`.claude/commands/`):
Claude Code uses Markdown files with Frontmatter metadata for slash commands. Create commands by concatenating Claude-specific frontmatter with instruction content:

```bash
mkdir -p .claude/commands/

# Generate Manifest command
cat > .claude/commands/asdm-generate-manifest.md << 'EOF'
---
description: "Generate manifest.json for a specified toolset directory"
argument-hint: "[toolset-path]"
---

EOF
cat .asdm/toolsets/toolset-manifest/actions/asdm-generate-manifest.md >> .claude/commands/asdm-generate-manifest.md
```

#### For GitHub Copilot (`.github/prompts/`):
GitHub Copilot uses `.prompt.md` files with YAML frontmatter. Create prompt files by concatenating GitHub-specific frontmatter with instruction content:

```bash
mkdir -p .github/prompts/

# Generate Manifest prompt
cat > .github/prompts/asdm-generate-manifest.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Generate manifest.json for a specified toolset directory'
argument-hint: 'toolset-path'
---

EOF
cat .asdm/toolsets/toolset-manifest/actions/asdm-generate-manifest.md >> .github/prompts/asdm-generate-manifest.prompt.md
```

#### For Tencent CodeBuddy (`.codebuddy/commands/`):
CodeBuddy doesn't support frontmatter, so simply copy the instruction files as-is:

```bash
mkdir -p .codebuddy/commands/

# Copy instruction files directly (no frontmatter needed)
cp .asdm/toolsets/toolset-manifest/actions/asdm-generate-manifest.md .codebuddy/commands/
```

### 4. Manual Usage for Other Providers

If your AI coding assistant provider is not detected by the automatic detection logic (Claude Code, GitHub Copilot, or Tencent CodeBuddy), you can still use the Toolset Manifest File Add manually. Follow these steps:

#### Direct Instruction Usage
You can directly use the instruction files by copying their relative paths and pasting them into your AI coding assistant's chat window:

1. **Navigate to the instruction files**:
   ```bash
   cd .asdm/toolsets/toolset-manifest/actions/
   ```

2. **Right-click on the desired instruction file** and copy its relative path:
   - For Generate Manifest: `asdm-generate-manifest.md`

3. **Enter a prompt** in your AI coding assistant:
   ```
   Follow the instructions in {relative path to instruction file}
   ```

## Initializing Toolset Manifest File Add

### Generate manifest.json for a specified toolset
After installation, you can start by running the first action:

```shell
Follow the instructions in .asdm/toolsets/toolset-manifest/actions/asdm-generate-manifest.md
```

This will:
- 自动从 README.md 提取元数据
- 扫描 actions/ 目录收集可用命令
- 引导用户输入场景信息
- 生成并保存 manifest.json 文件

### Available Commands
Once installed, you can use the following commands:

1. **`/asdm-generate-manifest`** - Generate manifest.json for a specified toolset directory

## Toolset Structure
The toolset will create the following structure in `.asdm/workspace/toolset-manifest/`:

```
.asdm/workspace/toolset-manifest/
├── temp/                                       ## Temporary files
└── logs/                                        ## Operation logs
    └── generate-log.md                          ## Generation operation log
```

## Spec Documents
The toolset uses the following spec documents as templates:

1. **manifest-spec.md** - Template for generating manifest.json files with complete toolset metadata

## Verification

After installation, verify that:

1. The `.asdm/workspace/toolset-manifest` directory exists for Toolset Manifest File Add
2. Shortcut commands for Toolset Manifest File Add (toolset ID: `toolset-manifest`) are created in the appropriate provider directory (if using Claude Code, GitHub Copilot, or Tencent CodeBuddy)
3. The Toolset Manifest File Add toolset files are located in `.asdm/toolsets/toolset-manifest` (toolset ID: `toolset-manifest`)

**For other providers**: Verify that you can access the instruction files at:
- `.asdm/toolsets/toolset-manifest/actions/asdm-generate-manifest.md`

## Usage Examples

### Example 1: Generate manifest.json for a new toolset
```shell
# First, install the toolset using AI Guided Installation
Follow instructions in .asdm/toolsets/toolset-manifest/INSTALL.md

# Then run the generate manifest action
Follow the instructions in .asdm/toolsets/toolset-manifest/actions/asdm-generate-manifest.md

# Example prompt when using slash command:
/asdm-generate-manifest .asdm/toolsets/my-new-toolset
```

### Example 2: Add manifest to existing toolset
```shell
# Run the action
Follow the instructions in .asdm/toolsets/toolset-manifest/actions/asdm-generate-manifest.md

# Example prompt when using slash command:
/asdm-generate-manifest .asdm/toolsets/existing-toolset
```

## Usage

### For Supported Providers (Claude Code, GitHub Copilot, Tencent CodeBuddy)
Once installed, you can use the following commands:

- `/asdm-generate-manifest`: Generate manifest.json for a specified toolset directory

### For Other Providers (Manual Usage)
If your provider is not automatically detected, you can manually use the instructions by following the steps in the "Manual Usage for Other Providers" section above.

## Notes

- This installation process assumes you have the necessary permissions to create directories and files
- The actual implementation of the commands will be handled by the AI model using the templates and instructions provided in Toolset Manifest File Add (toolset ID: `toolset-manifest`)
- Make sure to customize the provider-specific setup based on your actual AI coding assistant
- The toolset ID `toolset-manifest` should be used consistently when referring to Toolset Manifest File Add in commands and documentation
- **For providers not in the detection logic**: Users can manually use the instruction files by copying their relative paths and entering prompts like "follow the instructions in .asdm/toolsets/toolset-manifest/actions/asdm-generate-manifest.md"
- This toolset reads README.md from the target toolset to extract metadata, scans the actions/ directory for available commands, and guides users to input scenario information to generate a complete manifest.json file.

## Integration with Other Toolsets
Toolset Manifest File Add can integrate with other ASDM toolsets and context files. Context files from Context Builder can be referenced to ground the generated documents to the actual project.

### Getting Help
For issues with Toolset Manifest File Add toolset, refer to:
- [ASDM Documentation](https://asdm.ai/docs)
- Toolset README: `.asdm/toolsets/toolset-manifest/README.md`
- Spec documents in `.asdm/toolsets/toolset-manifest/spec/`

## License
Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.

---

*This installation document is part of the Toolset Manifest File Add toolset.*
