# FT-001 UI 设计优化 实施计划

## 项目概述

本计划将 ai-fast-web-user 平台从功能可用升级为视觉精致、交互流畅的现代 AI 产品级界面，核心工作包括：

1. 建立完整的 Design Token 动效体系和全局动效基础设施
2. 构建分层卡片、空状态、骨架屏等核心可复用组件
3. 逐页面实施视觉升级——首页 Hero Section、列表页、详情页、认证页面
4. 补齐 Header 滚动行为、移动端汉堡菜单、页面转场等全局体验

### 前置依赖

无。本特性是基础层 UI 优化，不依赖其他特性。

### 后续依赖

| 特性 | 说明 |
|------|------|
| 真实 API 接入 | 当前数据为 JSON mock，后续接入真实 API 时，本特性产出的组件需适配新数据结构 |

---

## 进度概要

| Phase | 任务 | 状态 | 交付物 |
|-------|------|------|--------|
| P1: 设计基础设施 | 1.1 Design Token 体系扩展与动效工具类建立 | ⏳ | main.scss Token 扩展 + scroll-reveal 工具类 + 全局 Observer 注册 |
| P2: 核心组件库 | 2.1 分层卡片 WorkflowCard 重设计 | ⏳ | 重设计的 WorkflowCard.vue |
| | 2.2 AgentCard 组件化抽取与视觉升级 | ⏳ | 新增 AgentCard.vue |
| | 2.3 EmptyState 空状态组件 | ⏳ | 新增 EmptyState.vue |
| | 2.4 CardSkeleton 骨架屏组件 | ⏳ | 新增 CardSkeleton.vue |
| P3: 首页 Hero 体验 | 3.1 Hero Section 全屏设计实现 | ⏳ | Home.vue Hero Section + 动态背景 |
| | 3.2 首页板块滚动动画与组件集成 | ⏳ | Home.vue 板块升级 + countUp + 组件集成 |
| P4: 列表页视觉升级 | 4.1 智能体广场 Agents.vue 完整升级 | ⏳ | Agents.vue 使用新组件 + 交互优化 |
| | 4.2 工作流中心 Workflows.vue 完整升级 | ⏳ | Workflows.vue 使用新组件 |
| | 4.3 资源库 Resources.vue 视觉升级 | ⏳ | Resources.vue 使用新组件 |
| P5: 详情页沉浸体验 | 5.1 详情页沉浸式封面与视差滚动 | ⏳ | WorkflowDetail.vue 沉浸式封面区 |
| | 5.2 详情页步骤卡片交互与进度标记 | ⏳ | 可展开/折叠步骤卡片 + 进度标记 |
| | 5.3 详情页 Sidebar Sticky 与浮动操作栏 | ⏳ | sticky sidebar + 底部浮动操作栏 |
| P6: 认证页面与全局打磨 | 6.1 登录/注册左图右表分屏布局 | ⏳ | Login.vue / Register.vue 分屏布局 |
| | 6.2 Header 滚动行为与移动端汉堡菜单 | ⏳ | Layout.vue Header 升级 + 汉堡菜单 |
| | 6.3 Footer 主题适配与暗色模式增强 | ⏳ | Layout.vue Footer 适配 + 暗色增强 |
| | 6.4 个人中心与页面转场动效优化 | ⏳ | UserCenter.vue 优化 + 转场增强 |

---

## Phase 1: 设计基础设施

### 目标

在 `main.scss` 中扩展 Design Token 体系（动效 + 间距 + 层次），建立全局动效工具类和滚动触发动画机制，为所有后续组件和页面提供统一的设计变量和动效基础设施。

### 任务 1.1: Design Token 体系扩展与动效工具类建立

#### 核心逻辑

**1. 动效 Token 扩展**：在 `main.scss` 的 `[data-theme="light"]` 和 `[data-theme="dark"]` 选择器中新增动效时长和缓动函数 CSS 变量：

| Token 名称 | 值 | 用途 |
|------------|-----|------|
| `--duration-fast` | 150ms | 微交互（hover、focus） |
| `--duration-normal` | 300ms | 常规过渡（展开、切换） |
| `--duration-slow` | 500ms | 大幅动画（页面转场、入场） |
| `--duration-extra-slow` | 800ms | 沉浸式动画（Hero 背景） |
| `--ease-standard` | cubic-bezier(0.4, 0, 0.2, 1) | 标准缓动 |
| `--ease-decelerate` | cubic-bezier(0, 0, 0.2, 1) | 减速缓动（入场） |
| `--ease-accelerate` | cubic-bezier(0.4, 0, 1, 1) | 加速缓动（退场） |
| `--ease-spring` | cubic-bezier(0.34, 1.56, 0.64, 1) | 弹性缓动（微交互） |

**2. 间距与层次 Token**：新增卡片交互、层级 z-index 相关变量：

| Token 名称 | 值 | 用途 |
|------------|-----|------|
| `--spacing-hero` | 80px | Hero Section 内边距 |
| `--card-hover-lift` | 8px | 卡片 hover 上浮距离 |
| `--card-cover-scale` | 1.05 | 封面区 hover 缩放 |
| `--layer-card` | 1 | 卡片层级 |
| `--layer-sticky` | 10 | Sticky 元素层级 |
| `--layer-overlay` | 100 | 遮罩层级 |
| `--layer-modal` | 1000 | 弹窗层级 |

