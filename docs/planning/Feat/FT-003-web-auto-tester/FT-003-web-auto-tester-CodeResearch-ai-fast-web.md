# FT-003 Code Research — ai-fast-web

> 代码库路径：`ai-fast-web/`
> 扫描日期：2026-07-13

---

## 1. 目录结构与关键文件

```
ai-fast-web/
├── ai-fast-web-admin/          # 管理后台 (端口 3001)
│   ├── index.html, package.json, vite.config.js
│   ├── src/
│   │   ├── main.js             # 入口 (Pinia+ElementPlus+VueRouter)
│   │   ├── App.vue             # 根组件 (主题初始化)
│   │   ├── assets/main.scss    # 全局样式
│   │   ├── components/StatCard.vue
│   │   ├── data/admin.json     # 模拟数据
│   │   ├── router/index.js     # 路由定义+认证守卫
│   │   ├── stores/ (admin/content/userManage/stats/theme)
│   │   ├── utils/persistence.js # localStorage持久化
│   │   └── views/ (Login/Layout/Dashboard + 5个占位视图)
│   └── dist/
│
├── ai-fast-web-user/           # 用户前端 (端口 3000)
│   ├── index.html, package.json, vite.config.js
│   ├── src/
│   │   ├── main.js             # 入口 (含滚动动画观察器)
│   │   ├── App.vue             # 根组件 (主题+用户初始化)
│   │   ├── assets/main.scss
│   │   ├── components/ (AgentCard/WorkflowCard/CardSkeleton/EmptyState)
│   │   ├── data/ (agents.json/users.json/workflows.json)
│   │   ├── router/index.js     # 路由定义+认证守卫
│   │   ├── stores/ (user/agent/workflow/theme)
│   │   └── views/ (全部已实现: Login/Register/Layout/Home/Agents/Workflows/WorkflowDetail/Resources/UserCenter)
│   └── dist/
```

---

## 2. 现有实现分析

### 2.1 技术栈

| 方面 | Admin 端 | User 端 |
|------|----------|---------|
| 框架 | Vue 3.4 (`<script setup>`) | Vue 3.4 (`<script setup>`) |
| 构建 | Vite 5.1 | Vite 5.1 |
| 路由 | vue-router 4.3 | vue-router 4.3 |
| 状态 | Pinia 2.1 | Pinia 2.1 |
| UI | Element Plus 2.6 | Element Plus 2.6 |
| 图表 | ECharts 5.5 | 无 |
| 语言 | **JavaScript**（非 TS） | **JavaScript**（非 TS） |
| 端口 | 3001 | 3000 |

**重要发现**：项目使用纯 **JavaScript**，非 TypeScript。测试脚本本身可用 TS 编写，但目标项目无 TS 类型定义。

### 2.2 路由与页面状态

**Admin 端路由**：

| 路径 | 页面 | 状态 | 测试重点 |
|------|------|------|----------|
| `/login` | 登录 | ✅ 已实现 | 登录表单、认证流程 |
| `/dashboard` | 仪表盘 | ✅ 已实现 | ECharts 图表、统计卡片 |
| `/content` | 内容管理 | ❌ 占位 | CRUD列表 |
| `/content/edit/:id?` | 内容编辑 | ❌ 占位 | 创建/编辑表单 |
| `/review` | 内容审核 | ❌ 占位 | 审核流程 |
| `/users` | 用户管理 | ❌ 占位 | 用户列表 |
| `/settings` | 系统配置 | ❌ 占位 | 配置表单 |

**User 端路由**：

| 路径 | 页面 | 认证 | 状态 | 测试重点 |
|------|------|------|------|----------|
| `/home` | 首页 | 无 | ✅ | Hero区、热门卡片、数字动画 |
| `/agents` | 智能体 | 无 | ✅ | 搜索、分类筛选 |
| `/workflows` | 工作流 | 无 | ✅ | 搜索、分类筛选 |
| `/workflow/:id` | 详情 | 无 | ✅ | 视差封面、步骤进度、点赞/收藏 |
| `/resources` | 资源库 | 无 | ✅ | 搜索、筛选 |
| `/user` | 个人中心 | **需认证** | ✅ | 编辑资料、收藏/点赞 |
| `/login` | 登录 | 无 | ✅ | 登录表单 |
| `/register` | 注册 | 无 | ✅ | 5字段注册 |

### 2.3 认证机制

| 维度 | Admin 端 | User 端 |
|------|----------|---------|
| Token key | `admin_token` | `token` |
| 凭证验证 | 硬编码 admin/admin123 | 任意非空 username+password |
| Token 格式 | `admin-token-{timestamp}` | `mock-token-{timestamp}` |
| 路由守卫 | 全站强制认证 | 仅 `/user` 需认证 |
| 登出 | ElMessageBox确认→清除token | Header下拉→清除token |

### 2.4 Store 层 CRUD 操作（已定义但视图占位）

| Store | 操作 | 方法 |
|-------|------|------|
| contentStore | CRUD | addWorkflow/getWorkflowById/updateWorkflow/deleteWorkflow |
| contentStore | 审核 | approveWorkflow/rejectWorkflow |
| userManageStore | 管理 | getUserById/updateUserStatus/updateUserRole/deleteUser |
| workflowStore(User) | 互动 | likeWorkflow/unlikeWorkflow/favoriteWorkflow/unfavoriteWorkflow |
| userStore(User) | 认证 | login/register/updateUserInfo |

### 2.5 UI 交互关键点

| 交互类型 | 选择器模式 | 说明 |
|----------|-----------|------|
| 表单 | `.login-form .el-form-item` / `.auth-form .el-form-item` | Element Plus 组件 |
| 导航 | `el-menu`(Admin) / router-link(User) | 侧边栏/顶部导航 |
| 列表 | 搜索框+分类chips+卡片网格 | 搜索筛选 |
| 主题 | 循环切换(light→dark→system)(Admin) / 二元切换(User) | `html.dark` class |

### 2.6 动画与异步

| 异步行为 | 延迟 | 影响 |
|----------|------|------|
| 登录/注册 setTimeout | 500ms | 需等待验证 |
| 骨架屏加载 | 600ms | 需等待DOM更新 |
| CountUp 数字动画 | 2s | 需等待数值稳定 |
| IntersectionObserver | 滚动触发 | 需模拟滚动 |

---

## 3. 关键发现与缺失项

| 编号 | 发现/缺失项 | 说明 |
|------|------------|------|
| web-G1 | **Admin端5个页面占位** | 内容管理/编辑/审核/用户管理/系统配置仅占位，Store层已定义 |
| web-G2 | **纯前端Mock认证** | 无后端API，所有认证是 localStorage 约定 |
| web-G3 | **JavaScript而非TypeScript** | 项目无 TS 类型定义，测试脚本选择需考虑 |
| web-G4 | **双项目并行启动** | 需同时启动端口3000+3001 |
| web-G5 | **Element Plus 组件结构** | 需熟悉 el-input__wrapper 等内部DOM |
| web-G6 | **动画延迟影响断言** | 500ms~2s 的动画/延迟需在测试中处理 |
| web-G7 | **localStorage 操控** | 可通过 localStorage 设置/清理测试状态 |

---

## 4. 与其他代码库的交互接口

- **无真实后端 API**：所有数据来自 JSON 文件 + localStorage
- **两端独立运行**：Admin 和 User 端独立 Vite 项目，端口不同
- **共享 UI 框架**：Element Plus + Vue 3 + Pinia + SCSS
