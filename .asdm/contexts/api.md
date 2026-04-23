# API Documentation

## Overview
This document provides API documentation for the AISE microservices system, including endpoint definitions, request/response formats, and usage examples.

## API Metadata

### Base URLs
| Environment | URL | Description |
|-------------|-----|-------------|
| **Development** | `http://localhost:8080` | Local development server |
| **Test** | `https://sit-api.example.com` | Test environment |
| **Production** | `https://api.example.com` | Production environment |

### Authentication
All protected APIs require JWT Token authentication:
```http
Authorization: Bearer <jwt_token>
```

### Common Request Headers
| Header | Required | Description | Example |
|--------|----------|-------------|---------|
| `Content-Type` | Yes | Request content type | `application/json` |
| `Authorization` | Conditional | JWT Token | `Bearer eyJhbGciOiJIUzI1NiIs...` |

### Common Response Formats

#### Success Response
```json
{
  "code": 200,
  "msg": "Operation successful",
  "data": { ... }
}
```

#### Paginated Response
```json
{
  "code": 200,
  "msg": "Query successful",
  "total": 100,
  "rows": [ ... ]
}
```

#### Error Response
```json
{
  "code": 500,
  "msg": "Error message"
}
```

## API Definitions

---

### Authentication Endpoints (AuthController)

**Source Location**: `aise-auth/src/main/java/com/leaniss/auth/controller/TokenController.java`

| Endpoint | Method | Description | Permission |
|----------|--------|-------------|------------|
| `/auth/login` | POST | User login | Public |
| `/auth/logout` | POST | User logout | Logged in |
| `/auth/register` | POST | User registration | Public |
| `/auth/refresh` | POST | Refresh token | Logged in |

#### POST /auth/login

**Description**: User login, obtain JWT Token.

**Request Parameters**:
```json
{
  "username": "admin",
  "password": "admin123",
  "code": "captcha",
  "uuid": "captcha-uuid"
}
```

**Success Response** (200):
```json
{
  "code": 200,
  "msg": "Operation successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Responses**:
- `400` - Incorrect username or password
- `500` - System error

#### POST /auth/logout

**Description**: User logout, clear token.

**Request Headers**:
```
Authorization: Bearer <token>
```

**Success Response** (200):
```json
{
  "code": 200,
  "msg": "Logout successful"
}
```

---

### User Endpoints (SysUserController)

**Source Location**: `aise-modules/aise-system/src/main/java/com/leaniss/system/controller/SysUserController.java`

| Endpoint | Method | Description | Permission |
|----------|--------|-------------|------------|
| `/system/user/list` | GET | User list | `system:user:list` |
| `/system/user/{userId}` | GET | User details | `system:user:query` |
| `/system/user` | POST | Add user | `system:user:add` |
| `/system/user` | PUT | Update user | `system:user:edit` |
| `/system/user/{userIds}` | DELETE | Delete user | `system:user:remove` |
| `/system/user/resetPwd` | PUT | Reset password | `system:user:resetPwd` |
| `/system/user/profile` | GET | Personal information | Logged in |

#### GET /system/user/list

**Description**: Query user list with pagination.

**Request Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pageNum` | int | No | Page number, default 1 |
| `pageSize` | int | No | Items per page, default 10 |
| `userName` | string | No | Username |
| `phonenumber` | string | No | Phone number |
| `status` | string | No | Status |
| `deptId` | long | No | Department ID |

**Success Response** (200):
```json
{
  "code": 200,
  "msg": "Query successful",
  "total": 100,
  "rows": [
    {
      "userId": 1,
      "userName": "admin",
      "nickName": "Administrator",
      "email": "admin@example.com",
      "phonenumber": "13800138000",
      "status": "0",
      "createTime": "2024-01-01 00:00:00",
      "dept": {
        "deptId": 103,
        "deptName": "Development Department"
      }
    }
  ]
}
```

#### POST /system/user

**Description**: Add new user.

**Request Body**:
```json
{
  "userName": "testuser",
  "nickName": "Test User",
  "password": "123456",
  "email": "test@example.com",
  "phonenumber": "13800138001",
  "sex": "0",
  "status": "0",
  "deptId": 103,
  "roleIds": [2]
}
```

**Success Response** (200):
```json
{
  "code": 200,
  "msg": "Add successful"
}
```

---

### Role Endpoints (SysRoleController)

**Source Location**: `aise-modules/aise-system/src/main/java/com/leaniss/system/controller/SysRoleController.java`

| Endpoint | Method | Description | Permission |
|----------|--------|-------------|------------|
| `/system/role/list` | GET | Role list | `system:role:list` |
| `/system/role/{roleId}` | GET | Role details | `system:role:query` |
| `/system/role` | POST | Add role | `system:role:add` |
| `/system/role` | PUT | Update role | `system:role:edit` |
| `/system/role/{roleIds}` | DELETE | Delete role | `system:role:remove` |
| `/system/role/dataScope` | PUT | Data permission | `system:role:edit` |

#### GET /system/role/list