**3. 滚动触发动画工具类**：定义 `.scroll-reveal`、`.scroll-reveal-left`、`.scroll-reveal-scale` 等工具类，配合 `.revealed` 触发态。stagger 延迟通过 `--stagger-index` + `calc()` 实现。

**4. 全局 IntersectionObserver 注册**：在 `main.js` 中注册全局 Observer 实例，监听 `.scroll-reveal` 元素进入视口后添加 `.revealed` 类。

**5. 页面转场 CSS 准备**：在 `main.scss` 中定义 `.slide-fade-enter-active`、`.slide-fade-leave-active`、`.fade-scale-enter-active`、`.fade-scale-leave-active` 等转场类，使用新动效 Token。

#### 交付物

- `src/assets/main.scss` — 新增动效 Token、间距/层次 Token、滚动触发工具类、页面转场 CSS
- `src/main.js` — 全局 IntersectionObserver 注册逻辑

#### 验证步骤

- [ ] **V1.1.1** 检查动效 Token 是否在亮色/暗色模式下均生效 → CSS 变量可读取
  `cd ai-fast-web/ai-fast-web-user && npx vite --port 3000 &` 然后浏览器 DevTools 执行 `getComputedStyle(document.documentElement).getPropertyValue('--duration-fast')` 返回 `150ms`
- [ ] **V1.1.2** 检查间距与层次 Token 是否正确注册 → CSS 变量可读取
  浏览器 DevTools 执行 `getComputedStyle(document.documentElement).getPropertyValue('--card-hover-lift')` 返回 `8px`
- [ ] **V1.1.3** 滚动触发动画工具类生效 → 元素添加 `.scroll-reveal` 后初始不可见，进入视口后可见
  在任意页面元素添加 `class="scroll-reveal"`，刷新页面，滚动至该元素位置，确认其从下方淡入出现
- [ ] **V1.1.4** stagger 延迟机制正常 → 列表子元素依次延迟入场
  给列表子元素设置 `style="--stagger-index: 0/1/2/3"`，确认入场动画依次延迟约 80ms
- [ ] **V1.1.5** 页面转场 CSS 类就绪 → 类名存在且过渡属性正确
  DevTools 搜索 `.slide-fade-enter-active` 和 `.fade-scale-enter-active` 样式规则存在
- [ ] **V1.1.6** 暗色模式下所有新增 Token 值正确 → 切换暗色主题后变量值存在
  切换暗色主题后，DevTools 执行 `getComputedStyle(document.documentElement).getPropertyValue('--ease-standard')` 返回缓动值
- [ ] **V1.1.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

---

## Phase 2: 核心组件库

### 目标

构建 4 个核心可复用组件（分层卡片、Agent 卡片、空状态、骨架屏），每个组件内部完成从样式到交互的完整闭环，为后续页面升级提供即插即用的组件。

### 任务 2.1: 分层卡片 WorkflowCard 重设计

#### 核心逻辑

将现有 `WorkflowCard.vue` 从传统双层结构升级为分层卡片设计：

1. **封面区增强**：高度从 180px 增至 220px，`overflow: hidden`；难度徽章绝对定位在封面区上方；hover 时封面图 `scale(1.05)`，使用 `--duration-slow` 和 `--ease-decelerate` 过渡
2. **内容区分层**：独立背景层（亮色白色/暗色对应色），与封面区视觉分离；标题 2 行截断、描述 2 行截断
3. **底部信息行**：标签与底部信息间加分隔线（`border-top`）；头像 + 名称 + 收藏数 + 下载数
4. **Hover 微交互**：整体 `translateY(-8px)`（使用 `--card-hover-lift`）+ shadow 增强；内容区产生上浮感
5. **暗色兼容**：内容区背景使用 CSS 变量，自动适配暗色主题

#### 交付物

- `src/components/WorkflowCard.vue` — 重设计的分层卡片组件

#### 验证步骤

- [ ] **V2.1.1** 封面区高度为 220px 且 hover 时缩放 → 视觉确认
  浏览工作流列表页，DevTools 检查封面区 `.card-cover` 高度为 220px，hover 时封面图 scale 变为 1.05
- [ ] **V2.1.2** 内容区与封面区视觉分层 → 内容区有独立背景色
  DevTools 检查内容区 `.card-content` 有独立的 `background-color`，与封面区不同
- [ ] **V2.1.3** Hover 上浮距离 8px + 阴影增强 → hover 状态视觉正确
  鼠标悬停卡片，确认卡片上浮约 8px，阴影明显增强
- [ ] **V2.1.4** 难度徽章绝对定位在封面区上方 → 位置正确
  检查难度徽章 `.difficulty-badge` 为 `position: absolute`，位于封面区右上角
- [ ] **V2.1.5** 标签与底部信息间有分隔线 → 分隔线可见
  检查 `.card-footer` 上方有 `border-top` 分隔线
- [ ] **V2.1.6** 暗色模式下视觉正确 → 切换暗色后无对比度问题
  切换暗色主题，确认封面区/内容区/文字/分隔线均正常显示
- [ ] **V2.1.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 2.2: AgentCard 组件化抽取与视觉升级

#### 核心逻辑

将 `Agents.vue` 和 `Home.vue` 中重复的内联 Agent 卡片样式抽取为独立组件，并升级为分层卡片风格：

