# Workspace Context Index

## Overview
This document serves as an index and guide for the AI model to understand and operate on this workspace. It provides a structured overview of the workspace content and guides the AI model to find relevant context information.

## Workspace Information

### Basic Information
- **Workspace Name**: AISE Microservices System (leaniss-system-core)
- **Description**: Enterprise-level AI intelligent service management platform based on Spring Cloud Alibaba, providing user authentication, system management, file services, task scheduling, AI model management, and knowledge base features
- **Created**: 2026-03-05
- **Last Updated**: 2026-03-05

### Technology Stack

#### Backend Technologies
| Technology | Version | Description |
|------------|---------|-------------|
| **Java** | 1.8 | JDK Version |
| **Spring Boot** | 2.7.18 | Core Framework |
| **Spring Cloud** | 2021.0.8 | Microservices Framework |
| **Spring Cloud Alibaba** | 2021.0.5.0 | Alibaba Microservices Suite |
| **Nacos** | v2.4.2 | Service Registry & Config Center |
| **Spring Cloud Gateway** | - | API Gateway |
| **MyBatis** | - | ORM Framework |
| **PageHelper** | 2.0.0 | Pagination Plugin |
| **Druid** | 1.2.20 | Database Connection Pool |
| **JWT** | 0.9.1 | Authentication |

#### Frontend Technologies
| Technology | Version | Description |
|------------|---------|-------------|
| **Vue.js** | 2.6.12 | Frontend Framework |
| **Element UI** | 2.15.13 | UI Component Library |
| **Vuex** | 3.6.0 | State Management |
| **Vue Router** | 3.4.9 | Routing Management |
| **Axios** | 0.24.0 | HTTP Client |
| **ECharts** | 5.4.0 | Chart Library |

#### Database & Middleware
| Component | Version | Purpose |
|-----------|---------|---------|
| **MySQL** | 5.7/8.0.23 | Primary Database |
| **PostgreSQL** | 15.2 | Auxiliary Database |
| **Redis** | 7.4.0 | Cache, Session |
| **MinIO** | RELEASE.2024-04-06 | Object Storage |
| **Milvus** | - | Vector Database |
| **Nacos** | v2.4.2 | Config Center |

### Business Context
- **Business Domain**: Enterprise-level AI Intelligent Service Management Platform
- **Core Business Functions**:
  - User authentication and authorization (JWT, LDAP, OAuth2)
  - System management (users, roles, menus, departments, dictionaries, configurations)
  - AI model management and orchestration
  - Prompt template management
  - Knowledge base management
  - File storage services
  - Scheduled task scheduling
- **Business Constraints**: Multi-tenant support, data permission isolation, LDAP domain account integration

## Workspace Structure

### Directory Structure Overview
```
leaniss-system-core/
├── .asdm/                          # ASDM configuration and toolsets
│   ├── contexts/                   # Context files (this directory)
│   ├── toolsets/                   # Installed toolsets
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
├── aise-manager/                   # Business management modules (AI models, knowledge base, etc.)
├── aise-modules/                   # Business modules
│   ├── aise-system/                # System management
│   ├── aise-file/                  # File service
│   └── aise-job/                   # Scheduled tasks
├── aise-ui/                        # Frontend project (Vue.js)
├── deploy/                         # Deployment scripts
├── deploy-kubernetes/              # Kubernetes deployment configurations
└── pom.xml                         # Maven parent POM
```

### Core Module Descriptions
| Module | Responsibilities | Port |
|--------|-------------------|------|
| **aise-gateway** | API routing, auth filtering, XSS protection, request caching | 8080 |
| **aise-auth** | User login, token management, registration, version check | - |
| **aise-system** | Users, roles, menus, departments, dictionaries, configs, LDAP, OAuth2 | - |
| **aise-manager** | AI model management, prompts, knowledge base, vector storage, app market | - |
| **aise-file** | File upload/download, MinIO/FastDFS integration | 9300 |
| **aise-job** | Scheduled task scheduling, log cleanup, health checks | - |

