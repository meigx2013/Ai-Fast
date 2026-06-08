import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import adminData from '@/data/admin.json'
import { loadData, saveData, STORAGE_KEYS } from '@/utils/persistence'

export const useStatsStore = defineStore('stats', () => {
  const stats = ref({ ...adminData.stats })
  const systemConfig = ref(loadData(STORAGE_KEYS.SYSTEM_CONFIG, adminData.systemConfig))

  function updateSystemConfig(config) {
    systemConfig.value = { ...systemConfig.value, ...config }
  }

  // 持久化：systemConfig 数据变更时自动保存
  watch(systemConfig, (newVal) => {
    saveData(STORAGE_KEYS.SYSTEM_CONFIG, newVal)
  }, { deep: true })

  return {
    stats,
    systemConfig,
    updateSystemConfig
  }
})
