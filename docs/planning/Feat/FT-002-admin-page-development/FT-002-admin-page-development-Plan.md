# FT-002 Admin 管理后台页面开发 实施计划

## 项目概述

本计划的目标是实现 AI Fast 管理后台（ai-fast-web-admin）的全部视图组件，使后台从"无法运行"变为"功能完整可用"。核心工作项包括：

1. 建立完整的 CSS Design Token 体系与三模式主题框架（亮/暗/跟随系统）
2. 补齐 8 个缺失视图组件，实现登录、布局、仪表盘、内容管理/编辑/审核、用户管理、系统配置全部功能
3. 实现 localStorage 数据持久化，关键业务操作刷新不丢失
4. 完成全站基础响应式适配，移动端核心操作可用

### 前置依赖

- 无外部特性依赖，本特性为独立开发
- 代码库前提：ai-fast-web-admin 脚手架已搭建（路由、Store、Mock 数据就绪）

### 后续依赖

- 真实 API 接入：当前数据为 JSON Mock，后续需替换 Store 数据源
- 权限管理：当前仅单一 admin 角色，后续可能需要角色权限路由
- 国际化：当前仅中文，后续可能需要 i18n 支持

---

## 进度概要

| Phase | 任务 | 状态 | 交付物 |
|:-----:|------|:----:|--------|
| **P1** 基础设施搭建 | 1.1 CSS 变量体系与主题框架就绪 | ⏳ | `main.scss`、`main.js`、`utils/persistence.js`、`stores/theme.js`、Store 持久化改造 |
| **P2** 登录与布局 | 2.1 管理员可登录进入后台 | ⏳ | `views/Login.vue` |
| | 2.2 后台布局框架可用 | ⏳ | `views/Layout.vue` |
| **P3** 数据仪表盘 | 3.1 仪表盘可查看统计数据与图表 | ⏳ | `components/StatCard.vue`、`views/Dashboard.vue` |
| **P4** 内容管理闭环 | 4.1 工作流列表可搜索筛选浏览 | ⏳ | `components/StatusTag.vue`、`components/SearchFilter.vue`、`views/ContentManage.vue` |
| | 4.2 工作流可新增与编辑 | ⏳ | `views/ContentEdit.vue` |
| **P5** 内容审核闭环 | 5.1 待审核内容可通过或拒绝 | ⏳ | `views/ContentReview.vue` |
| **P6** 用户管理与系统配置 | 6.1 用户状态可管控 | ⏳ | `views/UserManage.vue` |
| | 6.2 系统配置可维护 | ⏳ | `views/SystemSettings.vue` |
| **P7** 响应式适配 | 7.1 全站移动端基础适配 | ⏳ | 全站 CSS 媒体查询 + Layout 移动端抽屉 |

---

## Phase 1: 基础设施搭建 — 设计系统与主题框架

### 目标

建立完整的 CSS Design Token 体系、主题状态管理、localStorage 持久化工具，并为已有 Store 添加数据持久化能力，为后续所有页面开发提供统一的设计基础和数据持久化保障。

### 任务 1.1: CSS 变量体系与主题框架就绪

#### 核心逻辑

1. 扩展 `main.scss`，建立完整的 Design Token 体系（背景色、文字色、边框色、强调色、阴影、圆角、动效、Admin 专用 Token），覆盖 `:root` 和 `html.dark` 两套主题值
2. 在 `main.js` 中引入 Element Plus 暗黑模式 CSS，在 `main.scss` 的 `html.dark` 选择器下覆盖 Element Plus 关键变量
3. 创建 `src/utils/persistence.js`，提供 `loadData`、`saveData`、`removeData` 工具函数和 `STORAGE_KEYS` 常量
4. 创建 `src/stores/theme.js`，实现三模式切换（亮/暗/跟随系统）、系统偏好监听、侧边栏折叠状态管理、localStorage 持久化
5. 改造 `stores/content.js`、`stores/userManage.js`、`stores/stats.js`，添加 `watch` 监听 + `saveData` 调用，实现关键数据自动持久化

#### 配置要点

