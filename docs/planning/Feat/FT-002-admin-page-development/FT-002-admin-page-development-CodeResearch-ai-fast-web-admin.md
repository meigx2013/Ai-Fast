# FT-002 Admin 管理后台页面开发 - 代码调研总结

> 代码库路径：ai-fast-web/ai-fast-web-admin/
> 调研日期：2026-06-02
> 调研人：meiguangxian

---

## 1. 代码库名称和路径

| 项目 | 值 |
|------|------|
| 代码库名称 | ai-fast-web-admin |
| 代码库路径 | `ai-fast-web/ai-fast-web-admin/` |
| 技术栈 | Vue 3 / JavaScript / Vite / Element Plus / ECharts |
| 包管理器 | npm |
| 开发端口 | 3001 |

---

## 2. 目录结构和关键文件列表

```
ai-fast-web-admin/
├── index.html                     # HTML 入口模板
├── package.json                   # 项目依赖配置
├── vite.config.js                 # Vite 构建配置（@ 别名、端口 3001）
├── src/
│   ├── App.vue                    # 根组件（仅 router-view）
│   ├── main.js                    # 应用入口（注册 ElementPlus + Icons + Pinia + Router）
│   ├── assets/
│   │   └── main.scss              # 全局样式（基础重置 + 滚动条样式，677B）
│   ├── data/
│   │   └── admin.json             # Mock 数据（7.75KB，含 admin/users/workflows/categories/stats/systemConfig）
│   ├── router/
│   │   └── index.js               # 路由配置 + 导航守卫（8 条路由全部指向缺失视图）
│   ├── stores/
│   │   ├── admin.js               # 管理员状态（1KB）
│   │   ├── content.js             # 内容/工作流状态（3.21KB）
│   │   ├── stats.js                # 统计+系统配置状态（461B）
│   │   └── userManage.js           # 用户管理状态（1.99KB）
│   ├── views/                     # ❌ 不存在！需创建全部 8 个视图
│   ├── components/                # ❌ 不存在！
│   ├── utils/                     # ❌ 不存在！
│   └── api/                       # ❌ 不存在！
└── public/                        # ❌ 不存在！
```

### 关键文件状态

| 文件路径 | 状态 | 说明 |
|----------|:----:|------|
| `src/App.vue` | ✅ 已有 | 仅包含 `<router-view />`，样式极简 |
| `src/main.js` | ✅ 已有 | 注册 ElementPlus（中文）、Icons、Pinia、Router |
| `src/router/index.js` | ✅ 已有 | 8 条路由已配置，但视图组件全部缺失 |
| `src/data/admin.json` | ✅ 已有 | 完整 Mock 数据，覆盖所有业务场景 |
| `src/stores/admin.js` | ✅ 已有 | 登录/登出/Token 管理 |
| `src/stores/content.js` | ✅ 已有 | 工作流 CRUD + 筛选 + 审核操作 |
| `src/stores/stats.js` | ✅ 已有 | 统计数据 + 系统配置 |
| `src/stores/userManage.js` | ✅ 已有 | 用户列表 + 筛选 + 状态/角色更新 |
| `src/assets/main.scss` | ✅ 已有 | 仅基础重置样式 |
| `src/stores/theme.js` | ❌ 缺失 | 需新增主题状态管理 |
| `src/views/*.vue` | ❌ 全部缺失 | 需创建 8 个视图组件 |

---

## 3. 现有实现分析

### 3.1 路由配置