1. **组件抽取**：创建 `AgentCard.vue`，接收 `agent` prop（与现有 agents.json 数据结构兼容）
2. **分层卡片风格**：封面区使用 agent.icon 放大作为视觉焦点（渐变背景 + 大图标），下方为内容区
3. **Hover 微交互**：与 WorkflowCard 保持一致的上浮 + 封面放大效果
4. **复用性**：Home.vue 和 Agents.vue 均使用此组件替代原有内联样式
5. **标签和统计**：保留原有功能（分类标签、统计数据），增加分隔线

#### 交付物

- `src/components/AgentCard.vue` — 新增 Agent 卡片组件
- `src/views/Agents.vue` — 替换内联样式为组件引用
- `src/views/Home.vue` — 热门智能体区替换为组件引用

#### 验证步骤

- [ ] **V2.2.1** AgentCard 组件文件存在且可导入 → 模块解析正常
  `cd ai-fast-web/ai-fast-web-user && node -e "const fs=require('fs'); console.log(fs.existsSync('src/components/AgentCard.vue'))"`
- [ ] **V2.2.2** Agents.vue 使用 AgentCard 组件 → 无内联 Agent 卡片样式
  `grep -c "AgentCard" ai-fast-web/ai-fast-web-user/src/views/Agents.vue` 返回 ≥ 1
- [ ] **V2.2.3** Home.vue 热门智能体区使用 AgentCard 组件 → 功能不变
  `grep -c "AgentCard" ai-fast-web/ai-fast-web-user/src/views/Home.vue` 返回 ≥ 1
- [ ] **V2.2.4** AgentCard 封面区展示 agent.icon 大图标 → 视觉确认
  浏览智能体广场，确认卡片顶部有渐变背景 + 大图标视觉焦点
- [ ] **V2.2.5** Hover 微交互正常 → 上浮 + 图标区缩放
  鼠标悬停 AgentCard，确认上浮和封面放大效果
- [ ] **V2.2.6** 暗色模式下 AgentCard 视觉正确 → 无对比度问题
  切换暗色主题，确认卡片各区域正常显示
- [ ] **V2.2.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 2.3: EmptyState 空状态组件

#### 核心逻辑

创建自定义空状态组件，替代 Element Plus 默认 `el-empty`：

1. **组件接口**：Props 包括 `type`（no-data / no-result / error）、`title`、`description`、`actionText`、`actionLink`
2. **插图实现**：使用 CSS + Element Plus 图标组合，不依赖外部 SVG 资源
   - `no-data`：文件夹 + 空白图标组合
   - `no-result`：搜索图标 + 感叹号组合
   - `error`：警告图标 + 云图标组合
3. **动画**：插图有轻微浮动动画（3s 周期，使用 `--duration-extra-slow` 量级）
4. **操作按钮**：可选，点击后跳转 `actionLink` 或触发回调
5. **暗色兼容**：插图和文字使用 CSS 变量，自动适配

#### 交付物

- `src/components/EmptyState.vue` — 新增空状态组件

#### 验证步骤

- [ ] **V2.3.1** EmptyState 组件文件存在 → 文件可读
  `cd ai-fast-web/ai-fast-web-user && node -e "const fs=require('fs'); console.log(fs.existsSync('src/components/EmptyState.vue'))"`
- [ ] **V2.3.2** no-data 类型渲染正确 → 文件夹图标 + 标题 + 描述显示
  在任意页面临时使用 `<EmptyState type="no-data" title="暂无数据" description="还没有任何内容" />`，确认插图和文字正常
- [ ] **V2.3.3** no-result 类型渲染正确 → 搜索图标 + 感叹号组合
  使用 `<EmptyState type="no-result" title="未找到结果" />`，确认搜索图标组合显示
- [ ] **V2.3.4** 操作按钮可点击 → 点击后跳转或回调
  使用 `<EmptyState actionText="清除筛选" actionLink="/agents" />`，点击按钮确认跳转
- [ ] **V2.3.5** 插图浮动动画播放 → 3s 周期上下浮动
  DevTools Animation 面板检查插图元素有 3s 周期的 translateY 动画
- [ ] **V2.3.6** 暗色模式下插图和文字对比度足够 → 可读性正常
  切换暗色主题，确认空状态各元素可见
- [ ] **V2.3.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 2.4: CardSkeleton 骨架屏组件

#### 核心逻辑

创建骨架屏组件，用于列表页加载态展示：

1. **组件接口**：Props 包括 `count`（骨架卡片数量，默认 6）、`type`（card / agent / list）
2. **Shimmer 动画**：从左到右的渐变扫光动画，1.5s 循环，使用 `@keyframes shimmer`
3. **布局匹配**：与实际卡片网格布局一致（使用相同的 `grid-template-columns`），避免加载完成后的布局偏移
4. **实现策略**：基于 Element Plus `el-skeleton` 扩展，添加自定义 shimmer 动画和卡片形状模板
5. **暗色兼容**：骨架背景色使用 CSS 变量

#### 交付物

- `src/components/CardSkeleton.vue` — 新增骨架屏组件

#### 验证步骤

- [ ] **V2.4.1** CardSkeleton 组件文件存在 → 文件可读
  `cd ai-fast-web/ai-fast-web-user && node -e "const fs=require('fs'); console.log(fs.existsSync('src/components/CardSkeleton.vue'))"`
