## 平台简介

本平台是一个AI Agent和工作流教学分享平台，平台是一个基于 Vue3/Element UI 和 Spring Boot3/Spring Cloud & Alibaba 前后端分离的分布式微服务架构。

平台包含一个工作流教学分享的To C端站点和一个教学内容发布的管理后台。

## 核心服务

| 服务名称 | 服务说明 | 端口 |
|---------|---------|------|
| ai-fast-gateway | 网关服务，统一入口、路由转发、鉴权 | 8080 |
| ai-fast-auth | 认证服务，用户登录、Token管理 | 8081 |
| ai-fast-user | 用户服务，用户信息管理、权限控制 | 8082 |
| ai-fast-content | 内容服务，工作流教学内容的发布与管理 | 8083 |
| ai-fast-admin | 管理后台服务，内容审核、数据统计 | 8084 |

## 技术栈

### 后端技术
| 技术 | 说明 | 版本 |
|-----|------|-----|
| Spring Boot | 应用开发框架 | 3.x |
| Spring Cloud | 微服务框架 | 2022.x |
| Spring Cloud Alibaba | 阿里巴巴微服务套件 | 2022.x |
| Nacos | 服务注册与配置中心 | 2.x |
| Gateway | 网关服务 | 4.x |
| OpenFeign | 服务调用 | 4.x |
| MyBatis-Plus | ORM框架 | 3.5.x |
| MySQL | 关系型数据库 | 8.0 |
| Redis | 缓存中间件 | 7.x |
| MinIO | 对象存储 | latest |
| JWT | Token认证 | - |

### 前端技术
| 技术 | 说明 | 版本 |
|-----|------|-----|
| Vue | 渐进式JavaScript框架 | 3.x |
| Element Plus | UI组件库 | 2.x |
| Pinia | 状态管理 | 2.x |
| Vue Router | 路由管理 | 4.x |
| Axios | HTTP请求库 | 1.x |
| Vite | 构建工具 | 5.x |

## 项目结构

```
ai-fast
├── ai-fast-services              // 后端服务（统一目录）
│   ├── ai-fast-common            // 公共模块
│   │   ├── ai-fast-common-core   // 核心公共模块（工具类、常量、异常等）
│   │   ├── ai-fast-common-redis  // Redis公共模块
│   │   └── ai-fast-common-security // 安全公共模块
│   ├── ai-fast-gateway           // 网关服务
│   ├── ai-fast-auth              // 认证服务
│   ├── ai-fast-user              // 用户服务
│   │   ├── ai-fast-user-api      // 用户服务API接口
│   │   └── ai-fast-user-biz      // 用户服务业务实现
│   ├── ai-fast-content           // 内容服务
│   │   ├── ai-fast-content-api   // 内容服务API接口
│   │   └── ai-fast-content-biz   // 内容服务业务实现
│   └── ai-fast-admin             // 管理后台服务
├── ai-fast-web                   // 前端项目
│   ├── ai-fast-web-user          // To C端站点
│   └── ai-fast-web-admin         // 管理后台
└── sql                           // SQL脚本（全局）
```

## 快速开始

### 环境要求

- JDK 17+
- Maven 3.6+
| Node.js 16+
- MySQL 8.0+
- Redis 7.0+
- Nacos 2.x

### 后端启动

1. **克隆项目**
```bash
git clone https://github.com/your-repo/ai-fast.git
cd ai-fast
```

2. **初始化数据库**
```bash
# 创建数据库
mysql -u root -p
CREATE DATABASE ai_fast DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

# 导入SQL脚本
mysql -u root -p ai_fast < ai-fast-services/sql/ai_fast.sql
```

3. **配置Nacos**
   - 启动Nacos服务
   - 导入`config/nacos-config.zip`配置文件
   - 修改数据库连接配置

4. **修改本地配置**
   - 修改各服务`bootstrap.yml`中的Nacos地址
   - 修改Redis连接配置

5. **启动服务**
```bash
# 编译项目
cd ai-fast-services
mvn clean install -DskipTests

# 按顺序启动服务
# 1. 启动网关服务
cd ai-fast-gateway && mvn spring-boot:run

# 2. 启动认证服务
cd ai-fast-auth && mvn spring-boot:run

# 3. 启动用户服务
cd ai-fast-user/ai-fast-user-biz && mvn spring-boot:run

# 4. 启动内容服务
cd ai-fast-content/ai-fast-content-biz && mvn spring-boot:run

# 5. 启动管理后台服务
cd ai-fast-admin && mvn spring-boot:run
```

### 前端启动

1. **安装依赖**
```bash
cd ai-fast-web/ai-fast-web-user
npm install

cd ai-fast-web/ai-fast-web-admin
npm install
```

2. **启动开发服务器**
```bash
# To C端站点
cd ai-fast-web/ai-fast-web-user
npm run dev

# 管理后台
cd ai-fast-web/ai-fast-web-admin
npm run dev
```

3. **访问地址**
   - To C端站点：http://localhost:3000
   - 管理后台：http://localhost:3001
   - API网关：http://localhost:8080
   - Nacos控制台：http://localhost:8848/nacos

## 功能特性

### To C端站点
- 用户注册与登录
- 工作流内容浏览与搜索
- 工作流详情查看
- 工作流收藏与点赞
- 用户个人中心

### 管理后台
- 内容发布与编辑
- 内容审核管理
- 用户管理
- 数据统计与分析
- 系统配置

## 开发指南

### 代码规范
- 遵循阿里巴巴Java开发手册
- 前端代码遵循Vue官方风格指南

### 分支管理
- `main` - 主分支，生产环境代码
- `develop` - 开发分支
- `feature/*` - 功能分支
- `hotfix/*` - 热修复分支

### 提交规范
- `feat` - 新功能
- `fix` - 修复Bug
- `docs` - 文档更新
- `style` - 代码格式调整
- `refactor` - 代码重构
- `test` - 测试相关
- `chore` - 构建/工具相关

## 联系方式

如有问题或建议，欢迎提交Issue或Pull Request。
