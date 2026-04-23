# ASDM Toolset - Toolset Builder

toolset-id: toolset-builder
toolset-name: Toolset Builder
version: 0.0.2
updated-date: 2026-03-31
toolset-description: A toolset for helping developers create new ASDM toolsets efficiently.

## Overview

Toolset Builder (toolset-id: toolset-builder) is an ASDM toolset designed to help developers create new toolsets efficiently. It provides a structured approach to toolset development, guiding developers through the entire process from initial concept to complete implementation. The toolset generates all necessary files including README.md, INSTALL.md, action files, and spec templates based on developer's requirements.

User can install this toolset into a workspace and run `INSTALL.md` document using `AI Guided Installation` to initialize the toolset for the workspace. Just simply copy and paste the following prompt into your `AI Coding` tool's chat window and hit enter:

```shell
Follow instructions in .asdm/toolsets/toolset-builder/INSTALL.md
```

## Features

Main features of Toolset Builder:

### Common features

- Provide user friendly shortcuts `actions` using provider's entry point to ease the toolset development process
- Provide standard `spec` for creating new toolset files
- Interactive development guidance with step-by-step instructions
- Automatic file generation based on developer input

### Initialize New Toolset (init-toolset)

Initialize a new toolset by collecting essential information:
- Toolset ID (unique identifier)
- Toolset Name (display name)
- Toolset Description (overview of purpose)
- Toolset Version (default: 0.0.1)
- Initial workspace directory structure

Output: Basic toolset directory with README.md template and directory structure

### Define Toolset Features (define-features)

Define the main features and actions for the toolset:
- Collect feature descriptions
- Define action names and purposes
- Specify inputs, outputs, and use cases
- Generate action file templates

Output: Action template files in `actions/` directory

### Create Spec Templates (create-specs)

Create specification document templates for the toolset:
- Define spec document structure
- Create spec template files
- Provide guidelines for using specs

Output: Spec template files in `spec/` directory

### Complete Toolset (complete-toolset)

Review and finalize the toolset:
- Validate all files exist
- Generate INSTALL.md and manifest.json
- Check completeness and consistency
- Generate summary
- Provide next steps

Output: Complete, ready-to-use toolset with INSTALL.md and manifest.json

## Toolset Installation Process

`INSTALL.md` will setup the toolset with the following steps:

- Create `.asdm/toolsets` directory if it doesn't exist
- Detect the current `Agentic Engine` provider, e.g. Claude Code, GitHub Copilot, Tencent CodeBuddy etc.
- Create shortcuts commands for Toolset Builder in provider's entry point, e.g. `.claude/commands`, `.github/prompts`, `.codebuddy/commands` etc.

## Toolset Workflow

Once Toolset Builder is installed, user can use the following commands to create new toolsets:

- `/asdm-init-toolset`: Initialize a new toolset project
- `/asdm-define-features`: Define features and actions for the toolset
- `/asdm-create-specs`: Create specification templates
- `/asdm-complete-toolset`: Generate INSTALL.md, manifest.json and finalize the toolset

## Toolset Structure

The Toolset Builder toolset has the following structure:

```
.asdm/
└── toolsets/
    └── toolset-builder/                       ## Toolset Builder toolset
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

## Toolset Workspace

When creating a new toolset using Toolset Builder, the following structure will be generated:

```
.asdm/toolsets/<toolset-id>/
├── README.md                    ## Toolset description (developer writes)
├── INSTALL.md                   ## Installation instructions (AI generates)
├── actions/                     ## Action instructions (AI generates)
│   ├── <action-name>.md
│   └── ...
└── spec/                        ## Spec templates (AI generates)
    ├── <spec-name>.md
    └── ...
```

## Development Workflow

### Step 1: Initialize Toolset
Use `/asdm-init-toolset` to create a new toolset project with basic structure and README.md template.

### Step 2: Define Features
Use `/asdm-define-features` to define the main features, actions, and workflows for the toolset.

### Step 3: Create Spec Templates
Use `/asdm-create-specs` to create specification document templates needed by the toolset.

### Step 4: Complete and Review
Use `/asdm-complete-toolset` to generate INSTALL.md and manifest.json, finalize the toolset, validate all files, and get a summary.

## Benefits

Using Toolset Builder provides:

1. **Faster Development**: Quickly create new toolsets with guided steps
2. **Consistent Structure**: All toolsets follow the same structure and conventions
3. **Best Practices**: Built-in guidelines based on ASDM design principles
4. **Reduced Errors**: Automated generation reduces manual errors
5. **Documentation Ready**: Includes complete installation and usage documentation
6. **Self-Contained**: Includes all necessary reference documentation (design principles and training materials)

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
