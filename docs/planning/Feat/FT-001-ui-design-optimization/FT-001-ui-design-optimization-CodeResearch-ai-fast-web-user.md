# FT-001 UI 设计优化 — 代码调研总结

> 代码库：ai-fast-web-user
> 路径：`ai-fast-web/ai-fast-web-user/`
> 调研日期：2026-05-26
> 调研人：meiguangxian

---

## 1. 代码库概况

| 项目 | 说明 |
|------|------|
| 技术栈 | Vue 3 (Composition API `<script setup>`) + Element Plus + SCSS |
| 语言 | 纯 JavaScript（非 TypeScript） |
| 构建 | Vite 5.1.6 |
| 包管理 | npm |
| 状态管理 | Pinia |
| 路由 | Vue Router 4 |
| HTTP | axios（已安装但未使用） |
| UI 框架 | Element Plus 2.6.1 + @element-plus/icons-vue |
| CSS 预处理 | Sass 1.71.1 |
| 数据来源 | 本地 JSON mock（无真实 API） |

---

## 2. 目录结构与关键文件

```
ai-fast-web-user/
├── index.html
├── package.json
├── vite.config.js                      # 别名 @、端口 3000
└── src/
    ├── App.vue                         # 根组件（主题容器 + router-view）
    ├── main.js                         # 入口（全局注册 Element Plus 图标 + 中文语言包）
    ├── assets/
    │   └── main.scss                   # ★ 全局样式核心（247行）
    ├── components/
    │   └── WorkflowCard.vue            # ★ 唯一共享卡片组件（197行）
    ├── data/
    │   ├── agents.json                 # 8个智能体 + 9个分类
    │   ├── workflows.json              # 6个工作流 + 7个分类
    │   └── users.json                  # 2个用户 + currentUser
    ├── router/
    │   └── index.js                    # 路由配置（含登录守卫）
    ├── stores/
    │   ├── agent.js                    # Agent Store
    │   ├── theme.js                    # Theme Store（明暗切换）
    │   ├── user.js                     # User Store（登录态）
    │   └── workflow.js                 # Workflow Store
    └── views/
        ├── Home.vue                    # ★ 首页（630行，最复杂）
        ├── Agents.vue                  # 智能体广场
        ├── Workflows.vue               # 工作流中心
        ├── WorkflowDetail.vue          # ★ 工作流详情（420行）
        ├── Resources.vue              # 资源库
        ├── Login.vue                   # ★ 登录页（235行）
        ├── Register.vue                # 注册页
        ├── UserCenter.vue             # 个人中心
        └── Layout.vue                  # ★ 全局布局（465行）
```

**关键发现**：组件极度精简，只有一个共享组件 `WorkflowCard.vue`，各页面大量使用内联样式而非组件化复用。

---

## 3. 现有实现分析

### 3.1 全局样式系统 (`main.scss`)

**CSS 变量主题体系**：

| 变量类别 | 亮色模式 | 暗色模式 | 说明 |
|----------|----------|----------|------|
| 背景色 | 5 级（primary→footer） | 5 级 | 完整的背景层次 |
| 文字色 | 4 级（primary→inverse） | 4 级 | 对比度层次分明 |
| 强调色 | accent-primary + gradient | 亮度提升版本 | 主色 #6366f1 / #818cf8 |
| 阴影 | 4 级 + glow | 4 级 + glow | 层次完整 |
| 圆角 | 4 级（8px→24px） | 共用 | 设计 Token 齐全 |
| 轮播渐变 | 3 组 | 3 组 | Banner 专用 |
| 卡片边框 | 1px solid | 1px solid | CSS 变量控制 |

**现有动画系统**：

| 动画名 | 类型 | 参数 | 使用场景 |
|--------|------|------|----------|
| `fadeInUp` | @keyframes | translateY(20px→0), opacity(0→1) | 卡片入场、Banner 视觉元素 |
| `fadeIn` | @keyframes | opacity(0→1) | 通用淡入 |
| `slideInLeft` | @keyframes | translateX(-30px→0) | 左侧滑入 |
| `pulse-glow` | @keyframes | box-shadow 脉冲 | 未实际使用 |
| `float` | @keyframes | translateY(0→-8px) | 悬浮效果，未实际使用 |
| `.fade-in-up` | 工具类 | fadeInUp 0.5s | 列表卡片入场 |
| `.fade-in` | 工具类 | fadeIn 0.4s | 通用淡入 |
| 页面转场 | Vue transition | opacity 0.25s | Layout 路由切换 |

**Element Plus 覆盖**：暗色模式下全面覆盖了 bg-color、text-color、border-color、fill-color、color-primary 等变量，以及 el-card、el-input__wrapper、el-dialog、el-tabs、el-empty 的样式。

**关键缺失**：
- 无动效 Token 系统（时长/缓动函数未变量化）
- 无页面转场动效规范（仅有简单 fade）
- 无滚动触发动画（IntersectionObserver）
- 无骨架屏样式
- 无空状态插图样式

