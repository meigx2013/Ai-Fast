<template>
  <div class="layout-page">
    <!-- 移动端遮罩 -->
    <div
      v-if="isMobile && !themeStore.isSidebarCollapsed"
      class="sidebar-overlay"
      @click="themeStore.isSidebarCollapsed = true"
    ></div>

    <!-- 侧边栏 -->
    <aside
      class="sidebar"
      :class="{ 'is-collapsed': themeStore.isSidebarCollapsed, 'is-mobile': isMobile }"
      :style="{ width: isMobile ? '220px' : (themeStore.isSidebarCollapsed ? 'var(--sidebar-collapsed-width)' : 'var(--sidebar-width)') }"
    >
      <!-- Logo -->
      <div class="sidebar-logo" @click="router.push('/dashboard')">
        <div class="logo-icon-sm">
          <el-icon :size="20"><Monitor /></el-icon>
        </div>
        <transition name="fade">
          <span v-if="!themeStore.isSidebarCollapsed || isMobile" class="logo-text">AI Fast</span>
        </transition>
      </div>

      <!-- 菜单 -->
      <el-menu
        :default-active="activeMenu"
        :collapse="themeStore.isSidebarCollapsed && !isMobile"
        :collapse-transition="false"
        router
        class="sidebar-menu"
        background-color="transparent"
        :text-color="'var(--text-secondary)'"
        :active-text-color="'var(--accent-primary)'"
      >
        <el-menu-item
          v-for="route in menuRoutes"
          :key="route.path"
          :index="'/' + route.path"
        >
          <el-icon><component :is="route.meta.icon" /></el-icon>
          <template #title>{{ route.meta.title }}</template>
        </el-menu-item>
      </el-menu>

      <!-- 折叠按钮 -->
      <div class="sidebar-footer" v-if="!isMobile">
        <div class="collapse-btn" @click="themeStore.toggleSidebar()">
          <el-icon :size="16">
            <DArrowLeft v-if="!themeStore.isSidebarCollapsed" />
            <DArrowRight v-else />
          </el-icon>
        </div>
      </div>
    </aside>

    <!-- 主区域 -->
    <div class="main-area" :class="{ 'is-collapsed': themeStore.isSidebarCollapsed && !isMobile }">
      <!-- 顶栏 -->
      <header class="header">
        <div class="header-left">
          <!-- 移动端汉堡菜单 -->
          <el-icon
            v-if="isMobile"
            class="hamburger-icon"
            @click="themeStore.isSidebarCollapsed = !themeStore.isSidebarCollapsed"
          >
            <Expand />
          </el-icon>
          <!-- 面包屑 -->
          <el-breadcrumb separator="/" class="breadcrumb">
            <el-breadcrumb-item :to="{ path: '/dashboard' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item v-if="currentRoute.meta?.title && currentRoute.name !== 'Dashboard'">
              {{ currentRoute.meta.title }}
            </el-breadcrumb-item>
          </el-breadcrumb>
        </div>

        <div class="header-right">
          <!-- 主题切换 -->
          <el-tooltip :content="themeStore.modeLabel" placement="bottom">
            <el-button class="theme-btn" circle @click="themeStore.cycleThemeMode()">
              <el-icon :size="16">
                <Sunny v-if="themeStore.themeMode === 'light'" />
                <Moon v-else-if="themeStore.themeMode === 'dark'" />
                <Monitor v-else />
              </el-icon>
            </el-button>
          </el-tooltip>

          <!-- 管理员头像 -->
          <el-dropdown trigger="click" @command="handleCommand">
            <div class="admin-info">
              <el-avatar :size="32" :src="adminStore.adminInfo?.avatar">
                <el-icon :size="16"><User /></el-icon>
              </el-avatar>
              <span class="admin-name" v-if="!isMobile">{{ adminStore.adminInfo?.name || '管理员' }}</span>
              <el-icon class="dropdown-arrow"><ArrowDown /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile" disabled>
                  <el-icon><User /></el-icon>个人信息
                </el-dropdown-item>
                <el-dropdown-item command="logout" divided>
                  <el-icon><SwitchButton /></el-icon>退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>

      <!-- 内容区 -->
      <main class="content-area">
        <router-view v-slot="{ Component }">
          <transition name="fade-scale" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAdminStore } from '@/stores/admin'
import { useThemeStore } from '@/stores/theme'
import { ElMessageBox, ElMessage } from 'element-plus'
import {
  Sunny, Moon, Monitor, User, Expand,
  DArrowLeft, DArrowRight, ArrowDown, SwitchButton
} from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const adminStore = useAdminStore()
const themeStore = useThemeStore()

const isMobile = ref(false)

// 当前路由
const currentRoute = computed(() => route)

// 当前激活菜单
const activeMenu = computed(() => {
  // 对于 /content/edit/:id 这样的路由，激活 /content
  const path = route.path
  if (path.startsWith('/content/edit')) return '/content'
  return path
})