| 变量/常量 | 用途 | 必填 |
|-----------|------|:----:|
| `STORAGE_KEYS.WORKFLOWS` | 工作流列表持久化键 | ✅ |
| `STORAGE_KEYS.CATEGORIES` | 分类列表持久化键 | ✅ |
| `STORAGE_KEYS.USERS` | 用户列表持久化键 | ✅ |
| `STORAGE_KEYS.SYSTEM_CONFIG` | 系统配置持久化键 | ✅ |
| `STORAGE_KEYS.THEME_MODE` | 主题模式持久化键 | ✅ |
| `STORAGE_KEYS.SIDEBAR_COLLAPSED` | 侧边栏折叠状态持久化键 | ✅ |
| `--sidebar-width: 220px` | 侧边栏展开宽度 | ✅ |
| `--sidebar-collapsed-width: 64px` | 侧边栏折叠宽度 | ✅ |
| `--header-height: 56px` | 顶栏高度 | ✅ |

#### 交付物

- `src/assets/main.scss` — 完整 Design Token 体系 + Element Plus 暗色覆盖
- `src/main.js` — 引入 `element-plus/theme-chalk/dark/css-vars.css` + 主题初始化
- `src/utils/persistence.js` — localStorage 持久化工具
- `src/stores/theme.js` — 主题状态管理（三模式 + 侧边栏 + 持久化）
- `src/stores/content.js` — 添加 workflows + categories 持久化
- `src/stores/userManage.js` — 添加 users 持久化
- `src/stores/stats.js` — 添加 systemConfig 持久化

#### 验证步骤

- [ ] **V1.1.1** 项目启动成功，无编译错误 → 开发服务器正常运行
  `cd ai-fast-web/ai-fast-web-admin && npm run dev`
- [ ] **V1.1.2** CSS 变量体系生效 → `:root` 下可查到 `--bg-primary`、`--accent-primary` 等变量
  在浏览器 DevTools Elements 面板检查 `:root` 计算样式
- [ ] **V1.1.3** 暗色主题切换生效 → `html.dark` class 下变量值切换为暗色
  在浏览器控制台执行 `document.documentElement.classList.add('dark')`，检查背景色变化
- [ ] **V1.1.4** 主题 Store 初始化成功 → `themeStore.themeMode` 默认值为 `'system'`
  在浏览器控制台执行 `useThemeStore().themeMode`
- [ ] **V1.1.5** localStorage 持久化工具可用 → `saveData`/`loadData` 读写正常
  在浏览器控制台执行 `import {saveData,loadData} from '@/utils/persistence'; saveData('test_key',{a:1}); loadData('test_key')`
- [ ] **V1.1.6** Store 持久化生效 → 修改 Store 数据后 localStorage 中出现对应键值
  在浏览器控制台执行 `useContentStore().addWorkflow({...})`，检查 localStorage 中 `admin_workflows` 键
- [ ] **V1.1.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-admin && npm run build`

---

## Phase 2: 登录与布局 — 后台可进入

### 目标

实现管理员登录页面和后台布局框架，使管理员可以登录并看到后台整体框架，完成"进入后台"的核心通路。

### 任务 2.1: 管理员可登录进入后台

#### 核心逻辑

1. 创建 `Login.vue`，实现全屏渐变背景 + 白色/暗色登录卡片 + 品牌 Logo + 账号密码表单
2. 表单使用 `el-input`（用户名 + 密码），`el-button`（渐变主按钮登录）
3. 调用 `adminStore.login(username, password)` 进行 Mock 验证（admin/admin123）
4. 登录成功后 `router.push('/dashboard')`，失败显示 `ElMessage.error()`
5. 已登录用户访问 `/login` 自动跳转 `/dashboard`
6. 响应式：768px 以下卡片宽度 `90vw`

#### 交付物

- `src/views/Login.vue` — 管理员登录页面

#### 验证步骤

- [ ] **V2.1.1** 登录页正常渲染 → 页面显示渐变背景、品牌 Logo、登录表单
  访问 `http://localhost:3001/login`
- [ ] **V2.1.2** 正确凭据登录成功 → 输入 admin/admin123 点击登录，跳转至 Dashboard
  在登录页输入 admin/admin123 并点击登录按钮
