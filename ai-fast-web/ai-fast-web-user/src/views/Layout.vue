<template>
  <div class="layout">
    <header class="header" :class="{ 'header-scrolled': isHeaderScrolled }">
      <div class="header-inner">
        <div class="logo" @click="$router.push('/')">
          <div class="logo-icon">
            <el-icon :size="24"><Cpu /></el-icon>
          </div>
          <span class="logo-text" v-show="!isHeaderScrolled">AI Fast</span>
        </div>

        <!-- Desktop nav -->
        <nav class="nav-menu">
          <router-link to="/" class="nav-item" :class="{ active: $route.path === '/' || $route.path === '/home' }">
            <el-icon><HomeFilled /></el-icon>
            <span>首页</span>
          </router-link>
          <router-link to="/agents" class="nav-item">
            <el-icon><Monitor /></el-icon>
            <span>智能体</span>
          </router-link>
          <router-link to="/workflows" class="nav-item">
            <el-icon><Connection /></el-icon>
            <span>工作流</span>
          </router-link>
          <router-link to="/resources" class="nav-item">
            <el-icon><FolderOpened /></el-icon>
            <span>资源库</span>
          </router-link>
          <router-link to="/user" class="nav-item">
            <el-icon><UserFilled /></el-icon>
            <span>个人中心</span>
          </router-link>
        </nav>

        <div class="header-actions">
          <div class="theme-toggle" @click="themeStore.toggleTheme">
            <el-icon :size="18">
              <Sunny v-if="themeStore.isDark" />
              <Moon v-else />
            </el-icon>
          </div>

          <template v-if="userStore.isLoggedIn">
            <el-dropdown trigger="click" @command="handleCommand">
              <div class="user-avatar-wrapper">
                <el-avatar :size="34" :src="userStore.userInfo?.avatar">
                  <el-icon><UserFilled /></el-icon>
                </el-avatar>
                <span class="user-name">{{ userStore.userInfo?.name }}</span>
              </div>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="profile">
                    <el-icon><User /></el-icon>个人中心
                  </el-dropdown-item>
                  <el-dropdown-item command="logout" divided>
                    <el-icon><SwitchButton /></el-icon>退出登录
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </template>
          <template v-else>
            <el-button type="primary" round @click="$router.push('/login')">
              登录
            </el-button>
            <el-button round @click="$router.push('/register')">
              注册
            </el-button>
          </template>

          <!-- Mobile hamburger -->
          <div class="hamburger" @click="drawerVisible = true">
            <el-icon :size="22"><Operation /></el-icon>
          </div>
        </div>
      </div>
    </header>

    <!-- Mobile Drawer -->
    <el-drawer
      v-model="drawerVisible"
      direction="rtl"
      size="280px"
      :show-close="false"
      class="mobile-drawer"
    >
      <template #header>
        <div class="drawer-logo">
          <div class="logo-icon">
            <el-icon :size="20"><Cpu /></el-icon>
          </div>
          <span>AI Fast</span>
        </div>
      </template>
      <nav class="drawer-nav">
        <router-link to="/" class="drawer-nav-item" @click="drawerVisible = false">
          <el-icon><HomeFilled /></el-icon>
          <span>首页</span>
        </router-link>
        <router-link to="/agents" class="drawer-nav-item" @click="drawerVisible = false">
          <el-icon><Monitor /></el-icon>
          <span>智能体</span>
        </router-link>
        <router-link to="/workflows" class="drawer-nav-item" @click="drawerVisible = false">
          <el-icon><Connection /></el-icon>
          <span>工作流</span>
        </router-link>
        <router-link to="/resources" class="drawer-nav-item" @click="drawerVisible = false">
          <el-icon><FolderOpened /></el-icon>
          <span>资源库</span>
        </router-link>
        <router-link to="/user" class="drawer-nav-item" @click="drawerVisible = false">
          <el-icon><UserFilled /></el-icon>
          <span>个人中心</span>
        </router-link>
      </nav>
    </el-drawer>

    <main class="main-content">
      <router-view v-slot="{ Component, route }">
        <transition :name="route.meta.transition || 'fade'" mode="out-in">
          <component :is="Component" :key="route.path" />
        </transition>
      </router-view>
    </main>

    <footer class="footer">
      <div class="footer-inner">
        <div class="footer-top">
          <div class="footer-brand">
            <div class="footer-logo">
              <el-icon :size="20"><Cpu /></el-icon>
              <span>AI Fast</span>
            </div>
            <p class="footer-desc">AI Agent 与工作流教学分享平台，助力每个人掌握AI时代的核心技能</p>
          </div>
          <div class="footer-links-group">
            <div class="footer-col">
              <h4>平台</h4>
              <a href="#">智能体</a>
              <a href="#">工作流</a>
              <a href="#">资源库</a>
              <a href="#">社区</a>
            </div>
            <div class="footer-col">
              <h4>支持</h4>
              <a href="#">帮助中心</a>
              <a href="#">开发文档</a>
              <a href="#">API接口</a>
              <a href="#">常见问题</a>
            </div>
            <div class="footer-col">
              <h4>关于</h4>
              <a href="#">关于我们</a>
              <a href="#">联系方式</a>
              <a href="#">用户协议</a>
              <a href="#">隐私政策</a>
            </div>
          </div>
        </div>
        <div class="footer-bottom">
          <p>&copy; 2024 AI Fast - AI Agent与工作流教学分享平台</p>
          <p class="footer-slogan">探索AI无限可能</p>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useThemeStore } from '@/stores/theme'
