# Toolset Builder Installation

**Toolset ID:** `toolset-builder`

## Overview
This document provides instructions for installing and setting up the Toolset Builder toolset. Toolset Builder helps developers create new ASDM toolsets efficiently by providing guided development steps and automatic file generation.

## AI Guided Installation
To install this toolset using AI Guided Installation, copy and paste the following prompt into your AI Coding tool's chat window:

```shell
Follow instructions in .asdm/toolsets/toolset-builder/INSTALL.md
```

## Installation Steps

### 1. Create `.asdm/toolsets` directory for toolsets

Create the directory for storing toolsets:

```bash
mkdir -p .asdm/toolsets
```

### 2. Detect the current `Agentic Engine` provider

Detect the current AI coding assistant provider (e.g., Claude Code, GitHub Copilot, Tencent CodeBuddy). Using the following guidelines to detect the provider:

- If `.claude` directory exists, use `Claude Code`
- If `.github` directory exists, use `GitHub Copilot`
- If `.codebuddy` directory exists, use `Tencent CodeBuddy`
- If no such folder is found in the current workspace, give user a prompt to select a provider manually

### 3. Create shortcuts commands for Toolset Builder (toolset ID: `toolset-builder`) in provider's entry point

Create shortcut commands in the appropriate location based on the detected provider. The installation process is consistent across all providers - we use `cat` to concatenate provider-specific frontmatter with the actual instruction content:

#### For Claude Code (`.claude/commands/`):
Claude Code uses Markdown files with Frontmatter metadata for slash commands. Create commands by concatenating Claude-specific frontmatter with instruction content:

```bash
mkdir -p .claude/commands/

# Initialize toolset command
cat > .claude/commands/asdm-init-toolset.md << 'EOF'
---
description: "Initialize a new toolset project"
argument-hint: "[toolset-id]"
---

EOF
cat .asdm/toolsets/toolset-builder/actions/asdm-init-toolset.md >> .claude/commands/asdm-init-toolset.md

# Define features command
cat > .claude/commands/asdm-define-features.md << 'EOF'
---
description: "Define features and actions for toolset"
argument-hint: "[toolset-id]"
---

EOF
cat .asdm/toolsets/toolset-builder/actions/asdm-define-features.md >> .claude/commands/asdm-define-features.md

# Create specs command
cat > .claude/commands/asdm-create-specs.md << 'EOF'
---
description: "Create specification templates for toolset"
argument-hint: "[toolset-id]"
---

EOF
cat .asdm/toolsets/toolset-builder/actions/asdm-create-specs.md >> .claude/commands/asdm-create-specs.md

# Complete toolset command
cat > .claude/commands/asdm-complete-toolset.md << 'EOF'
---
description: "Complete, generate INSTALL.md and manifest.json for the toolset"
argument-hint: "[toolset-id]"
---

EOF
cat .asdm/toolsets/toolset-builder/actions/asdm-complete-toolset.md >> .claude/commands/asdm-complete-toolset.md
```

#### For GitHub Copilot (`.github/prompts/`):
GitHub Copilot uses `.prompt.md` files with YAML frontmatter. Create prompt files by concatenating GitHub-specific frontmatter with instruction content:

```bash
mkdir -p .github/prompts/

# Initialize toolset prompt
cat > .github/prompts/asdm-init-toolset.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Initialize a new toolset project'
argument-hint: 'Enter toolset ID'
---

EOF
cat .asdm/toolsets/toolset-builder/actions/asdm-init-toolset.md >> .github/prompts/asdm-init-toolset.prompt.md

# Define features prompt
cat > .github/prompts/asdm-define-features.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Define features and actions for toolset'
argument-hint: 'Enter toolset ID'
---

EOF
cat .asdm/toolsets/toolset-builder/actions/asdm-define-features.md >> .github/prompts/asdm-define-features.prompt.md

# Create specs prompt
cat > .github/prompts/asdm-create-specs.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Create specification templates for toolset'
argument-hint: 'Enter toolset ID'
---

EOF
cat .asdm/toolsets/toolset-builder/actions/asdm-create-specs.md >> .github/prompts/asdm-create-specs.prompt.md

# Complete toolset prompt
cat > .github/prompts/asdm-complete-toolset.prompt.md << 'EOF'
---
agent: 'agent'
description: 'Complete, generate INSTALL.md and manifest.json for the toolset'
argument-hint: 'Enter toolset ID'
---

EOF
cat .asdm/toolsets/toolset-builder/actions/asdm-complete-toolset.md >> .github/prompts/asdm-complete-toolset.prompt.md
```

