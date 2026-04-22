import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import userData from '@/data/users.json'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref(null)

  const isLoggedIn = computed(() => !!token.value)

  function login(username, password) {
    if (username && password) {
      token.value = 'mock-token-' + Date.now()
      userInfo.value = userData.currentUser
      localStorage.setItem('token', token.value)
      return { success: true, data: userInfo.value }
    }
    return { success: false, message: '用户名或密码错误' }
  }

  function register(data) {
    if (data.username && data.password && data.email) {
      token.value = 'mock-token-' + Date.now()
      userInfo.value = {
        id: Date.now(),
        ...data,
        avatar: 'https://picsum.photos/seed/user' + Date.now() + '/100/100',
        favorites: [],
        likes: [],
        createdAt: new Date().toISOString().split('T')[0]
      }
      localStorage.setItem('token', token.value)
      return { success: true, data: userInfo.value }
    }
    return { success: false, message: '注册信息不完整' }
  }

  function logout() {
    token.value = ''
    userInfo.value = null
    localStorage.removeItem('token')
  }

  function updateUserInfo(data) {
    userInfo.value = { ...userInfo.value, ...data }
  }

  function initUser() {
    if (token.value) {
      userInfo.value = userData.currentUser
    }
  }

  return {
    token,
    userInfo,
    isLoggedIn,
    login,
    register,
    logout,
    updateUserInfo,
    initUser
  }
})
