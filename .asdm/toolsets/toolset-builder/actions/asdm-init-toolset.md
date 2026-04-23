# Instructions for asdm-init-toolset action

## Purpose
This instruction guides the AI model to initialize a new toolset project. It collects essential information from the developer, creates the basic directory structure, and generates a README.md template with placeholders for the developer to complete.

## Language Detection

Before generating any files, you must detect and use the current environment's response language:

1. **Detect Response Language**: Analyze the environment settings to determine the primary language:
   - Check system/user language settings or environment configuration
   - Identify the primary language used in project documentation and comments
   - Determine the language preference based on workspace context

2. **Apply Language Consistency**: Ensure all generated files use the detected language:
   - Use the same language for all markdown files, comments, and documentation
   - Maintain language consistency across all generated files
   - Follow the detected language's writing conventions and formatting

3. **Supported Languages**:
   - English (en)
   - Chinese (zh)
   - Other languages as needed based on environment detection

**IMPORTANT**: The language detection is the FIRST step before any file generation. All output must consistently use the detected language throughout the entire process.

## Context Injection

Before initializing a toolset, the AI model should read and understand the ASDM context if available:

### Context Files to Read (Optional)

1. **ASDM Design Principles** (Recommended)
   - Path: `.asdm/toolsets/toolset-builder/contexts/ASDM_TOOLSET_DESIGN_PRINCIPLES.md`
   - Purpose: Understand ASDM design principles and best practices

2. **Toolset Development Training** (Recommended)
   - Path: `.asdm/toolsets/toolset-builder/contexts/TOOLSET_DEV_TRAINING.md`
   - Purpose: Understand the toolset development workflow

3. **Existing Toolset Examples** (Optional)
   - Read a few existing toolset READMEs as examples
   - Purpose: Understand common patterns and conventions

## Steps to Initialize New Toolset

### 1. Receive Toolset Information

Collect the following information from the developer:

#### Required Information:
- **Toolset ID**: Unique identifier for the toolset
  - Format: lowercase letters, numbers, and hyphens only
  - Examples: `my-toolset`, `code-review`, `test-generator`
  - Must be unique among existing toolsets

- **Toolset Name**: Display name for the toolset
  - Can include spaces and mixed case
  - Examples: "Code Review", "Test Generator", "My Toolset"

- **Toolset Description**: Brief description of what the toolset does
  - One or two sentences
  - Should explain the toolset's purpose

- **Toolset Scenario**: Usage scenario or context for the toolset
  - Describes when and why users would use this toolset
  - Examples: "Writing product requirements documents", "Code review and quality assurance", "API documentation generation"
  - Should help users understand the toolset's primary use case

#### Optional Information (use defaults if not provided):
- **Toolset Version**: Default: `0.0.1`
- **Updated Date**: Default: today's date (YYYY-MM-DD format)

**Prompt Template**:
```
Please provide the following information for your new toolset:

1. Toolset ID (required): [e.g., my-toolset]
2. Toolset Name (required): [e.g., Code Review Toolset]
3. Toolset Description (required): [Brief description]
4. Toolset Scenario (required): [e.g., 需求分析、方案设计、代码编写、测试用例生成等]
5. Toolset Version (optional, default: 0.0.1):
6. Updated Date (optional, default: today):
```

### 2. Validate Toolset ID

Check if the toolset ID is unique:
- List existing toolsets in `.asdm/toolsets/`
- If toolset ID already exists, ask the developer to choose a different ID
- Toolset ID should not conflict with existing toolsets

### 3. Create Toolset Directory Structure

Create the following directory structure:

```bash
mkdir -p .asdm/toolsets/<toolset-id>
mkdir -p .asdm/toolsets/<toolset-id>/actions
mkdir -p .asdm/toolsets/<toolset-id>/spec
```

### 4. Generate README.md Template

Create a README.md file following the template from `.asdm/toolsets/toolset-builder/spec/toolset-readme-spec.md`:

The README.md should include:

```markdown
# ASDM Toolset - <Toolset Name>

toolset-id: <toolset-id>
toolset-name: <Toolset Name>
version: <version>
updated-date: <updated-date>
toolset-description: <toolset-description>

## Overview

[Developer completes this section - 2-3 paragraphs describing what the toolset does, who it's for, and what problem it solves]

## Features

### Common features

[Developer completes this section]

### Feature 1: <Feature Name>
[Developer completes this section with feature description]

### Feature 2: <Feature Name>
[Developer completes this section with feature description]

[Developer adds more features as needed]

## Toolset Installation Process

`INSTALL.md` will setup the toolset with the following steps:

[Developer briefly describes what installation will do - refer to INSTALL.md for details]

## Toolset Workflow

Once <Toolset Name> is installed, user can use the following commands:

[Developer lists available commands/workflows]

## Toolset Structure

The <Toolset Name> toolset has the following structure:

```
.asdm/
└── toolsets/
    └── <toolset-id>/
        ├── INSTALL.md
        ├── README.md
        ├── actions/
        │   ├── <action-name>.md
        │   └── ...
        └── spec/
            ├── <spec-name>.md
            └── ...
