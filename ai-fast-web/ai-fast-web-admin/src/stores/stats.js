import { defineStore } from 'pinia'
import { ref } from 'vue'
import adminData from '@/data/admin.json'

export const useStatsStore = defineStore('stats', () => {
  const stats = ref({ ...adminData.stats })
  const systemConfig = ref({ ...adminData.systemConfig })

  function updateSystemConfig(config) {
    systemConfig.value = { ...systemConfig.value, ...config }
  }

  return {
    stats,
    systemConfig,
    updateSystemConfig
  }
})