- [ ] **V2.1.3** 错误凭据登录失败 → 输入错误密码，显示错误提示
  在登录页输入 admin/wrong 并点击登录按钮
- [ ] **V2.1.4** 已登录用户访问 /login 自动跳转 → 直接跳转至 /dashboard
  登录后访问 `http://localhost:3001/login`
- [ ] **V2.1.5** 未登录访问后台页面重定向至 /login → 显示登录页
  清除 localStorage 中的 admin_token 后访问 `http://localhost:3001/dashboard`
- [ ] **V2.1.6** 暗色模式下登录页正常 → 卡片背景和文字色跟随暗色主题
  在浏览器控制台添加 `html.dark` class 后访问登录页

### 任务 2.2: 后台布局框架可用

#### 核心逻辑

1. 创建 `Layout.vue`，实现 `display: flex` 全屏布局（侧边栏 + 主区域）
2. 侧边栏使用 `el-menu`（router 模式），从路由配置动态生成菜单项，跳过 `hidden: true` 的路由
3. 侧边栏底部折叠按钮，切换展开（220px）/折叠（64px），状态持久化到 localStorage
4. 顶栏固定 56px，左侧面包屑导航，右侧主题切换按钮 + 管理员头像下拉菜单
5. 主题切换按钮循环切换：亮色 → 暗色 → 跟随系统，图标显示 Sunny/Moon/Monitor
6. 管理员头像使用 `el-avatar` + `el-dropdown`，下拉含"个人信息"和"退出登录"
7. 退出登录调用 `adminStore.logout()`，跳转 `/login`
8. 内容区 `flex: 1`，嵌套 `<router-view />`

#### 交付物

- `src/views/Layout.vue` — 后台布局框架

#### 验证步骤

- [ ] **V2.2.1** 布局框架正常渲染 → 侧边栏 + 顶栏 + 内容区完整展示
  登录后查看后台页面
- [ ] **V2.2.2** 侧边栏菜单项正确显示 → 显示数据统计、内容管理、内容审核、用户管理、系统配置 5 项（不含隐藏的内容编辑）
  查看侧边栏菜单列表
- [ ] **V2.2.3** 侧边栏折叠/展开正常 → 点击折叠按钮后侧边栏缩至 64px 图标模式，再点击展开
  点击侧边栏底部折叠/展开按钮
- [ ] **V2.2.4** 主题切换按钮工作正常 → 点击循环切换亮色→暗色→跟随系统，界面即时响应
  点击顶栏右侧主题切换按钮
- [ ] **V2.2.5** 退出登录正常 → 点击退出后清除登录状态，跳转至登录页
  点击管理员头像下拉菜单中的"退出登录"
- [ ] **V2.2.6** 面包屑导航显示当前页面 → 顶栏左侧显示当前页面路径
  切换不同侧边栏菜单项，观察面包屑变化
- [ ] **V2.2.7** 侧边栏折叠状态持久化 → 刷新页面后折叠状态保持
  折叠侧边栏后刷新浏览器页面

---

## Phase 3: 数据仪表盘可查看 — 运营数据可视化

### 目标

实现数据统计仪表盘，管理员登录后可一眼掌握平台核心运营数据（总用户、总工作流、总浏览、总点赞）和趋势分布图表。

### 任务 3.1: 仪表盘可查看统计数据与图表

#### 核心逻辑

1. 创建 `StatCard.vue` 组件，接收 `title`、`value`、`suffix`、`todayNew`、`icon`、`gradientFrom`、`gradientTo` props，实现渐变色图标 + 大号数字 + 今日新增的统计卡片
2. 创建 `Dashboard.vue`，顶部 4 列 grid 布局展示 StatCard（总用户/总工作流/总浏览/总点赞）
3. 中部使用 ECharts 渲染 7 天趋势折线图（用户增长、工作流增长、浏览量三条线），数据从 `statsStore.stats.weeklyData` 获取
4. 底部使用 ECharts 渲染分类分布饼图，数据从 `statsStore.stats.categoryDistribution` 获取
5. 通过 `watch(themeStore.isDark)` 监听主题变化，动态更新 ECharts 图表配色
6. 响应式：统计卡片 1200px 以下 2 列，768px 以下 1 列

