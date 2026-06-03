# FT-002 Admin 管理后台页面开发 - 详细设计

> **🔗 前置文档引用**：本文档基于 [FT-002-admin-page-development-Feature-Overall.md](./FT-002-admin-page-development-Feature-Overall.md)（概要设计文档）编写。Overall 中的总体概述、使用场景、核心设计决策等是本详细设计的直接输入来源。

> 最后更新：2026-06-02

---

## 修订记录

| 版本 | 日期 | 修订人 | 修订内容 |
|------|------|--------|----------|
| 1.0.0 | 2026-06-02 | meiguangxian | 初始版本 |

---

## 目录

- [1. 总体概述 — 背景、目标与设计决策](#1-总体概述)
  - [1.1 项目背景与现状问题](#11-项目背景与现状问题)
  - [1.2 开发目标与核心价值](#12-开发目标与核心价值)
  - [1.3 已确认设计决策汇总](#13-已确认设计决策汇总)
  - [1.4 变更范围](#14-变更范围)
- [2. 使用场景 — 管理员操作流程与预期结果](#2-使用场景)
  - [2.1 管理员登录](#21-管理员登录)
  - [2.2 数据统计总览](#22-数据统计总览)
  - [2.3 内容管理与编辑](#23-内容管理与编辑)
  - [2.4 内容审核](#24-内容审核)
  - [2.5 用户管理](#25-用户管理)
  - [2.6 系统配置](#26-系统配置)
  - [2.7 主题切换](#27-主题切换)
  - [2.8 移动端基础使用](#28-移动端基础使用)
- [3. 设计系统 — Design Token 与主题规范](#3-设计系统)
  - [3.1 设计原则](#31-设计原则)
  - [3.2 Design Token 体系](#32-design-token-体系)
  - [3.3 主题系统设计](#33-主题系统设计)
  - [3.4 localStorage 持久化机制](#34-localstorage-持久化机制)
- [4. 组件设计 — 公共组件](#4-组件设计)
  - [4.1 统计卡片组件 StatCard](#41-统计卡片组件-statcard)
  - [4.2 状态标签组件 StatusTag](#42-状态标签组件-statustag)
  - [4.3 搜索筛选组件 SearchFilter](#43-搜索筛选组件-searchfilter)
- [5. 页面设计方案 — 逐页详细设计](#5-页面设计方案)
  - [5.1 登录页 Login.vue](#51-登录页-loginvue)
  - [5.2 布局框架 Layout.vue](#52-布局框架-layoutvue)
  - [5.3 数据统计仪表盘 Dashboard.vue](#53-数据统计仪表盘-dashboardvue)
  - [5.4 内容管理 ContentManage.vue](#54-内容管理-contentmanagevue)
  - [5.5 内容编辑 ContentEdit.vue](#55-内容编辑-contenteditvue)
  - [5.6 内容审核 ContentReview.vue](#56-内容审核-contentreviewvue)
  - [5.7 用户管理 UserManage.vue](#57-用户管理-usermanagevue)
  - [5.8 系统配置 SystemSettings.vue](#58-系统配置-systemsettingsvue)
- [6. 主题状态管理 — stores/theme.js](#6-主题状态管理)
- [7. 依赖关系](#7-依赖关系)
  - [7.1 前置依赖](#71-前置依赖)
  - [7.2 后续依赖](#72-后续依赖)
  - [7.3 代码库依赖](#73-代码库依赖)
  - [7.4 第三方依赖](#74-第三方依赖)
- [8. 实施顺序与开发计划](#8-实施顺序与开发计划)
- [9. 完成规范 (DoD)](#9-完成规范-dod)
  - [9.1 核心功能](#91-核心功能)
  - [9.2 用户体验](#92-用户体验)
  - [9.3 兼容性](#93-兼容性)
- [10. 相关文档](#10-相关文档)

---

## 1. 总体概述

### 1.1 项目背景与现状问题

ai-fast-web-admin 是 AI Fast 平台的管理后台，基于 Vue 3 + Element Plus + ECharts + Pinia 构建。当前项目仅完成脚手架搭建（路由、Store、Mock 数据），8 个视图组件全部缺失，后台无法运行。

**现状问题清单**：

| 编号 | 问题 | 影响等级 |
|------|------|:--------:|
| admin-G1 | `views/` 目录不存在，8 个视图组件全部缺失 | P0 |
| admin-G2 | 主题 Store 缺失，无法实现亮/暗/跟随系统三模式 | P1 |
| admin-G3 | CSS 变量系统缺失，仅有基础重置样式 | P1 |
| admin-G4 | Element Plus 暗黑模式未配置 | P1 |
| admin-G5 | localStorage 持久化未实现（除 admin token 外） | P1 |
| admin-G6 | `components/` 公共组件目录缺失 | P2 |
| admin-G7 | `utils/` 工具函数目录缺失 | P2 |
| admin-G8 | 项目为 JavaScript 非 TypeScript，需保持 JS 一致性 | P2 |

### 1.2 开发目标与核心价值

本特性的目标是**实现所有视图组件，使管理后台可用**，具体包括：

- **补齐 8 个缺失的视图组件**：登录、布局、仪表盘、内容管理、内容编辑、内容审核、用户管理、系统配置
- **实现主题状态管理**：亮/暗/跟随系统三模式切换 + localStorage 持久化
- **建立 CSS 变量体系**：对齐用户端设计语言，支持主题切换
- **关键业务数据持久化**：工作流列表、用户列表、系统配置等刷新不丢失
- **基础响应式适配**：移动端核心操作可用

### 1.3 已确认设计决策汇总

> 来源：[FT-002-admin-page-development-AskMe.md](./FT-002-admin-page-development-AskMe.md)

| # | 决策项 | 确认方案 | 核心理由 |
|---|--------|---------|---------|
| 1 | UI 设计风格 | B — 现代管理风格（品牌色渐变、卡片阴影、圆角设计） | 与用户端品牌一致性，Element Plus CSS 变量覆盖成熟 |
| 2 | 侧边栏导航 | B — 可折叠侧边栏（默认展开，可折叠为 64px 图标模式） | 兼顾导航与空间，el-menu 原生支持折叠 |
| 3 | Dashboard 图表 | A — 核心指标 + 趋势图 + 分布图 | 信息完整，Mock 数据可直用，ECharts 成熟稳定 |
| 4 | 内容编辑器 | A — Element Plus 表单（纯表单方案） | description 为纯文本，后台定位为结构化数据录入 |
| 5 | 数据持久化 | B — localStorage 手动持久化 | 可控精确，后续对接 API 可平滑替换 |
| 6 | 内容审核交互 | B — 列表 + 抽屉审核 | 抽屉空间充足展示详情，保持列表可见 |
| 7 | 移动端适配 | B — 基础响应式 | 紧急审核场景移动端可用，适配成本可控 |
| 8 | API 层预留 | A — 暂不预留 | 核心目标是让后台可用，Store 接口设计已较规范 |
| 9 | 亮/暗色调 | C — 跟随系统主题 + 手动切换 | 与用户端架构一致，Element Plus 原生支持暗黑模式 |

### 1.4 变更范围

| 变更模块 | 变更类型 | 功能说明 |
|----------|:--------:|----------|
| `src/assets/main.scss` | 🔧 重构 | CSS 变量体系扩展（主题 Token + 暗色覆盖 + 动效） |
| `src/main.js` | 🔧 修改 | 引入 Element Plus 暗黑模式 CSS、主题初始化 |
| `src/views/Login.vue` | 🔲 新增 | 管理员登录页面 |
| `src/views/Layout.vue` | 🔲 新增 | 后台布局框架 |
| `src/views/Dashboard.vue` | 🔲 新增 | 数据统计仪表盘 |
| `src/views/ContentManage.vue` | 🔲 新增 | 内容/工作流列表管理 |
| `src/views/ContentEdit.vue` | 🔲 新增 | 内容新增/编辑表单 |
| `src/views/ContentReview.vue` | 🔲 新增 | 内容审核列表 |
| `src/views/UserManage.vue` | 🔲 新增 | 用户列表管理 |
| `src/views/SystemSettings.vue` | 🔲 新增 | 系统配置表单 |
| `src/stores/theme.js` | 🔲 新增 | 主题状态管理 |
| `src/components/StatCard.vue` | 🔲 新增 | 统计卡片组件 |
| `src/components/StatusTag.vue` | 🔲 新增 | 状态标签组件 |
| `src/components/SearchFilter.vue` | 🔲 新增 | 搜索筛选组件 |
| `src/utils/persistence.js` | 🔲 新增 | localStorage 持久化工具 |

---

## 2. 使用场景

> 详细使用场景参见 [FT-002-admin-page-development-Feature-Overall.md](./FT-002-admin-page-development-Feature-Overall.md) 第 2 节，此处为摘要。

### 2.1 管理员登录

1. 管理员访问管理后台 URL，展示品牌视觉登录页
2. 输入账号密码（Mock：admin/admin123），点击登录
3. 系统验证凭据，成功后跳转 Dashboard；失败显示错误提示
4. 路由守卫确保未登录用户重定向至登录页

### 2.2 数据统计总览

1. 登录后进入 Dashboard，顶部 4 个统计卡片（总用户/总工作流/总浏览/总点赞 + 今日新增）
2. 中部 7 天趋势折线图（ECharts），含用户增长、工作流增长、浏览量三条线
3. 底部分类分布饼图（ECharts）
4. 图表配色跟随主题切换

### 2.3 内容管理与编辑

1. 侧边栏点击"内容管理"进入列表页，表格展示工作流
2. 搜索框 + 分类/状态筛选条件快速定位
3. 状态标签区分已发布/待审核/已拒绝/草稿
4. 新增/编辑进入表单页，填写标题、描述、封面、分类、标签、难度、时长
5. 保存后更新 Store 并持久化

### 2.4 内容审核

1. 侧边栏点击"内容审核"进入审核列表，默认筛选"待审核"
2. 点击"审核"按钮，右侧滑出抽屉面板展示详情
3. 抽屉底部"通过"/"拒绝"按钮，拒绝需填审核意见
4. 操作后状态更新，抽屉关闭，列表刷新

### 2.5 用户管理

1. 侧边栏点击"用户管理"进入用户列表
2. 搜索 + 角色/状态筛选
3. 操作列启用/禁用切换按钮
4. 状态变更后 Store 更新并持久化

### 2.6 系统配置

1. 侧边栏点击"系统配置"进入配置页
2. 按功能分组展示配置项（基础/内容/通知）
3. 修改后"保存"持久化，"重置"恢复默认值

### 2.7 主题切换

1. Layout 顶栏主题切换按钮（太阳/月亮/系统图标）
2. 点击循环切换：亮色 → 暗色 → 跟随系统
3. 切换即时生效，ECharts 图表配色同步更新
4. 偏好持久化到 localStorage

### 2.8 移动端基础使用

1. 侧边栏自动切换为抽屉模式
2. 表格横向滚动查看完整数据
3. Dashboard 图表自适应宽度
4. 审核抽屉移动端全屏展示

---

## 3. 设计系统 — Design Token 与主题规范

> 代码库路径：`ai-fast-web/ai-fast-web-admin/`
> 核心文件：`src/assets/main.scss`

### 3.1 设计原则

- **对齐用户端**：CSS 变量命名和值与用户端（ai-fast-web-user）保持一致，确保品牌统一
- **主题可切换**：所有颜色通过 CSS 变量管控，`html.dark` class 切换暗色值
- **Element Plus 兼容**：暗色模式下覆盖 Element Plus 的 CSS 变量，确保组件风格统一
- **精简实用**：管理后台以功能为主，动画和装饰适当精简，不引入滚动触发动画

### 3.2 Design Token 体系

从用户端 `main.scss` 复用核心 CSS 变量体系，并扩展 admin 专用变量：

#### 3.2.1 背景色 Tokens

| 变量 | 亮色值 | 暗色值 | 用途 |
|------|--------|--------|------|
| `--bg-primary` | `#ffffff` | `#0f0f1a` | 主背景 |
| `--bg-secondary` | `#f5f7fa` | `#161625` | 次级背景 |
| `--bg-tertiary` | `#ecf0f5` | `#1e1e32` | 三级背景 |
| `--bg-card` | `#ffffff` | `#1a1a2e` | 卡片背景 |
| `--bg-card-hover` | `#fafbfc` | `#22223a` | 卡片 hover |
| `--bg-sidebar` | `#ffffff` | `#12121f` | 侧边栏背景 |
| `--bg-header` | `rgba(255,255,255,0.95)` | `rgba(15,15,26,0.95)` | 顶栏背景 |

#### 3.2.2 文字色 Tokens

| 变量 | 亮色值 | 暗色值 | 用途 |
|------|--------|--------|------|
| `--text-primary` | `#1a1a2e` | `#e8e8f0` | 主文字 |
| `--text-secondary` | `#4a4a6a` | `#b0b0cc` | 次级文字 |
| `--text-tertiary` | `#8a8aaa` | `#7070a0` | 辅助文字 |
| `--text-inverse` | `#ffffff` | `#ffffff` | 反色文字 |

#### 3.2.3 边框色 Tokens

| 变量 | 亮色值 | 暗色值 | 用途 |
|------|--------|--------|------|
| `--border-color` | `#e8ecf1` | `#2a2a40` | 默认边框 |
| `--border-light` | `#f0f2f5` | `#1e1e32` | 轻边框 |

#### 3.2.4 强调色 Tokens

| 变量 | 亮色值 | 暗色值 | 用途 |
|------|--------|--------|------|
| `--accent-primary` | `#6366f1` | `#818cf8` | 主强调色 |
| `--accent-primary-light` | `#818cf8` | `#a5b4fc` | 浅强调色 |
| `--accent-primary-bg` | `rgba(99,102,241,0.08)` | `rgba(129,140,248,0.1)` | 强调色背景 |
| `--accent-gradient` | `linear-gradient(135deg, #6366f1, #8b5cf6, #a78bfa)` | `linear-gradient(135deg, #818cf8, #a78bfa, #c4b5fd)` | 渐变色 |

#### 3.2.5 阴影 Tokens

| 变量 | 亮色值 | 暗色值 | 用途 |
|------|--------|--------|------|
| `--shadow-sm` | `0 1px 3px rgba(0,0,0,0.06)` | `0 1px 3px rgba(0,0,0,0.2)` | 小阴影 |
| `--shadow-md` | `0 4px 12px rgba(0,0,0,0.08)` | `0 4px 12px rgba(0,0,0,0.3)` | 中阴影 |
| `--shadow-lg` | `0 8px 24px rgba(0,0,0,0.1)` | `0 8px 24px rgba(0,0,0,0.4)` | 大阴影 |
| `--shadow-glow` | `0 0 20px rgba(99,102,241,0.15)` | `0 0 20px rgba(129,140,248,0.2)` | 主题色辉光 |

#### 3.2.6 圆角 Tokens

| 变量 | 值 | 用途 |
|------|-----|------|
| `--radius-sm` | `8px` | 小圆角（标签、徽章） |
| `--radius-md` | `12px` | 中圆角（卡片、输入框） |
| `--radius-lg` | `16px` | 大圆角（面板、对话框） |
| `--radius-xl` | `24px` | 超大圆角（特殊容器） |

#### 3.2.7 动效 Tokens

| 变量 | 值 | 用途 |
|------|-----|------|
| `--duration-fast` | `150ms` | 微交互（hover、focus） |
| `--duration-normal` | `300ms` | 常规过渡（展开、切换） |
| `--ease-standard` | `cubic-bezier(0.4, 0, 0.2, 1)` | 标准缓动 |
| `--ease-decelerate` | `cubic-bezier(0, 0, 0.2, 1)` | 减速缓动（入场） |

#### 3.2.8 Admin 专用 Tokens

| 变量 | 值 | 用途 |
|------|-----|------|
| `--sidebar-width` | `220px` | 侧边栏展开宽度 |
| `--sidebar-collapsed-width` | `64px` | 侧边栏折叠宽度 |
| `--header-height` | `56px` | 顶栏高度 |
| `--content-padding` | `24px` | 内容区内边距 |
| `--stat-icon-size` | `48px` | 统计卡片图标尺寸 |

### 3.3 主题系统设计

#### 3.3.1 主题模式

支持三种主题模式：

| 模式 | 值 | 行为 |
|------|-----|------|
| 亮色 | `light` | 始终使用亮色主题 |
| 暗色 | `dark` | 始终使用暗色主题 |
| 跟随系统 | `system` | 监听 `prefers-color-scheme` 媒体查询，自动切换 |

#### 3.3.2 主题切换机制

```
┌─────────────────────┐
│  themeStore.themeMode│  ← 'light' | 'dark' | 'system'
│         │            │
│    ┌────┴────┐       │
│    ▼         ▼       │
│ isDark   systemPref │  ← computed: 根据 themeMode 决定实际是否暗色
│    │                  │
│    ▼                  │
│ document.documentElement│
│   .classList.toggle('dark')│  ← 切换 HTML class
│    │                  │
│    ▼                  │
│ CSS Variables Switch  │  ← :root / html.dark 变量切换
│ + Element Plus Dark   │  ← --el-* 变量覆盖
│ + ECharts Theme       │  ← 图表配色更新
└─────────────────────┘
```

#### 3.3.3 主题切换 UI 交互

Layout 顶栏右侧放置主题切换按钮，点击循环切换：

```
☀️ 亮色 → 🌙 暗色 → 💻 跟随系统 → ☀️ 亮色
```

按钮图标显示当前模式的对应图标，tooltip 显示当前模式名称。

#### 3.3.4 Element Plus 暗色覆盖

在 `main.scss` 的 `html.dark` 选择器下覆盖 Element Plus 关键变量：

```scss
html.dark {
  // Element Plus 背景色
  --el-bg-color: var(--bg-primary);
  --el-bg-color-overlay: var(--bg-card);
  --el-bg-color-page: var(--bg-secondary);

  // Element Plus 文字色
  --el-text-color-primary: var(--text-primary);
  --el-text-color-regular: var(--text-secondary);
  --el-text-color-secondary: var(--text-tertiary);

  // Element Plus 边框色
  --el-border-color: var(--border-color);
  --el-border-color-light: var(--border-light);

  // Element Plus 主色
  --el-color-primary: var(--accent-primary);

  // Element Plus 填充色
  --el-fill-color: var(--bg-tertiary);
  --el-fill-color-light: var(--bg-secondary);
  --el-fill-color-blank: var(--bg-card);
}
```

#### 3.3.5 main.js 主题初始化

```javascript
// 在 main.js 中引入 Element Plus 暗黑模式 CSS
import 'element-plus/theme-chalk/dark/css-vars.css'
```

在应用启动时（`App.vue` 的 `onMounted` 或 `main.js`），调用 `themeStore.applyTheme()` 确保页面加载时立即应用持久化的主题。

### 3.4 localStorage 持久化机制

#### 3.4.1 持久化工具 (`src/utils/persistence.js`)

```javascript
/**
 * localStorage 持久化工具
 * 提供 Store 数据的读写和同步机制
 */
export const STORAGE_KEYS = {
  WORKFLOWS: 'admin_workflows',
  CATEGORIES: 'admin_categories',
  USERS: 'admin_users',
  SYSTEM_CONFIG: 'admin_system_config',
  THEME_MODE: 'admin_theme_mode',
  SIDEBAR_COLLAPSED: 'admin_sidebar_collapsed'
}

export function loadData(key, defaultValue = null) { ... }
export function saveData(key, value) { ... }
export function removeData(key) { ... }
```

#### 3.4.2 持久化范围

| Store | 持久化字段 | Storage Key | 策略 |
|-------|-----------|-------------|------|
| content | `workflows` | `admin_workflows` | 数据变更时保存 |
| content | `categories` | `admin_categories` | 数据变更时保存 |
| userManage | `users` | `admin_users` | 数据变更时保存 |
| stats | `systemConfig` | `admin_system_config` | 数据变更时保存 |
| theme | `themeMode` | `admin_theme_mode` | 模式切换时保存 |
| — | 侧边栏折叠状态 | `admin_sidebar_collapsed` | 折叠/展开时保存 |

#### 3.4.3 持久化实现方式

在各 Store 中使用 `watch` 监听需要持久化的数据变化，变化时调用 `saveData` 写入 localStorage。Store 初始化时，优先从 localStorage 读取数据，若无则使用 Mock JSON 默认值。

```javascript
// 示例：content store 中添加持久化
import { loadData, saveData, STORAGE_KEYS } from '@/utils/persistence'

const workflows = ref(loadData(STORAGE_KEYS.WORKFLOWS, adminData.workflows))

watch(workflows, (newVal) => {
  saveData(STORAGE_KEYS.WORKFLOWS, newVal)
}, { deep: true })
```

---

## 4. 组件设计 — 公共组件

> 代码库路径：`ai-fast-web/ai-fast-web-admin/src/components/`

### 4.1 统计卡片组件 StatCard

用于 Dashboard 页面展示核心统计指标。

| 属性 | 说明 |
|------|------|
| 组件名 | `StatCard.vue` |
| Props | `title`（标题）、`value`（数值）、`suffix`（后缀，如"人"/"次"）、`todayNew`（今日新增，可选）、`icon`（图标组件名）、`gradientFrom`（渐变起始色）、`gradientTo`（渐变结束色） |

**视觉设计**：

```
┌─────────────────────────────────┐
│                          ┌────┐ │
│  总用户数                │ 📊 │ │  ← 渐变色图标（48px，圆角12px）
│                          └────┘ │
│  1,256 人                       │  ← 大号数字 + 后缀
│                                 │
│  ↑ 今日新增 23                  │  ← 绿色小字（可选显示）
└─────────────────────────────────┘
  ↑ 卡片阴影 + 悬浮微上浮
```

**关键样式**：

- 卡片：`background: var(--bg-card)`，`border-radius: var(--radius-md)`，`box-shadow: var(--shadow-sm)`
- 图标容器：`background: linear-gradient(135deg, gradientFrom, gradientTo)`，渐变色由父组件通过 props 传入
- 数字：`font-size: 28px`，`font-weight: 700`，`color: var(--text-primary)`
- hover：`transform: translateY(-2px)`，`box-shadow: var(--shadow-md)`，`transition: all var(--duration-fast) var(--ease-standard)`

**使用位置**：Dashboard 页面 × 4 张

### 4.2 状态标签组件 StatusTag

用于内容管理、内容审核页面展示工作流状态。

| 属性 | 说明 |
|------|------|
| 组件名 | `StatusTag.vue` |
| Props | `status`（状态值：published/pending/rejected/draft） |

**状态映射**：

| status | 标签文本 | Element Plus type | 自定义色 |
|--------|---------|-------------------|---------|
| `published` | 已发布 | success | — |
| `pending` | 待审核 | warning | — |
| `rejected` | 已拒绝 | danger | — |
| `draft` | 草稿 | info | — |

直接使用 `<el-tag :type="tagType">{{ label }}</el-tag>` 实现，无需自定义样式。

**使用位置**：ContentManage、ContentReview、ContentEdit 页面

### 4.3 搜索筛选组件 SearchFilter

可复用的搜索 + 筛选条，用于内容管理和用户管理页面。

| 属性 | 说明 |
|------|------|
| 组件名 | `SearchFilter.vue` |
| Props | `searchPlaceholder`（搜索框占位文本）、`filters`（筛选配置数组） |
| Emits | `search(keyword)`、`filter-change({key, value})` |

**筛选配置格式**：

```javascript
filters: [
  { key: 'status', label: '状态', options: [
    { label: '全部', value: 'all' },
    { label: '已发布', value: 'published' },
    { label: '待审核', value: 'pending' },
    { label: '已拒绝', value: 'rejected' },
    { label: '草稿', value: 'draft' }
  ]},
  { key: 'category', label: '分类', options: [...] }
]
```

**布局**：

```
┌──────────────────────────────────────────────────────────┐
│  🔍 [搜索关键词...                    ]   [状态 ▼]  [分类 ▼]  │
└──────────────────────────────────────────────────────────┘
```

- 搜索框：`el-input` + `prefix-icon="Search"`，宽度 280px
- 筛选器：`el-select`，宽度 120px
- 间距：`gap: 12px`

**使用位置**：ContentManage、ContentReview、UserManage 页面

---

## 5. 页面设计方案 — 逐页详细设计

> 代码库路径：`ai-fast-web/ai-fast-web-admin/src/views/`
> 调研详情参见 [FT-002-admin-page-development-CodeResearch-ai-fast-web-admin.md](./FT-002-admin-page-development-CodeResearch-ai-fast-web-admin.md)

### 5.1 登录页 Login.vue

**当前状态**：缺失，路由指向 `@/views/Login.vue` 但文件不存在。

**目标方案**：

```
┌───────────────────────────────────────────────────┐
│                                                   │
│              ┌─────────────────────┐              │
│              │                     │              │  ← 渐变背景（全屏）
│              │    🤖 AI Fast       │              │     linear-gradient(135deg, #6366f1, #8b5cf6)
│              │    管理后台          │              │
│              │                     │              │
│              │  ┌───────────────┐  │              │
│              │  │ 👤 用户名     │  │              │  ← el-input
│              │  └───────────────┘  │              │
│              │  ┌───────────────┐  │              │
│              │  │ 🔒 密码       │  │              │  ← el-input type=password
│              │  └───────────────┘  │              │
│              │                     │              │
│              │  ┌───────────────┐  │              │
│              │  │    登 录      │  │              │  ← 渐变主按钮
│              │  └───────────────┘  │              │
│              │                     │              │
│              │  默认账号: admin    │              │  ← 提示文字
│              │  默认密码: admin123│              │
│              └─────────────────────┘              │  ← 白色/暗色卡片
│                                                   │     border-radius: var(--radius-lg)
│                                                   │     box-shadow: var(--shadow-xl)
└───────────────────────────────────────────────────┘
```

**详细规格**：

| 元素 | 规格 |
|------|------|
| 页面背景 | `min-height: 100vh`，`background: var(--accent-gradient)`，居中布局 |
| 装饰元素 | 背景添加 2-3 个半透明圆形（CSS 绝对定位 + blur），增强视觉层次 |
| 登录卡片 | `width: 420px`，`padding: 48px 40px`，`background: var(--bg-card)`，`border-radius: var(--radius-lg)`，`box-shadow: var(--shadow-xl)` |
| Logo 区域 | 图标 + "AI Fast" + "管理后台" 标题，图标使用 `var(--accent-gradient)` 渐变 |
| 用户名输入 | `el-input`，`prefix-icon="User"`，`size="large"` |
| 密码输入 | `el-input`，`type="password"`，`prefix-icon="Lock"`，`size="large"`，`show-password` |
| 登录按钮 | `el-button`，`type="primary"`，渐变背景，`width: 100%`，`size="large"` |
| 错误提示 | `el-message.error()`，登录失败时显示 |
| 提示文字 | 卡片底部小字，`color: var(--text-tertiary)`，`font-size: 12px` |
| 响应式 | 768px 以下卡片宽度 `90vw`，padding 缩小 |

**数据流**：

```
用户点击登录
  → adminStore.login(username, password)
  → 成功：router.push('/dashboard')
  → 失败：ElMessage.error('用户名或密码错误')
```

**组件生命周期**：

- `onMounted`：检测 `adminStore.isLoggedIn`，若已登录则跳转 `/dashboard`

### 5.2 布局框架 Layout.vue

**当前状态**：缺失。

**目标方案**：

```
┌──────────────────────────────────────────────────────────────┐
│ ┌──────────┐ ┌─────────────────────────────────────────────┐ │
│ │          │ │  Header (56px)                     ☀️ 管理员 │ │  ← 顶栏
│ │  Sidebar │ ├─────────────────────────────────────────────┤ │
│ │          │ │                                             │ │
│ │  📊 数据 │ │                                             │ │
│ │  📄 内容 │ │            Content Area                     │ │  ← router-view
│ │  ✏️ 编辑 │ │                                             │ │
│ │  ✅ 审核 │ │                                             │ │
│ │  👥 用户 │ │                                             │ │
│ │  ⚙️ 配置 │ │                                             │ │
│ │          │ │                                             │ │
│ │ ──────── │ │                                             │ │
│ │  ◀ 折叠  │ │                                             │ │  ← 折叠按钮
│ └──────────┘ └─────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

**详细规格**：

| 元素 | 规格 |
|------|------|
| 整体布局 | `display: flex`，`height: 100vh`，`background: var(--bg-secondary)` |
| 侧边栏 | `width: var(--sidebar-width)`（展开）/ `var(--sidebar-collapsed-width)`（折叠），`background: var(--bg-sidebar)`，`border-right: 1px solid var(--border-color)`，`transition: width var(--duration-normal) var(--ease-standard)` |
| 侧边栏 Logo | 展开时显示 Logo 图标 + "AI Fast" 文字；折叠时仅显示图标 |
| 侧边栏菜单 | `el-menu`，`router` 模式，`background-color: transparent`，`text-color: var(--text-secondary)`，`active-text-color: var(--accent-primary)` |
| 侧边栏菜单项 | 从路由配置动态生成，跳过 `hidden: true` 的路由；每项显示 `el-icon` + 标题文字 |
| 折叠按钮 | 侧边栏底部，`el-icon` 展开/折叠箭头，点击切换 `isCollapsed` 状态 |
| 顶栏 | `height: var(--header-height)`，`background: var(--bg-header)`，`border-bottom: 1px solid var(--border-color)`，`backdrop-filter: blur(12px)`，flex 布局 |
| 顶栏左侧 | 面包屑导航（`el-breadcrumb`），显示当前页面路径 |
| 顶栏右侧 | 主题切换按钮 + 管理员头像 + 下拉菜单（个人信息/退出登录） |
| 主题切换按钮 | 圆形按钮，图标：Sunny/Moon/Monitor，`tooltip` 显示当前模式 |
| 管理员头像 | `el-avatar` + `el-dropdown`，下拉含"个人信息"和"退出登录" |
| 内容区 | `flex: 1`，`padding: var(--content-padding)`，`overflow-y: auto` |
| 响应式 | 768px 以下侧边栏切换为 `el-drawer` 抽屉模式，顶栏显示汉堡菜单按钮 |

**侧边栏菜单生成逻辑**：

```javascript
const menuRoutes = computed(() => {
  const layoutRoute = router.options.routes.find(r => r.path === '/')
  return layoutRoute?.children?.filter(r => !r.meta?.hidden) || []
})
```

**数据流**：

```
折叠/展开侧边栏
  → themeStore.isSidebarCollapsed (或本地 ref)
  → localStorage 持久化

主题切换
  → themeStore.cycleThemeMode()
  → document.documentElement.classList.toggle('dark')
  → localStorage 持久化

退出登录
  → adminStore.logout()
  → router.push('/login')
```

### 5.3 数据统计仪表盘 Dashboard.vue

**当前状态**：缺失。

**目标方案**：

```
┌──────────────────────────────────────────────────────────┐
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │ 总用户数  │ │ 总工作流  │ │ 总浏览量  │ │ 总点赞数  │   │  ← 4 个 StatCard
│  │ 1,256 人 │ │   86 个  │ │ 45,230 次 │ │ 8,930 次 │   │
│  │ ↑ 今日+23│ │ ↑ 今日+5 │ │ ↑ 今日+1250│ │          │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │               7 天趋势折线图                        │   │  ← ECharts
│  │   📈 用户增长 / 工作流增长 / 浏览量                 │   │
│  │                                                     │   │
│  │                                                     │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │              分类分布饼图                            │   │  ← ECharts
│  │          🥧 客服/数据分析/内容创作/...               │   │
│  │                                                     │   │
│  └───────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

**详细规格**：

| 元素 | 规格 |
|------|------|
| 统计卡片区 | `display: grid`，`grid-template-columns: repeat(4, 1fr)`，`gap: 20px` |
| 统计卡片配色 | 总用户（#6366f1→#818cf8）、总工作流（#8b5cf6→#a78bfa）、总浏览量（#ec4899→#f472b6）、总点赞数（#f59e0b→#fbbf24） |
| 趋势图卡片 | `background: var(--bg-card)`，`border-radius: var(--radius-md)`，`padding: 20px`，`box-shadow: var(--shadow-sm)` |
| 趋势图标题 | "7 天趋势"，`font-size: 16px`，`font-weight: 600`，`color: var(--text-primary)` |
| 折线图 | ECharts，宽度 100%，高度 350px |
| 饼图卡片 | 同趋势图卡片样式 |
| 饼图标题 | "分类分布" |
| 饼图 | ECharts，宽度 100%，高度 350px |
| 响应式 | 统计卡片 1200px 以下 2 列，768px 以下 1 列 |

**ECharts 配色方案**：

```javascript
// 亮色主题
const lightColors = {
  users: '#6366f1',
  workflows: '#8b5cf6',
  views: '#ec4899',
  pie: ['#6366f1', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#06b6d4']
}

// 暗色主题
const darkColors = {
  users: '#818cf8',
  workflows: '#a78bfa',
  views: '#f472b6',
  pie: ['#818cf8', '#a78bfa', '#f472b6', '#fbbf24', '#34d399', '#22d3ee']
}
```

**ECharts 主题切换**：

通过 `watch(themeStore.isDark)` 监听主题变化，调用 `chart.setOption({ color: ... })` 更新配色。

**数据源**：

```javascript
const statsStore = useStatsStore()
// statsStore.stats.totalUsers / totalWorkflows / totalViews / totalLikes / ...
// statsStore.stats.weeklyData → 趋势图
// statsStore.stats.categoryDistribution → 饼图
```

### 5.4 内容管理 ContentManage.vue

**当前状态**：缺失。

**目标方案**：

```
┌──────────────────────────────────────────────────────────┐
│  内容管理                              [+ 新增工作流]     │  ← 页面标题 + 操作按钮
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │ 🔍 [搜索...]    [状态 ▼]    [分类 ▼]              │   │  ← SearchFilter
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │ 标题 │ 分类 │ 状态 │ 浏览 │ 点赞 │ 更新时间 │ 操作│   │  ← el-table
│  │──────┼─────┼─────┼─────┼─────┼─────────┼─────│   │
│  │ AI.. │ 客服 │已发布│1520 │328  │03-20   │✏️ 🗑│   │
│  │ 自.. │ 数据 │已发布│2340 │456  │03-18   │✏️ 🗑│   │
│  │ 内.. │ 创作 │待审核│  0  │  0  │03-22   │✏️ 🗑│   │
│  │ ...  │ ... │ ... │ ... │ ... │  ...    │...  │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  共 6 条                              [< 1 2 3 >]       │  ← 分页
└──────────────────────────────────────────────────────────┘
```

**详细规格**：

| 元素 | 规格 |
|------|------|
| 页面标题 | "内容管理"，`font-size: 20px`，`font-weight: 600` |
| 新增按钮 | `el-button`，`type="primary"`，渐变背景，图标 Plus |
| 搜索筛选 | `SearchFilter` 组件，filters 含 status + category |
| 表格 | `el-table`，`stripe`，`style="width: 100%"` |
| 标题列 | 显示工作流标题，超长截断 `show-overflow-tooltip` |
| 分类列 | 普通文本 |
| 状态列 | `StatusTag` 组件 |
| 浏览/点赞列 | 数字，右对齐 |
| 更新时间列 | 格式化为 `MM-DD` |
| 操作列 | 编辑按钮（`el-button` text）+ 删除按钮（`el-button` text danger），固定右侧 |
| 分页 | `el-pagination`，`layout="total, prev, pager, next"`，`page-size: 10` |
| 空状态 | 表格数据为空时显示"暂无数据"提示 |
| 响应式 | 表格横向滚动 `overflow-x: auto` |

**数据流**：

```
搜索/筛选
  → contentStore.setSearchKeyword / setFilterStatus / setFilterCategory
  → contentStore.filteredWorkflows (computed)

新增
  → router.push('/content/edit')

编辑
  → router.push(`/content/edit/${row.id}`)

删除
  → ElMessageBox.confirm('确认删除？')
  → contentStore.deleteWorkflow(id)
```

### 5.5 内容编辑 ContentEdit.vue

**当前状态**：缺失。

**目标方案**：

```
┌──────────────────────────────────────────────────────────┐
│  ← 返回列表            内容编辑 / 新增内容                │  ← 顶栏
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │  标题 *    [                                    ]   │   │  ← el-input
│  │                                                     │   │
│  │  分类 *    [请选择分类 ▼]                           │   │  ← el-select
│  │                                                     │   │
│  │  描述      [                                    ]   │   │  ← el-input textarea
│  │            [                                    ]   │   │     :rows="4"
│  │                                                     │   │
│  │  封面      [点击上传] 或 显示已有封面               │   │  ← el-upload
│  │                                                     │   │
│  │  标签      [AI] [客服] [+ 添加]                    │   │  ← el-tag + 动态添加
│  │                                                     │   │
│  │  难度      [初级 ▼]                                │   │  ← el-select
│  │                                                     │   │
│  │  时长      [2小时]                                 │   │  ← el-input
│  │                                                     │   │
│  │            [保存]  [取消]                           │   │  ← 操作按钮
│  └───────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

**详细规格**：

| 元素 | 规格 |
|------|------|
| 页面标题 | 编辑模式："编辑内容"；新增模式："新增内容" |
| 返回按钮 | 左上角，`el-button` text + ArrowLeft 图标，点击返回 `/content` |
| 表单 | `el-form`，`label-width="80px"`，`label-position="top"` |
| 标题 | `el-input`，必填，`maxlength="100"`，`show-word-limit` |
| 分类 | `el-select`，必填，options 从 `contentStore.categories` 获取 |
| 描述 | `el-input` `type="textarea"`，`:rows="4"`，`maxlength="500"`，`show-word-limit` |
| 封面 | `el-upload`，仅展示当前封面 URL（`el-image`），当前为 Mock 阶段不实现真实上传 |
| 标签 | 动态标签输入：已有标签用 `el-tag` 可关闭展示，新增标签用 `el-input` + 回车添加 |
| 难度 | `el-select`，options：初级/中级/高级 |
| 时长 | `el-input`，如"2小时"、"3.5小时" |
| 保存按钮 | `el-button` `type="primary"`，渐变背景 |
| 取消按钮 | `el-button`，点击返回上一页 |
| 表单宽度 | `max-width: 680px` |
| 表单验证 | `el-form` `:rules`，标题和分类为必填 |

**编辑模式 vs 新增模式**：

```javascript
const route = useRoute()
const isEdit = computed(() => !!route.params.id)
const pageTitle = computed(() => isEdit.value ? '编辑内容' : '新增内容')

// 编辑模式：从 Store 加载已有数据
onMounted(() => {
  if (isEdit.value) {
    const workflow = contentStore.getWorkflowById(route.params.id)
    if (workflow) {
      formData.value = { ...workflow }
    }
  }
})
```

**数据流**：

```
保存
  → 编辑模式: contentStore.updateWorkflow(id, formData)
  → 新增模式: contentStore.addWorkflow(formData)
  → 成功: ElMessage.success() + router.push('/content')
  → 失败: ElMessage.error()
```

### 5.6 内容审核 ContentReview.vue

**当前状态**：缺失。

**目标方案**：

```
┌──────────────────────────────────────────────────────────┐
│  内容审核                                                │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │ 🔍 [搜索...]    [状态 ▼]  默认: 待审核            │   │  ← SearchFilter
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │ 标题 │ 提交者 │ 提交时间 │ 状态 │ 操作            │   │  ← el-table
│  │──────┼───────┼─────────┼─────┼──────────────────│   │
│  │ 内.. │ 王五  │ 03-22   │待审核│ [审核]           │   │
│  │ 智.. │ 赵六  │ 03-20   │已拒绝│ [查看]           │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────┐ ┌───────────────┐ │  ← 审核抽屉
│  │                                  │ │  审核详情      │ │
│  │     (列表区域保持可见)            │ │               │ │
│  │                                  │ │  标题: xxx     │ │
│  │                                  │ │  描述: xxx     │ │
│  │                                  │ │  分类: xxx     │ │
│  │                                  │ │  标签: [...]   │ │
│  │                                  │ │  难度: xxx     │ │
│  │                                  │ │  时长: xxx     │ │
│  │                                  │ │               │ │
│  │                                  │ │  ┌───────────┐│ │
│  │                                  │ │  │拒审意见   ││ │  ← 拒绝时显示
│  │                                  │ │  └───────────┘│ │
│  │                                  │ │               │ │
│  │                                  │ │  [✓ 通过] [✗ 拒绝]│ │
│  └──────────────────────────────────┘ └───────────────┘ │
└──────────────────────────────────────────────────────────┘
```

**详细规格**：

| 元素 | 规格 |
|------|------|
| 搜索筛选 | `SearchFilter` 组件，默认 `filterStatus: 'pending'` |
| 表格 | `el-table`，列：标题、提交者（`author.name`）、提交时间、状态（`StatusTag`）、操作 |
| 审核按钮 | 待审核状态显示"审核"按钮（primary text），其他状态显示"查看"按钮 |
| 审核抽屉 | `el-drawer`，`direction="rtl"`，`size="480px"`，`title="审核详情"` |
| 抽屉内容 | 展示工作流完整信息：标题、描述、封面（`el-image`）、分类、标签、难度、时长 |
| 拒审意见 | 已拒绝的工作流显示原拒审意见 |
| 审核操作 | 底部固定，通过按钮（`el-button` `type="success"`）和拒绝按钮（`el-button` `type="danger"`） |
| 拒绝弹窗 | 点击拒绝弹出 `ElMessageBox.prompt`，要求输入拒审原因 |
| 操作反馈 | 审核操作后 `ElMessage.success()`，抽屉关闭，列表刷新 |
| 响应式 | 768px 以下抽屉 `size="100%"` |

**数据流**：

```
点击审核/查看
  → currentWorkflow = contentStore.getWorkflowById(id)
  → drawerVisible = true

审核通过
  → contentStore.approveWorkflow(id)
  → ElMessage.success('审核通过')
  → drawerVisible = false

审核拒绝
  → ElMessageBox.prompt('请输入拒审原因', '拒绝审核', { inputValidator: ... })
  → contentStore.rejectWorkflow(id, reason)
  → ElMessage.success('已拒绝')
  → drawerVisible = false
```

### 5.7 用户管理 UserManage.vue

**当前状态**：缺失。

**目标方案**：

```
┌──────────────────────────────────────────────────────────┐
│  用户管理                                                │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │ 🔍 [搜索...]    [状态 ▼]    [角色 ▼]              │   │  ← SearchFilter
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │ 头像 │用户名│ 显示名 │  邮箱  │ 角色 │ 状态 │ 操作│   │  ← el-table
│  │──────┼─────┼───────┼───────┼─────┼─────┼─────│   │
│  │  🧑  │zs   │ 张三  │zs@.. │用户 │ 启用 │🔄  │   │
│  │  🧑  │ls   │ 李四  │ls@.. │用户 │ 启用 │🔄  │   │
│  │  🧑  │ww   │ 王五  │ww@.. │作者 │ 启用 │🔄  │   │
│  │  🧑  │zl   │ 赵六  │zl@.. │用户 │ 禁用 │🔄  │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  共 5 条                              [< 1 2 3 >]       │
└──────────────────────────────────────────────────────────┘
```

**详细规格**：

| 元素 | 规格 |
|------|------|
| 搜索筛选 | `SearchFilter` 组件，filters 含 status + role |
| 表格 | `el-table`，列：头像（`el-avatar` 32px）、用户名、显示名、邮箱、角色、状态、操作 |
| 角色列 | 标签展示，用户=`info` tag，作者=`success` tag |
| 状态列 | `el-tag`，active=`success`（"启用"），disabled=`danger`（"禁用"） |
| 操作列 | 启用/禁用切换按钮（`el-switch` 或 `el-button` text），固定右侧 |
| 启用/禁用切换 | 点击后确认弹窗 `ElMessageBox.confirm`，确认后 `userManageStore.updateUserStatus(id, newStatus)` |
| 分页 | `el-pagination`，同内容管理 |
| 注册时间列 | 格式化为 `YYYY-MM-DD` |
| 响应式 | 表格横向滚动 |

**数据流**：

```
搜索/筛选
  → userManageStore.setSearchKeyword / setFilterStatus / setFilterRole
  → userManageStore.filteredUsers (computed)

启用/禁用切换
  → ElMessageBox.confirm('确认切换用户状态？')
  → userManageStore.updateUserStatus(id, newStatus)
  → ElMessage.success('操作成功')
```

### 5.8 系统配置 SystemSettings.vue

**当前状态**：缺失。

**目标方案**：

```
┌──────────────────────────────────────────────────────────┐
│  系统配置                                                │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │  📋 基础配置                                       │   │  ← 分组卡片
│  │                                                     │   │
│  │  站点名称    [AI Fast                            ]  │   │
│  │  站点描述    [AI Agent与工作流教学分享平台         ]  │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │  📝 内容配置                                       │   │
│  │                                                     │   │
│  │  允许注册    [开关 ●]                               │   │
│  │  内容审核    [开关 ●]                               │   │
│  │  最大上传    [50] MB                                │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │  📬 通知配置                                       │   │
│  │                                                     │   │
│  │  SMTP 服务器 [smtp.example.com   ]                 │   │
│  │  SMTP 端口   [465]                                 │   │
│  │  SMTP 用户   [noreply@aifast.com ]                 │   │
│  │  SSL         [开关 ●]                               │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │  🛠️ 其他配置                                       │   │
│  │                                                     │   │
│  │  水印        [开关 ○]                               │   │
│  │  维护模式    [开关 ○]                               │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│                                   [重置默认] [保存配置]   │
└──────────────────────────────────────────────────────────┘
```

**详细规格**：

| 元素 | 规格 |
|------|------|
| 配置分组 | 4 个分组卡片，每个卡片 `background: var(--bg-card)`，`border-radius: var(--radius-md)`，`padding: 24px`，`margin-bottom: 20px` |
| 分组标题 | 图标 + 标题，`font-size: 16px`，`font-weight: 600`，`margin-bottom: 20px`，`border-bottom: 1px solid var(--border-color)`，`padding-bottom: 12px` |
| 表单 | `el-form`，`label-width="120px"`，`label-position="left"` |
| 站点名称/描述 | `el-input` |
| 布尔开关 | `el-switch` |
| 最大上传 | `el-input-number`，`min: 1`，`max: 100`，`suffix: "MB"` |
| SMTP 端口 | `el-input-number`，`min: 1`，`max: 65535` |
| 保存按钮 | `el-button` `type="primary"`，渐变背景 |
| 重置按钮 | `el-button`，点击后 `ElMessageBox.confirm`，确认后恢复 `adminData.systemConfig` 默认值 |
| 表单宽度 | `max-width: 680px` |

**配置字段映射**：

| 分组 | 字段 | 组件 | admin.json key |
|------|------|------|----------------|
| 基础 | 站点名称 | el-input | siteName |
| 基础 | 站点描述 | el-input | siteDescription |
| 内容 | 允许注册 | el-switch | allowRegister |
| 内容 | 内容审核 | el-switch | contentReviewEnabled |
| 内容 | 最大上传 | el-input-number | maxUploadSize |
| 通知 | SMTP 服务器 | el-input | smtpHost |
| 通知 | SMTP 端口 | el-input-number | smtpPort |
| 通知 | SMTP 用户 | el-input | smtpUser |
| 通知 | SSL | el-switch | smtpSsl |
| 其他 | 水印 | el-switch | watermarkEnabled |
| 其他 | 维护模式 | el-switch | maintenanceMode |

**数据流**：

```
保存配置
  → statsStore.updateSystemConfig(formData)
  → ElMessage.success('配置已保存')

重置默认
  → ElMessageBox.confirm('确认恢复默认配置？')
  → statsStore.systemConfig = { ...adminData.systemConfig }
  → ElMessage.success('已恢复默认配置')
```

---

## 6. 主题状态管理 — stores/theme.js

**文件路径**：`src/stores/theme.js`

**设计规格**：

```javascript
import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import { loadData, saveData, STORAGE_KEYS } from '@/utils/persistence'

export const useThemeStore = defineStore('theme', () => {
  // 状态
  const themeMode = ref(loadData(STORAGE_KEYS.THEME_MODE, 'system')) // 'light' | 'dark' | 'system'
  const isSidebarCollapsed = ref(loadData(STORAGE_KEYS.SIDEBAR_COLLAPSED, false))

  // 系统主题偏好检测
  const systemPrefersDark = ref(false)

  // 计算实际是否暗色
  const isDark = computed(() => {
    if (themeMode.value === 'system') {
      return systemPrefersDark.value
    }
    return themeMode.value === 'dark'
  })

  // 主题模式标签
  const modeLabel = computed(() => {
    const labels = { light: '亮色', dark: '暗色', system: '跟随系统' }
    return labels[themeMode.value]
  })

  // 应用主题到 DOM
  function applyTheme() {
    if (isDark.value) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }

  // 循环切换主题模式
  function cycleThemeMode() {
    const modes = ['light', 'dark', 'system']
    const currentIndex = modes.indexOf(themeMode.value)
    themeMode.value = modes[(currentIndex + 1) % modes.length]
  }

  // 监听系统主题偏好
  let mediaQuery = null
  function initSystemThemeListener() {
    mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    systemPrefersDark.value = mediaQuery.matches
    mediaQuery.addEventListener('change', (e) => {
      systemPrefersDark.value = e.matches
    })
  }

  // 切换侧边栏折叠
  function toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value
  }

  // 持久化
  watch(themeMode, (val) => {
    saveData(STORAGE_KEYS.THEME_MODE, val)
  })

  watch(isSidebarCollapsed, (val) => {
    saveData(STORAGE_KEYS.SIDEBAR_COLLAPSED, val)
  })

  // 主题变化时应用
  watch(isDark, () => {
    applyTheme()
  })

  // 初始化
  function init() {
    initSystemThemeListener()
    applyTheme()
  }

  return {
    themeMode,
    isSidebarCollapsed,
    isDark,
    modeLabel,
    cycleThemeMode,
    toggleSidebar,
    init,
    applyTheme
  }
})
```

**与用户端主题 Store 的对比**：

| 维度 | 用户端 (ai-fast-web-user) | 管理端 (ai-fast-web-admin) |
|------|--------------------------|---------------------------|
| 模式 | 亮色/暗色 二选一 | 亮色/暗色/跟随系统 三选一 |
| 状态 | `isDark: ref` | `themeMode: ref` + `isDark: computed` |
| 切换 | `toggleTheme()` 取反 | `cycleThemeMode()` 三态循环 |
| 系统监听 | 无 | `matchMedia` + `addEventListener` |
| 侧边栏 | 无 | `isSidebarCollapsed` + 持久化 |

---

## 7. 依赖关系

### 7.1 前置依赖

| 依赖 | 说明 |
|------|------|
| 无 | 本特性为独立开发，不依赖其他特性 |

### 7.2 后续依赖

| 特性 | 说明 |
|------|------|
| 真实 API 接入 | 当前数据为 JSON mock，后续接入真实 API 时 Store 层需适配 |
| 权限管理 | 当前仅单一 admin 角色，后续可能需要角色权限路由 |
| 国际化 | 当前仅中文，后续可能需要 i18n 支持 |

### 7.3 代码库依赖

| 代码库 | 路径 | 说明 |
|--------|------|------|
| ai-fast-web-admin | `ai-fast-web/ai-fast-web-admin/` | 唯一涉及的代码库 |
| ai-fast-web-user | `ai-fast-web/ai-fast-web-user/` | CSS 变量体系参考，无代码依赖 |

### 7.4 第三方依赖

| 包名 | 版本 | 用途 | 是否新增 | 当前状态 |
|------|------|------|:--------:|:--------:|
| element-plus | ^2.6.1 | UI 组件库 | 否 | 已安装 |
| @element-plus/icons-vue | ^2.3.1 | 图标库 | 否 | 已安装 |
| echarts | ^5.5.0 | 图表库 | 否 | 已安装未使用 |
| vue | ^3.4.21 | 核心框架 | 否 | 已安装 |
| vue-router | ^4.3.0 | 路由 | 否 | 已安装 |
| pinia | ^2.1.7 | 状态管理 | 否 | 已安装 |
| sass | ^1.71.1 | CSS 预处理 | 否 | 已安装 |

> **技术决策**：不引入任何新的第三方依赖。所有功能通过 Element Plus 组件 + ECharts + 原生 CSS 变量 + Pinia 实现。

---

## 8. 实施顺序与开发计划

按照依赖关系和优先级，建议以下实施顺序：

| 阶段 | 内容 | 涉及文件 | 依赖 |
|:----:|------|----------|------|
| **P0-1** | CSS 变量体系 + 主题 Store + 持久化工具 | `main.scss`、`stores/theme.js`、`utils/persistence.js`、`main.js` | 无 |
| **P0-2** | 登录页 | `views/Login.vue` | P0-1 |
| **P0-3** | 布局框架 | `views/Layout.vue` | P0-1 |
| **P0-4** | 公共组件 | `components/StatCard.vue`、`StatusTag.vue`、`SearchFilter.vue` | P0-1 |
| **P1-1** | 仪表盘 | `views/Dashboard.vue` | P0-3、P0-4 |
| **P1-2** | 内容管理 | `views/ContentManage.vue` | P0-3、P0-4 |
| **P1-3** | 内容编辑 | `views/ContentEdit.vue` | P0-3 |
| **P1-4** | 内容审核 | `views/ContentReview.vue` | P0-3、P0-4 |
| **P1-5** | 用户管理 | `views/UserManage.vue` | P0-3、P0-4 |
| **P1-6** | 系统配置 | `views/SystemSettings.vue` | P0-3 |
| **P2** | Store 持久化改造 | `stores/content.js`、`stores/userManage.js`、`stores/stats.js` | P0-1 |
| **P3** | 响应式适配 | 所有页面 | P1 全部 |

---

## 9. 完成规范 (DoD)

> **状态说明**：
> - **已完成**：✅ 该功能点已实现，无需额外开发
> - **部分完成**：🟡 该功能点部分实现，需进一步完善
> - **待实现**：❌ 该功能点尚未实现，需要在开发阶段实现

### 9.1 核心功能

| 编号 | 完成点 | 说明 | 状态 | 完成状态说明 |
|------|--------|------|------|------------|
| 9.1.1 | CSS 变量体系 | main.scss 建立完整的 Design Token 体系（背景/文字/边框/强调/阴影/圆角/动效/专用 Token），支持 `:root` 和 `html.dark` 双主题 | ❌ | 当前仅有基础重置样式，无变量体系（admin-G3） |
| 9.1.2 | Element Plus 暗色配置 | main.js 引入 dark/css-vars.css，main.scss 覆盖 `--el-*` 变量 | ❌ | 当前未配置暗色模式（admin-G4） |
| 9.1.3 | 主题 Store | stores/theme.js 实现三模式切换（亮/暗/跟随系统）+ localStorage 持久化 + 系统偏好监听 | ❌ | 当前无主题 Store（admin-G2） |
| 9.1.4 | 持久化工具 | utils/persistence.js 提供统一的 localStorage 读写接口 | ❌ | 当前无 utils 目录（admin-G7） |
| 9.1.5 | Store 持久化改造 | content/userManage/stats Store 关键数据持久化 | ❌ | 仅 admin token 持久化（admin-G5） |
| 9.1.6 | Login.vue | 管理员登录页面，品牌视觉 + Mock 验证 | ❌ | 文件缺失（admin-G1） |
| 9.1.7 | Layout.vue | 后台布局框架，可折叠侧边栏 + 顶栏 + 主题切换 | ❌ | 文件缺失（admin-G1） |
| 9.1.8 | Dashboard.vue | 数据统计仪表盘，4 统计卡片 + ECharts 图表 | ❌ | 文件缺失（admin-G1） |
| 9.1.9 | ContentManage.vue | 内容列表管理，搜索筛选 + 表格 + 状态标签 | ❌ | 文件缺失（admin-G1） |
| 9.1.10 | ContentEdit.vue | 内容编辑表单，新增/编辑双模式 | ❌ | 文件缺失（admin-G1） |
| 9.1.11 | ContentReview.vue | 内容审核列表 + 抽屉审核面板 | ❌ | 文件缺失（admin-G1） |
| 9.1.12 | UserManage.vue | 用户列表管理，搜索筛选 + 状态切换 | ❌ | 文件缺失（admin-G1） |
| 9.1.13 | SystemSettings.vue | 系统配置表单，分组展示 + 保存/重置 | ❌ | 文件缺失（admin-G1） |
| 9.1.14 | StatCard 组件 | 统计卡片组件，渐变图标 + 大号数字 | ❌ | components 目录缺失（admin-G6） |
| 9.1.15 | StatusTag 组件 | 状态标签组件，4 种状态映射 | ❌ | components 目录缺失（admin-G6） |
| 9.1.16 | SearchFilter 组件 | 搜索筛选条组件，可复用 | ❌ | components 目录缺失（admin-G6） |

### 9.2 用户体验

| 编号 | 完成点 | 说明 | 状态 | 完成状态说明 |
|------|--------|------|------|------------|
| 9.2.1 | 主题切换即时生效 | 切换主题后所有组件和图表配色立即更新 | ❌ | 当前无主题切换 |
| 9.2.2 | ECharts 主题联动 | 图表配色跟随暗色/亮色主题自动切换 | ❌ | ECharts 未使用 |
| 9.2.3 | 操作反馈 | 所有操作（登录/保存/删除/审核）提供 Message 反馈 | ❌ | 无视图组件 |
| 9.2.4 | 确认弹窗 | 删除/退出等危险操作提供确认弹窗 | ❌ | 无视图组件 |
| 9.2.5 | 表单验证 | 必填字段提供验证提示 | ❌ | 无视图组件 |
| 9.2.6 | 数据持久化 | 关键操作后刷新不丢失 | ❌ | 仅 admin token 持久化 |

### 9.3 兼容性

| 编号 | 完成点 | 说明 | 状态 | 完成状态说明 |
|------|--------|------|------|------------|
| 9.3.1 | Element Plus 主题兼容 | 暗色模式下 EP 组件风格统一 | ❌ | 暗色模式未配置（admin-G4） |
| 9.3.2 | 数据结构兼容 | 组件兼容现有 admin.json Mock 数据 | ✅ | 数据结构固定，Store 已封装 |
| 9.3.3 | 移动端基础可用 | 768px 断点基础响应式适配 | ❌ | 无视图组件 |
| 9.3.4 | 纯 JS 兼容 | 新增文件保持纯 JS，不引入 TS | ✅ | 项目为纯 JS，已确认保持一致（admin-G8） |
| 9.3.5 | 路由守卫正常 | 未登录重定向登录页，已登录重定向仪表盘 | ✅ | 路由守卫逻辑已实现 |

---

## 10. 相关文档

- [FT-002-admin-page-development-Feature-Overall.md](./FT-002-admin-page-development-Feature-Overall.md) — 概要设计文档
- [FT-002-admin-page-development-AskMe.md](./FT-002-admin-page-development-AskMe.md) — 需求访谈文档
- [FT-002-admin-page-development-CodeResearch-ai-fast-web-admin.md](./FT-002-admin-page-development-CodeResearch-ai-fast-web-admin.md) — 代码调研总结
- [FT-001-ui-design-optimization-Feature-Detailed.md](../FT-001-ui-design-optimization/FT-001-ui-design-optimization-Feature-Detailed.md) — 用户端 UI 优化详细设计（CSS 变量体系参考）
- [ASDM-ProductPlanning](../../ASDM-ProductPlanning.md) — ASDM 产品规划总览
- [ai-fast-web-admin 代码](../../../ai-fast-web/ai-fast-web-admin/) — 管理端前端代码库
- [ai-fast-web-user 代码](../../../ai-fast-web/ai-fast-web-user/) — 用户端前端代码库（主题系统参考）

---

**文档版本**：1.0.0
**创建日期**：2026-06-02
**最后更新**：2026-06-02
**维护者**：meiguangxian