#### For Tencent CodeBuddy (`.codebuddy/commands/`):
CodeBuddy doesn't support frontmatter, so simply copy the instruction files as-is:

```bash
mkdir -p .codebuddy/commands/

# Copy instruction files directly (no frontmatter needed)
cp .asdm/toolsets/toolset-builder/actions/asdm-init-toolset.md .codebuddy/commands/
cp .asdm/toolsets/toolset-builder/actions/asdm-define-features.md .codebuddy/commands/
cp .asdm/toolsets/toolset-builder/actions/asdm-create-specs.md .codebuddy/commands/
cp .asdm/toolsets/toolset-builder/actions/asdm-complete-toolset.md .codebuddy/commands/
```

### 4. Manual Usage for Other Providers

If your AI coding assistant provider is not detected by the automatic detection logic (Claude Code, GitHub Copilot, or Tencent CodeBuddy), you can still use the Toolset Builder manually. Follow these steps:

#### Direct Instruction Usage
You can directly use the instruction files by copying their relative paths and pasting them into your AI coding assistant's chat window:

1. **Navigate to the instruction files**:
   ```bash
   cd .asdm/toolsets/toolset-builder/actions/
   ```

2. **Right-click on the desired instruction file** and copy its relative path:
   - For initializing: `asdm-init-toolset.md`
   - For defining features: `asdm-define-features.md`
   - For creating specs: `asdm-create-specs.md`
   - For completing: `asdm-complete-toolset.md`

3. **Enter a prompt** in your AI coding assistant:
   ```
   Follow the instructions in {relative path to instruction file}
   ```

## Using Toolset Builder

### Step 1: Initialize a New Toolset

After installation, you can create a new toolset:

```shell
Follow the instructions in .asdm/toolsets/toolset-builder/actions/asdm-init-toolset.md
```

This will:
1. Prompt you for toolset information (ID, name, description, version)
2. Create the basic directory structure
3. Generate a README.md template with placeholders
4. Prepare the workspace for further development

### Step 2: Define Features and Actions

Once initialized, define the features and actions:

```shell
Follow the instructions in .asdm/toolsets/toolset-builder/actions/asdm-define-features.md
```

This will:
1. Ask you to describe each feature/action
2. Generate action instruction file templates
3. Create the action files with proper structure
4. Update the README.md with feature information

### Step 3: Create Spec Templates

Create specification document templates:

```shell
Follow the instructions in .asdm/toolsets/toolset-builder/actions/asdm-create-specs.md
```

This will:
1. Ask you about the spec documents needed
2. Generate spec template files with proper structure
3. Include guidelines for using the specs
4. Update the README.md with spec information

### Step 4: Complete and Finalize

Review and finalize the toolset (includes generating INSTALL.md and manifest.json):

```shell
Follow the instructions in .asdm/toolsets/toolset-builder/actions/asdm-complete-toolset.md
```

This will:
1. Generate INSTALL.md for the new toolset
2. Generate manifest.json with toolset metadata
3. Validate all files exist
4. Check completeness and consistency
5. Generate a summary of the toolset
6. Provide next steps and recommendations

### Available Commands
Once installed, you can use the following commands:

1. **`/asdm-init-toolset`** - Initialize a new toolset project
2. **`/asdm-define-features`** - Define features and actions for toolset
3. **`/asdm-create-specs`** - Create specification templates
4. **`/asdm-complete-toolset`** - Complete, generate INSTALL.md and manifest.json for the toolset

