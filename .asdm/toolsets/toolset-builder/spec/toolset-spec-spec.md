# Toolset Spec Template Specification

## Overview

This specification defines guidelines for creating spec (specification) template files. Spec templates (located in `spec/` directory) define the structure and format for documents that toolsets generate.

**Note**: Spec templates provide structure and guidelines for output documents. They are referenced by action files to ensure consistent output format.

---

## What Are Spec Templates?

Spec templates serve two main purposes:

1. **Define Structure**: Specify how output documents should be structured
2. **Provide Guidelines**: Offer instructions for generating content according to the structure

Spec templates are NOT the actual output documents. They are the blueprints or schemas that define what output documents should look like.

---

## Spec Template Types

Common types of spec templates include:

1. **Output Document Specs**: Define structure for documents toolsets generate (e.g., analysis documents, reports)
2. **List/File Specs**: Define structure for tracking lists or data files
3. **Configuration Specs**: Define structure for configuration files
4. **Workflow Specs**: Define guidelines for workflows or processes

---

## Spec Template Structure

A spec template should include the following sections:

```markdown
# <Spec Name> Specification

## Language Guidelines

[Instructions about language consistency]

## Overview

[Brief overview of what this spec defines]

## Document Structure

[Template structure with placeholders]

## Section Guidelines

[Detailed guidelines for each section]

## Usage Guidelines

[How to use this spec]

## Output Format

[Expected output format]

## Best Practices

[Tips and best practices]

## Related Documents

[References to related files]

## Checklist

[Validation checklist]
```

---

## Section Guidelines

### 1. Title

Format: `# <Spec Name> Specification` or `# <Spec Name> Template`

The spec name should:
- Be descriptive of what it defines
- Use clear, recognizable terms
- Match the output document type (e.g., "Requirement Analysis Specification")

### 2. Language Guidelines

Ensure spec templates support multiple languages:

```markdown
## Language Guidelines

This <document type> must use the detected response language from the environment. Ensure all content in this document follows:

1. **Language Consistency**: Use the same language throughout the entire document
2. **Writing Conventions**: Follow the detected language's writing style and formatting
3. **Clarity**: Ensure content is clear and understandable in the chosen language

**Supported Languages**:
- English (en)
- Chinese (zh)
- Other languages based on environment detection
```

This section should be included in every spec template that defines documents with text content.

### 3. Overview Section

Briefly explain what this spec defines:

```markdown
## Overview

本规范定义了<document type>的结构和格式要求。此类文档用于<purpose>。

**主要用途**:
- Use case 1
- Use case 2
- Use case 3
```

Keep it concise (1-2 paragraphs).

### 4. Document Structure Section

Define the template structure:

```markdown
## Document Structure

使用以下模板结构 when generating <document type>:

```markdown
<complete template with placeholders>
```

**Key Elements**:
- Element 1: Description
- Element 2: Description
- Element 3: Description
```

**Important**:
- Use code blocks for the actual template
- Use descriptive placeholders (e.g., `<field-name>`, `<description>`)
- Provide explanations for complex sections
- Include examples where helpful

### 5. Section Guidelines

Provide detailed guidelines for each major section:

```markdown
## Section Guidelines

### 5.1 <Section 1 Name>

<Description of what this section contains>

#### Guidelines

- Guideline 1
- Guideline 2

#### Example

```markdown
<example of this section>
```

### 5.2 <Section 2 Name>

[Continue for all major sections]
```

### 6. Usage Guidelines

Explain how to use this spec:

```markdown
## Usage Guidelines

When generating <document type>:

1. **Step 1**: Description
2. **Step 2**: Description
3. **Step 3**: Description

**Important**:
- Important consideration 1
- Important consideration 2
```

### 7. Output Format Section

Specify the expected output format:

```markdown
## Output Format

The <document type> should be output in:

**Format**: <format specification>
**Location**: <where to save>
**Naming**: <naming convention>

**Format Details**:
- Detail 1
- Detail 2

**Example**:
- Example output path: `path/to/output.md`
- Example naming: `<id>-<name>-type.ext`
```

### 8. Best Practices Section

Provide tips and best practices:

```markdown
## Best Practices

When working with this spec:

1. **Practice 1**: Description
2. **Practice 2**: Description
3. **Practice 3**: Description

### Common Pitfalls to Avoid

- Pitfall 1: How to avoid
- Pitfall 2: How to avoid
```

### 9. Related Documents Section

Reference related files:

```markdown
## Related Documents

This spec template works with:

- **<spec 1>**: Description
- **<action 1>**: Description

This spec is used by:

- **<action 2>**: Description
- **<action 3>**: Description
```

### 10. Checklist Section

Provide a validation checklist:

```markdown
## Checklist

Before finalizing <document type>, check:

- [ ] <Check 1>
- [ ] <Check 2>
- [ ] <Check 3>

For <specific aspect>, verify:

- [ ] <Specific check 1>
- [ ] <Specific check 2>
```

---

## Writing Guidelines

### Clarity

- Be clear about what each section should contain
- Provide concrete examples
- Avoid ambiguous language

### Completeness

- Cover all aspects of the output document
- Define all required fields
- Include optional fields and mark them as such

### Consistency

