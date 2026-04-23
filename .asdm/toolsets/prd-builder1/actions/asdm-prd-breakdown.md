# Instructions for asdm-prd-breakdown action

## Purpose
This instruction guides the AI model to break down tasks for a feature using Task Planner & Executor toolset. It first generates a comprehensive task list based on the feature PRD, then creates detailed task PRD documents for each task in the task list.

## Language Detection

Before generating any task PRD documents, you must detect and use the current environment's response language:

1. **Detect Response Language**: Analyze the environment settings to determine the primary language:
   - Check system/user language settings or environment configuration
   - Identify the primary language used in project documentation and comments
   - Determine the language preference based on workspace context

2. **Apply Language Consistency**: Ensure all generated task PRD documents use the detected language:
   - Use the same language for all markdown files, comments, and documentation
   - Maintain language consistency across all generated files
   - Follow the detected language's writing conventions and formatting

3. **Supported Languages**:
   - English (en)
   - Chinese (zh)
   - Other languages as needed based on environment detection

**IMPORTANT**: The language detection is the FIRST step before any task breakdown document generation. All output must consistently use the detected language throughout the entire process.

## Context Loading

Before breaking down tasks, the AI model must load the feature context from the feature directory. This ensures that task breakdown aligns with the feature requirements and specifications.

### Context Files to Read

The AI model should read the following context files:

1. **Feature PRD** (Required - MUST be read first)
   - Path: `.asdm/workspace/features/<feature-id>-<feature-name>/feature-prd.md`
   - Purpose: Provides detailed feature requirements, scope, and acceptance criteria
   - Contains: Feature description, user stories, technical requirements, and success criteria

2. **Task List** (Optional - Generated if not exists)
   - Path: `.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`
   - Purpose: Provides the list of tasks to be broken down
   - Contains: Task IDs, task names, task descriptions, and current status
   - If not exists, will be generated in step 3

3. **Additional Context** (Optional - On-Demand)
   - Only after reviewing the feature PRD and task list, if additional context is needed
   - The AI model can request additional context files from `.asdm/contexts/` and `.asdm/specs/` based on specific task requirements
   - Examples of additional context files:
     - `.asdm/contexts/standard-project-structure.md`
     - `.asdm/contexts/standard-coding-style.md`
     - `.asdm/contexts/data-models.md`
     - `.asdm/contexts/api.md`
     - `.asdm/contexts/architecture.md`
     - `.asdm/contexts/standard-security-practices.md` (MANDATORY for tasks involving authentication, data handling, or APIs)
     - `.asdm/contexts/standard-compliance-practices.md` (MANDATORY for tasks involving user data, audit trails, or regulatory requirements)
     - `.asdm/specs/java-springboot-jpa/` (for Java Spring Boot + JPA tasks)
       - `architecture-design.md`: Application logic design and layer responsibilities
       - `entities.md`: Entity class guidelines and annotations
       - `repositories.md`: Repository/DAO patterns and JPQL best practices
       - `services.md`: Service layer design and transaction management
       - `dtos.md`: Data Transfer Object patterns and validation
       - `rest-controllers.md`: REST controller design and API routing
       - `response-handling.md`: API response format and exception handling

### Progressive Context Loading Strategy

To avoid overwhelming the AI model with excessive context, follow this progressive loading approach:

1. **Initial Phase** (Before task breakdown starts):
   - Read feature PRD to understand feature requirements
   - Read task list if it exists, otherwise prepare to generate it
   - Identify which additional context files might be needed

2. **Breakdown Phase** (During task breakdown):
   - Load additional context files only when specifically needed for a task
   - **CRITICAL**: For ALL tasks involving user data, authentication, or APIs, MUST read:
     - `.asdm/contexts/standard-security-practices.md`
     - `.asdm/contexts/standard-compliance-practices.md`
   - Example: If a task involves database changes, read `.asdm/contexts/data-models.md`
   - Example: If a task involves API changes, read `.asdm/contexts/api.md`
   - Example: If a task involves Java Spring Boot + JPA implementation, read relevant spec files from `.asdm/specs/java-springboot-jpa/`

