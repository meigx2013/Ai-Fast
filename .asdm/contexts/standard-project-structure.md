# Standard Project Structure

## Overview
This document defines the standard project structure for the AISE microservices system. It provides guidelines for organizing files and directories to maintain consistency and facilitate collaboration.

## Project Structure Overview

### Overall Directory Structure
```
leaniss-system-core/
├── .asdm/                          # ASDM configuration and toolsets
│   ├── contexts/                   # Context files (AI model reference)
│   ├── toolsets/                   # Installed ASDM toolsets
│   └── workspace/                  # Workspace data
├── aise-api/                       # API interface modules
│   └── aise-api-system/            # System Feign interface definitions
├── aise-auth/                      # Authentication and authorization center
├── aise-common/                    # Common modules
│   ├── aise-common-core/           # Core utility classes
│   ├── aise-common-security/       # Security authentication
│   ├── aise-common-redis/          # Redis cache
│   ├── aise-common-datasource/     # Multi-datasource
│   ├── aise-common-datascope/      # Data permissions
│   ├── aise-common-log/            # Logging
│   ├── aise-common-swagger/        # API documentation
│   ├── aise-common-i18n/           # Internationalization
│   └── aise-common-seata/          # Distributed transactions
├── aise-gateway/                   # API Gateway
├── aise-manager/                   # Business management modules
├── aise-modules/                   # Business modules
│   ├── aise-system/                # System management
│   ├── aise-file/                  # File service
│   └── aise-job/                   # Scheduled tasks
├── aise-ui/                        # Frontend project (Vue.js)
├── deploy/                         # Deployment scripts
├── deploy-kubernetes/              # Kubernetes deployment configurations
├── deploy-smarttask-server/        # SmartTask server deployment
├── deploy-tools/                   # Deployment tools
├── pom.xml                         # Maven parent POM
└── azure-pipelines*.yml            # Azure CI/CD configurations
```

## Java/Spring Boot Module Structure

### Standard Backend Module Structure
```
aise-{module}/
├── pom.xml                         # Maven configuration
└── src/
    ├── main/
    │   ├── java/
    │   │   └── com/leaniss/{module}/
    │   │       ├── controller/     # REST controllers
    │   │       ├── service/        # Service layer interfaces
    │   │       │   └── impl/       # Service layer implementations
    │   │       ├── mapper/         # MyBatis Mapper interfaces
    │   │       ├── domain/         # Domain models/entities
    │   │       │   ├── vo/         # View objects
    │   │       │   └── dto/        # Data transfer objects
    │   │       ├── config/         # Configuration classes
    │   │       ├── handler/        # Handlers
    │   │       ├── form/           # Form objects
    │   │       ├── extend/         # Extension classes
    │   │       └── utils/          # Utility classes
    │   └── resources/
    │       ├── application.yml     # Application configuration
    │       ├── mapper/             # MyBatis XML mapping files
    │       ├── static/             # Static resources
    │       └── templates/          # Template files
    └── test/
        └── java/                   # Test code
```

### Common Module Structure
```
aise-common-{feature}/
├── pom.xml
└── src/
    └── main/
        ├── java/
        │   └── com/leaniss/common/{feature}/
        │       ├── annotation/     # Custom annotations
        │       ├── aspect/         # Aspects
        │       ├── config/         # Configuration classes
        │       ├── exception/      # Exception classes
        │       ├── utils/          # Utility classes
        │       ├── constant/       # Constants
        │       └── web/            # Web related
        │           ├── controller/ # Base controllers
        │           ├── domain/     # Web domain objects
        │           └── page/       # Pagination
        └── resources/
            └── *.yml               # Configuration files
```

### API Module Structure
```
aise-api-system/
├── pom.xml
└── src/
    └── main/
        └── java/
            └── com/leaniss/system/api/
                ├── domain/         # Shared entities
                ├── model/          # Models
                ├── factory/        # Feign fallback factories
                └── Remote*.java    # Feign client interfaces
```

## Vue.js Frontend Structure