#### 核心逻辑

| 统计卡片 | 渐变色 |
|----------|--------|
| 总用户数 | #6366f1 → #818cf8 |
| 总工作流 | #8b5cf6 → #a78bfa |
| 总浏览量 | #ec4899 → #f472b6 |
| 总点赞数 | #f59e0b → #fbbf24 |

#### 交付物

- `src/components/StatCard.vue` — 统计卡片组件
- `src/views/Dashboard.vue` — 数据统计仪表盘页面

#### 验证步骤

- [ ] **V3.1.1** 仪表盘页面正常渲染 → 4 个统计卡片 + 趋势图 + 饼图完整展示
  登录后访问 `/dashboard`
- [ ] **V3.1.2** 统计卡片数据正确 → 总用户 1,256、总工作流 86、总浏览 45,230、总点赞 8,930
  检查仪表盘 4 张统计卡片的数值
- [ ] **V3.1.3** 趋势折线图渲染成功 → 显示 7 天趋势，含用户/工作流/浏览量三条线
  检查仪表盘中部 ECharts 折线图
- [ ] **V3.1.4** 分类分布饼图渲染成功 → 按工作流分类展示数量占比
  检查仪表盘底部 ECharts 饼图
- [ ] **V3.1.5** 主题切换时图表配色更新 → 从亮色切到暗色，图表颜色同步变化
  点击主题切换按钮，观察图表颜色变化
- [ ] **V3.1.6** 统计卡片响应式布局 → 窗口缩小时卡片从 4 列变 2 列再变 1 列
  将浏览器窗口宽度分别调整至 1200px 和 768px 以下

---

## Phase 4: 内容管理闭环 — 工作流可增删改查

### 目标

实现内容管理（列表搜索筛选）和内容编辑（新增/编辑表单），管理员可以完成工作流的完整 CRUD 操作，数据持久化至 localStorage。

### 任务 4.1: 工作流列表可搜索筛选浏览

#### 核心逻辑

1. 创建 `StatusTag.vue` 组件，接收 `status` prop，映射为 Element Plus `el-tag` 的对应 type（published→success、pending→warning、rejected→danger、draft→info）
2. 创建 `SearchFilter.vue` 组件，接收 `searchPlaceholder` 和 `filters` props，emit `search` 和 `filter-change` 事件，布局为搜索框 + 筛选下拉并排
3. 创建 `ContentManage.vue`，顶部页面标题 + "新增工作流"按钮，中部 SearchFilter（状态 + 分类筛选），下部 el-table 展示工作流列表
4. 表格列：标题（超长截断）、分类、状态（StatusTag）、浏览量、点赞数、更新时间、操作（编辑 + 删除）
5. 搜索/筛选调用 `contentStore` 的 `setSearchKeyword`/`setFilterStatus`/`setFilterCategory`，读取 `filteredWorkflows` computed
6. 删除操作弹出 `ElMessageBox.confirm` 确认后调用 `contentStore.deleteWorkflow(id)`
7. 新增按钮跳转 `/content/edit`，编辑按钮跳转 `/content/edit/${row.id}`
8. 底部分页 `el-pagination`

#### 交付物

- `src/components/StatusTag.vue` — 状态标签组件
- `src/components/SearchFilter.vue` — 搜索筛选组件
- `src/views/ContentManage.vue` — 内容管理列表页

#### 验证步骤

- [ ] **V4.1.1** 内容管理页正常渲染 → 搜索筛选条 + 工作流列表表格 + 分页
  访问 `/content`
- [ ] **V4.1.2** 工作流列表数据正确 → 显示 admin.json 中的 6 条工作流
  检查内容管理表格数据行数
- [ ] **V4.1.3** 搜索功能正常 → 输入关键词后列表过滤匹配的工作流
  在搜索框输入关键词，观察列表变化
- [ ] **V4.1.4** 状态筛选正常 → 选择"待审核"后仅显示 pending 状态的工作流
  在状态筛选下拉选择"待审核"
- [ ] **V4.1.5** 分类筛选正常 → 选择分类后仅显示该分类的工作流
  在分类筛选下拉选择某个分类
