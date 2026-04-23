# Coding Standards

## Overview
This document defines the coding standards and style guide for the AISE microservices system. Consistent coding style improves code readability, maintainability, and collaboration efficiency.

## General Principles

### 1. Readability First
- Code should be easy to read and understand
- Use meaningful variable, function, and class names
- Write self-documenting code

### 2. Consistency
- Follow established patterns in the project
- Use standard conventions for the language and framework
- Maintain consistent style across team members

### 3. Maintainability
- Keep functions and classes with single responsibilities
- Avoid unnecessary complexity
- Write testable code

## Java Coding Standards

### Naming Conventions

#### Classes and Interfaces
```java
// Class names - PascalCase
public class SysUserController { }
public class SysUserServiceImpl { }

// Interface names - PascalCase, prefix with I (service interfaces)
public interface ISysUserService { }

// Constant classes - PascalCase, constant fields UPPER_SNAKE_CASE
public class HttpStatus {
    public static final int SUCCESS = 200;
    public static final int ERROR = 500;
}
```

#### Methods and Variables
```java
// Method names - camelCase, start with verb
public void getUserList() { }
public boolean checkPermission() { }
public SysUser selectUserById(Long userId) { }

// Variable names - camelCase
private String userName;
private Integer orderCount;
private List<SysUser> userList;

// Constants - UPPER_SNAKE_CASE
private static final String DEFAULT_PASSWORD = "123456";
private static final int MAX_RETRY_COUNT = 3;
```

#### Package Naming
```java
// Base package structure
com.leaniss.{module}           // Business module
com.leaniss.common.{feature}   // Common module
com.leaniss.system.api         // API module

// Examples
com.leaniss.system.controller
com.leaniss.system.service.impl
com.leaniss.common.core.utils
```

### Code Formatting

#### Indentation and Braces
```java
// Use 4-space indentation
public class Example {
    public void method() {
        if (condition) {
            // Code block
        }
    }
}

// Opening brace on same line
public void example() {
    // ...
}

// Closing brace on its own line
if (condition) {
    doSomething();
}
```

#### Line Length and Line Breaks
```java
// Maximum 120 characters per line
// Wrap long lines while maintaining readability
public SysUser selectUserByIdAndStatus(
        Long userId, 
        String status, 
        String deptId) {
    // ...
}

// Method chaining line breaks
String result = userList.stream()
        .filter(user -> user.getStatus().equals("0"))
        .map(SysUser::getUserName)
        .collect(Collectors.joining(","));
```

### Annotation Usage

#### Spring Annotation Order
```java
@RestController
@RequestMapping("/system/user")
public class SysUserController extends BaseController {
    
    @Autowired
    private ISysUserService userService;
    
    @RequiresPermissions("system:user:list")
    @GetMapping("/list")
    public TableDataInfo list(SysUser user) {
        startPage();
        List<SysUser> list = userService.selectUserList(user);
        return getDataTable(list);
    }
}
```

#### Custom Annotations
```java
// Log annotation
@Log(title = "User Management", businessType = BusinessType.INSERT)
@PostMapping
public AjaxResult add(@RequestBody SysUser user) {
    return toAjax(userService.insertUser(user));
}

// Data permission annotation
@DataScope(deptAlias = "d", userAlias = "u")
public List<SysUser> selectUserList(SysUser user) {
    return userMapper.selectUserList(user);
}

// Internal service authentication
@InnerAuth
@GetMapping("/info/{username}")
public R<LoginUser> info(@PathVariable("username") String username) {
    return R.ok(userService.getUserInfo(username));
}
```

### Exception Handling

```java
// Use try-catch for expected exceptions
try {
    userService.insertUser(user);
} catch (DuplicateKeyException e) {
    throw new ServiceException("Username already exists");
} catch (Exception e) {
    log.error("Failed to add user", e);
    throw new ServiceException("Failed to add user: " + e.getMessage());
}

// Use global exception handler
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ServiceException.class)
    public AjaxResult handleServiceException(ServiceException e) {
        return AjaxResult.error(e.getCode(), e.getMessage());
    }
}
```

### Comment Standards

#### Class Comments
```java
/**
 * User Information Controller
 * 
 * @author leaniss
 * @date 2024-01-01
 */
@RestController
@RequestMapping("/system/user")
public class SysUserController {
    // ...
}
```

#### Method Comments
```java
/**
 * Query user list by conditions with pagination
 * 
 * @param user User information
 * @return User list
 */
@DataScope(deptAlias = "d", userAlias = "u")
@GetMapping("/list")
public TableDataInfo list(SysUser user) {
    startPage();
    List<SysUser> list = userService.selectUserList(user);
    return getDataTable(list);
}
```

