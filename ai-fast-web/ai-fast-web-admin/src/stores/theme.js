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