- [ ] **V4.1.6** 删除功能正常 → 点击删除后确认弹窗，确认后工作流从列表移除
  点击某行操作列的"删除"按钮
- [ ] **V4.1.7** 删除后数据持久化 → 刷新页面后已删除的工作流不再出现
  删除一条工作流后刷新浏览器
- [ ] **V4.1.8** StatusTag 组件显示正确 → 已发布(绿)、待审核(黄)、已拒绝(红)、草稿(灰)
  检查列表中不同状态行的标签颜色

### 任务 4.2: 工作流可新增与编辑

#### 核心逻辑

1. 创建 `ContentEdit.vue`，根据 `route.params.id` 是否存在判断新增/编辑模式
2. 表单字段：标题（el-input，必填，maxlength 100）、分类（el-select，必填，options 从 contentStore.categories 获取）、描述（textarea，4 行）、封面（el-image 展示）、标签（el-tag 动态添加/删除）、难度（el-select：初级/中级/高级）、时长（el-input）
3. 表单验证使用 `el-form :rules`，标题和分类为必填
4. 编辑模式通过 `contentStore.getWorkflowById(id)` 加载已有数据填充表单
5. 保存调用 `contentStore.addWorkflow()` 或 `contentStore.updateWorkflow()`，成功后 `ElMessage.success()` + `router.push('/content')`
6. 返回按钮跳转 `/content`

#### 交付物

- `src/views/ContentEdit.vue` — 内容编辑表单页

#### 验证步骤

- [ ] **V4.2.1** 新增内容页正常渲染 → 显示"新增内容"标题和空白表单
  在内容管理页点击"新增工作流"按钮
- [ ] **V4.2.2** 新增工作流保存成功 → 填写表单保存后返回列表，新工作流出现在列表中
  填写标题和分类后点击保存
- [ ] **V4.2.3** 编辑内容页正常渲染 → 显示"编辑内容"标题和预填数据
  在内容管理页点击某行的"编辑"按钮
- [ ] **V4.2.4** 编辑保存成功 → 修改标题后保存，返回列表显示新标题
  修改工作流标题后点击保存
- [ ] **V4.2.5** 必填验证生效 → 不填标题直接保存，显示验证提示
  清空标题字段后点击保存
- [ ] **V4.2.6** 新增/编辑数据持久化 → 操作后刷新页面数据不丢失
  新增或编辑工作流后刷新浏览器
- [ ] **V4.2.7** 标签动态添加/删除 → 可添加和移除标签
  在标签输入框输入标签名后回车添加，点击标签 × 移除

---

## Phase 5: 内容审核闭环 — 待审核内容可审批

### 目标

实现内容审核页面，管理员可以高效地审核待发布的工作流内容，支持通过和拒绝（含拒审意见），审核结果即时生效并持久化。

### 任务 5.1: 待审核内容可通过或拒绝

#### 核心逻辑

1. 创建 `ContentReview.vue`，顶部 SearchFilter 组件（默认筛选 `status: 'pending'`），中部 el-table 展示审核列表
2. 表格列：标题、提交者（author.name）、提交时间、状态（StatusTag）、操作（审核/查看）
3. 待审核状态显示"审核"按钮（primary），其他状态显示"查看"按钮
4. 点击"审核"/"查看"从右侧滑出 `el-drawer`（direction="rtl"，size="480px"），展示工作流完整信息（标题、描述、封面、分类、标签、难度、时长）
5. 已拒绝的工作流在抽屉中显示原拒审意见
6. 抽屉底部"通过"按钮调用 `contentStore.approveWorkflow(id)`，"拒绝"按钮弹出 `ElMessageBox.prompt` 输入拒审原因后调用 `contentStore.rejectWorkflow(id, reason)`
7. 审核操作后 `ElMessage.success()`，抽屉关闭，列表刷新
8. 响应式：768px 以下抽屉 `size="100%"`

#### 交付物

- `src/views/ContentReview.vue` — 内容审核页面

#### 验证步骤

- [ ] **V5.1.1** 审核页正常渲染 → 默认显示待审核状态的工作流列表
  访问 `/review`
