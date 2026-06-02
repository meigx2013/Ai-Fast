# AI Fast - 管理后台

AI Agent 与工作流教学分享平台的管理后台，基于 Vue 3 + Element Plus + ECharts 构建，提供内容管理、用户管理、数据统计和系统配置等运营管理功能。

## 功能概览

### 页面模块

| 页面 | 路由 | 说明 |
|------|------|------|
| 登录 | `/login` | 管理员登录（硬编码账号：admin / admin123） |
| 数据统计 | `/dashboard` | 平台核心指标、7 天趋势图、分类分布图 |
| 内容管理 | `/content` | 工作流内容列表，支持状态/分类筛选和关键词搜索 |
| 内容编辑 | `/content/edit/:id?` | 工作流内容新增/编辑表单 |
| 内容审核 | `/review` | 待审核内容列表，支持通过/拒绝操作 |
| 用户管理 | `/users` | 用户列表，支持状态/角色筛选、启用/禁用/删除 |
| 系统配置 | `/settings` | 站点信息、注册/审核开关、上传限制、SMTP、水印、维护模式 |

### 核心功能

- **数据统计** — 展示平台核心指标（总用户/工作流/浏览/点赞），ECharts 趋势图与分类分布图
- **内容管理** — 工作流的完整 CRUD 操作，支持按状态（已发布/待审核/已拒绝/草稿）、分类和关键词筛选
- **内容审核** — 审核工作流提交，支持通过/拒绝操作，待审核计数提示
- **用户管理** — 用户列表管理，支持修改用户状态（启用/禁用）、角色（user/author）、删除用户
- **系统配置** — 站点名称/描述、注册开关、审核开关、上传限制、SMTP 配置、水印开关、维护模式
- **路由鉴权** — 未登录自动跳转登录页，已登录访问登录页自动跳转仪表盘

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Vue | 3.4.x | 渐进式 JavaScript 框架 |
| Vue Router | 4.3.x | 路由管理（HTML5 History 模式） |
| Pinia | 2.1.x | 状态管理（Composition API 风格） |
| Element Plus | 2.6.x | UI 组件库（中文语言包） |
| @element-plus/icons-vue | 2.3.x | 图标库（全局注册） |
| ECharts | 5.5.x | 数据可视化图表库 |
| Axios | 1.6.x | HTTP 请求库 |
| Vite | 5.1.x | 构建工具 |
| Sass | 1.71.x | CSS 预处理器 |

## 项目结构

```
ai-fast-web-admin/
├── public/                  # 静态资源
├── src/
│   ├── assets/              # 全局样式
│   │   └── main.scss        # 全局 SCSS 重置与滚动条样式
│   ├── data/                # Mock 数据
│   │   └── admin.json       # 管理后台模拟数据（管理员/用户/工作流/分类/统计/系统配置）
│   ├── router/              # 路由配置
│   │   └── index.js         # 路由定义与导航守卫
│   ├── stores/              # Pinia 状态管理
│   │   ├── admin.js         # 管理员状态（登录/登出/Token 管理）
│   │   ├── content.js       # 内容状态（工作流 CRUD/筛选/审核）
│   │   ├── stats.js         # 统计状态（平台数据/系统配置）
│   │   └── userManage.js    # 用户管理状态（用户列表/筛选/状态修改/删除）
│   ├── views/               # 页面组件（待创建）
│   │   ├── Login.vue        # 管理员登录
│   │   ├── Layout.vue       # 后台布局（侧边栏 + 顶栏 + 内容区）
│   │   ├── Dashboard.vue    # 数据统计仪表盘
│   │   ├── ContentManage.vue # 内容管理列表
│   │   ├── ContentEdit.vue  # 内容编辑表单
│   │   ├── ContentReview.vue # 内容审核列表
│   │   ├── UserManage.vue   # 用户管理列表
│   │   └── SystemSettings.vue # 系统配置表单
│   ├── App.vue              # 根组件
│   └── main.js              # 入口文件（全局注册 Element Plus 图标）
├── index.html               # HTML 模板
├── vite.config.js           # Vite 配置
└── package.json             # 项目依赖
```

## 快速开始

### 环境要求

- Node.js 16+
- npm 或 yarn

### 安装依赖

```bash
cd ai-fast-web/ai-fast-web-admin
npm install
```

### 启动开发服务器

```bash
npm run dev
```

访问 http://localhost:3001

### 构建生产版本

```bash
npm run build
```

### 预览生产构建

```bash
npm run preview
```

## 状态管理

项目使用 Pinia 进行状态管理，当前采用 Mock 数据模式：

| Store | 文件 | 职责 |
|-------|------|------|
| `useAdminStore` | `stores/admin.js` | 管理员登录/登出、Token 管理（localStorage 持久化） |
| `useContentStore` | `stores/content.js` | 工作流内容列表、CRUD 操作、审核流程、状态/分类/关键词筛选 |
| `useStatsStore` | `stores/stats.js` | 平台统计数据、系统配置读写 |
| `useUserManageStore` | `stores/userManage.js` | 用户列表、状态/角色修改、删除、筛选 |

> 当前管理员认证为 Mock 模式，硬编码账号 `admin/admin123`，Token 存储在 localStorage。后续对接后端 API 时需替换为真实认证逻辑。

## 与用户端的关系

| 维度 | 用户端 (`ai-fast-web-user`) | 管理后台 (`ai-fast-web-admin`) |
|------|---------------------------|-------------------------------|
| 端口 | 3000 | 3001 |
| 角色 | C 端用户（浏览/学习/收藏） | 管理员（审核/管理/配置） |
| 核心页面 | 首页/智能体/工作流/资源库/个人中心 | 仪表盘/内容管理/审核/用户管理/系统配置 |
| 数据方向 | 读取 + 互动（点赞/收藏） | 读取 + 写入 + 审核 + 配置 |
| 技术栈 | Vue 3 + Element Plus | Vue 3 + Element Plus + ECharts |
| 主题 | 明暗主题切换 | 固定亮色主题 |

## 开发进度

- [x] 项目骨架搭建（路由/状态管理/模拟数据/全局样式）
- [ ] 视图组件开发（Login / Layout / Dashboard / ContentManage / ContentEdit / ContentReview / UserManage / SystemSettings）
- [ ] 对接后端 API（替换 Mock 数据）
- [ ] 管理员权限细分（超级管理员 / 普通管理员）

## 配置说明

- **开发端口**：`3001`（在 `vite.config.js` 中配置）
- **路径别名**：`@` → `src/`
- **Element Plus**：使用中文语言包（`zh-cn`），全局注册所有图标
- **路由模式**：HTML5 History 模式