// 菜单路由（过滤 hidden）
const menuRoutes = computed(() => {
  const layoutRoute = router.options.routes.find(r => r.path === '/')
  return layoutRoute?.children?.filter(r => !r.meta?.hidden) || []
})

// 初始化管理员信息
onMounted(() => {
  adminStore.initAdmin()
  checkMobile()
  window.addEventListener('resize', checkMobile)
})

onUnmounted(() => {
  window.removeEventListener('resize', checkMobile)
})

function checkMobile() {
  isMobile.value = window.innerWidth <= 768
  if (isMobile.value) {
    themeStore.isSidebarCollapsed = true
  }
}

async function handleCommand(command) {
  if (command === 'logout') {
    try {
      await ElMessageBox.confirm('确认退出登录？', '提示', {
        confirmButtonText: '确认',
        cancelButtonText: '取消',
        type: 'warning'
      })
      adminStore.logout()
      ElMessage.success('已退出登录')
      router.push('/login')
    } catch {
      // 取消
    }
  }
}
</script>

<style lang="scss" scoped>
.layout-page {
  display: flex;
  height: 100vh;
  background: var(--bg-secondary);
  overflow: hidden;
}

/* ===== 侧边栏 ===== */
.sidebar {
  height: 100vh;
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
  transition: width var(--duration-normal) var(--ease-standard);
  flex-shrink: 0;
  overflow: hidden;
  z-index: 100;

  &.is-mobile {
    position: fixed;
    left: 0;
    top: 0;
    transform: translateX(-100%);
    transition: transform var(--duration-normal) var(--ease-standard);

    &:not(.is-collapsed) {
      transform: translateX(0);
    }
  }
}

.sidebar-logo {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px;
  height: var(--header-height);
  cursor: pointer;
  border-bottom: 1px solid var(--border-light);
  flex-shrink: 0;
}

.logo-icon-sm {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: var(--accent-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  flex-shrink: 0;
}

.logo-text {
  font-size: 16px;
  font-weight: 700;
  color: var(--text-primary);
  white-space: nowrap;
}

/* 菜单 */
.sidebar-menu {
  flex: 1;
  overflow-y: auto;
  border-right: none !important;
  padding: 8px;

  &:not(.el-menu--collapse) {
    width: 100%;
  }

  :deep(.el-menu-item) {
    border-radius: var(--radius-sm);
    margin-bottom: 4px;
    height: 44px;
    line-height: 44px;

    &.is-active {
      background: var(--accent-primary-bg) !important;
      font-weight: 600;
    }

    &:hover:not(.is-active) {
      background: var(--bg-card-hover) !important;
    }
  }
}

/* 折叠按钮 */
.sidebar-footer {
  padding: 12px;
  border-top: 1px solid var(--border-light);
  flex-shrink: 0;
}

.collapse-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 36px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  color: var(--text-tertiary);
  transition: all var(--duration-fast) var(--ease-standard);

  &:hover {
    background: var(--bg-card-hover);
    color: var(--text-secondary);
  }
}

/* ===== 移动端遮罩 ===== */
.sidebar-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 99;
  transition: opacity var(--duration-normal) var(--ease-standard);
}

/* ===== 主区域 ===== */
.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-width: 0;
  transition: margin-left var(--duration-normal) var(--ease-standard);

  &.is-mobile {
    margin-left: 0 !important;
  }
}

/* ===== 顶栏 ===== */
.header {
  height: var(--header-height);
  background: var(--bg-header);
  border-bottom: 1px solid var(--border-color);
  backdrop-filter: blur(12px);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--content-padding);
  flex-shrink: 0;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.hamburger-icon {
  font-size: 20px;
  cursor: pointer;
  color: var(--text-secondary);
  transition: color var(--duration-fast) var(--ease-standard);

  &:hover {
    color: var(--accent-primary);
  }
}

.breadcrumb {
  :deep(.el-breadcrumb__inner) {
    color: var(--text-secondary);
  }

  :deep(.el-breadcrumb__inner.is-link:hover) {
    color: var(--accent-primary);
  }
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

/* 主题按钮 */
.theme-btn {
  border: none;
  background: var(--bg-tertiary);
  color: var(--text-secondary);
  transition: all var(--duration-fast) var(--ease-standard);

  &:hover {
    color: var(--accent-primary);
    background: var(--accent-primary-bg);
  }
}

/* 管理员信息 */
.admin-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: var(--radius-sm);
  transition: background var(--duration-fast) var(--ease-standard);

  &:hover {
    background: var(--bg-tertiary);
  }
}

.admin-name {
  font-size: 14px;
  color: var(--text-primary);
  font-weight: 500;
}

.dropdown-arrow {
  font-size: 12px;
  color: var(--text-tertiary);
}

/* ===== 内容区 ===== */
.content-area {
  flex: 1;
  padding: var(--content-padding);
  overflow-y: auto;
  background: var(--bg-secondary);
}
</style>