3. **Integration with Language Detection**:
   - Context loading should occur **after** language detection but **before** starting the breakdown steps
   - This ensures the AI model uses the correct language for understanding and generating content

**IMPORTANT**: Always read the feature PRD and task list before starting the task breakdown steps. These documents are the foundation for generating accurate and detailed task PRDs.

## Steps to Break Down Tasks for a Feature

### 1. Identify Feature and Validate Existence
Identify the feature to break down tasks for:
- Accept a feature ID or feature name from the user
- Validate the feature directory exists: `.asdm/workspace/features/<feature-id>-<feature-name>/`
- If the feature doesn't exist, inform the user and suggest using `/asdm-prd-planning` first

### 2. Load Feature Context
Load the necessary context files:
- Read feature PRD: `.asdm/workspace/features/<feature-id>-<feature-name>/feature-prd.md`
- Check if task list exists: `.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`
- If task list doesn't exist, proceed to step 3 to generate it
- Load additional context files as needed based on task requirements

### 3. Generate Task List (if not exists)
If task list doesn't exist, generate a comprehensive task list for the feature:
- Path: `.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`
- Use the template from `.asdm/toolsets/task-planner-executor/spec/task-list.md`
- Use the detected language throughout the document
- Follow the template structure and fill out all relevant sections
- Ensure task list only contains basic task information without detailed descriptions
- Ensure task count validation (see step 3.1)

If task list already exists, skip to step 4.

### 3.1 Validate Task Count
After generating the task list, validate the task count:
- Count the total number of tasks in the task list
- If task count is **10 or fewer**: Proceed to step 4
- If task count is **more than 10**:
  - **Stop** the breakdown process
  - Explain to the user that the feature is too large and needs to be decomposed
  - Provide a summary of the preliminary task breakdown to help the user understand the scope
  - Ask the user to break down the feature into smaller sub-features
  - Request the user to specify which sub-feature to break down first
  - Once a smaller sub-feature is provided, restart the breakdown process from step 2 with the new feature

**Note**: Refer to `.asdm/toolsets/task-planner-executor/spec/task-list.md` for detailed guidelines on task count limitation, task granularity, status management, and dependency management. The task list should only contain basic task information without detailed descriptions or implementation details.

### 4. Select Tasks for Breakdown
Determine which tasks to break down:
- If user specifies task IDs, break down only those tasks
- If user doesn't specify task IDs, break down all tasks with status `TODO` or `IN PROGRESS`
- Confirm with the user which tasks will be broken down before proceeding

### 5. Generate Task PRDs
For each selected task, generate a detailed task PRD document:
- Path: `.asdm/workspace/features/<feature-id>-<feature-name>/<task-id>-<task-name>-prd.md`
- Use the template from `.asdm/toolsets/task-planner-executor/spec/task-prd-spec.md`
- Use the detected language throughout the document
- Follow the spec template structure and fill out all relevant sections
- **MANDATORY**: Include security requirements based on `.asdm/contexts/standard-security-practices.md`:
  - Authentication and authorization requirements
  - Input validation standards
  - Data encryption requirements (at rest and in transit)
  - Sensitive data handling and masking
  - API security measures (rate limiting, CSRF protection, etc.)
  - Session security requirements
  - Security headers configuration
- **MANDATORY**: Include compliance requirements based on `.asdm/contexts/standard-compliance-practices.md`:
  - Data classification levels for all data involved
  - Applicable regulatory requirements (PIPL, GDPR, PCI DSS, SOX, ISO 27001, etc.)
  - Audit trail and logging requirements
  - Data retention and deletion policies
  - Privacy by design considerations
  - User consent management (if applicable)
  - Data portability and erasure rights (if applicable)