- [ ] **V2.4.2** 默认渲染 6 张骨架卡片 → 数量正确
  使用 `<CardSkeleton />`，确认渲染 6 张骨架卡片
- [ ] **V2.4.3** 自定义 count 生效 → 指定数量渲染正确
  使用 `<CardSkeleton :count="3" />`，确认渲染 3 张骨架卡片
- [ ] **V2.4.4** Shimmer 扫光动画播放 → 1.5s 循环，从左到右
  DevTools Animation 面板检查骨架元素有 shimmer 动画，周期 1.5s
- [ ] **V2.4.5** card 类型骨架布局与 WorkflowCard 一致 → 无明显布局偏移
  在工作流列表中，骨架屏加载态与实际卡片切换时无显著布局跳动
- [ ] **V2.4.6** 暗色模式下骨架屏可见 → 背景色对比度正常
  切换暗色主题，确认骨架元素可见
- [ ] **V2.4.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

---

## Phase 3: 首页 Hero 体验

### 目标

将首页 Banner 从传统轮播升级为 Hero Section 全屏设计，配合动态背景、滚动触发动画和统计数字递增效果，提供端到端的首页视觉冲击力。

### 任务 3.1: Hero Section 全屏设计实现

#### 核心逻辑

替换 Home.vue 中的 `el-carousel` 为全屏 Hero Section：

1. **Hero 容器**：100vh 高度（或 80vh），flex 垂直居中，`position: relative`
2. **动态背景**：优先使用纯 CSS 实现 — 多层渐变 + `@keyframes` 动画的浮动圆形（2-3 个伪元素，不同大小/速度/位置），性能优于 Canvas
3. **核心内容**：Slogan 主标题 + 副标题描述 + CTA 渐变按钮 + "了解更多" 次要按钮
4. **CTA 按钮**：渐变背景（使用 `--accent-gradient`）+ hover glow 效果（`box-shadow` 扩散）
5. **滚动指示器**：底部箭头 + bounce 动画，引导向下浏览
6. **响应式**：移动端 Hero 高度降为 60vh，字号缩小

#### 交付物

- `src/views/Home.vue` — Hero Section 替代轮播 + 动态背景 + CTA + 滚动指示器

#### 验证步骤

- [ ] **V3.1.1** 首页展示 Hero Section 而非轮播 → el-carousel 已移除
  访问首页，确认无轮播组件，显示全屏 Hero Section
- [ ] **V3.1.2** Hero Section 高度为 80vh → 垂直空间占比正确
  DevTools 检查 `.hero-section` 的 `height` 为 `80vh`
- [ ] **V3.1.3** 动态背景动画播放 → 浮动圆形缓慢运动
  观察 Hero 背景，确认有 2-3 个渐变圆形缓慢浮动动画
- [ ] **V3.1.4** CTA 按钮渐变背景 + hover glow → 视觉交互正确
  确认 CTA 按钮有渐变背景，hover 时有 glow 扩散效果
- [ ] **V3.1.5** 滚动指示器 bounce 动画 → 箭头上下弹跳
  确认 Hero 底部有箭头指示器，带 bounce 动画
- [ ] **V3.1.6** 移动端 Hero 高度降为 60vh → 响应式正确
  浏览器缩窄至 768px 以下，确认 Hero 高度降为 60vh
- [ ] **V3.1.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 3.2: 首页板块滚动动画与组件集成

#### 核心逻辑

升级首页各板块，集成新组件并添加滚动触发动画：

1. **热门智能体区**：替换内联卡片为 `AgentCard` 组件；添加 `scroll-reveal` 交错入场；标题区保留 section-header
2. **热点工作流区**：使用重设计的 `WorkflowCard` 组件；添加 `scroll-reveal` 交错入场
3. **平台统计区**：数字递增动画（countUp）— 使用纯 JS 实现，从 0 递增到目标值，`scroll-reveal` 触发开始
4. **Stagger 延迟**：卡片列表子元素设置 `--stagger-index`，实现依次入场效果

#### 交付物

- `src/views/Home.vue` — 板块滚动动画 + AgentCard/WorkflowCard 集成 + countUp 动画

#### 验证步骤

- [ ] **V3.2.1** 首页热门智能体区使用 AgentCard 组件 → 组件正常渲染
  检查首页热门智能体区，确认使用分层风格的 AgentCard
- [ ] **V3.2.2** 首页热点工作流区使用 WorkflowCard 组件 → 组件正常渲染
  检查首页热点工作流区，确认使用重设计的 WorkflowCard
- [ ] **V3.2.3** 滚动触发动画生效 → 各板块滚动进入视口时交错入场
  从 Hero 向下滚动，观察热门智能体、热点工作流、平台统计区依次交错出现
- [ ] **V3.2.4** 统计数字 countUp 动画 → 从 0 递增到目标值
  滚动到平台统计区，确认数字从 0 开始递增到目标值
- [ ] **V3.2.5** Stagger 延迟入场 → 卡片依次出现而非同时出现
  观察卡片列表，确认每张卡片有约 80ms 的依次延迟入场
- [ ] **V3.2.6** 暗色模式下首页所有板块正常 → 无视觉问题
  切换暗色主题，从头到尾滚动首页，确认所有区域显示正常
- [ ] **V3.2.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

---

## Phase 4: 列表页视觉升级

### 目标

将智能体广场、工作流中心、资源库三个列表页升级为使用新组件 + 空状态 + 骨架屏的完整体验，每个页面端到端可验证。