### Standard Frontend Directory Structure
```
aise-ui/
├── public/                         # Static resources
│   └── index.html                  # Entry HTML
├── src/
│   ├── api/                        # API interface definitions
│   ├── assets/                     # Static resources (images, fonts, etc.)
│   ├── components/                 # Common components
│   ├── directive/                  # Custom directives
│   ├── icons/                      # SVG icons
│   ├── layout/                     # Layout components
│   ├── router/                     # Route configurations
│   ├── store/                      # Vuex state management
│   ├── styles/                     # Global styles
│   ├── utils/                      # Utility functions
│   └── views/                      # Page views
│       ├── system/                 # System management pages
│       ├── login.vue               # Login page
│       └── index.vue               # Home page
├── package.json                    # npm configuration
├── vue.config.js                   # Vue CLI configuration
└── .env.*                          # Environment variable configurations
```

### Vue Component Structure
```
views/{module}/
├── index.vue                       # List page
├── components/                     # Module-specific components
│   ├── DetailDialog.vue            # Detail dialog
│   └── EditForm.vue                # Edit form
└── mixins/                         # Mixins
```

## Deployment Configuration Structure

### Kubernetes Deployment Structure
```
deploy-kubernetes/
├── deploys/                        # Deployment configurations
│   ├── aise-gateway-deployment.yaml
│   ├── aise-auth-deployment.yaml
│   ├── aise-modules-system-deployment.yaml
│   ├── aise-manager-deployment.yaml
│   ├── aise-env-config.yaml        # Environment variable configuration
│   ├── aise-nacos-config.yaml      # Nacos configuration
│   └── aise-nginx-config.yaml      # Nginx configuration
├── docker-compose*.yml             # Docker Compose configurations
└── *.sh                            # Deployment scripts
```

### Database Script Structure
```
deploy/
├── mysql/                          # MySQL initialization scripts
│   └── *.sql
├── postgresql/                     # PostgreSQL scripts
│   └── *.sql
└── *.env                           # Environment configurations
```

## Directory Purpose Description

### Source Code Directories
| Directory | Purpose | Description |
|-----------|---------|-------------|
| `aise-api/` | API interface definitions | Feign remote service interfaces and shared models |
| `aise-auth/` | Authentication and authorization | User login, token management |
| `aise-common/` | Common modules | Cross-module shared utility classes and configurations |
| `aise-gateway/` | API Gateway | Routing, authentication, rate limiting |
| `aise-manager/` | Business management | AI model management, knowledge base, prompt management |
| `aise-modules/` | Business modules | System management, file service, scheduled tasks |
| `aise-ui/` | Frontend project | Vue.js single page application |

### Configuration Directories
| Directory | Purpose | Description |
|-----------|---------|-------------|
| `deploy/` | Deployment scripts | Docker Compose, database scripts |
| `deploy-kubernetes/` | K8s configurations | Kubernetes deployment files |
| `deploy-tools/` | Deployment tools | Helper scripts and tools |

### Documentation Directories
| Directory/File | Purpose |
|-----------------|---------|
| `.asdm/contexts/` | AI model context documentation |
| `README.md` | Project description |
| Module `pom.xml` files | Module dependencies and build configurations |

## Naming Conventions

### Directory Naming
- **Backend modules**: `aise-{module-name}` (kebab-case)
- **Common modules**: `aise-common-{feature}`
- **Frontend directories**: `kebab-case`

### File Naming
- **Java classes**: `PascalCase` (e.g., `SysUserController.java`)
- **Vue components**: `PascalCase.vue` (e.g., `UserList.vue`)
- **Configuration files**: `kebab-case.yml`
- **SQL scripts**: `snake_case.sql`

### Package Naming
- **Base packages**: `com.leaniss.{module}`
- **Common packages**: `com.leaniss.common.{feature}`
- **API packages**: `com.leaniss.system.api`

## Best Practices

### 1. Modular Design
- Each module has single responsibility
- Define service boundaries through API modules
- Abstract common functionality to common modules

### 2. Code Organization
- Organize by functional layers (Controller → Service → Mapper)
- Place related classes in the same package
- Avoid circular dependencies

### 3. Configuration Management
- Use Nacos for centralized configuration management
- Use environment variables for sensitive information
- Distinguish configurations by environment (dt/sit/uat)

### 4. Frontend Organization
- Organize views by business modules
- Place common components in `components/`
- Encapsulate API calls in `api/`

---

*This document should be updated when project structure changes. Use `/context-update` command to keep the document current.*