## Toolset Structure Created

Toolset Builder will create the following structure:

```
.asdm/toolsets/<toolset-id>/
├── README.md                    ## Toolset description (developer completes)
├── INSTALL.md                   ## Installation instructions (generated)
├── actions/                     ## Action instruction files
│   ├── <action-name>.md
│   └── ...
└── spec/                        ## Spec template files
    ├── <spec-name>.md
    └── ...
```

## Toolset Builder Structure

The Toolset Builder itself has the following structure:

```
.asdm/toolsets/toolset-builder/
├── INSTALL.md                         ## Installation instructions
├── README.md                          ## Current document
├── manifest.json                      ## Toolset manifest
├── actions/                           ## Instructions for Toolset Builder
│   ├── asdm-init-toolset.md          ## Initialize new toolset
│   ├── asdm-define-features.md       ## Define toolset features
│   ├── asdm-create-specs.md          ## Create spec templates
│   └── asdm-complete-toolset.md     ## Complete, generate INSTALL.md and manifest.json
├── spec/                              ## Spec documents for Toolset Builder
│   ├── toolset-readme-spec.md       ## README template
│   ├── toolset-action-spec.md        ## Action file template
│   └── toolset-spec-spec.md         ## Spec template
└── contexts/                          ## Reference documentation
    ├── ASDM_TOOLSET_DESIGN_PRINCIPLES.md   ## ASDM design principles
    └── TOOLSET_DEV_TRAINING.md           ## Toolset development training
```

## Verification

After installation, verify that:

1. The `.asdm/toolsets` directory exists
2. Shortcut commands for Toolset Builder (toolset ID: `toolset-builder`) are created in the appropriate provider directory (if using Claude Code, GitHub Copilot, or Tencent CodeBuddy)
3. The Toolset Builder toolset files are located in `.asdm/toolsets/toolset-builder` (toolset ID: `toolset-builder`)

**For other providers**: Verify that you can access the instruction files at:
- `.asdm/toolsets/toolset-builder/actions/asdm-init-toolset.md`
- `.asdm/toolsets/toolset-builder/actions/asdm-define-features.md`
- `.asdm/toolsets/toolset-builder/actions/asdm-create-specs.md`
- `.asdm/toolsets/toolset-builder/actions/asdm-complete-toolset.md`

## Usage Example

### Creating a New Toolset

```shell
# Step 1: Initialize toolset
/asdm-init-toolset my-toolset

# Step 2: Define features
/asdm-define-features my-toolset

# Step 3: Create specs
/asdm-create-specs my-toolset

# Step 4: Complete and review (generates INSTALL.md and manifest.json)
/asdm-complete-toolset my-toolset
```

## Notes

- This installation process assumes you have the necessary permissions to create directories and files
- Toolset Builder guides you through the development process step by step
- The toolset ID should use lowercase letters, numbers, and hyphens only (e.g., `my-toolset`, `code-review`, `test-generator`)
- All generated files follow ASDM design principles and best practices
- You can iterate and refine the toolset at any step
- The `README.md` is completed by the developer (you), while other files are generated by AI

## Integration with ASDM

Toolset Builder follows ASDM design principles and integrates with the existing ASDM ecosystem:
- Follows the standard toolset directory structure
- Uses the same action and spec conventions
- Supports all major AI coding assistants
- Generates installation instructions compatible with ASDM

### Getting Help
For issues with Toolset Builder, refer to:
- [ASDM Documentation](https://asdm.ai/docs)
- Toolset README: `.asdm/toolsets/toolset-builder/README.md`
- ASDM Design Principles: `ASDM_TOOLSET_DESIGN_PRINCIPLES.md`
- Toolset Development Training: `TOOLSET_DEV_TRAINING.md`

## License
Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.

---

*This installation document is part of the Toolset Builder toolset. Use Toolset Builder to efficiently create new ASDM toolsets.*