- **MANDATORY**: Include testing requirements for all implementation tasks:
  - Unit test requirements using project's testing framework (detect framework from project configuration):
    - For Java/Spring Boot: JUnit 5, Mockito, Spring Boot Test
    - For Vue.js: Jest or Vitest (check `package.json` for dependencies)
    - For other technologies: Identify framework from project configuration
  - Test coverage targets (minimum percentage based on project standards)
  - Test data setup and mocking strategies
  - Integration test requirements for API endpoints and database interactions
  - Test scenarios for security and compliance validations
  - Performance and load testing requirements (if applicable)
  - Test automation and CI/CD integration requirements

### 6. Update Task List Status
Update the task list to reflect task breakdown status:
- For tasks with generated PRDs, update the status if needed
- Maintain the status according to the task's actual state
- Path: `.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`

### 7. Review and Validate
Review all generated documents (task list if newly created, and task PRD documents) for:
- Completeness and accuracy
- Language consistency
- Proper structure and formatting
- Clear and actionable requirements
- Alignment with feature PRD
- Feasibility and implementability
- Clear acceptance criteria
- **Security compliance**:
  - All security requirements from `standard-security-practices.md` are included
  - Authentication and authorization are properly defined
  - Input validation covers all user inputs
  - Sensitive data handling follows best practices
  - API security measures are comprehensive
- **Compliance adherence**:
  - Data classification is applied to all data elements
  - Applicable regulatory requirements are identified
  - Audit trail requirements are specified
  - Data retention policies are defined
  - Privacy considerations are addressed
- **Testing coverage**:
  - Unit test requirements are specified for all implemented code
  - Testing framework is identified and appropriate for the technology stack
  - Test scenarios cover happy paths, edge cases, and error conditions
  - Security and compliance validations are included in test scenarios
  - Test coverage targets are defined and achievable
  - Integration tests are included for API endpoints and database interactions
  - Mock strategies are defined for external dependencies

**Note**: Refer to `.asdm/toolsets/task-planner-executor/spec/task-prd-spec.md` for detailed guidelines on task PRD content, best practices, and handling different task types.

## Usage

To use this instruction, the AI model should:

1. **Receive Feature Selection**: Get the feature ID or name from the user
2. **Detect Language**: Detect and set the response language
3. **Validate Feature**: Check if the feature directory and necessary files exist
4. **Load Context**: Read feature PRD, check for task list, and load any additional context files
5. **Generate Task List**: If task list doesn't exist, create it based on feature PRD and validate task count
6. **Select Tasks**: Determine which tasks to break down based on user input or task status
7. **Confirm Tasks**: Present the list of tasks to be broken down and get user confirmation
8. **Load Security & Compliance Context**: Load mandatory security and compliance practice documents for relevant tasks
9. **Generate Task PRDs**: Create detailed task PRD documents for each selected task, incorporating security, compliance, and testing requirements (testing requirements based on detected framework from project configuration)
10. **Update Task List**: Update task statuses if needed
11. **Review and Present**: Present all generated documents for user review
12. **Wait for Approval**: Wait for user approval or feedback before proceeding to execution

### User Interaction Guidelines

#### Before Starting Breakdown
- Ask the user to specify which feature to break down tasks for
- If multiple features exist, present a list of features from `features-list.md`
- If the user doesn't specify tasks, explain that all `TODO` and `IN PROGRESS` tasks will be broken down

#### During Task Selection
- Present the list of tasks that will be broken down
- Show task ID, task name, current status, and brief description
- Ask user to confirm or modify the selection

#### During Generation
- Provide progress updates as task PRDs are generated
- Notify user if any issues or warnings arise
- Ask for clarification if task descriptions are ambiguous
- Highlight when security and compliance requirements are being incorporated
- Indicate which security/compliance standards are being applied to each task
- Specify testing framework (detected from project configuration) and test coverage requirements for each task

