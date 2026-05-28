<template>
  <div class="auth-page">
    <!-- Left: Brand Panel -->
    <div class="brand-panel">
      <div class="brand-content">
        <div class="brand-logo">
          <div class="logo-icon">
            <el-icon :size="32"><Cpu /></el-icon>
          </div>
          <span>AI Fast</span>
        </div>
        <h1 class="brand-title">探索 AI 无限可能</h1>
        <p class="brand-subtitle">AI Agent 与工作流教学分享平台，助力每个人掌握 AI 时代的核心技能</p>

        <div class="brand-features">
          <div class="feature-item">
            <div class="feature-icon">
              <el-icon :size="20"><Monitor /></el-icon>
            </div>
            <div class="feature-text">
              <h4>智能体广场</h4>
              <p>发现和使用强大的 AI 智能体</p>
            </div>
          </div>
          <div class="feature-item">
            <div class="feature-icon">
              <el-icon :size="20"><Connection /></el-icon>
            </div>
            <div class="feature-text">
              <h4>工作流中心</h4>
              <p>学习和构建自动化工作流</p>
            </div>
          </div>
          <div class="feature-item">
            <div class="feature-icon">
              <el-icon :size="20"><FolderOpened /></el-icon>
            </div>
            <div class="feature-text">
              <h4>资源库</h4>
              <p>获取教程、模板和开发工具</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Floating decorative elements -->
      <div class="deco deco-1"></div>
      <div class="deco deco-2"></div>
      <div class="deco deco-3"></div>
    </div>

    <!-- Right: Form Panel -->
    <div class="form-panel">
      <div class="form-wrapper">
        <div class="form-header">
          <h2>欢迎回来</h2>
          <p>登录您的账户，探索更多智能体和工作流</p>
        </div>

        <el-form
          ref="formRef"
          :model="formData"
          :rules="rules"
          class="auth-form"
          @submit.prevent="handleLogin"
        >
          <el-form-item prop="username">
            <el-input
              v-model="formData.username"
              placeholder="请输入用户名"
              :prefix-icon="User"
              size="large"
            />
          </el-form-item>

          <el-form-item prop="password">
            <el-input
              v-model="formData.password"
              type="password"
              placeholder="请输入密码"
              :prefix-icon="Lock"
              size="large"
              show-password
            />
          </el-form-item>

          <el-form-item>
            <div class="form-options">
              <el-checkbox v-model="rememberMe">记住我</el-checkbox>
              <el-link type="primary">忘记密码？</el-link>
            </div>
          </el-form-item>

          <el-form-item>
            <el-button
              type="primary"
              size="large"
              class="auth-btn"
              :loading="loading"
              @click="handleLogin"
            >
              登录
            </el-button>
          </el-form-item>
        </el-form>

        <div class="form-footer">
          <span>还没有账户？</span>
          <el-link type="primary" @click="$router.push('/register')">立即注册</el-link>
          <span class="footer-divider">|</span>
          <router-link to="/" class="back-home-link">
            <el-icon><Back /></el-icon>
            <span>返回首页</span>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { User, Lock, Cpu, Monitor, Connection, FolderOpened, Back } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const router = useRouter()
const userStore = useUserStore()

const formRef = ref(null)
const loading = ref(false)
const rememberMe = ref(false)

const formData = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少6位', trigger: 'blur' }
  ]
}

async function handleLogin() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true

  setTimeout(() => {
    const result = userStore.login(formData.username, formData.password)

    if (result.success) {
      ElMessage.success('登录成功')
      router.push('/home')
    } else {
      ElMessage.error(result.message)
    }

    loading.value = false
  }, 500)
}
</script>

<style lang="scss" scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  background: var(--bg-secondary);
}

/* ===== Brand Panel ===== */
.brand-panel {
  width: 50%;
  background: var(--accent-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px;
  position: relative;
  overflow: hidden;

  .brand-content {
    position: relative;
    z-index: 2;
    max-width: 480px;
    color: #fff;
  }

  .brand-logo {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 40px;

    .logo-icon {
      width: 48px;
      height: 48px;
      border-radius: var(--radius-md);
      background: rgba(255, 255, 255, 0.2);
      backdrop-filter: blur(8px);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
    }

    span {
      font-size: 24px;
      font-weight: 700;
      color: #fff;
    }
  }

  .brand-title {
    font-size: 36px;
    font-weight: 700;
    line-height: 1.3;
    margin-bottom: 16px;
  }

  .brand-subtitle {
    font-size: 16px;
    line-height: 1.8;
    opacity: 0.85;
    margin-bottom: 48px;
  }

  .brand-features {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }

  .feature-item {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 16px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: var(--radius-md);
    backdrop-filter: blur(8px);
    transition: background var(--duration-fast) var(--ease-standard);

    &:hover {
      background: rgba(255, 255, 255, 0.18);
    }

    .feature-icon {
      width: 44px;
      height: 44px;
      border-radius: var(--radius-sm);
      background: rgba(255, 255, 255, 0.15);
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .feature-text {
      h4 {
        font-size: 15px;
        font-weight: 600;
        margin-bottom: 2px;
      }

      p {
        font-size: 13px;
        opacity: 0.8;
      }
    }
  }

  /* Decorative circles */
  .deco {
    position: absolute;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.08);
  }

  .deco-1 {
    width: 400px;
    height: 400px;
    top: -100px;
    right: -100px;
    animation: float 8s ease-in-out infinite;
  }

  .deco-2 {
    width: 300px;
    height: 300px;
    bottom: -80px;
    left: -60px;
    animation: float 10s ease-in-out infinite reverse;
  }

  .deco-3 {
    width: 150px;
    height: 150px;
    top: 50%;
    right: 15%;
    animation: float 6s ease-in-out infinite 2s;
  }
}

@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-20px); }
}

/* ===== Form Panel ===== */
.form-panel {
  width: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
  background: var(--bg-primary);
}

.form-wrapper {
  width: 100%;
  max-width: 420px;
}

.form-header {
  margin-bottom: 36px;

  h2 {
    font-size: 28px;
    font-weight: 700;
    color: var(--text-primary);
    margin-bottom: 8px;
  }

  p {
    color: var(--text-tertiary);
    font-size: 14px;
  }
}

.auth-form {
  .form-options {
    display: flex;
    justify-content: space-between;
    width: 100%;
  }

  .auth-btn {
    width: 100%;
    height: 44px;
    font-size: 16px;
    font-weight: 600;
    background: var(--accent-gradient);
    border: none;
    border-radius: var(--radius-sm);
    transition: all var(--duration-fast) var(--ease-standard);

    &:hover {
      opacity: 0.9;
      box-shadow: var(--shadow-glow);
    }
  }
}

.form-footer {
  text-align: center;
  margin-top: 28px;
  color: var(--text-tertiary);
  font-size: 14px;

  .el-link {
    margin-left: 4px;
  }

  .footer-divider {
    margin: 0 12px;
    color: var(--border-color);
  }

  .back-home-link {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    color: var(--text-tertiary);
    font-size: 14px;
    transition: color var(--duration-fast) var(--ease-standard);

    &:hover {
      color: var(--accent-primary);
    }
  }
}

/* ===== Responsive ===== */
@media (max-width: 768px) {
  .auth-page {
    flex-direction: column;
  }

  .brand-panel {
    display: none;
  }

  .form-panel {
    width: 100%;
    min-height: 100vh;
    padding: 24px;
  }
}
</style>