| 路由路径 | 路由名称 | 视图组件 | Meta | 层级 |
|----------|----------|----------|------|------|
| `/login` | AdminLogin | `@/views/Login.vue` | `{ title: '登录' }` | 顶级 |
| `/` | — | `@/views/Layout.vue` | redirect → `/dashboard` | 顶级（布局） |
| `/dashboard` | Dashboard | `@/views/Dashboard.vue` | `{ title: '数据统计', icon: 'DataAnalysis' }` | Layout 子路由 |
| `/content` | ContentManage | `@/views/ContentManage.vue` | `{ title: '内容管理', icon: 'Document' }` | Layout 子路由 |
| `/content/edit/:id?` | ContentEdit | `@/views/ContentEdit.vue` | `{ title: '内容编辑', icon: 'Edit', hidden: true }` | Layout 子路由（隐藏菜单） |
| `/review` | ContentReview | `@/views/ContentReview.vue` | `{ title: '内容审核', icon: 'Finished' }` | Layout 子路由 |
| `/users` | UserManage | `@/views/UserManage.vue` | `{ title: '用户管理', icon: 'User' }` | Layout 子路由 |
| `/settings` | SystemSettings | `@/views/SystemSettings.vue` | `{ title: '系统配置', icon: 'Setting' }` | Layout 子路由 |

**路由守卫逻辑**：
- 未登录访问非 `/login` 页 → 重定向至 `/login`
- 已登录访问 `/login` → 重定向至 `/dashboard`
- Token 存储在 `localStorage` 的 `admin_token` 键
- 页面标题格式：`${meta.title} - AI Fast 管理后台`

**设计要点**：
- Layout 是所有后台页面的父级容器
- ContentEdit 设置 `hidden: true` 不在侧边栏菜单显示
- ContentEdit 的 `:id?` 参数可选，支持新建和编辑两种模式
- 所有视图使用懒加载 `() => import()`
- 使用 HTML5 History 模式

### 3.2 Pinia Store 详细分析

#### useAdminStore（`stores/admin.js`）

| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| `token` | ref\<string\> | 从 localStorage 初始化，键名 `admin_token` |
| `adminInfo` | ref\<object\|null\> | 管理员信息对象 |
| `isLoggedIn` | computed | `!!token.value` |
| `login(username, password)` | function | 硬编码验证 `admin/admin123`，成功写入 localStorage |
| `logout()` | function | 清空 token 和 adminInfo |
| `initAdmin()` | function | 若有 token 则加载 adminInfo |

**adminInfo 数据结构**：

| 字段 | 类型 | 示例值 |
|------|------|--------|
| id | number | 1 |
| username | string | "admin" |
| name | string | "系统管理员" |
| avatar | string | URL |
| role | string | "super_admin" |
| email | string | "admin@aifast.com" |
| lastLoginAt | string | "2024-03-22 10:30:00" |

#### useContentStore（`stores/content.js`）

| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| `workflows` | ref\<Array\> | 工作流列表，初始化自 adminData.workflows |
| `categories` | ref\<Array\> | 分类列表 |
| `searchKeyword` | ref\<string\> | 搜索关键词 |
| `filterStatus` | ref\<string\> | 状态筛选，默认 `'all'` |
| `filterCategory` | ref\<string\> | 分类筛选，默认 `'all'` |
| `filteredWorkflows` | computed | 三重过滤：状态→分类→关键词 |
| `pendingCount` | computed | 待审核数量 |
| `getWorkflowById(id)` | function | 查找单个工作流 |
| `addWorkflow(workflow)` | function | 新增，默认 published 状态 |
| `updateWorkflow(id, data)` | function | 更新，自动更新 updatedAt |
| `deleteWorkflow(id)` | function | 删除工作流 |
| `approveWorkflow(id)` | function | 审核通过 → status = 'published' |
| `rejectWorkflow(id, reason)` | function | 审核拒绝 → status = 'rejected' + rejectReason |
| `setSearchKeyword/setFilterStatus/setFilterCategory` | function | 设置筛选条件 |

**workflow 数据结构**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 唯一标识 |
| title | string | 标题 |
| description | string | 描述（纯文本） |
| cover | string | 封面图 URL |
| category | string | 分类名称 |
| tags | string[] | 标签数组 |
| author | { id, name } | 作者信息 |
| status | string | 状态：published/pending/rejected/draft |
| views/likes/favorites | number | 统计数据 |
| createdAt/updatedAt | string | 日期字符串 |
| difficulty | string | 难度：初级/中级/高级 |
| duration | string | 时长描述 |
| rejectReason | string | 拒绝原因（仅 rejected 状态） |

