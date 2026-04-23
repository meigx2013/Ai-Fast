import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import adminData from '@/data/admin.json'

export const useAdminStore = defineStore('admin', () => {
  const token = ref(localStorage.getItem('admin_token') || '')
  const adminInfo = ref(null)

  const isLoggedIn = computed(() => !!token.value)

  function login(username, password) {
    if (username === 'admin' && password === 'admin123') {
      token.value = 'admin-token-' + Date.now()
      adminInfo.value = adminData.admin
      localStorage.setItem('admin_token', token.value)
      return { success: true }
    }
    return { success: false, message: '用户名或密码错误' }
  }

  function logout() {
    token.value = ''
    adminInfo.value = null
    localStorage.removeItem('admin_token')
  }

  function initAdmin() {
    if (token.value) {
      adminInfo.value = adminData.admin
    }
  }

  return {
    token,
    adminInfo,
    isLoggedIn,
    login,
    logout,
    initAdmin
  }
})
