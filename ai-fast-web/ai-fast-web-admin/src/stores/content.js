import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import adminData from '@/data/admin.json'
import { loadData, saveData, STORAGE_KEYS } from '@/utils/persistence'

export const useContentStore = defineStore('content', () => {
  const workflows = ref(loadData(STORAGE_KEYS.WORKFLOWS, adminData.workflows))
  const categories = ref(loadData(STORAGE_KEYS.CATEGORIES, adminData.categories))
  const searchKeyword = ref('')
  const filterStatus = ref('all')
  const filterCategory = ref('all')

  const filteredWorkflows = computed(() => {
    let result = workflows.value

    if (filterStatus.value !== 'all') {
      result = result.filter(w => w.status === filterStatus.value)
    }

    if (filterCategory.value !== 'all') {
      result = result.filter(w => w.category === filterCategory.value)
    }

    if (searchKeyword.value) {
      const keyword = searchKeyword.value.toLowerCase()
      result = result.filter(w =>
        w.title.toLowerCase().includes(keyword) ||
        w.description.toLowerCase().includes(keyword) ||
        w.author.name.toLowerCase().includes(keyword)
      )
    }

    return result
  })

  const pendingCount = computed(() =>
    workflows.value.filter(w => w.status === 'pending').length
  )

  function getWorkflowById(id) {
    return workflows.value.find(w => w.id === parseInt(id))
  }

  function addWorkflow(workflow) {
    const newWorkflow = {
      id: Date.now(),
      ...workflow,
      author: { id: 0, name: '管理员' },
      views: 0,
      likes: 0,
      favorites: 0,
      status: 'published',
      createdAt: new Date().toISOString().split('T')[0],
      updatedAt: new Date().toISOString().split('T')[0]
    }
    workflows.value.unshift(newWorkflow)
  }

  function updateWorkflow(id, data) {
    const index = workflows.value.findIndex(w => w.id === parseInt(id))
    if (index !== -1) {
      workflows.value[index] = {
        ...workflows.value[index],
        ...data,
        updatedAt: new Date().toISOString().split('T')[0]
      }
    }
  }

  function deleteWorkflow(id) {
    const index = workflows.value.findIndex(w => w.id === parseInt(id))
    if (index !== -1) {
      workflows.value.splice(index, 1)
    }
  }

  function approveWorkflow(id) {
    const workflow = workflows.value.find(w => w.id === parseInt(id))
    if (workflow) {
      workflow.status = 'published'
      workflow.updatedAt = new Date().toISOString().split('T')[0]
    }
  }

  function rejectWorkflow(id, reason) {
    const workflow = workflows.value.find(w => w.id === parseInt(id))
    if (workflow) {
      workflow.status = 'rejected'
      workflow.rejectReason = reason
      workflow.updatedAt = new Date().toISOString().split('T')[0]
    }
  }

  function setSearchKeyword(keyword) {
    searchKeyword.value = keyword
  }

  function setFilterStatus(status) {
    filterStatus.value = status
  }

  function setFilterCategory(category) {
    filterCategory.value = category
  }

  // 持久化：workflows 数据变更时自动保存
  watch(workflows, (newVal) => {
    saveData(STORAGE_KEYS.WORKFLOWS, newVal)
  }, { deep: true })

  // 持久化：categories 数据变更时自动保存
  watch(categories, (newVal) => {
    saveData(STORAGE_KEYS.CATEGORIES, newVal)
  }, { deep: true })

  return {
    workflows,
    categories,
    searchKeyword,
    filterStatus,
    filterCategory,
    filteredWorkflows,
    pendingCount,
    getWorkflowById,
    addWorkflow,
    updateWorkflow,
    deleteWorkflow,
    approveWorkflow,
    rejectWorkflow,
    setSearchKeyword,
    setFilterStatus,
    setFilterCategory
  }
})