## Development Guide

### Build & Compile
```bash
# Backend build (default dt environment)
mvn clean install

# Backend build (specific environment)
mvn clean install -P sit    # Test environment
mvn clean install -P uat    # Production environment

# Frontend build
cd aise-ui
npm install
npm run build:stage         # Test environment
npm run build:prod          # Production environment
```

### Development Server
```bash
# Backend startup (requires Nacos, MySQL, Redis first)
# Modules start independently, discovered via Nacos

# Frontend development server
cd aise-ui
npm run dev                 # Default development environment
```

### Testing
```bash
# Backend tests
mvn test

# Frontend tests
cd aise-ui
npm run test
```

### Code Quality
- **Backend Standards**: Alibaba Java Coding Guidelines
- **Frontend Standards**: ESLint + Vue Official Style Guide
- **Comment Standards**: Use Chinese comments, Javadoc format

## Context Files Reference

The workspace provides the following context files in `.asdm/contexts/` directory (generated on demand):

1. **[standard-project-structure.md](./standard-project-structure.md)** - Standard project structure and organization
2. **[standard-coding-style.md](./standard-coding-style.md)** - Coding standards and style guide
3. **[data-models.md](./data-models.md)** - Data models, relationships, and diagrams
4. **[deployment.md](./deployment.md)** - Deployment configurations and procedures
5. **[api.md](./api.md)** - API definitions, endpoints, and documentation
6. **[architecture.md](./architecture.md)** - System architecture and design decisions
7. **[standard-security-practices.md](./standard-security-practices.md)** - Security standards and best practices (Java & Vue.js)
8. **[standard-compliance-practices.md](./standard-compliance-practices.md)** - Compliance standards and regulatory requirements (Java & Vue.js)

## AI Model Guide

### How to Use This Context
1. **Start from this index** - Understand the overall workspace structure
2. **Consult specific context files** - Reference detailed documents based on task needs
3. **Follow development guidelines** - Operate according to build, test, and deployment procedures
4. **Maintain consistency** - Stay consistent with existing patterns and conventions

### Common Task Guide
| Task Type | Recommended Reference | Notes |
|------------|----------------------|-------|
| Add new feature | architecture.md, data-models.md | Follow module layered architecture |
| Modify API | api.md | Update Swagger documentation |
| Database changes | data-models.md | Write migration scripts |
| Deploy updates | deployment.md | Check K8s configurations |
| Frontend development | standard-coding-style.md | Follow Vue component standards |
| Security implementation | standard-security-practices.md | Follow security best practices |
| Compliance requirements | standard-compliance-practices.md | Ensure regulatory compliance |

### Naming Convention Quick Reference
| Type | Naming Convention | Example |
|------|-------------------|--------|
| Controller | `{Entity}Controller` | `SysUserController` |
| Service Interface | `I{Entity}Service` | `ISysUserService` |
| Service Implementation | `{Entity}ServiceImpl` | `SysUserServiceImpl` |
| Mapper | `{Entity}Mapper` | `SysUserMapper` |
| Entity | `{Entity}` | `SysUser` |
| Feign Client | `Remote{Entity}Service` | `RemoteUserService` |

### Troubleshooting
- **Build issues**: Check Maven dependencies and Profile configuration
- **Runtime issues**: Check Nacos configuration and environment variables
- **Authentication issues**: Check JWT Token and Redis connection
- **Database issues**: Check datasource configuration and Druid connection pool
- **Security issues**: Reference standard-security-practices.md
- **Compliance issues**: Reference standard-compliance-practices.md

## Version History
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2026-03-05 | Initial context creation | ASDM Context Builder |
| 1.0.1 | 2026-03-05 | Added security and compliance context files | ASDM Context Builder |

---

*This context file is maintained by the Context Builder toolset. Use `Follow the instructions in .codebuddy/commands/asdm-context-update.md` to update when the workspace changes.*
