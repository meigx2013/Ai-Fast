# Instructions for asdm-create-specs action

## Purpose
This instruction guides the AI model to create specification template files for an existing toolset. It collects information about the spec documents needed, generates spec template files, and updates the README.md with spec information.

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

Before creating specs, the AI model should read the toolset's README.md and action files:

### Context Files to Read (Required)

1. **Toolset README.md** (Required)
   - Path: `.asdm/toolsets/<toolset-id>/README.md`
   - Purpose: Understand the toolset's purpose and features

2. **Action Files** (Required)
   - Path: `.asdm/toolsets/<toolset-id>/actions/*.md`
   - Purpose: Understand what output documents the actions will generate

3. **Spec Spec Template** (Reference)
   - Path: `.asdm/toolsets/toolset-builder/spec/toolset-spec-spec.md`
   - Purpose: Follow the spec template structure

## Steps to Create Spec Templates

### 1. Identify the Toolset

The action receives a toolset ID as input. If not provided, prompt the user to select a toolset:
- List existing toolsets in `.asdm/toolsets/`
- Display toolset IDs and names
- Ask user to select which toolset to create specs for

### 2. Validate Toolset Exists

Check if the toolset exists:
- Path: `.asdm/toolsets/<toolset-id>/README.md`
- If the README.md doesn't exist, inform the user that the toolset hasn't been initialized yet
- Suggest running `/asdm-init-toolset <toolset-id>` first

### 3. Load Toolset Information

Read the toolset's README.md and action files to understand:
- Toolset purpose and features
- What output documents the actions will generate
- What structure/format those documents need

### 4. Identify Required Specs

Analyze the action files to determine what spec templates are needed:

**Common spec types:**
1. **Output Document Specs**: For documents that actions generate (e.g., analysis reports, feature PRDs)
2. **List/File Specs**: For tracking lists or data files (e.g., feature lists, task lists)
3. **Configuration Specs**: For configuration files (if applicable)

**Method to Identify Specs:**
- Read each action file's "Output Summary" section
- List all output files mentioned
- Determine if a spec template is needed for each output type
- Ask the developer to confirm or modify the spec list

**Prompt Template**:
```
Based on the toolset's actions, I've identified the following spec templates that may be needed:

1. <Spec 1 Name> - <Purpose>
2. <Spec 2 Name> - <Purpose>
3. <Spec 3 Name> - <Purpose>

Do you want to:
- A) Use all suggested specs
- B) Remove some specs (specify which)
- C) Add more specs (specify which)

Please choose A, B, or C and provide details if needed.
```

### 5. Collect Spec Information

For each spec template, collect the following information:

1. **Spec Name**: Name of the spec template
   - Examples: "Requirement Analysis Specification", "Feature List Specification"
   - Should be descriptive of what it defines

2. **Spec Filename**: Filename for the spec template
   - Format: lowercase with hyphens, ending with `-spec.md`
   - Examples: `requirement-analysis-spec.md`, `feature-list-spec.md`

3. **Purpose**: What does this spec define?
   - Brief description of the output document structure
   - What the output document is used for

4. **Document Structure**: What sections should the output document have?
   - List the main sections
   - Brief description of each section

5. **Key Elements**: What are the key elements of the output document?
   - List important fields or components
   - Specify required vs. optional

6. **Output Format**: What format should the output be?
   - Format type (Markdown, JSON, XML, etc.)
   - File naming convention
   - File location

**Prompt Template for Each Spec**:
```
Please provide details for spec template: "<Spec Name>"

1. Document Purpose: [What does this output document do?]
2. Document Structure: [List main sections with brief descriptions]
3. Key Elements: [List important fields/components]
4. Output Format: [What format? Where saved? Naming convention?]

(Enter 'done' when finished with this spec)
```

### 6. Generate Spec Template Files

For each spec, generate a spec template file following the structure from `.asdm/toolsets/toolset-builder/spec/toolset-spec-spec.md`:

The spec template should include:

```markdown
# <Spec Name> Specification

## Language Guidelines

This <document type> must use the detected response language from the environment. Ensure all content in this document follows:

1. **Language Consistency**: Use the same language throughout the entire document
2. **Writing Conventions**: Follow the detected language's writing style and formatting
3. **Clarity**: Ensure content is clear and understandable in the chosen language

**Supported Languages**:
- English (en)
- Chinese (zh)
- Other languages based on environment detection

---

## Overview

本规范定义了<document type>的结构和格式要求。此类文档用于<purpose from spec info>.

**主要用途**:
- Use case 1
- Use case 2
- Use case 3

---

## Document Structure

使用以下模板结构 when generating <document type>:

```markdown
# <Document Title>

**Field 1**: <value-placeholder>
**Field 2**: <value-placeholder>

## 1. <Section 1 Title>

<Content placeholder for section 1>

### 1.1 <Subsection Title>
<Content placeholder for subsection>

## 2. <Section 2 Title>

<Content placeholder for section 2>