- [ ] **V5.1.2** 默认筛选待审核 → 列表仅显示 pending 状态的工作流
  检查审核列表中的工作流状态
- [ ] **V5.1.3** 切换筛选查看全部 → 切换状态筛选为"全部"后显示所有工作流
  在状态筛选中选择"全部"
- [ ] **V5.1.4** 审核抽屉正常打开 → 点击"审核"按钮后右侧滑出抽屉，展示工作流详情
  点击某待审核行的"审核"按钮
- [ ] **V5.1.5** 审核通过操作成功 → 点击"通过"后工作流状态变为"已发布"，抽屉关闭
  在审核抽屉中点击"通过"按钮
- [ ] **V5.1.6** 审核拒绝操作成功 → 点击"拒绝"输入原因后工作流状态变为"已拒绝"，显示拒审意见
  在审核抽屉中点击"拒绝"按钮，输入拒审原因并确认
- [ ] **V5.1.7** 审核结果持久化 → 审核后刷新页面，状态保持
  审核通过或拒绝后刷新浏览器
- [ ] **V5.1.8** 拒绝时必须输入原因 → 不输入原因无法提交拒绝
  点击"拒绝"按钮后不输入原因直接确认

---

## Phase 6: 用户管理与系统配置 — 运营管理可用

### 目标

实现用户管理和系统配置页面，管理员可以管控用户状态（启用/禁用）和维护系统运行参数，操作结果持久化至 localStorage。

### 任务 6.1: 用户状态可管控

#### 核心逻辑

1. 创建 `UserManage.vue`，顶部 SearchFilter 组件（状态 + 角色筛选），中部 el-table 展示用户列表
2. 表格列：头像（el-avatar 32px）、用户名、显示名、邮箱、角色（el-tag：user→info、author→success）、状态（el-tag：active→success"启用"、disabled→danger"禁用"）、操作
3. 操作列为启用/禁用切换，点击后弹出 `ElMessageBox.confirm` 确认，确认后调用 `userManageStore.updateUserStatus(id, newStatus)`
4. 搜索/筛选调用 `userManageStore` 的 setSearchKeyword/setFilterStatus/setFilterRole，读取 `filteredUsers` computed
5. 注册时间格式化为 YYYY-MM-DD
6. 底部分页

#### 交付物

- `src/views/UserManage.vue` — 用户管理页面

#### 验证步骤

- [ ] **V6.1.1** 用户管理页正常渲染 → 搜索筛选条 + 用户列表表格 + 分页
  访问 `/users`
- [ ] **V6.1.2** 用户列表数据正确 → 显示 admin.json 中的 5 条用户数据
  检查用户管理表格数据行数
- [ ] **V6.1.3** 搜索功能正常 → 输入用户名后列表过滤匹配的用户
  在搜索框输入用户名关键词
- [ ] **V6.1.4** 状态筛选正常 → 选择"禁用"后仅显示 disabled 状态的用户
  在状态筛选下拉选择"禁用"
- [ ] **V6.1.5** 角色筛选正常 → 选择"作者"后仅显示 author 角色的用户
  在角色筛选下拉选择"作者"
- [ ] **V6.1.6** 启用/禁用切换正常 → 点击切换按钮确认后用户状态变更
  点击某用户操作列的状态切换按钮并确认
- [ ] **V6.1.7** 状态变更持久化 → 切换用户状态后刷新页面，状态保持
  切换用户状态后刷新浏览器

### 任务 6.2: 系统配置可维护

#### 核心逻辑

1. 创建 `SystemSettings.vue`，按功能分 4 组卡片展示配置项：基础配置、内容配置、通知配置、其他配置
2. 基础配置：站点名称（el-input）、站点描述（el-input）
3. 内容配置：允许注册（el-switch）、内容审核（el-switch）、最大上传（el-input-number，min 1，max 100，suffix "MB"）
4. 通知配置：SMTP 服务器（el-input）、SMTP 端口（el-input-number，min 1，max 65535）、SMTP 用户（el-input）、SSL（el-switch）
5. 其他配置：水印（el-switch）、维护模式（el-switch）
6. 表单 `label-width="120px"`，`label-position="left"`，`max-width: 680px`
7. 保存按钮调用 `statsStore.updateSystemConfig(formData)` + `ElMessage.success()`
8. 重置按钮弹出 `ElMessageBox.confirm`，确认后恢复 `adminData.systemConfig` 默认值