### 任务 4.1: 智能体广场 Agents.vue 完整升级

#### 核心逻辑

1. **AgentCard 组件集成**：已在 P2 完成，本任务确保页面级集成完整
2. **page-hero 增强**：增加渐变背景装饰，提升视觉层次
3. **分类栏动画**：标签切换添加过渡动画（使用 `--duration-normal`）
4. **EmptyState 替换**：用 `EmptyState` 组件替代 `el-empty`，type 为 `no-result`
5. **CardSkeleton 加载态**：数据加载期间显示 `CardSkeleton`，type 为 `agent`
6. **筛选过渡动画**：筛选/搜索结果更新时卡片以过渡动画更新

#### 交付物

- `src/views/Agents.vue` — 完整视觉升级（新组件 + 动画 + 空状态 + 骨架屏）

#### 验证步骤

- [ ] **V4.1.1** 智能体广场使用 AgentCard 组件 → 卡片视觉为分层风格
  访问智能体广场，确认卡片为分层设计
- [ ] **V4.1.2** page-hero 有渐变背景装饰 → 视觉层次提升
  DevTools 检查 `.page-hero` 有渐变背景装饰元素
- [ ] **V4.1.3** 分类栏切换有过渡动画 → 标签切换平滑
  点击不同分类标签，确认切换有过渡动画
- [ ] **V4.1.4** 空状态使用 EmptyState 组件 → 搜索无结果时显示自定义空状态
  搜索一个不存在的关键词，确认显示 EmptyState 而非 el-empty
- [ ] **V4.1.5** 加载态显示 CardSkeleton → 骨架屏正常
  模拟加载状态，确认显示骨架屏而非空白
- [ ] **V4.1.6** 暗色模式下页面正常 → 无对比度或布局问题
  切换暗色主题，确认页面所有区域正常
- [ ] **V4.1.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 4.2: 工作流中心 Workflows.vue 完整升级

#### 核心逻辑

与 Agents.vue 同构升级：

1. **WorkflowCard 组件集成**：使用重设计的 WorkflowCard
2. **page-hero 增强**：增加渐变背景装饰
3. **分类栏动画**：标签切换过渡动画
4. **EmptyState 替换**：替代 `el-empty`
5. **CardSkeleton 加载态**：type 为 `card`

#### 交付物

- `src/views/Workflows.vue` — 完整视觉升级

#### 验证步骤

- [ ] **V4.2.1** 工作流中心使用重设计 WorkflowCard → 卡片为分层风格
  访问工作流中心，确认卡片为分层设计
- [ ] **V4.2.2** page-hero 有渐变背景装饰 → 视觉层次提升
  DevTools 检查 `.page-hero` 有渐变背景装饰元素
- [ ] **V4.2.3** 分类栏切换有过渡动画 → 标签切换平滑
  点击不同分类标签，确认切换有过渡动画
- [ ] **V4.2.4** 空状态使用 EmptyState 组件 → 筛选无结果时显示自定义空状态
  筛选无结果时，确认显示 EmptyState
- [ ] **V4.2.5** 加载态显示 CardSkeleton → 骨架屏正常
  模拟加载状态，确认显示骨架屏
- [ ] **V4.2.6** 暗色模式下页面正常 → 无对比度或布局问题
  切换暗色主题，确认页面正常
- [ ] **V4.2.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 4.3: 资源库 Resources.vue 视觉升级

#### 核心逻辑

1. **卡片风格升级**：资源卡片使用分层风格（类型图标区 + 内容区）
2. **EmptyState 替换**：替代 `el-empty`
3. **CardSkeleton 加载态**：type 为 `card`
4. **分类栏动画**：标签切换过渡动画

#### 交付物

- `src/views/Resources.vue` — 视觉升级

#### 验证步骤

- [ ] **V4.3.1** 资源卡片使用分层风格 → 类型图标区与内容区视觉分离
  访问资源库，确认卡片有分层视觉效果
- [ ] **V4.3.2** 空状态使用 EmptyState 组件 → 显示自定义空状态
  筛选无结果时，确认显示 EmptyState
- [ ] **V4.3.3** 加载态显示 CardSkeleton → 骨架屏正常
  模拟加载状态，确认显示骨架屏
- [ ] **V4.3.4** 分类栏切换有过渡动画 → 标签切换平滑
  点击不同分类标签，确认切换有过渡动画
- [ ] **V4.3.5** 暗色模式下页面正常 → 无对比度或布局问题
  切换暗色主题，确认页面正常
- [ ] **V4.3.6** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

---

## Phase 5: 详情页沉浸体验

### 目标

将工作流详情页从传统布局升级为沉浸式体验——全宽大封面 + 视差滚动 + 可交互步骤卡片 + sticky 侧边栏 + 浮动操作栏，提供端到端的详情浏览交互闭环。

### 任务 5.1: 详情页沉浸式封面与视差滚动

#### 核心逻辑

1. **全宽大封面**：宽度 100%，高度 400px，`overflow: hidden`；移除圆角卡片容器
2. **视差滚动**：JS 监听 scroll 事件，封面区 `transform: translateY(scrollY * 0.3) scale(1.1)`，性能优于 CSS `background-attachment: fixed`
3. **渐变过渡**：封面底部添加 `linear-gradient(transparent, var(--bg-primary))` 实现封面到内容区的自然过渡
4. **返回按钮**：绝对定位在封面区左上角，半透明背景 + 圆角
5. **响应式**：移动端封面高度降为 250px