#### useStatsStore（`stores/stats.js`）

| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| `stats` | ref\<Object\> | 统计数据对象 |
| `systemConfig` | ref\<Object\> | 系统配置对象 |
| `updateSystemConfig(config)` | function | 合并更新系统配置 |

**stats 数据结构**：

| 字段 | 类型 | 说明 |
|------|------|------|
| totalUsers | number | 总用户数（1256） |
| totalWorkflows | number | 总工作流数（86） |
| totalViews | number | 总浏览量（45230） |
| totalLikes | number | 总点赞数（8930） |
| todayNewUsers/todayNewWorkflows/todayViews | number | 今日新增数据 |
| pendingReviews | number | 待审核数（3） |
| weeklyData | Array\<{date, users, workflows, views}\> | 7 天趋势数据 |
| categoryDistribution | Array\<{name, value}\> | 分类分布数据 |

**systemConfig 数据结构**：

| 字段 | 类型 | 说明 |
|------|------|------|
| siteName | string | 站点名称 |
| siteDescription | string | 站点描述 |
| allowRegister | boolean | 允许注册 |
| contentReviewEnabled | boolean | 内容审核开关 |
| maxUploadSize | number | 最大上传大小（MB） |
| smtpHost/smtpPort/smtpUser/smtpSsl | string/number/boolean | SMTP 配置 |
| watermarkEnabled | boolean | 水印开关 |
| maintenanceMode | boolean | 维护模式 |

#### useUserManageStore（`stores/userManage.js`）

| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| `users` | ref\<Array\> | 用户列表 |
| `searchKeyword` | ref\<string\> | 搜索关键词 |
| `filterStatus` | ref\<string\> | 状态筛选 |
| `filterRole` | ref\<string\> | 角色筛选 |
| `filteredUsers` | computed | 三重过滤：状态→角色→关键词 |
| `getUserById(id)` | function | 查找用户 |
| `updateUserStatus(id, status)` | function | 更新用户状态（active/disabled） |
| `updateUserRole(id, role)` | function | 更新用户角色（user/author） |
| `deleteUser(id)` | function | 删除用户 |
| `setSearchKeyword/setFilterStatus/setFilterRole` | function | 设置筛选条件 |

**user 数据结构**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 唯一标识 |
| username | string | 用户名 |
| name | string | 显示名 |
| email | string | 邮箱 |
| avatar | string | 头像 URL |
| bio | string | 简介 |
| status | string | 状态：active/disabled |
| role | string | 角色：user/author |
| contentCount | number | 内容数量 |
| createdAt | string | 注册日期 |

### 3.3 应用入口（`main.js`）

已配置的核心能力：
- Vue 3 应用创建
- Pinia 状态管理
- Vue Router
- Element Plus（中文 locale `zh-cn`）
- Element Plus Icons 全局注册
- 全局样式引入

### 3.4 全局样式（`assets/main.scss`）

当前仅有基础重置样式和滚动条样式，**没有 CSS 变量系统、主题变量、动画定义**。与用户端差距极大。

### 3.5 依赖分析（`package.json`）

| 依赖 | 版本 | 用途 |
|------|------|------|
| vue | ^3.4.21 | 核心框架 |
| vue-router | ^4.3.0 | 路由 |
| pinia | ^2.1.7 | 状态管理 |
| element-plus | ^2.6.1 | UI 组件库 |
| @element-plus/icons-vue | ^2.3.1 | 图标库 |
| axios | ^1.6.7 | HTTP 客户端（已安装但未使用） |
| echarts | ^5.5.0 | 图表库（已安装但未使用） |
| sass | ^1.71.1 | CSS 预处理器 |

---

## 4. 关键发现和缺失项

