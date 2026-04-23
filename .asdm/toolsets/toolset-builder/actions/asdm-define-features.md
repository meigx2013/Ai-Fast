# Instructions for asdm-define-features action

## Purpose
This instruction guides the AI model to define features and actions for an existing toolset. It collects detailed information about each feature/action, generates action instruction files, and updates the README.md with the feature information.

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

Before defining features, the AI model should read the toolset's README.md and understand the toolset context:

### Context Files to Read (Required)

1. **Toolset README.md** (Required)
   - Path: `.asdm/toolsets/<toolset-id>/README.md`
   - Purpose: Understand the toolset's purpose and existing structure

2. **ASDM Design Principles** (Recommended)
   - Path: `ASDM_TOOLSET_DESIGN_PRINCIPLES.md`
   - Purpose: Follow ASDM conventions for action files

3. **Action Spec Template** (Reference)
   - Path: `.asdm/toolsets/toolset-builder/spec/toolset-action-spec.md`
   - Purpose: Follow the action file structure

## Steps to Define Features and Actions

### 1. Identify the Toolset

The action receives a toolset ID as input. If not provided, prompt the user to select a toolset:
- List existing toolsets in `.asdm/toolsets/`
- Display toolset IDs and names
- Ask user to select which toolset to define features for

### 2. Validate Toolset Exists

Check if the toolset exists:
- Path: `.asdm/toolsets/<toolset-id>/README.md`
- If the README.md doesn't exist, inform the user that the toolset hasn't been initialized yet
- Suggest running `/asdm-init-toolset <toolset-id>` first

### 3. Load Toolset README

Read the toolset's README.md to understand:
- Toolset purpose and overview
- Existing feature descriptions (if any)
- Toolset workflow and structure

### 4. Collect Feature Information

Ask the developer to describe each feature/action for the toolset:

**For each feature/action, collect:**

1. **Feature Name**: Display name for the feature
   - Examples: "Code Scanning", "Report Generation"
   - Should be descriptive

2. **Action Name**: Unique identifier for the action
   - Format: lowercase with hyphens
   - Examples: `code-scan`, `generate-report`
   - Will be used as the command name (e.g., `/code-scan`)

3. **Purpose**: What does this action do?
   - Brief description (1-2 sentences)
   - Should explain the action's goal

4. **Input**: What does this action need?
   - List required parameters
   - List optional parameters
   - Describe parameter formats

5. **Output**: What does this action produce?
   - List output files or artifacts
   - Describe output formats

6. **Use Case**: When should this action be used?
   - Describe typical scenarios
   - Explain user goals

**Prompt Template for Each Feature**:
```
Please describe feature/action #{n}:

1. Feature Name: [e.g., Code Scanning]
2. Action Name: [e.g., code-scan]
3. Purpose: [What does this action do?]
4. Input: [What does it need?]
5. Output: [What does it produce?]
6. Use Case: [When should it be used?]

(Enter 'done' when finished adding features)
```

### 5. Generate Action Instruction Files

For each feature/action, generate an action instruction file following the template from `.asdm/toolsets/toolset-builder/spec/toolset-action-spec.md`:

The action file should include:

```markdown
# Instructions for <action-name> action

## Purpose
This instruction guides the AI model to [purpose description]. It [additional details].

## Language Detection

[Full language detection section - include this if the action generates text content]

## Context Injection

[Context loading strategy - specify what files to read, if any]

## Steps to <Action Name>

### 1. <Step Name>
[Detailed step instructions]

### 2. <Step Name>
[Detailed step instructions]

[Continue for all steps - provide a logical workflow]

## Execution Guidelines

### When to Use This Action

Use this action when:
- [Condition 1]
- [Condition 2]

### <Guideline Category>

[Additional guidelines as needed]

## Usage

To use this instruction, the AI model should:
1. [Step 1]
2. [Step 2]

## Output Summary

After completing the action, the following artifacts will be generated:
- [Artifact 1]
- [Artifact 2]

All files will be saved in [location].
```

**Important**:
- Follow the action file specification structure
- Include Language Detection section if the action generates text
- Include Context Injection section with relevant files
- Provide detailed, actionable steps
- Include execution guidelines and usage instructions
- Specify output summary clearly

**Action File Path**: `.asdm/toolsets/<toolset-id>/actions/<action-name>.md`

### 6. Update README.md

Update the toolset's README.md to include the features section:

Add or update the Features section in README.md:

```markdown
## Features

### Common features

[Developer may add common features here]

### Feature 1: <Feature Name>

<Purpose description from feature information>

**Input**: [Input description]
**Output**: [Output description]
**Use Case**: [Use case description]

### Feature 2: <Feature Name>

[Purpose description]

**Input**: [Input description]
**Output**: [Output description]
**Use Case**: [Use case description]

[Continue for all features]
```

Update the Workflow section to include the new commands:

```markdown
## Toolset Workflow

Once <Toolset Name> is installed, user can use the following commands:

- `/action-one`: [Brief description]
- `/action-two`: [Brief description]
- `/action-three`: [Brief description]

[Continue for all actions]
```

Update the Toolset Structure section to include the new action files:

```markdown
## Toolset Structure

The <Toolset Name> toolset has the following structure:

```
.asdm/
└── toolsets/
    └── <toolset-id>/
        ├── INSTALL.md
        ├── README.md
        ├── actions/
        │   ├── <action-one>.md
        │   ├── <action-two>.md
        │   └── <action-three>.md
        └── spec/
            ├── <spec-name>.md
            └── ...
```
```

### 7. Remove Placeholder Files

Remove the `.gitkeep` files from the directories:
- Delete `.asdm/toolsets/<toolset-id>/actions/.gitkeep`
- Delete `.asdm/toolsets/<toolset-id>/spec/.gitkeep`

These are no longer needed since the directories now contain actual files.

### 8. Generate Feature Definition Summary

Create a summary for the developer:

```markdown
# Feature Definition Summary

## Toolset
- **Toolset ID**: <toolset-id>
- **Toolset Name**: <Toolset Name>

## Defined Features

| Feature Name | Action Name | Purpose |
|--------------|-------------|---------|
| <Feature 1> | <action-one> | <Purpose> |
| <Feature 2> | <action-two> | <Purpose> |
| ... | ... | ... |

## Generated Files
- Action files in `.asdm/toolsets/<toolset-id>/actions/`
- Updated README.md with features and workflow

## Next Steps
1. Review the generated action files
2. Use `/asdm-create-specs <toolset-id>` to create spec templates
3. Use `/asdm-generate-install <toolset-id>` to generate installation guide
4. Use `/asdm-complete-toolset <toolset-id>` to finalize the toolset

## Important Notes
- Action files contain detailed instructions for AI models
- Each action should have clear, executable steps
- Review the context injection in each action file
- Ensure actions follow ASDM design principles
```

Save this summary to a temporary location or display it to the developer.

## Execution Guidelines

### When to Use This Action

Use this action when:
- You have initialized a toolset and need to define its features
- You want to create action instruction files
- You need to update the README.md with feature information

### Feature Definition Guidelines

When defining features and actions:

1. **Be Descriptive**: Provide clear descriptions of what each action does
2. **Consider Workflow**: Actions should form a logical workflow
3. **Define Clear Inputs/Outputs**: Specify what each action needs and produces
4. **Think About Context**: What context files should each action read?
5. **Follow ASDM Principles**: Align with ASDM design principles

### Action Name Guidelines

When choosing action names:
- Use lowercase letters only
- Use hyphens to separate words
- Keep them short but descriptive
- Avoid conflicts with existing commands

**Good Examples**:
- `code-scan`
- `generate-report`
- `analyze-requirements`
- `deploy-service`

### Steps Guidelines

When writing action steps:
- Make each step clear and actionable
- Number steps sequentially
- Use descriptive step names
- Include specific file paths where relevant
- Provide examples where helpful
- Consider error handling

## Usage

To use this instruction, the AI model should:
1. Detect the response language
2. Identify the toolset (prompt if not provided)
3. Validate the toolset exists and has been initialized
4. Load the toolset's README.md
5. Collect feature information from the developer for each feature
6. Generate action instruction files following the action spec template
7. Update the README.md with features, workflow, and structure
8. Remove placeholder `.gitkeep` files
9. Present a feature definition summary with next steps

## Output Summary

After completing the feature definition, the following will be generated:
- Action instruction files: `.asdm/toolsets/<toolset-id>/actions/<action-name>.md` (one for each feature)
- Updated README.md with features section and workflow
- Removed placeholder `.gitkeep` files

All action files follow the structure defined in `.asdm/toolsets/toolset-builder/spec/toolset-action-spec.md` and include detailed execution steps for AI models.