#### 交付物

- `src/views/WorkflowDetail.vue` — 沉浸式封面区 + 视差滚动 + 渐变过渡

#### 验证步骤

- [ ] **V5.1.1** 详情页封面为全宽大图 → 宽度 100%，高度 400px
  访问任意工作流详情，DevTools 检查封面区宽度为 100%、高度 400px
- [ ] **V5.1.2** 视差滚动效果生效 → 滚动时封面区以 0.3 倍速移动
  向下滚动页面，观察封面区以较慢速度移动，产生深度感
- [ ] **V5.1.3** 渐变过渡可见 → 封面底部到内容区过渡自然
  确认封面底部有渐变遮罩，与内容区背景色自然过渡
- [ ] **V5.1.4** 返回按钮在封面区左上角 → 半透明背景，可点击
  确认返回按钮位置正确，点击后返回列表页
- [ ] **V5.1.5** 移动端封面高度 250px → 响应式适配
  浏览器缩窄至 768px 以下，确认封面高度降为 250px
- [ ] **V5.1.6** 暗色模式下沉浸式封面正常 → 渐变过渡适配暗色
  切换暗色主题，确认渐变过渡使用暗色背景变量
- [ ] **V5.1.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 5.2: 详情页步骤卡片交互与进度标记

#### 核心逻辑

1. **展开/折叠**：点击步骤标题切换内容显示，使用 Vue `<transition>` 展开动画（`max-height` + `--duration-normal`）
2. **进度标记**：勾选框标记已完成步骤，状态存入 `localStorage`（key: `workflow-progress:{workflowId}`）
3. **视觉反馈**：已完成步骤添加 accent 边框 + ✓ 标记；未完成步骤保持默认样式
4. **进度条**：在步骤区顶部添加进度条，显示已完成/总步骤数

#### 交付物

- `src/views/WorkflowDetail.vue` — 可交互步骤卡片 + 进度标记 + 进度条

#### 验证步骤

- [ ] **V5.2.1** 点击步骤标题可展开/折叠内容 → 动画过渡平滑
  点击步骤标题，确认内容区展开/折叠有动画过渡
- [ ] **V5.2.2** 勾选步骤标记已完成 → 步骤获得 accent 边框 + ✓ 标记
  勾选一个步骤，确认其获得视觉变化（边框 + 标记）
- [ ] **V5.2.3** 进度存入 localStorage → 刷新页面后进度保留
  标记几个步骤后刷新页面，确认进度状态保留
- [ ] **V5.2.4** 进度条显示正确 → 已完成/总步骤数计算正确
  检查进度条显示的比例与实际完成步骤数一致
- [ ] **V5.2.5** 再次点击取消标记 → 步骤恢复未完成样式
  取消勾选已完成的步骤，确认视觉标记移除
- [ ] **V5.2.6** 不同工作流进度独立 → 切换工作流后进度不混淆
  访问不同工作流详情，确认各自进度独立
- [ ] **V5.2.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 5.3: 详情页 Sidebar Sticky 与浮动操作栏

#### 核心逻辑

1. **Sidebar Sticky**：添加 `position: sticky; top: 80px`，滚动时固定；操作按钮组（收藏/分享/开始学习）使用渐变主按钮
2. **浮动操作栏**：页面滚动超过封面区后显示，固定在页面底部（`position: fixed; bottom: 0`），包含核心操作：开始学习、收藏、分享；移动端可见性提升（因 Sidebar 隐藏）
3. **显示逻辑**：通过 JS 监听 scroll，封面区离开视口时显示浮动栏，使用 `--duration-normal` 过渡

#### 交付物

- `src/views/WorkflowDetail.vue` — sticky sidebar + 浮动操作栏

#### 验证步骤

- [ ] **V5.3.1** Sidebar 滚动时固定 → sticky 定位生效
  向下滚动详情页，确认侧边栏保持在视口内（top: 80px）
- [ ] **V5.3.2** 侧边栏操作按钮为渐变主按钮 → 视觉正确
  检查"开始学习"等按钮有渐变背景样式
- [ ] **V5.3.3** 滚动超过封面区后浮动操作栏出现 → 过渡动画平滑
  滚动到内容区，确认底部浮动操作栏出现，带过渡动画
- [ ] **V5.3.4** 向上滚回封面区时浮动操作栏消失 → 隐藏逻辑正确
  滚回顶部，确认浮动操作栏消失
- [ ] **V5.3.5** 浮动操作栏按钮可点击 → 功能正常
  点击浮动栏的收藏/分享按钮，确认功能正常
- [ ] **V5.3.6** 移动端 Sidebar 隐藏时浮动操作栏可见 → 适配正确
  缩窄至 768px 以下，确认浮动操作栏可见
- [ ] **V5.3.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

---

## Phase 6: 认证页面与全局打磨

### 目标

完成认证页面左图右表分屏布局、Header 滚动行为与移动端汉堡菜单、Footer 主题适配、个人中心优化和页面转场增强，实现全站体验闭环。

### 任务 6.1: 登录/注册左图右表分屏布局

#### 核心逻辑