#### Inline Comments
```java
// Use Chinese comments
// Get current logged-in user
LoginUser loginUser = SecurityUtils.getLoginUser();

// Complex logic explanation
// 1. Validate username uniqueness
// 2. Encrypt password
// 3. Insert user data
// 4. Assign default role
```

## Vue.js Coding Standards

### Naming Conventions

#### Component Naming
```vue
<!-- Component file names - PascalCase -->
<!-- UserList.vue -->
<!-- EditDialog.vue -->

<!-- Component registration -->
import UserList from './components/UserList.vue'

export default {
  components: {
    UserList
  }
}
```

#### Variable and Function Naming
```javascript
// Variables - camelCase
const userList = []
const totalCount = 0
const queryParams = {
  pageNum: 1,
  pageSize: 10
}

// Functions - camelCase, start with verb
function getUserList() { }
function handleSelectionChange() { }
function resetQuery() { }

// Constants - UPPER_SNAKE_CASE
const DEFAULT_PAGE_SIZE = 10
const STATUS_NORMAL = '0'
```

### Component Structure

#### Single File Component Structure
```vue
<template>
  <div class="app-container">
    <!-- Template content -->
  </div>
</template>

<script>
export default {
  name: 'UserList',
  components: {},
  props: {},
  data() {
    return {}
  },
  computed: {},
  watch: {},
  created() {},
  methods: {}
}
</script>

<style scoped>
/* Component styles */
</style>
```

#### Props Definition
```javascript
props: {
  // Basic type checking
  userId: Number,
  
  // Multiple possible types
  value: [String, Number],
  
  // Required field
  title: {
    type: String,
    required: true
  },
  
  // With default value
  visible: {
    type: Boolean,
    default: false
  },
  
  // Object default value
  queryParams: {
    type: Object,
    default: () => ({
      pageNum: 1,
      pageSize: 10
    })
  }
}
```

### Code Style

#### Indentation and Spacing
```vue
<!-- Use 2-space indentation -->
<template>
  <div class="container">
    <el-form :model="form" :rules="rules">
      <el-form-item label="Username" prop="userName">
        <el-input v-model="form.userName" />
      </el-form-item>
    </el-form>
  </div>
</template>

<script>
export default {
  methods: {
    handleSubmit() {
      if (this.valid) {
        this.submitForm()
      }
    }
  }
}
</script>
```

#### Directive Usage
```vue
<!-- v-for must bind key -->
<el-option
  v-for="item in options"
  :key="item.value"
  :label="item.label"
  :value="item.value"
/>

<!-- Separate v-if and v-for -->
<template v-for="item in list">
  <div v-if="item.visible" :key="item.id">
    {{ item.name }}
  </div>
</template>

<!-- Shorthand syntax -->
<div @click="handleClick" />
<input v-model="form.name" />
<comp :data="listData" />
```

### API Calls

```javascript
// api/system/user.js
import request from '@/utils/request'

// Query user list
export function listUser(query) {
  return request({
    url: '/system/user/list',
    method: 'get',
    params: query
  })
}

// Add user
export function addUser(data) {
  return request({
    url: '/system/user',
    method: 'post',
    data: data
  })
}
```

## MyBatis XML Standards

### Mapper XML Structure
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.leaniss.system.mapper.SysUserMapper">
    
    <resultMap type="SysUser" id="SysUserResult">
        <id     property="userId"       column="user_id"        />
        <result property="userName"     column="user_name"      />
        <result property="nickName"     column="nick_name"      />
        <result property="status"       column="status"         />
    </resultMap>
    
    <sql id="selectUserVo">
        select user_id, user_name, nick_name, status
        from sys_user
    </sql>
    
    <select id="selectUserList" parameterType="SysUser" resultMap="SysUserResult">
        <include refid="selectUserVo"/>
        <where>
            <if test="userName != null and userName != ''">
                AND user_name like concat('%', #{userName}, '%')
            </if>
            <if test="status != null and status != ''">
                AND status = #{status}
            </if>
        </where>
    </select>
</mapper>
```

## Code Quality

### IDE Configuration
```xml
<!-- .editorconfig -->
root = true

[*.java]
indent_style = space
indent_size = 4

[*.{vue,js}]
indent_style = space
indent_size = 2

[*.xml]
indent_style = space
indent_size = 4
```

### Checklist
- [ ] No compilation warnings
- [ ] Follow naming conventions
- [ ] Add necessary comments
- [ ] No duplicate code
- [ ] Complete exception handling
- [ ] No security vulnerabilities

---

*This document should be updated when coding standards change. Use `/context-update` command to keep the document current.*
