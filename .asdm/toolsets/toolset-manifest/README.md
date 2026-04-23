# ASDM Toolset - Toolset Manifest File Add

toolset-id: toolset-manifest
toolset-name: Toolset Manifest File Add
version: 0.0.1
updated-date: 2026-04-17
toolset-description: 为缺少 manifest.json 文件的工具集自动获取信息创建 manifest 文件。

## Overview

Toolset Manifest File Add (toolset-id: toolset-manifest) is an ASDM toolset that automatically generates manifest.json files for existing toolsets. It reads metadata from README.md, scans available actions from the actions/ directory, and guides users to input the scenario information to create a complete manifest.json file.

User can install this toolset into a workspace and run `INSTALL.md` document using `AI Guided Installation` to initialize the toolset for the workspace. Just simply copy and paste the following prompt into your `AI Coding` tool's chat window and hit enter:

```shell
Follow instructions in .asdm/toolsets/toolset-manifest/INSTALL.md
```

## Features

Main features of Toolset Manifest File Add:

### Common features

- **Automatic Metadata Extraction**: Parses registry_id, name, description, and version from README.md
- **Action Discovery**: Scans the actions/ directory to automatically collect all available action commands
- **Interactive Scenario Confirmation**: Confirms with user for toolset usage scenario (6 characters or less)
- **JSON Validation**: Validates the generated JSON format before saving
- **Safe Overwrite Protection**: Prompts user confirmation if manifest.json already exists

### Generate Manifest (generate-manifest)

Generate a manifest.json file for a specified toolset directory.

**Input**:
- Toolset root directory path (user-specified)

**Output**:
- `manifest.json` file with complete toolset metadata

**Processing Flow**:
1. Read README.md from target directory, extract metadata (registry_id, name, description, version)
2. Scan actions/ directory, collect all .md files as commands list
3. Guide user to input/confirm scenario
4. Generate manifest.json file with configType set to "toolset"

**manifest.json Structure**:
```json
{
  "registry_id": "<toolset-id>",
  "name": "<toolset-name>",
  "description": "<toolset-description>",
  "scenario": "<toolset-scenario>",
  "version": "<version>",
  "configType": "toolset",
  "commands": ["<action-name-1>", "<action-name-2>", "..."]
}
```

**Use Case**: Generate manifest.json quickly for newly created toolsets that lack one.

## Toolset Installation Process

`INSTALL.md` will setup the toolset with the following steps:

- Create `.asdm/workspace/toolset-manifest` workspace directory
- Detect the current `Agentic Engine` provider, e.g. Claude Code, GitHub Copilot, Tencent CodeBuddy etc.
- Create shortcut command `/asdm-generate-manifest` in provider's entry point

## Toolset Workflow

Once Toolset Manifest File Add is installed, user can use the following command:

- `/asdm-generate-manifest`: Generate manifest.json for a specified toolset directory
  - User specifies the toolset root directory
  - Automatically extracts information from README.md
  - Automatically scans actions directory
  - Confirms with user for scenario (6 characters or less)
  - Generates manifest.json

## Toolset Structure

The Toolset Manifest File Add toolset has the following structure:

```
.asdm/
└── toolsets/
    └── toolset-manifest/                       ## Toolset Manifest File Add
        ├── INSTALL.md                           ## Installation instructions
        ├── README.md                            ## Current document
        ├── actions/                             ## Action instructions
        │   └── asdm-generate-manifest.md        ## Generate manifest action
        └── spec/                                ## Spec templates
            └── manifest-spec.md                  ## Manifest JSON spec
```

## Spec Documents

The toolset uses the following spec documents as templates:

- **manifest-spec.md**: Template for generating manifest.json files with complete toolset metadata

## Toolset Workspace

The Toolset Manifest File Add toolset has the following workspace structure:

```
.asdm/workspace/toolset-manifest/
├── temp/                                       ## Temporary files
└── logs/                                        ## Operation logs
    └── generate-log.md                          ## Generation operation log
```

## Copyright & License

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.

Licensed under the PROPRIETARY SOFTWARE LICENSE. See [LICENSE](LICENSE) in the project root for license information.