1. **布局结构**：左图右表分屏 — 左侧品牌展示区（50% 宽度）+ 右侧表单区（50% 宽度），flex 布局
2. **左侧品牌区**：渐变背景（使用 `--accent-gradient`）+ 浮动装饰元素（CSS 动画）+ 3 条产品亮点文字 + Logo
3. **右侧表单区**：简洁白色/暗色背景，与当前表单结构一致（保留字段、按钮、辅助链接）
4. **响应式**：768px 以下隐藏左侧品牌区，表单区全屏展示
5. **同时改造**：Login.vue 和 Register.vue 均使用相同分屏布局

#### 交付物

- `src/views/Login.vue` — 左图右表分屏布局
- `src/views/Register.vue` — 左图右表分屏布局

#### 验证步骤

- [ ] **V6.1.1** 登录页为左图右表分屏布局 → 两区各占 50%
  访问登录页，确认左侧品牌区 + 右侧表单区各占约 50%
- [ ] **V6.1.2** 左侧品牌区有渐变背景 + 浮动装饰 + 产品亮点 → 视觉完整
  确认左侧有渐变背景、浮动动画装饰、3 条产品亮点文字
- [ ] **V6.1.3** 右侧表单功能正常 → 登录/注册流程不受影响
  使用表单完成登录操作，确认功能正常
- [ ] **V6.1.4** 注册页同样使用分屏布局 → 布局一致
  访问注册页，确认同样为左图右表分屏布局
- [ ] **V6.1.5** 768px 以下品牌区隐藏 → 表单区全屏展示
  缩窄浏览器至 768px 以下，确认品牌区隐藏，表单全屏
- [ ] **V6.1.6** 暗色模式下分屏布局正常 → 两侧视觉协调
  切换暗色主题，确认左侧渐变和右侧表单区域正常
- [ ] **V6.1.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 6.2: Header 滚动行为与移动端汉堡菜单

#### 核心逻辑

1. **Header 滚动行为**：监听 scroll 事件，超过阈值（如 50px）后：缩小 padding（`--spacing-sm` → 更小值）、增加 shadow（`--shadow-md`）、Logo 文字隐藏仅保留图标；回滚时恢复
2. **移动端汉堡菜单**：768px 以下显示汉堡图标（三横线），点击展开为侧边抽屉（`el-drawer` 从左/右滑出），包含完整导航链接
3. **过渡动画**：Header 状态切换使用 `--duration-fast` 过渡，避免突兀

#### 交付物

- `src/views/Layout.vue` — Header 滚动行为 + 移动端汉堡菜单

#### 验证步骤

- [ ] **V6.2.1** Header 滚动后缩小 padding + 增加阴影 → 视觉变化明显
  向下滚动页面超过 50px，确认 Header 缩小且增加阴影
- [ ] **V6.2.2** 滚动后 Logo 文字隐藏仅保留图标 → 布局紧凑
  滚动后确认 Logo 旁的文字隐藏，仅显示图标
- [ ] **V6.2.3** 向上滚回后 Header 恢复 → 过渡平滑
  滚回顶部，确认 Header 恢复原始大小，过渡平滑
- [ ] **V6.2.4** 768px 以下显示汉堡菜单图标 → 导航文字隐藏
  缩窄浏览器至 768px 以下，确认出现汉堡菜单图标
- [ ] **V6.2.5** 点击汉堡菜单展开侧边抽屉 → 导航链接可点击
  点击汉堡图标，确认侧边抽屉滑出，导航链接可点击
- [ ] **V6.2.6** 抽屉内导航跳转正常 → 路由切换成功
  在抽屉内点击导航链接，确认跳转到对应页面
- [ ] **V6.2.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 6.3: Footer 主题适配与暗色模式增强

#### 核心逻辑

1. **Footer 主题适配**：亮色模式下使用浅色背景（`--bg-tertiary` 或新增 Footer 专用变量），暗色模式保持深色背景
2. **暗色模式渐变色增强**：检查所有使用渐变色的区域（Hero 背景、CTA 按钮、品牌区），暗色下渐变色亮度提升，确保表现力不衰减
3. **Footer 内部元素**：文字色、链接色、分隔线颜色均使用 CSS 变量，适配亮暗色主题

#### 交付物

- `src/views/Layout.vue` — Footer 主题适配
- `src/assets/main.scss` — 暗色模式渐变色增强

#### 验证步骤

- [ ] **V6.3.1** 亮色模式下 Footer 使用浅色背景 → 与页面风格协调
  亮色主题下检查 Footer，确认背景为浅色而非深色
- [ ] **V6.3.2** 暗色模式下 Footer 保持深色背景 → 视觉一致
  暗色主题下检查 Footer，确认背景为深色
- [ ] **V6.3.3** Footer 文字/链接颜色适配亮暗色 → 可读性正常
  两种主题下确认 Footer 文字和链接可读
- [ ] **V6.3.4** 暗色模式下渐变色表现力增强 → 渐变更亮/更鲜明
  暗色模式下检查 Hero、CTA 按钮、品牌区渐变色，确认亮度提升
- [ ] **V6.3.5** 亮色模式下渐变色不受影响 → 视觉保持原有效果
  亮色模式下检查渐变色，确认无异常变化
- [ ] **V6.3.6** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

### 任务 6.4: 个人中心与页面转场动效优化

#### 核心逻辑

