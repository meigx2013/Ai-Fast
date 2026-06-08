<template>
  <div class="login-page">
    <!-- 装饰元素 -->
    <div class="login-decor login-decor-1"></div>
    <div class="login-decor login-decor-2"></div>
    <div class="login-decor login-decor-3"></div>

    <!-- 登录卡片 -->
    <div class="login-card fade-in-up">
      <!-- Logo 区域 -->
      <div class="login-logo">
        <div class="logo-icon">
          <el-icon :size="28"><Monitor /></el-icon>
        </div>
        <h1 class="logo-title">AI Fast</h1>
        <p class="logo-subtitle">管理后台</p>
      </div>

      <!-- 表单 -->
      <el-form ref="formRef" :model="formData" :rules="formRules" class="login-form" @keyup.enter="handleLogin">
        <el-form-item prop="username">
          <el-input
            v-model="formData.username"
            placeholder="请输入用户名"
            size="large"
            :prefix-icon="User"
          />
        </el-form-item>
        <el-form-item prop="password">
          <el-input
            v-model="formData.password"
            type="password"
            placeholder="请输入密码"
            size="large"
            :prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            class="login-btn"
            :loading="loading"
            @click="handleLogin"
          >
            登 录
          </el-button>
        </el-form-item>
      </el-form>

      <!-- 提示 -->
      <div class="login-hint">
        <span>默认账号: admin</span>
        <span class="hint-divider">|</span>
        <span>默认密码: admin123</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminStore } from '@/stores/admin'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'

const router = useRouter()
const adminStore = useAdminStore()

const formRef = ref(null)
const loading = ref(false)
const formData = ref({
  username: '',
  password: ''
})

const formRules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

onMounted(() => {
  if (adminStore.isLoggedIn) {
    router.push('/dashboard')
  }
})

async function handleLogin() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  // 模拟网络延迟
  await new Promise(resolve => setTimeout(resolve, 500))

  const result = adminStore.login(formData.value.username, formData.value.password)
  loading.value = false

  if (result.success) {
    ElMessage.success('登录成功')
    router.push('/dashboard')
  } else {
    ElMessage.error(result.message || '用户名或密码错误')
  }
}
</script>

<style lang="scss" scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--accent-gradient);
  position: relative;
  overflow: hidden;
}

/* 装饰圆 */
.login-decor {
  position: absolute;
  border-radius: 50%;
  opacity: 0.12;
  filter: blur(60px);
  pointer-events: none;
}

.login-decor-1 {
  width: 400px;
  height: 400px;
  background: #ffffff;
  top: -100px;
  right: -80px;
}

.login-decor-2 {
  width: 300px;
  height: 300px;
  background: #a78bfa;
  bottom: -60px;
  left: -60px;
}

.login-decor-3 {
  width: 200px;
  height: 200px;
  background: #818cf8;
  top: 50%;
  left: 10%;
}

/* 登录卡片 */
.login-card {
  width: 420px;
  padding: 48px 40px;
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-xl);
  position: relative;
  z-index: 1;
}

/* Logo */
.login-logo {
  text-align: center;
  margin-bottom: 36px;
}

.logo-icon {
  width: 56px;
  height: 56px;
  border-radius: var(--radius-md);
  background: var(--accent-gradient);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  margin-bottom: 16px;
}

.logo-title {
  font-size: 24px;
  font-weight: 700;
  color: var(--text-primary);
  margin: 0 0 4px;
}

.logo-subtitle {
  font-size: 14px;
  color: var(--text-tertiary);
  margin: 0;
}

/* 表单 */
.login-form {
  :deep(.el-input__wrapper) {
    border-radius: var(--radius-sm);
  }

  :deep(.el-form-item) {
    margin-bottom: 20px;
  }
}

.login-btn {
  width: 100%;
  background: var(--accent-gradient);
  border: none;
  border-radius: var(--radius-sm);
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 4px;
  transition: all var(--duration-fast) var(--ease-standard);

  &:hover {
    background: var(--accent-gradient-hover);
    box-shadow: var(--shadow-glow);
    transform: translateY(-1px);
  }

  &:active {
    transform: translateY(0);
  }
}

/* 提示 */
.login-hint {
  text-align: center;
  color: var(--text-tertiary);
  font-size: 12px;
  margin-top: 8px;

  .hint-divider {
    margin: 0 8px;
    opacity: 0.5;
  }
}

/* 响应式 */
@media (max-width: 768px) {
  .login-card {
    width: 90vw;
    padding: 32px 24px;
  }

  .logo-title {
    font-size: 20px;
  }
}
</style>