**Request Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pageNum` | int | No | Page number |
| `pageSize` | int | No | Items per page |
| `roleName` | string | No | Role name |
| `roleKey` | string | No | Permission character |
| `status` | string | No | Status |

**Success Response** (200):
```json
{
  "code": 200,
  "msg": "Query successful",
  "total": 5,
  "rows": [
    {
      "roleId": 1,
      "roleName": "Super Administrator",
      "roleKey": "admin",
      "roleSort": 1,
      "status": "0",
      "createTime": "2024-01-01 00:00:00"
    }
  ]
}
```

---

### Menu Endpoints (SysMenuController)

**Source Location**: `aise-modules/aise-system/src/main/java/com/leaniss/system/controller/SysMenuController.java`

| Endpoint | Method | Description | Permission |
|----------|--------|-------------|------------|
| `/system/menu/list` | GET | Menu list | `system:menu:list` |
| `/system/menu/{menuId}` | GET | Menu details | `system:menu:query` |
| `/system/menu` | POST | Add menu | `system:menu:add` |
| `/system/menu` | PUT | Update menu | `system:menu:edit` |
| `/system/menu/{menuId}` | DELETE | Delete menu | `system:menu:remove` |
| `/system/menu/treeselect` | GET | Menu tree | Logged in |

---

### Department Endpoints (SysDeptController)

**Source Location**: `aise-modules/aise-system/src/main/java/com/leaniss/system/controller/SysDeptController.java`

| Endpoint | Method | Description | Permission |
|----------|--------|-------------|------------|
| `/system/dept/list` | GET | Department list | `system:dept:list` |
| `/system/dept/{deptId}` | GET | Department details | `system:dept:query` |
| `/system/dept` | POST | Add department | `system:dept:add` |
| `/system/dept` | PUT | Update department | `system:dept:edit` |
| `/system/dept/{deptId}` | DELETE | Delete department | `system:dept:remove` |
| `/system/dept/treeselect` | GET | Department tree | Logged in |

---

### File Endpoints (SysFileController)

**Source Location**: `aise-modules/aise-file/src/main/java/com/leaniss/file/controller/SysFileController.java`

| Endpoint | Method | Description | Permission |
|----------|--------|-------------|------------|
| `/file/upload` | POST | File upload | Logged in |
| `/file/download/{fileId}` | GET | File download | Logged in |

#### POST /file/upload

**Description**: Upload file to MinIO.

**Request**: `multipart/form-data`
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | file | Yes | File |

**Success Response** (200):
```json
{
  "code": 200,
  "msg": "Upload successful",
  "data": {
    "fileId": 1,
    "fileName": "document.pdf",
    "url": "http://minio:9000/bucket/document.pdf"
  }
}
```

---

### Dictionary Endpoints (SysDictDataController)

**Source Location**: `aise-modules/aise-system/src/main/java/com/leaniss/system/controller/SysDictDataController.java`

| Endpoint | Method | Description | Permission |
|----------|--------|-------------|------------|
| `/system/dict/data/list` | GET | Dictionary data list | `system:dict:list` |
| `/system/dict/data/type/{dictType}` | GET | Query dictionary by type | Public |
| `/system/dict/data` | POST | Add dictionary data | `system:dict:add` |
| `/system/dict/data` | PUT | Update dictionary data | `system:dict:edit` |

#### GET /system/dict/data/type/{dictType}

**Description**: Query dictionary data by dictionary type.

**Success Response** (200):
```json
{
  "code": 200,
  "msg": "Query successful",
  "data": [
    {
      "dictValue": "0",
      "dictLabel": "Normal"
    },
    {
      "dictValue": "1",
      "dictLabel": "Disabled"
    }
  ]
}
```

---

## Feign Remote Service Interfaces

### RemoteUserService

**Source Location**: `aise-api/aise-api-system/src/main/java/com/leaniss/system/api/RemoteUserService.java`

```java
@FeignClient(contextId = "remoteUserService", 
             value = ServiceNameConstants.SYSTEM_SERVICE,
             fallbackFactory = RemoteUserFallbackFactory.class)
public interface RemoteUserService {
    
    /**
     * Query user information by username
     */
    @GetMapping("/user/info/{username}")
    R<LoginUser> getUserInfo(@PathVariable("username") String username);
    
    /**
     * Register user information
     */
    @PostMapping("/user/register")
    R<Boolean> registerUserInfo(@RequestBody SysUser sysUser);
}
```

### RemoteFileService

**Source Location**: `aise-api/aise-api-system/src/main/java/com/leaniss/system/api/RemoteFileService.java`

```java
@FeignClient(contextId = "remoteFileService", 
             value = ServiceNameConstants.FILE_SERVICE)
public interface RemoteFileService {
    
    /**
     * Upload file
     */
    @PostMapping("/file/upload")
    R<SysFile> upload(@RequestParam("file") MultipartFile file);
}
```

---

## Error Code Reference

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| 200 | 200 | Operation successful |
| 401 | 401 | Unauthorized |
| 403 | 403 | No permission |
| 404 | 404 | Resource not found |
| 500 | 500 | System error |

---

## cURL Test Examples

```bash
# Login to get token
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Get user list (requires token)
TOKEN="your-jwt-token"
curl -X GET "http://localhost:8080/system/user/list?pageNum=1&pageSize=10" \
  -H "Authorization: Bearer $TOKEN"

# Add user
curl -X POST http://localhost:8080/system/user \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"userName":"test","nickName":"Test","password":"123456"}'
```

---

*This document should be updated when APIs change. Use `/context-update` command to keep the document current.*