| 编号 | 缺失项 | 影响范围 | 优先级 | 说明 |
|:----:|--------|----------|:------:|------|
| admin-G1 | 8 个视图组件全部缺失 | 全部视图 | P0 | `views/` 目录不存在，所有路由指向的组件均无法加载 |
| admin-G2 | 主题 Store 缺失 | Layout + 全局 | P1 | 需新建 `stores/theme.js`，实现亮/暗/跟随系统三模式 |
| admin-G3 | CSS 变量系统缺失 | 全局样式 | P1 | 当前仅有基础重置，缺少主题变量、阴影、渐变、动画等设计 Token |
| admin-G4 | Element Plus 暗黑模式未配置 | 全局样式 | P1 | 需在 `main.scss` 中添加 Element Plus 暗黑模式 CSS 变量覆盖 |
| admin-G5 | localStorage 持久化未实现 | Store 层 | P1 | 除 admin store 的 token 外，content/stats/userManage 的数据均未持久化 |
| admin-G6 | 公共组件目录缺失 | 组件层 | P2 | `components/` 目录不存在，需创建统计卡片、状态标签等公共组件 |
| admin-G7 | 工具函数目录缺失 | 工具层 | P2 | `utils/` 目录不存在，后续可能需要 localStorage 持久化工具 |
| admin-G8 | 项目为 JavaScript 非 TypeScript | 全局 | P2 | README 提及 TypeScript 但实际为 JavaScript 项目，需保持 JS 一致性 |

---

## 5. 与其他代码库的交互接口

### 5.1 与 ai-fast-web-user 的关系

| 维度 | 说明 |
|------|------|
| 共享数据 | 共享相同的 Mock 数据结构（用户、工作流、分类），但各自独立维护 |
| 设计语言 | 用户端已有完整的 CSS 变量系统（`:root` + `html.dark`），admin 端需对齐 |
| 主题架构 | 用户端 `stores/theme.js` 实现了 dark/light 切换 + `html.classList` 切换；admin 需扩展为 dark/light/system 三模式 |
| 组件风格 | 用户端使用品牌渐变、圆角、阴影、动画等现代设计，admin 端需对齐 |
| 独立运行 | 两个项目独立运行（端口 3000 vs 3001），无直接 API 交互 |

### 5.2 用户端 CSS 变量系统参考

用户端 `main.scss` 定义了完整的设计 Token 体系，admin 端应复用该体系：

- **背景色系**：`--bg-primary`、`--bg-secondary`、`--bg-tertiary`、`--bg-card`
- **文字色系**：`--text-primary`、`--text-secondary`、`--text-tertiary`
- **强调色**：`--accent-primary`（#6366f1）、`--accent-gradient`
- **阴影**：`--shadow-sm/md/lg/xl`
- **圆角**：`--radius-sm/md/lg/xl`
- **动画**：`--duration-fast/normal/slow`、`--ease-standard/decelerate`
- **Element Plus 暗黑覆盖**：`html.dark` 下对 `--el-*` 变量的完整覆盖

---

## 6. 待确认问题清单

| 编号 | 问题 | 建议方案 | 影响 |
|:----:|------|----------|------|
| Q1 | admin 端的 CSS 变量系统是否直接复用用户端定义 | 建议从用户端 `main.scss` 复制 CSS 变量系统，并在其基础上扩展 admin 专用变量（如侧边栏宽度、布局间距等） | 影响全局样式和主题切换 |
| Q2 | 主题 Store 是否需要支持「跟随系统」模式 | Overall 文档已确认需要三模式（亮/暗/跟随系统），用户端仅支持两模式（亮/暗），admin 端需扩展 | 影响主题 Store 设计和切换交互 |
| Q3 | localStorage 持久化的 Store 范围 | Overall 确认「关键业务数据持久化」，建议持久化：content.workflows、stats.systemConfig、userManage.users、theme 偏好 | 影响数据一致性和刷新体验 |
| Q4 | 是否需要将用户端的 scroll-reveal 动画系统引入 admin | 建议简化引入，admin 端更注重功能可用性，动画可适当精简 | 影响开发工作量 |