import {
  Cpu, HomeFilled, Monitor, Connection, FolderOpened,
  UserFilled, Sunny, Moon, User, SwitchButton, Operation
} from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const router = useRouter()
const userStore = useUserStore()
const themeStore = useThemeStore()

const isHeaderScrolled = ref(false)
const drawerVisible = ref(false)

function handleScroll() {
  isHeaderScrolled.value = window.scrollY > 50
}

onMounted(() => {
  userStore.initUser()
  window.addEventListener('scroll', handleScroll, { passive: true })
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})

function handleCommand(command) {
  if (command === 'profile') {
    router.push('/user')
  } else if (command === 'logout') {
    userStore.logout()
    ElMessage.success('已退出登录')
    router.push('/')
  }
}
</script>

<style lang="scss" scoped>
.layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: var(--bg-secondary);
}

/* ===== Header ===== */
.header {
  position: sticky;
  top: 0;
  z-index: var(--layer-sticky);
  background: var(--bg-header);
  backdrop-filter: blur(var(--header-blur));
  -webkit-backdrop-filter: blur(var(--header-blur));
  border-bottom: 1px solid var(--border-color);
  transition: all var(--duration-fast) var(--ease-standard);

  .header-inner {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 32px;
    height: 68px;
    display: flex;
    align-items: center;
    gap: 40px;
    transition: height var(--duration-fast) var(--ease-standard);
  }

  /* Scrolled state */
  &.header-scrolled {
    box-shadow: var(--shadow-md);

    .header-inner {
      height: 56px;
    }

    .logo-icon {
      width: 34px;
      height: 34px;
    }
  }
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  flex-shrink: 0;

  .logo-icon {
    width: 40px;
    height: 40px;
    border-radius: var(--radius-md);
    background: var(--accent-gradient);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    transition: all var(--duration-fast) var(--ease-standard);

    &:hover {
      transform: scale(1.05);
    }
  }

  .logo-text {
    font-size: 20px;
    font-weight: 700;
    background: var(--accent-gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    transition: opacity var(--duration-fast) var(--ease-standard);
  }
}

.nav-menu {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: auto;

  .nav-item {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 8px 18px;
    border-radius: var(--radius-xl);
    color: var(--text-secondary);
    font-size: 14px;
    font-weight: 500;
    transition: all var(--duration-fast) var(--ease-standard);
    white-space: nowrap;

    .el-icon {
      font-size: 16px;
    }

    &:hover {
      color: var(--accent-primary);
      background: var(--accent-primary-bg);
    }

    &.active,
    &.router-link-active {
      color: var(--accent-primary);
      background: var(--accent-primary-bg);
    }
  }
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-shrink: 0;

  .theme-toggle {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: var(--text-secondary);
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    transition: all var(--duration-fast) var(--ease-standard);

    &:hover {
      color: var(--accent-primary);
      border-color: var(--accent-primary);
      transform: rotate(15deg);
    }
  }

  .user-avatar-wrapper {
    display: flex;
    align-items: center;
    gap: 8px;
    cursor: pointer;
    padding: 4px 12px 4px 4px;
    border-radius: var(--radius-xl);
    transition: all var(--duration-fast) var(--ease-standard);

    &:hover {
      background: var(--accent-primary-bg);
    }

    .user-name {
      font-size: 14px;
      color: var(--text-primary);
      font-weight: 500;
    }
  }

  .el-button {
    font-weight: 500;
  }

  .hamburger {
    display: none;
    width: 36px;
    height: 36px;
    border-radius: 50%;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: var(--text-secondary);
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    transition: all var(--duration-fast) var(--ease-standard);

    &:hover {
      color: var(--accent-primary);
      border-color: var(--accent-primary);
    }
  }
}

/* ===== Mobile Drawer ===== */
.drawer-logo {
  display: flex;
  align-items: center;
  gap: 10px;

  .logo-icon {
    width: 36px;
    height: 36px;
    border-radius: var(--radius-md);
    background: var(--accent-gradient);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
  }

  span {
    font-size: 18px;
    font-weight: 700;
    background: var(--accent-gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
}

.drawer-nav {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding-top: 8px;

  .drawer-nav-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 16px;
    border-radius: var(--radius-md);
    color: var(--text-secondary);
    font-size: 15px;
    font-weight: 500;
    transition: all var(--duration-fast) var(--ease-standard);

    .el-icon {
      font-size: 18px;
    }

    &:hover,
    &.router-link-active {
      color: var(--accent-primary);
      background: var(--accent-primary-bg);
    }
  }
}

/* ===== Main ===== */
.main-content {
  flex: 1;
  width: 100%;
}

/* ===== Footer ===== */
.footer {
  background: var(--bg-footer);
  margin-top: auto;

  .footer-inner {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 32px;
  }

  .footer-top {
    display: flex;
    justify-content: space-between;
    gap: 60px;
    padding: 48px 0 32px;
    border-bottom: 1px solid var(--footer-divider);
  }

  .footer-brand {
    max-width: 320px;

    .footer-logo {
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--footer-heading);
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 12px;
    }

    .footer-desc {
      font-size: 14px;
      line-height: 1.8;
      color: var(--footer-text);
    }
  }

  .footer-links-group {
    display: flex;
    gap: 60px;
  }

  .footer-col {
    display: flex;
    flex-direction: column;
    gap: 10px;

    h4 {
      color: var(--footer-heading);
      font-size: 14px;
      font-weight: 600;
      margin-bottom: 4px;
    }

    a {
      color: var(--footer-text);
      font-size: 13px;
      transition: color var(--duration-fast) var(--ease-standard);

      &:hover {
        color: var(--footer-link-hover);
      }
    }
  }

  .footer-bottom {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 0;

    p {
      font-size: 13px;
      color: var(--footer-muted);
    }

    .footer-slogan {
      font-size: 13px;
      background: var(--accent-gradient);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      font-weight: 500;
    }
  }
}

/* ===== Responsive ===== */
@media (max-width: 992px) {
  .header .header-inner {
    gap: 16px;
    padding: 0 16px;
  }

  .nav-menu {
    gap: 4px;

    .nav-item {
      padding: 6px 12px;
      font-size: 13px;

      span {
        display: none;
      }
    }
  }

  .footer {
    .footer-top {
      flex-direction: column;
      gap: 32px;
    }

    .footer-links-group {
      gap: 32px;
      flex-wrap: wrap;
    }

    .footer-bottom {
      flex-direction: column;
      gap: 8px;
      text-align: center;
    }
  }
}

@media (max-width: 768px) {
  .header .header-inner {
    height: 56px;
  }

  .nav-menu {
    display: none;
  }

  .header-actions {
    .hamburger {
      display: flex;
    }

    .el-button {
      display: none;
    }

    .user-avatar-wrapper .user-name {
      display: none;
    }
  }
}
</style>
