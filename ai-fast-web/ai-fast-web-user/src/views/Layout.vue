<template>
  <div class="layout">
    <header class="header">
      <div class="header-inner">
        <div class="logo" @click="$router.push('/')">
          <div class="logo-icon">
            <el-icon :size="24"><Cpu /></el-icon>
          </div>
          <span class="logo-text">AI Fast</span>
        </div>

        <nav class="nav-menu">
          <router-link to="/" class="nav-item" :class="{ active: $route.path === '/' }">
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
        </div>
      </div>
    </header>

    <main class="main-content">
      <router-view v-slot="{ Component }">
        <transition name="fade" mode="out-in">
          <component :is="Component" />
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
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useThemeStore } from '@/stores/theme'
import {
  Cpu, HomeFilled, Monitor, Connection, FolderOpened,
  UserFilled, Sunny, Moon, User, SwitchButton
} from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const router = useRouter()
const userStore = useUserStore()
const themeStore = useThemeStore()

onMounted(() => {
  userStore.initUser()
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
  z-index: 100;
  background: var(--bg-header);
  backdrop-filter: blur(var(--header-blur));
  -webkit-backdrop-filter: blur(var(--header-blur));
  border-bottom: 1px solid var(--border-color);
  transition: all 0.3s ease;

  .header-inner {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 32px;
    height: 68px;
    display: flex;
    align-items: center;
    gap: 40px;
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
    transition: transform 0.3s;

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
    transition: all 0.3s ease;
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
    transition: all 0.3s;

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
    transition: all 0.3s;

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
}

/* ===== Main ===== */
.main-content {
  flex: 1;
  width: 100%;
}

/* ===== Footer ===== */
.footer {
  background: var(--bg-footer);
  color: #b0b0cc;
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
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  }

  .footer-brand {
    max-width: 320px;

    .footer-logo {
      display: flex;
      align-items: center;
      gap: 8px;
      color: #fff;
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 12px;
    }

    .footer-desc {
      font-size: 14px;
      line-height: 1.8;
      color: #8080a0;
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
      color: #e8e8f0;
      font-size: 14px;
      font-weight: 600;
      margin-bottom: 4px;
    }

    a {
      color: #8080a0;
      font-size: 13px;
      transition: color 0.3s;

      &:hover {
        color: #a5b4fc;
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
      color: #606080;
    }

    .footer-slogan {
      font-size: 13px;
      background: linear-gradient(135deg, #818cf8, #a78bfa);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      font-weight: 500;
    }
  }
}

/* ===== Page Transition ===== */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
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

  .nav-menu .nav-item span {
    display: inline;
    font-size: 12px;
  }

  .user-avatar-wrapper .user-name {
    display: none;
  }
}
</style>