1. **UserCenter.vue 视觉优化**：标签页切换添加过渡动画（`--duration-normal`）；表单卡片添加 hover 效果；整体间距和排版对齐设计规范
2. **页面转场增强**：在 Layout.vue 的 `<transition>` 中根据路由 meta 信息动态切换转场类型：
   - 默认：`fade`（保持现有）
   - 列表→详情：`slide-fade`
   - 其他：`fade-scale`
3. **路由 meta 配置**：在 `router/index.js` 中为详情页路由添加 `meta: { transition: 'slide-fade' }`

#### 交付物

- `src/views/UserCenter.vue` — 视觉优化
- `src/views/Layout.vue` — 页面转场增强
- `src/router/index.js` — 路由 meta 转场配置

#### 验证步骤

- [ ] **V6.4.1** 个人中心标签页切换有过渡动画 → 切换平滑
  在个人中心切换标签页，确认有过渡动画
- [ ] **V6.4.2** 个人中心表单卡片有 hover 效果 → 微交互反馈
  鼠标悬停表单卡片，确认有 hover 视觉反馈
- [ ] **V6.4.3** 列表→详情使用 slide-fade 转场 → 滑入淡入效果
  从工作流列表点击进入详情，确认页面切换为 slide-fade 效果
- [ ] **V6.4.4** 详情→列表使用反向 slide-fade → 滑出淡出效果
  从详情页返回列表，确认页面切换为反向 slide-fade 效果
- [ ] **V6.4.5** 其他页面使用 fade-scale 转场 → 缩放淡入效果
  在非列表-详情的页面间切换，确认 fade-scale 效果
- [ ] **V6.4.6** 暗色模式下个人中心和转场正常 → 无视觉问题
  暗色主题下测试个人中心和页面转场，确认正常
- [ ] **V6.4.7** 项目构建成功 → 无编译错误
  `cd ai-fast-web/ai-fast-web-user && npm run build`

---

## 实施顺序建议

1. **P1 设计基础设施**（任务 1.1）→ 所有后续任务的前置依赖
2. **P2 核心组件库**（任务 2.1 → 2.2 → 2.3 → 2.4）→ 并行开发，组件独立可验证
3. **P3 首页 Hero 体验**（任务 3.1 → 3.2）→ Hero 先行，板块跟进
4. **P4 列表页视觉升级**（任务 4.1 / 4.2 / 4.3 可并行）→ 三个页面互不依赖
5. **P5 详情页沉浸体验**（任务 5.1 → 5.2 → 5.3）→ 封面先行，交互跟进，操作栏收尾
6. **P6 认证页面与全局打磨**（任务 6.1 / 6.2 / 6.3 可并行 → 6.4 收尾）→ 并行推进，转场收尾

## 风险与挑战

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 视差滚动性能问题（低端设备/移动端） | 滚动卡顿，体验降级 | 使用 `transform` 替代 `top/left` 移动；移动端降级为静态封面 |
| CSS 变量兼容性 | 极老浏览器不支持 CSS 变量 | 项目已使用 CSS 变量，无新增兼容风险 |
| Hero 动态背景性能 | CPU 占用过高 | 纯 CSS 渐变 + 伪元素动画优先，避免 Canvas；提供 `prefers-reduced-motion` 降级 |
| 组件重设计导致布局偏移 | 页面切换时布局跳动 | 骨架屏与实际卡片使用相同 grid 布局；过渡动画平滑切换 |
| 暗色模式渐变色表现力不足 | 暗色下视觉冲击力减弱 | 暗色模式下提升渐变色亮度，增强阴影和光晕效果 |
| IntersectionObserver 浏览器兼容性 | 极老浏览器不支持 | 项目面向现代浏览器，且 IO 兼容性已很好；提供 fallback 直接显示 |

## 变更模块总览

| 变更模块 | 涉及 Phase | 核心变更 |
|----------|-----------|----------|
| `src/assets/main.scss` | P1, P6 | 动效 Token + 间距 Token + scroll-reveal 工具类 + 转场 CSS + 暗色增强 |
| `src/main.js` | P1 | 全局 IntersectionObserver 注册 |
| `src/components/WorkflowCard.vue` | P2 | 分层卡片重设计 |
| `src/components/AgentCard.vue` | P2 | 新增 Agent 卡片组件 |
| `src/components/EmptyState.vue` | P2 | 新增空状态组件 |
| `src/components/CardSkeleton.vue` | P2 | 新增骨架屏组件 |
| `src/views/Home.vue` | P2, P3 | AgentCard 集成 + Hero Section + 滚动动画 + countUp |
| `src/views/Agents.vue` | P2, P4 | AgentCard + EmptyState + CardSkeleton + 动画 |
| `src/views/Workflows.vue` | P4 | WorkflowCard + EmptyState + CardSkeleton + 动画 |
| `src/views/Resources.vue` | P4 | 分层卡片 + EmptyState + CardSkeleton |
| `src/views/WorkflowDetail.vue` | P5 | 沉浸式封面 + 视差 + 步骤交互 + sticky + 浮动栏 |
| `src/views/Login.vue` | P6 | 左图右表分屏布局 |
| `src/views/Register.vue` | P6 | 左图右表分屏布局 |
| `src/views/Layout.vue` | P6 | Header 滚动行为 + 汉堡菜单 + Footer 适配 + 转场 |
| `src/views/UserCenter.vue` | P6 | 标签页动画 + 卡片 hover + 间距优化 |
| `src/router/index.js` | P6 | 路由 meta 转场配置 |
