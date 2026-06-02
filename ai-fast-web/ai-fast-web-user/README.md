# AI Fast - To C 用户端

AI Agent 与工作流教学分享平台的用户端前端，基于 Vue 3 + Element Plus 构建，提供智能体浏览、工作流学习、资源获取等功能。

## 功能概览

### 页面模块

| 页面 | 路由 | 说明 |
|------|------|------|
| 首页 | `/home` | Hero 横幅、热门智能体、热点工作流、平台数据统计 |
| 智能体 | `/agents` | AI 智能体列表，支持分类筛选和关键词搜索 |
| 工作流 | `/workflows` | 工作流教程列表，支持分类筛选和关键词搜索 |
| 工作流详情 | `/workflow/:id` | 工作流详细信息、步骤展示、收藏与点赞 |
| 资源库 | `/resources` | 技术文档、视频教程、开发工具、工作流模板等资源分类浏览 |
| 个人中心 | `/user` | 用户信息管理（需登录） |
| 登录 | `/login` | 用户登录 |
| 注册 | `/register` | 用户注册 |

### 核心功能

- **智能体浏览** — 展示热门 AI 智能体卡片，支持分类筛选（写作、数据分析、开发、客服、设计等）
- **工作流学习** — 浏览工作流教程，查看详细步骤，支持收藏与点赞
- **资源库** — 按类别浏览技术文档、视频教程、开发工具、工作流模板、SDK & API 等资源
- **搜索筛选** — 全站关键词搜索 + 分类标签筛选
- **明暗主题** — 支持亮色/暗色主题切换，主题偏好持久化
- **响应式布局** — 适配桌面端与移动端，移动端抽屉式导航
- **滚动动画** — 基于 IntersectionObserver 的滚动揭示动画
- **路由鉴权** — 个人中心等页面需登录访问，未登录自动跳转登录页

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Vue | 3.4.x | 渐进式 JavaScript 框架 |
| Vue Router | 4.3.x | 路由管理 |
| Pinia | 2.1.x | 状态管理 |
| Element Plus | 2.6.x | UI 组件库（中文语言包） |
| @element-plus/icons-vue | 2.3.x | 图标库 |
| Axios | 1.6.x | HTTP 请求库 |
| Vite | 5.1.x | 构建工具 |
| Sass | 1.71.x | CSS 预处理器 |

## 项目结构

```
ai-fast-web-user/
├── public/                  # 静态资源
├── src/
│   ├── assets/              # 全局样式
│   │   └── main.scss        # 全局 SCSS 变量与样式
│   ├── components/          # 公共组件
│   │   ├── AgentCard.vue    # 智能体卡片
│   │   ├── WorkflowCard.vue # 工作流卡片
│   │   ├── CardSkeleton.vue # 骨架屏加载组件
│   │   └── EmptyState.vue   # 空状态组件
│   ├── data/                # Mock 数据
│   │   ├── agents.json      # 智能体数据
│   │   ├── workflows.json   # 工作流数据
│   │   └── users.json       # 用户数据
│   ├── router/              # 路由配置
│   │   └── index.js         # 路由定义与导航守卫
│   ├── stores/              # Pinia 状态管理
│   │   ├── user.js          # 用户状态（登录/注册/登出）
│   │   ├── theme.js         # 主题状态（亮/暗切换）
│   │   ├── agent.js         # 智能体状态（列表/筛选/搜索）
│   │   └── workflow.js      # 工作流状态（列表/筛选/搜索/点赞/收藏）
│   ├── views/               # 页面组件
│   │   ├── Layout.vue       # 全局布局（Header + Main + Footer）
│   │   ├── Home.vue         # 首页
│   │   ├── Agents.vue       # 智能体列表
│   │   ├── Workflows.vue    # 工作流列表
│   │   ├── WorkflowDetail.vue # 工作流详情
│   │   ├── Resources.vue    # 资源库
│   │   ├── UserCenter.vue   # 个人中心
│   │   ├── Login.vue        # 登录
│   │   └── Register.vue     # 注册
│   ├── App.vue              # 根组件
│   └── main.js              # 入口文件
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
cd ai-fast-web/ai-fast-web-user
npm install
```

### 启动开发服务器

```bash
npm run dev
```

访问 http://localhost:3000

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
| `useUserStore` | `stores/user.js` | 用户登录/注册/登出、Token 管理、用户信息 |
| `useThemeStore` | `stores/theme.js` | 亮/暗主题切换、主题持久化到 localStorage |
| `useAgentStore` | `stores/agent.js` | 智能体列表、分类筛选、搜索、热门推荐 |
| `useWorkflowStore` | `stores/workflow.js` | 工作流列表、分类筛选、搜索、点赞/收藏 |

> 当前用户认证为 Mock 模式，Token 存储在 localStorage。后续对接后端 API 时需替换为真实认证逻辑。

## 配置说明

- **开发端口**：`3000`（在 `vite.config.js` 中配置）
- **路径别名**：`@` → `src/`
- **Element Plus**：使用中文语言包（`zh-cn`）
- **路由模式**：HTML5 History 模式
