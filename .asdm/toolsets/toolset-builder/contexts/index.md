# Toolset Builder Contexts Index

## Overview

This directory contains reference documentation for toolset developers using Toolset Builder. These documents provide comprehensive guidance on ASDM toolset development principles and best practices.

## Context Documents

### 1. ASDM_TOOLSET_DESIGN_PRINCIPLES.md

**Purpose**: Core design principles for ASDM toolsets

**Target Audience**: Toolset developers, technical architects, AI-assisted development engineers

**Key Topics**:
- Toolset overall architecture
- Action design principles
- Context injection strategies
- Tool usage guidelines
- Execution steps design
- Exit conditions design
- Spec template design
- Installation mechanisms
- Skill and MCP extensions
- Security and compliance requirements
- Error handling design

**Use When**:
- Designing a new toolset
- Understanding ASDM conventions
- Referencing best practices
- Troubleshooting design issues

### 2. TOOLSET_DEV_TRAINING.md

**Purpose**: Training materials for ASDM toolset development

**Target Audience**: Development team members

**Key Topics**:
- What is ASDM Toolset
- Development workflow
- README.md writing guide
- Directory structure explanation
- Skill and MCP extension usage
- Writing examples
- AI-generated content explanation
- Validation and iteration
- Development practices
- Exercises and Q&A

**Use When**:
- Learning toolset development for the first time
- Following the development workflow
- Understanding developer vs AI responsibilities
- Reviewing README.md writing guidelines

## Document Relationships

```
TOOLSET_DEV_TRAINING.md
    ↓ (references)
ASDM_TOOLSET_DESIGN_PRINCIPLES.md
    ↓ (applies to)
Toolset Development
```

**Relationship**:
- TOOLSET_DEV_TRAINING.md is the entry point for new developers
- ASDM_TOOLSET_DESIGN_PRINCIPLES.md provides the technical details
- Both documents complement each other for complete understanding

## Usage Guide

### For New Developers

1. **Start with TOOLSET_DEV_TRAINING.md**
   - Understand the overall development workflow
   - Learn developer vs AI responsibilities
   - Follow the step-by-step guide

2. **Reference ASDM_TOOLSET_DESIGN_PRINCIPLES.md**
   - Deep dive into design principles
   - Understand technical requirements
   - Apply best practices

### For Experienced Developers

1. **Quick Reference**: Use ASDM_TOOLSET_DESIGN_PRINCIPLES.md for specific design questions
2. **Troubleshooting**: Check both documents when encountering issues
3. **Best Practices**: Review regularly to ensure compliance

### For AI Models

When generating toolset components, AI models should:

1. **Read ASDM_TOOLSET_DESIGN_PRINCIPLES.md**
   - Understand the required structure
   - Apply design principles
   - Follow conventions

2. **Consider TOOLSET_DEV_TRAINING.md**
   - Understand the development workflow
   - Align with developer expectations
   - Provide appropriate guidance

## Key Concepts

### Core Principles

1. **Separation of Concerns**
   - Developers describe "what" (README.md)
   - AI implements "how" (actions, specs)

2. **Progressive Context Loading**
   - Load context on-demand
   - Avoid information overload
   - Start with index.md

3. **Deterministic Validation**
   - Validate through actual execution
   - Don't just display commands
   - Verify completion

4. **State Management**
   - Clear state definitions
   - Defined transitions
   - Track changes

5. **Error Recovery**
   - Identify root causes
   - Propose solutions
   - Plan next steps

### Toolset Structure

```
.asdm/toolsets/<toolset-id>/
├── README.md                    # Developer writes
├── INSTALL.md                   # AI generates
├── actions/                     # AI generates
│   ├── <action-name>.md
│   └── ...
└── spec/                        # AI generates
    ├── <spec-name>.md
    └── ...
```

### Development Workflow

```
Developer writes README.md
        ↓
AI reads README.md
        ↓
AI generates actions/
        ↓
AI generates spec/
        ↓
AI generates INSTALL.md
        ↓
Developer validates
```

## Integration with Toolset Builder

These context documents are integrated with Toolset Builder actions:

### /asdm-init-toolset
- References TOOLSET_DEV_TRAINING.md for workflow guidance
- Provides initial structure based on design principles

### /asdm-define-features
- Applies action design principles from ASDM_TOOLSET_DESIGN_PRINCIPLES.md
- Follows training guidelines for feature descriptions

### /asdm-create-specs
- Uses spec template design principles
- Follows training material for spec creation

### /asdm-generate-install
- Applies installation mechanisms from design principles
- Follows training guidelines for installation steps

### /asdm-complete-toolset
- Validates against design principles
- Checks compliance with training requirements

## Best Practices

### Reading the Documents

1. **Start with Overview**: Read the introduction sections first
2. **Focus on Relevant Sections**: Jump to sections relevant to current task
3. **Take Notes**: Note key principles and guidelines
4. **Refer Back**: Keep these documents handy during development

### Applying the Guidelines

1. **Follow Principles**: Adhere to the core design principles
2. **Use Templates**: Leverage provided templates and examples
3. **Validate Compliance**: Check against principles during development
4. **Iterate**: Refine based on feedback from validation

### Sharing Knowledge

1. **Team Training**: Use TOOLSET_DEV_TRAINING.md for team onboarding
2. **Design Reviews**: Reference ASDM_TOOLSET_DESIGN_PRINCIPLES.md during reviews
3. **Continuous Learning**: Review regularly to reinforce understanding

## Version History

| Version | Date | Changes |
|---------|------|----------|
| 1.0 | 2026-03-31 | Initial version with integrated contexts |

## Maintenance

These context documents should be updated when:

- New design principles are established
- Development workflow changes
- Best practices evolve
- New tools or capabilities are added

## Support

For questions about these documents or toolset development:

1. **Check the Documents**: Review the relevant sections
2. **Use Toolset Builder**: Follow the guided development workflow
3. **Refer Examples**: Look at existing toolsets for patterns
4. **Ask for Help**: Contact the ASDM team if needed

---

*This index is part of the Toolset Builder contexts*
*Last updated: 2026-03-31*