#### After Completion
- Present a summary of all generated task PRDs
- Show the file paths for each generated document
- Highlight security, compliance, and testing requirements included in each task PRD (testing framework detected from project configuration)
- Ask if the user wants to review any specific task PRD
- Prompt for next steps (e.g., proceed to execution)

## Output Summary

After completing the task breakdown phase, the following artifacts will be generated:

### Generated Documents
- **Task List** (if not already exists): Comprehensive list of tasks for the feature
  - Path: `.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`
  - Contains: Task IDs, task names, descriptions, status, dependencies, and estimated effort

- **Task PRD Documents**: One detailed PRD document for each selected task
  - Path: `.asdm/workspace/features/<feature-id>-<feature-name>/<task-id>-<task-name>-prd.md`
  - Each includes: task description, requirements, implementation approach, acceptance criteria, dependencies, estimated effort, security requirements, compliance requirements, and testing requirements

### Updated Documents
- **Task List**: Updated to reflect current task status
  - Path: `.asdm/workspace/features/<feature-id>-<feature-name>/task-list.md`

### Task Breakdown Summary
The breakdown process should generate a summary that includes:
- Task list generation status (newly created or already existed)
- Total number of tasks in the task list
- Number of tasks broken down
- List of task PRD documents generated
- Security standards applied to each task
- Compliance requirements identified for each task
- Testing frameworks (detected from project configuration) and coverage requirements specified for each task
- Any warnings or issues encountered
- Recommendations for next steps

These documents serve as the foundation for the execution phase (asdm-task-execution action). Each task PRD provides detailed guidance for implementing the task, ensuring alignment with feature requirements and project standards.

## Error Handling

### Common Scenarios and Solutions

#### Feature Not Found
- **Error**: Feature directory or feature PRD doesn't exist
- **Solution**: Inform the user and suggest using `/asdm-prd-planning` to create the feature first

#### Task List Not Found
- **Behavior**: Task list doesn't exist in the feature directory
- **Solution**: Automatically generate the task list based on the feature PRD (step 3)

#### Task Already Has PRD
- **Error**: Task PRD document already exists for a task
- **Solution**: Ask the user if they want to overwrite the existing PRD or skip this task

#### Insufficient Context
- **Error**: Cannot break down task due to missing or unclear requirements
- **Solution**: Ask the user for clarification or additional requirements for the task

#### Feature PRD Incomplete
- **Error**: Feature PRD doesn't provide enough information to break down tasks
- **Solution**: Ask the user to provide more details in the feature PRD or provide additional context directly

#### Security Requirements Missing
- **Warning**: Task PRD lacks security requirements
- **Solution**: Load `standard-security-practices.md` and add appropriate security requirements based on task scope

#### Compliance Requirements Missing
- **Warning**: Task PRD lacks compliance requirements
- **Solution**: Load `standard-compliance-practices.md` and add appropriate compliance requirements based on data handling and regulatory scope

#### Testing Requirements Missing
- **Warning**: Task PRD lacks testing requirements
- **Solution**: Add testing requirements by:
  - Detecting testing framework from project configuration:
    - Check `pom.xml` for Java projects (look for JUnit, Mockito, Spring Boot Test dependencies)
    - Check `package.json` for Vue.js projects (look for Jest, Vitest dependencies)
    - Check project structure for existing test files and patterns
  - Determine test coverage requirements from project standards (if documented)
  - Define test scenarios based on task implementation scope
  - Include integration tests for API endpoints and database interactions

#### Testing Framework Not Identified
- **Warning**: No testing framework detected from project configuration
- **Solution**: Identify the appropriate testing framework based on:
  - Technology stack (e.g., JUnit 5 for Java Spring Boot, Jest/Vitest for Vue.js)
  - Project's existing test files (check `src/test/java` or `tests` directory)
  - Build configuration files (`pom.xml` for Maven, `package.json` for npm)
  - Industry best practices for the technology stack
  - Add framework installation instructions if framework is not yet configured