#### 配置要点

| 分组 | 字段 | admin.json key | 组件 |
|------|------|----------------|------|
| 基础 | 站点名称 | siteName | el-input |
| 基础 | 站点描述 | siteDescription | el-input |
| 内容 | 允许注册 | allowRegister | el-switch |
| 内容 | 内容审核 | contentReviewEnabled | el-switch |
| 内容 | 最大上传 | maxUploadSize | el-input-number |
| 通知 | SMTP 服务器 | smtpHost | el-input |
| 通知 | SMTP 端口 | smtpPort | el-input-number |
| 通知 | SMTP 用户 | smtpUser | el-input |
| 通知 | SSL | smtpSsl | el-switch |
| 其他 | 水印 | watermarkEnabled | el-switch |
| 其他 | 维护模式 | maintenanceMode | el-switch |

#### 交付物

- `src/views/SystemSettings.vue` — 系统配置页面

#### 验证步骤

- [ ] **V6.2.1** 系统配置页正常渲染 → 显示 4 组配置卡片，表单控件可交互
  访问 `/settings`
- [ ] **V6.2.2** 配置数据正确加载 → 各字段显示 admin.json 中的默认值
  检查各配置项的初始值
- [ ] **V6.2.3** 修改配置保存成功 → 修改站点名称后保存，显示成功提示
  修改站点名称并点击"保存配置"
- [ ] **V6.2.4** 保存后配置持久化 → 刷新页面后配置值保持修改后的值
  保存配置后刷新浏览器
- [ ] **V6.2.5** 重置默认配置成功 → 点击重置确认后，所有配置恢复为默认值
  点击"重置默认"按钮并确认
- [ ] **V6.2.6** 重置后配置持久化 → 刷新页面后配置仍为默认值
  重置配置后刷新浏览器

---

## Phase 7: 响应式适配 — 移动端基础可用

### 目标

对全站进行基础响应式适配（768px 断点），确保管理员在移动设备上可完成紧急审核、用户管理、系统配置等核心操作。

### 任务 7.1: 全站移动端基础适配

#### 核心逻辑

1. Layout.vue：768px 以下侧边栏切换为 `el-drawer` 抽屉模式，顶栏显示汉堡菜单按钮触发
2. 所有表格页（ContentManage、ContentReview、UserManage）：表格容器添加 `overflow-x: auto` 横向滚动
3. Dashboard.vue：统计卡片响应式 grid（1200px 以下 2 列，768px 以下 1 列），ECharts 图表自适应宽度
4. ContentReview.vue：768px 以下审核抽屉 `size="100%"` 全屏展示
5. Login.vue：768px 以下登录卡片宽度 `90vw`，padding 缩小
6. ContentEdit.vue、SystemSettings.vue：表单 `max-width` 适配

#### 交付物

- 全站 CSS 媒体查询更新
- `Layout.vue` 移动端抽屉模式

#### 验证步骤

- [ ] **V7.1.1** 移动端 Layout 侧边栏变抽屉 → 768px 以下侧边栏不显示，顶栏出现汉堡菜单
  将浏览器窗口宽度调整至 768px 以下
- [ ] **V7.1.2** 汉堡菜单打开抽屉导航 → 点击汉堡菜单后侧边栏以抽屉形式滑出
  在移动端视图下点击汉堡菜单按钮
- [ ] **V7.1.3** 表格横向滚动可用 → 内容管理页表格在窄屏下可横向滚动查看完整数据
  在 768px 以下宽度访问 `/content`
- [ ] **V7.1.4** Dashboard 图表自适应 → 图表宽度随窗口大小自适应
  在不同宽度下访问 `/dashboard`
- [ ] **V7.1.5** 审核抽屉移动端全屏 → 768px 以下审核抽屉全屏展示
  在移动端视图下打开审核抽屉