[Continue for all sections]
```

**Key Elements**:
- Element 1: <Description>
- Element 2: <Description>
- Element 3: <Description>

---

## Section Guidelines

### <Section 1> Guidelines

<Provide detailed guidelines for this section>

**Important**:
- Important consideration 1
- Important consideration 2

**Example**:
```markdown
<Example of this section>
```

### <Section 2> Guidelines

<Provide detailed guidelines for this section>

[Continue for all major sections]

---

## Usage Guidelines

When generating <document type>:

1. **Step 1**: <Description>
2. **Step 2**: <Description>
3. **Step 3**: <Description>

**Important**:
- Important consideration 1
- Important consideration 2

---

## Output Format

The <document type> should be output in:

**Format**: <format specification from spec info>
**Location**: <location from spec info>
**Naming**: <naming convention from spec info>

**Format Details**:
- Detail 1
- Detail 2

**Example**:
- Example output path: `<example-path>`
- Example naming: `<example-naming>`

---

## Best Practices

When working with this spec:

1. **Practice 1**: Description
2. **Practice 2**: Description
3. **Practice 3**: Description

### Common Pitfalls to Avoid

- Pitfall 1: How to avoid
- Pitfall 2: How to avoid

---

## Related Documents

This spec template works with:

- **<spec 1>**: Description
- **<spec 2>**: Description

This spec is used by:

- **Action: <action-name>**: Description
- **Action: <action-name>**: Description

---

## Checklist

Before finalizing <document type>, check:

- [ ] <Check 1>
- [ ] <Check 2>
- [ ] <Check 3>

For <specific aspect>, verify:

- [ ] <Specific check 1>
- [ ] <Specific check 2>
```

**Important**:
- Follow the spec template specification structure
- Include Language Guidelines section
- Provide complete Document Structure with placeholders
- Include Section Guidelines for major sections
- Specify Output Format clearly
- Include Best Practices and Checklist sections
- Reference related documents and actions

**Spec File Path**: `.asdm/toolsets/<toolset-id>/spec/<spec-filename>`

### 7. Update README.md

Update the toolset's README.md to include spec information in the Toolset Structure section:

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
        │   └── ...
        └── spec/
            ├── <spec-one>.md
            ├── <spec-two>.md
            └── <spec-three>.md
```

### Spec Documents

The toolset uses the following spec documents as templates:

- **<spec-one>**: Template for generating <document type>
- **<spec-two>**: Template for generating <document type>
- **<spec-three>**: Template for generating <document type>
```

### 8. Generate Spec Creation Summary

Create a summary for the developer:

```markdown
# Spec Template Creation Summary

## Toolset
- **Toolset ID**: <toolset-id>
- **Toolset Name**: <Toolset Name>

## Created Spec Templates

| Spec Name | Filename | Purpose |
|-----------|----------|---------|
| <Spec 1> | <spec-one>.md | <Purpose> |
| <Spec 2> | <spec-two>.md | <Purpose> |
| ... | ... | ... |

## Generated Files
- Spec template files in `.asdm/toolsets/<toolset-id>/spec/`
- Updated README.md with spec information

## Next Steps
1. Review the generated spec templates
2. Use `/asdm-generate-install <toolset-id>` to generate installation guide
3. Use `/asdm-complete-toolset <toolset-id>` to finalize the toolset

## Important Notes
- Spec templates define the structure for output documents
- Actions will reference these specs when generating documents
- Ensure spec templates are complete and accurate
- Review section guidelines carefully
```

Save this summary to a temporary location or display it to the developer.

## Execution Guidelines

### When to Use This Action

Use this action when:
- You have defined the toolset's features and actions
- You need to create spec templates for output documents
- You want to ensure consistent output format across your toolset

### Spec Creation Guidelines

When creating spec templates:

1. **Identify What's Needed**: Analyze actions to determine what specs are required
2. **Be Specific**: Clearly define document structure and format
3. **Provide Guidelines**: Include detailed guidelines for each section
4. **Think About Usage**: Consider how actions will use these specs
5. **Follow Standards**: Align with ASDM spec conventions

### Spec Name Guidelines

When naming spec files:
- Use descriptive names
- End with `-spec.md` suffix
- Use lowercase with hyphens
- Keep names concise

**Good Examples**:
- `feature-prd-spec.md`
- `requirement-analysis-spec.md`
- `task-list-spec.md`

## Usage

To use this instruction, the AI model should:
1. Detect the response language
2. Identify the toolset (prompt if not provided)
3. Validate the toolset exists and has been initialized
4. Load the toolset's README.md and action files
5. Identify required spec templates by analyzing action outputs
6. Collect spec information from the developer for each spec
7. Generate spec template files following the spec spec template
8. Update the README.md with spec information
9. Present a spec creation summary with next steps

## Output Summary

After completing the spec creation, the following will be generated:
- Spec template files: `.asdm/toolsets/<toolset-id>/spec/<spec-filename>` (one for each spec)
- Updated README.md with spec information

All spec templates follow the structure defined in `.asdm/toolsets/toolset-builder/spec/toolset-spec-spec.md` and provide detailed structure and guidelines for output documents.