- Use consistent terminology
- Follow the same structure across sections
- Maintain similar level of detail

### Flexibility

- Allow for reasonable variation where appropriate
- Mark optional vs. required content
- Provide guidance rather than rigid rules

---

## Example: Simple Spec Template

```markdown
# Task List Specification

## Language Guidelines

This task list must use the detected response language...

[Full language guidelines section]

## Document Structure

Use following template structure when creating a task list:

```markdown
# 任务列表

**最后更新日期**: <YYYY-MM-DD>
**语言**: <detected-language>

## 1. 摘要

| 统计项 | 数量 |
|--------|------|
| 总任务数 | <总数> |
| 待完成 | <数量> |
| 进行中 | <数量> |
| 已完成 | <数量> |

## 2. 任务明细

| 任务ID | 任务名称 | 描述 | 状态 | 优先级 | 创建日期 |
|--------|---------|------|------|--------|----------|
| TASK-001 | <任务名称> | <简要描述> | 待完成 | 高/中/低 | YYYY-MM-DD |
| TASK-002 | <任务名称> | <简要描述> | 进行中 | 高/中/低 | YYYY-MM-DD |
| ... | ... | ... | ... | ... | ... |

## 3. 维护说明

### 3.1 添加新任务
[Instructions for adding tasks]

### 3.2 更新任务状态
[Instructions for updating status]
```

**Key Elements**:
- Summary table with task counts
- Task list table with all task information
- Maintenance instructions

## Section Guidelines

### 3.1 Summary Table

The summary table should include:
- Total number of tasks
- Count by status (TODO, IN PROGRESS, DONE)
- Update whenever tasks are added or status changes

### 3.2 Task List Table

The task list table should include:
- Task ID (unique identifier)
- Task name
- Brief description
- Status
- Priority
- Creation date

## Usage Guidelines

When maintaining the task list:

1. **Keep it Updated**: Update task status promptly
2. **Accurate Counts**: Ensure summary matches detail list
3. **Consistent Naming**: Follow task ID naming convention
4. **Record Dates**: Track creation and update dates

## Output Format

**Format**: Markdown
**Location**: `.asdm/workspace/tasks/task-list.md`
**Naming**: Fixed filename `task-list.md`

## Best Practices

When working with task lists:

1. **Regular Reviews**: Review task list regularly
2. **Status Tracking**: Keep status current
3. **Priority Management**: Assign appropriate priorities
4. **Clear Descriptions**: Use clear, concise descriptions

## Related Documents

This spec is used by:
- **Action: /task-planning**: Creates task lists
- **Action: /task-execution**: Updates task status

## Checklist

Before finalizing task list:

- [ ] All tasks are listed
- [ ] Summary counts are accurate
- [ ] Status values are valid
- [ ] Task IDs are unique
- [ ] Dates are in correct format (YYYY-MM-DD)
```

---

## Common Spec Patterns

### Pattern 1: Document with Tables

```markdown
## Document Structure

```markdown
# <Document Name>

## Table Section

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
```

**Key Elements**:
- Table with clear column headers
- Consistent data formatting
```

### Pattern 2: Document with Sections

```markdown
## Document Structure

```markdown
# <Document Name>

## 1. Section One
<Content>

## 2. Section Two
<Content>

### 2.1 Subsection
<Content>
```

**Key Elements**:
- Numbered sections (1, 2, 3...)
- Subsections (2.1, 2.2...)
- Clear hierarchy
```

### Pattern 3: Document with Metadata

```markdown
## Document Structure

```markdown
# <Document Name>

**Field 1**: <Value 1>
**Field 2**: <Value 2>
**Field 3**: <Value 3>

## Content

<Main content>
```

**Key Elements**:
- Metadata at top in key-value format
- Main content below
- Clear separation
```

---

## Best Practices

### 1. Define Structure Clearly

- Show complete template in code block
- Use descriptive placeholders
- Explain complex sections
- Provide examples

### 2. Include Language Guidelines

For specs that define text documents:
- Always include language guidelines
- Place early in the spec
- Emphasize importance

### 3. Be Specific About Format

- Specify exact format requirements
- Define field types (string, date, enum, etc.)
- Provide format examples
- Specify allowed values for enums

### 4. Provide Usage Instructions

- Explain how to use the spec
- Give step-by-step guidance
- Highlight important considerations
- Include best practices

### 5. Include Validation

- Provide checklist for validation
- Define required vs. optional fields
- Specify constraints or rules
- Give examples of valid/invalid data

---

## Checklist for Writing Spec Templates

Before finalizing your spec template, check:

- [ ] Title is descriptive
- [ ] Language Guidelines are included (if relevant)
- [ ] Overview is clear
- [ ] Document Structure is complete with placeholders
- [ ] Section Guidelines are detailed
- [ ] Usage Guidelines are provided
- [ ] Output Format is specified
- [ ] Best Practices are included
- [ ] Related Documents are referenced
- [ ] Checklist for validation is provided
- [ ] Examples are clear and helpful
- [ ] No ambiguous language

---

## Related Documents

This specification is used by:
- **Toolset Builder**: `/asdm-create-specs` action generates spec templates based on this spec
- **Developers**: Follow this spec when creating spec templates
- **Action Files**: Reference spec templates for output format