```

## Toolset Workspace

The <Toolset Name> toolset has the following workspace structure:

```
.asdm/workspace/<workspace-type>/
├── <files>
└── <directories>
```

[Developer completes this section based on the toolset's needs]

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
```

**IMPORTANT**: The README.md is written by the developer. This is a template with placeholders that the developer should complete.

### 5. Create Placeholder Files

Create empty placeholder files for future use:

- `actions/.gitkeep` - Keeps the actions directory in version control
- `spec/.gitkeep` - Keeps the spec directory in version control

### 6. Generate Initialization Summary

Create a summary for the developer:

```markdown
# Toolset Initialization Summary

## Toolset Information
- **Toolset ID**: <toolset-id>
- **Toolset Name**: <Toolset Name>
- **Toolset Version**: <version>
- **Updated Date**: <updated-date>
- **Description**: <toolset-description>
- **Scenario**: <toolset-scenario>

## Created Files
- `.asdm/toolsets/<toolset-id>/README.md` (Template - needs completion)
- `.asdm/toolsets/<toolset-id>/actions/` (Directory)
- `.asdm/toolsets/<toolset-id>/spec/` (Directory)

## Next Steps
1. Complete the README.md file by filling in all placeholders
2. Use `/asdm-define-features <toolset-id>` to define features and actions
3. Use `/asdm-create-specs <toolset-id>` to create spec templates
4. Use `/asdm-generate-install <toolset-id>` to generate installation guide
5. Use `/asdm-complete-toolset <toolset-id>` to finalize the toolset

## Important Notes
- The README.md is your primary documentation - complete it thoroughly
- Follow ASDM design principles from `.asdm/toolsets/toolset-builder/contexts/ASDM_TOOLSET_DESIGN_PRINCIPLES.md`
- Use existing toolsets as examples (e.g., prd-builder, prd-analyzer)
- Refer to `.asdm/toolsets/toolset-builder/contexts/TOOLSET_DEV_TRAINING.md` for development guidance
```

Save this summary to a temporary location or display it to the developer.

## Execution Guidelines

### When to Use This Action

Use this action when:
- You want to start developing a new toolset
- You need a structured starting point for toolset development
- You want to ensure your toolset follows ASDM conventions

### Initialization Guidelines

When initializing a new toolset:

1. **Choose a Good ID**: Use descriptive, lowercase IDs with hyphens
2. **Write a Clear Description**: The description should be concise but informative
3. **Start with README**: Focus on completing the README.md first
4. **Think About Structure**: Consider what actions and specs you'll need
5. **Follow Conventions**: Align with existing toolsets and ASDM principles

### Toolset ID Guidelines

When choosing a toolset ID:
- Use lowercase letters only
- Use hyphens to separate words
- Avoid special characters and spaces
- Keep it short but descriptive
- Ensure it's unique

**Good Examples**:
- `code-review`
- `test-generator`
- `api-doc-builder`
- `deploy-helper`

**Bad Examples**:
- `MyToolset` (uppercase)
- `my toolset` (spaces)
- `my_toolset` (underscores)
- `toolset-001` (not descriptive)

## Usage

To use this instruction, the AI model should:
1. Detect the response language
2. Read ASDM context files if available (optional but recommended)
3. Collect toolset information from the developer (ID, name, description, scenario, version, date)
4. Validate the toolset ID is unique
5. Create the directory structure
6. Generate a README.md template with placeholders
7. Create placeholder files for actions/ and spec/ directories
8. Present an initialization summary with next steps

## Output Summary

After completing the initialization, the following will be generated:
- Toolset directory: `.asdm/toolsets/<toolset-id>/`
- README.md template: `.asdm/toolsets/<toolset-id>/README.md` (developer completes)
- Empty directories: `actions/` and `spec/`
- Placeholder files: `.gitkeep` files for version control

The README.md is a template that the developer needs to complete. It contains placeholders and guidance for filling in the toolset's features, workflow, structure, and workspace requirements.
