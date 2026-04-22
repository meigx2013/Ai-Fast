<template>
  <div class="layout">
    <header class="header">
      <div class="header-content">
        <div class="logo" @click="$router.push('/home')">
          <el-icon :size="28"><Cpu /></el-icon>
          <span class="logo-text">AI Fast</span>
        </div>
        
        <div class="search-bar">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索工作流..."
            :prefix-icon="Search"
            clearable
            @input="handleSearch"
          />
        </div>
        
        <nav class="nav-menu">
          <router-link to="/home" class="nav-item">首页</router-link>
          <router-link to="/user" class="nav-item" v-if="userStore.isLoggedIn">个人中心</router-link>
        </nav>
        
        <div class="user-area">
          <template v-if="userStore.isLoggedIn">
            <el-dropdown trigger="click">
              <div class="user-avatar">
                <el-avatar :size="36" :src="userStore.userInfo?.avatar">
                  <el-icon><UserFilled /></el-icon>
                </el-avatar>
              </div>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item @click="$router.push('/user')">
                    <el-icon><User /></el-icon>个人中心
                  </el-dropdown-item>
                  <el-dropdown-item @click="handleLogout">
                    <el-icon><SwitchButton /></el-icon>退出登录
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </template>
          <template v-else>
            <el-button type="primary" @click="$router.push('/login')">登录</el-button>
            <el-button @click="$router.push('/register')">注册</el-button>
          </template>
        </div>
      </div>
    </header>
    
    <main class="main-content">
      <router-view />
    </main>
    
    <footer class="footer">
      <div class="footer-content">
        <p>&copy; 2024 AI Fast - AI Agent与工作流教学分享平台</p>
        <div class="footer-links">
          <a href="#">关于我们</a>
          <a href="#">联系方式</a>
          <a href="#">帮助中心</a>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useWorkflowStore } from '@/stores/workflow'
import { Search, UserFilled, User, SwitchButton, Cpu } from '@element-plus/icons-vue'

const router = useRouter()
const userStore = useUserStore()
const workflowStore = useWorkflowStore()

const searchKeyword = ref('')

onMounted(() => {
  userStore.initUser()
})

function handleSearch() {
  workflowStore.setSearchKeyword(searchKeyword.value)
}

function handleLogout() {
  userStore.logout()
  router.push('/home')
}
</script>

<style lang="scss" scoped>
.layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.header {
  background: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  position: sticky;
  top: 0;
  z-index: 100;
  
  .header-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 24px;
    height: 64px;
    display: flex;
    align-items: center;
    gap: 32px;
  }
}

.logo {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  color: #409eff;
  
  .logo-text {
    font-size: 20px;
    font-weight: 600;
  }
}

.search-bar {
  flex: 1;
  max-width: 400px;
  
  :deep(.el-input__wrapper) {
    border-radius: 20px;
  }
}

.nav-menu {
  display: flex;
  gap: 24px;
  
  .nav-item {
    color: #606266;
    font-size: 15px;
    padding: 8px 0;
    border-bottom: 2px solid transparent;
    transition: all 0.3s;
    
    &:hover, &.router-link-active {
      color: #409eff;
      border-bottom-color: #409eff;
    }
  }
}

.user-area {
  display: flex;
  align-items: center;
  gap: 12px;
  
  .user-avatar {
    cursor: pointer;
    transition: transform 0.3s;
    
    &:hover {
      transform: scale(1.05);
    }
  }
}

.main-content {
  flex: 1;
  max-width: 1400px;
  width: 100%;
  margin: 0 auto;
  padding: 24px;
}

.footer {
  background: #f5f7fa;
  border-top: 1px solid #e4e7ed;
  padding: 24px 0;
  margin-top: auto;
  
  .footer-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 24px;
    text-align: center;
    
    p {
      color: #909399;
      margin-bottom: 12px;
    }
    
    .footer-links {
      display: flex;
      justify-content: center;
      gap: 24px;
      
      a {
        color: #606266;
        font-size: 14px;
        
        &:hover {
          color: #409eff;
        }
      }
    }
  }
}
</style>
