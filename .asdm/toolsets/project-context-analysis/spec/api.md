# API Documentation

## Overview
This document provides comprehensive API documentation for this workspace. It includes endpoint definitions, request/response formats, usage examples, and testing guidelines designed for AI Models to understand, design, modify, and implement the API.

## API Meta Data

### Base URLs
| Environment | URL | Description |
|-------------|-----|-------------|
| **Development** | `http://localhost:3000/api` | Local development server |
| **Staging** | `https://staging-api.example.com/api` | Pre-production testing environment |
| **Production** | `https://api.example.com/api` | Live production environment |

### Authentication
All protected endpoints require JWT authentication:
```http
Authorization: Bearer <jwt_token>
```

## API Definitions

**Guidelines**: This section is organized by controller classes. Each controller groups related API endpoints. Follow the source code links to view detailed implementation.

---

### AAAAAController

**Source Code**: `server/src/main/java/com/example/api/controller/AAAAAController.java`

**Description**: Controller description.

| Endpoint | Method | Description | Security | Status Codes |
|----------|--------|-------------|----------|--------------|
| `/AAAAA/bbb` | GET/POST/... | description | Public | 200, 400, 401, 429, 500 |


#### GET /AAAAA/bbb

**Description**: Controller description.
List all API in this controller.

**Request Parameters**:
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `param1` | data type | Yes/No | param description | `"example"` |
| `param2` | data type | Yes/No | param description | `"example"` |

**Success Response (200)**:
```json
response example
```

**Error Responses**:
- **400** - Invalid request format
- **401** - Invalid credentials
- **429** - Rate limit exceeded


---
### XXXXXController

**Source Code**: `server/src/main/java/com/example/api/controller/XXXXXController.java`

**Description**: Controller description.
List all API in this controller.

| Endpoint | Method | Description | Security | Status Codes |
|----------|--------|-------------|----------|--------------|
| `/XXXXX/yyy` | GET/POST/... | description | Public | 200, 400, 401, 429, 500 |


#### POST /XXXXX/yyy

**Description**: Authenticates a user with email and password credentials, returning a JWT token for subsequent API calls.

```json
request example
```

**Success Response (200)**:
```json
response example
```

**Error Responses**:
- **400** - Invalid request format
- **401** - Invalid credentials
- **429** - Rate limit exceeded

---

*This API documentation template is organized by controller classes. Follow the source code links to view detailed implementation. Update this document using `/context-update-instruction` whenever endpoints change.*