### 3.2 Layout.vue — 全局布局

**Header 结构**：
- sticky 定位 + `backdrop-filter: blur(20px)` 毛玻璃
- Logo（渐变图标 + 渐变文字）
- 导航菜单（圆角胶囊式 nav-item，hover/active 态统一）
- 右侧操作区（主题切换圆形按钮 + 登录/注册按钮 + 用户头像下拉）

**Footer 结构**：
- 深色背景 `#1a1a2e` / `#0a0a14`
- 三列链接组（平台/支持/关于）
- 底部版权 + 渐变 slogan

**路由转场**：`<transition name="fade" mode="out-in">` — 仅有 0.25s opacity 过渡

**响应式**：992px 隐藏 nav 文字只留图标；768px 缩小 header 高度

**关键缺失**：
- Header 无滚动行为变化（如缩小、阴影增强）
- Footer 固定深色无法适配亮色下的风格变化
- 导航无移动端汉堡菜单

### 3.3 Home.vue — 首页（最核心页面）

**Banner 区**：
- `el-carousel` 组件，5s 自动播放，420px 高度
- 每张幻灯片：左文右图布局 — 标题/描述/CTA按钮 + 2x2 图标卡片网格
- 背景使用 CSS 渐变变量（`--carousel-gradient-1/2/3`）+ 两个圆形伪元素装饰
- 视觉卡片：`backdrop-filter: blur(8px)` + 半透明白色背景 + fadeInUp 入场

**热门智能体区**：
- section-header（渐变图标 + 标题/副标题 + "查看全部"链接）
- 横向卡片网格（`grid-template-columns: repeat(auto-fill, minmax(380px, 1fr))`）
- Agent 卡片：横向布局（图标+名称描述+统计数据），hover translateY(-3px) + accent 边框

**热点工作流区**：
- 使用 `WorkflowCard` 组件渲染
- `grid-template-columns: repeat(auto-fill, minmax(340px, 1fr))`

**平台统计区**：
- 4 列统计卡片（渐变图标 + 大数字 + 标签）
- hover translateY(-4px) + scale(1.1)

**关键缺失（对照 Overall 文档）**：
- ❌ 无 Hero Section 全屏设计（当前为轮播卡片式）
- ❌ 无动态粒子/网格背景效果
- ❌ 无滚动触发动画（各板块同时出现，无交错入场）
- ❌ 无全宽沉浸式 Banner
- ⚠️ CTA 按钮区有但视觉权重不足

### 3.4 Agents.vue / Workflows.vue — 列表页

**共同结构**：
- `page-hero`：标题 + 描述 + 搜索框（el-input 圆角 480px）
- `category-bar`：可滚动分类芯片（Workflows 多了 count 计数徽章）
- 卡片网格 + `el-empty` 空状态

**Agent 卡片**（内联样式，非组件化）：
- 纵向布局：header(icon+category tag) → name → description(2行截断) → tags → footer(avatar+name | stats)
- 52x52px 图标区，accent-primary-bg 背景
- hover: translateY(-4px) + shadow-lg + accent 边框

**关键缺失**：
- ❌ 无分层卡片设计（当前为传统单层卡片）
- ❌ 无封面区（Agent 卡片无图片）
- ❌ `el-empty` 为 Element Plus 默认样式，无自定义空状态插图
- ❌ 无骨架屏加载态
- ⚠️ 搜索和筛选无过渡动画

### 3.5 WorkflowCard.vue — 共享卡片组件

**当前设计**：
- 传统双层结构：封面区（180px 高度 + difficulty 徽章）+ 内容区（标题/描述/tags/作者/统计）
- hover: translateY(-4px) + scale(1.05)(封面图)
- 使用 `el-tag`、`el-avatar`

**关键缺失（对照 Overall 文档）**：
- ❌ 非分层卡片设计（Overall 要求封面区沉浸式大图 + 内容区分层）
- ❌ 无封面放大微交互
- ❌ 无内容区上浮效果
- ❌ 无 hover 状态的层次分离感

### 3.6 WorkflowDetail.vue — 工作流详情

**当前布局**：两栏（main flex:1 + sidebar 320px）

**Main 区**：
- 返回按钮 + 420px 大图封面 + 标题/作者/统计/tags + 简介 + el-timeline 学习步骤
- 步骤卡片：简单白底 + 标题/内容，无交互

**Sidebar**：
- info-card（课程信息：难度/时长/分类/更新时间）
- action-card（点赞/收藏按钮）

**关键缺失（对照 Overall 文档）**：
- ❌ 无全宽沉浸式封面（当前为常规圆角卡片）
- ❌ 无视差滚动效果
- ❌ 无渐变过渡到内容区
- ❌ 步骤卡片不可展开/折叠，无进度标记
- ❌ Sidebar 无 sticky 定位
- ❌ 无浮动操作栏
- ❌ 无相关推荐区域