- [ ] **V7.1.6** 登录页移动端适配 → 卡片宽度自适应，布局合理
  在 768px 以下宽度访问 `/login`
- [ ] **V7.1.7** 全站构建成功 → 所有页面响应式适配后构建无错误
  `cd ai-fast-web/ai-fast-web-admin && npm run build`

---

## 实施顺序建议

1. **Phase 1** — 基础设施（所有后续 Phase 的前置依赖）
2. **Phase 2** — 登录与布局（进入后台的必经通路，依赖 Phase 1）
3. **Phase 3** — 仪表盘（登录后的首屏，依赖 Phase 2 布局 + Phase 1 公共组件基础）
4. **Phase 4** — 内容管理闭环（核心 CRUD 功能，依赖 Phase 2 布局 + Phase 1 公共组件）
5. **Phase 5** — 内容审核闭环（依赖 Phase 4 的 StatusTag/SearchFilter 组件）
6. **Phase 6** — 用户管理与系统配置（依赖 Phase 2 布局 + Phase 1 的 SearchFilter 组件）
7. **Phase 7** — 响应式适配（依赖所有页面完成后统一适配）

> Phase 4/5/6 之间无严格依赖关系，可根据优先级灵活调整顺序。建议 Phase 4 优先（内容管理是核心业务），Phase 5 其次（审核依赖 StatusTag），Phase 6 最后（用户和配置相对独立）。

---

## 风险与挑战

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| ECharts 主题切换闪烁 | 图表在主题切换瞬间可能短暂白屏 | 使用 `chart.setOption()` 增量更新而非重绘，确保过渡平滑 |
| localStorage 容量限制 | 大量 Mock 数据持久化可能接近 5MB 限制 | 当前数据量约 8KB，远低于限制；后续接入 API 后可清除 |
| Element Plus 暗色覆盖不全 | 部分第三方组件暗色模式样式异常 | 在 `main.scss` 中逐步补充覆盖变量，发现一个修一个 |
| 移动端表格操作空间不足 | 小屏幕下表格行操作按钮拥挤 | 使用固定操作列 + 适当缩小按钮尺寸，必要时改用下拉操作菜单 |
| ContentEdit 标签输入体验 | el-tag 动态添加在移动端操作不便 | 保持回车添加机制，768px 以下标签输入框宽度自适应 |

---

## 变更模块总览

| 变更模块 | 涉及 Phase | 核心变更 |
|----------|:----------:|----------|
| `src/assets/main.scss` | P1 | CSS 变量体系 + EP 暗色覆盖 |
| `src/main.js` | P1 | EP 暗色 CSS 引入 + 主题初始化 |
| `src/utils/persistence.js` | P1 | localStorage 持久化工具 |
| `src/stores/theme.js` | P1 | 主题状态管理（三模式 + 侧边栏 + 持久化） |
| `src/stores/content.js` | P1 | 添加 workflows + categories 持久化 |
| `src/stores/userManage.js` | P1 | 添加 users 持久化 |
| `src/stores/stats.js` | P1 | 添加 systemConfig 持久化 |
| `src/views/Login.vue` | P2 | 管理员登录页面 |
| `src/views/Layout.vue` | P2, P7 | 后台布局框架 + 移动端抽屉 |
| `src/components/StatCard.vue` | P3 | 统计卡片组件 |
| `src/views/Dashboard.vue` | P3, P7 | 数据仪表盘 + 响应式 |
| `src/components/StatusTag.vue` | P4 | 状态标签组件 |
| `src/components/SearchFilter.vue` | P4 | 搜索筛选组件 |
| `src/views/ContentManage.vue` | P4, P7 | 内容管理列表 + 响应式 |
| `src/views/ContentEdit.vue` | P4 | 内容编辑表单 |
| `src/views/ContentReview.vue` | P5, P7 | 内容审核 + 移动端全屏抽屉 |
| `src/views/UserManage.vue` | P6, P7 | 用户管理 + 响应式 |
| `src/views/SystemSettings.vue` | P6 | 系统配置表单 |

---

**文档版本**：1.0.0
**创建日期**：2026-06-03
**最后更新**：2026-06-03
**维护者**：CodeBuddy