### 3.7 Login.vue / Register.vue — 认证页面

**当前设计**：
- 居中卡片式布局（max-width: 420px）
- 两个圆形渐变伪元素作为背景装饰
- 登录表单：logo + 标题/描述 + 用户名/密码 + 记住我/忘记密码 + 登录按钮
- 注册页结构类似

**关键缺失（对照 Overall 文档）**：
- ❌ 非左图右表分屏布局（Overall 确认方案 A）
- ❌ 无品牌展示区（动态背景/插画）
- ❌ 无产品亮点展示
- ❌ 移动端无自适应（当前为居中卡片，非全屏表单）

### 3.8 Resources.vue / UserCenter.vue

**Resources.vue**：
- 列表页同构结构（page-hero + category + 网格）
- 资源卡片：类型图标 + 标题/描述 + 统计
- 同样使用 `el-empty` 默认空状态

**UserCenter.vue**：
- 标签页切换（基本资料/我的收藏/我的点赞）
- 基础表单和列表展示

**关键缺失**：
- ❌ 无分层卡片设计
- ❌ 无骨架屏
- ❌ 无自定义空状态

---

## 4. 关键发现和缺失项

| 编号 | 缺失项 | 影响范围 | 优先级 |
|------|--------|----------|:------:|
| user-G1 | 无 Hero Section 全屏设计，Banner 为传统轮播 | Home.vue | P0 |
| user-G2 | 无动态粒子/网格背景效果 | Home.vue Banner | P1 |
| user-G3 | 无滚动触发动画（IntersectionObserver） | 全局 | P1 |
| user-G4 | 无动效 Token 系统（时长/缓动/间距未变量化） | main.scss | P1 |
| user-G5 | 无分层卡片设计（WorkflowCard/Agent 卡片均为传统单层） | WorkflowCard, Agents, Workflows | P0 |
| user-G6 | 无自定义空状态组件（使用 el-empty 默认样式） | Agents, Workflows, Resources | P1 |
| user-G7 | 无骨架屏组件 | 全局列表页 | P1 |
| user-G8 | 登录/注册非左图右表分屏布局 | Login.vue, Register.vue | P0 |
| user-G9 | 详情页无沉浸式封面/视差滚动/浮动操作栏 | WorkflowDetail.vue | P1 |
| user-G10 | 详情页步骤卡片无交互（不可展开/折叠/标记进度） | WorkflowDetail.vue | P2 |
| user-G11 | Sidebar 无 sticky 定位 | WorkflowDetail.vue | P2 |
| user-G12 | Header 无滚动行为变化（缩小/阴影增强） | Layout.vue | P2 |
| user-G13 | 无移动端汉堡菜单 | Layout.vue | P2 |
| user-G14 | 页面转场动效单一（仅 fade） | Layout.vue | P2 |
| user-G15 | 无设计规范文件（Design Token 未独立为 SCSS 变量文件） | main.scss | P1 |
| user-G16 | Agent 卡片样式未组件化（在 Agents.vue/Home.vue 中重复定义） | Home.vue, Agents.vue | P1 |

---

## 5. 与其他代码库的交互接口

本项目为纯前端独立项目，数据来自本地 JSON mock 文件，无后端 API 调用，无跨代码库交互。Store 中引入了 axios 但未使用。

后续接入真实 API 时，所有 Store 文件需改写数据获取逻辑，但不影响本次 UI 优化的实施范围。

---

## 6. 技术约束与注意事项

| 约束项 | 说明 |
|--------|------|
| 非 TypeScript | 项目为纯 JS，新增组件需保持一致，不可引入 TS |
| Element Plus 依赖 | 大量使用 EP 组件，优化时需考虑与 EP 主题的兼容 |
| SCSS 变量系统 | 当前 CSS 变量已较完善，扩展应基于现有体系 |
| Mock 数据 | 数据结构固定，卡片组件需兼容现有数据格式 |
| Vite 配置 | 已配置 @ 别名和端口 3000，无需额外调整 |
| 无代码检查 | 无 ESLint/Prettier 配置，需注意代码风格一致性 |

---

## 7. 待确认问题清单

| # | 问题 | 影响 |
|---|------|------|
| Q1 | 动态粒子/网格背景是否使用第三方库（如 tsparticles）还是纯 CSS/Canvas 实现？ | 影响技术选型和包体积 |
| Q2 | 骨架屏是否需要 EP 兼容的 el-skeleton 扩展，还是完全自定义实现？ | 影响组件实现方式 |
| Q3 | 空状态插图是否需要设计资源（SVG）提供，还是使用 CSS 图形 + 图标组合？ | 影响资源准备 |
| Q4 | 详情页视差滚动效果的性能目标（移动端是否降级）？ | 影响实现复杂度 |
| Q5 | 是否需要引入新的 npm 依赖（如 animate.css、@vueuse/motion 等）？ | 影响包管理 |
