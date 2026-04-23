import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import workflowData from '@/data/workflows.json'

export const useWorkflowStore = defineStore('workflow', () => {
  const workflows = ref(workflowData.workflows)
  const categories = ref(workflowData.categories)
  const currentWorkflow = ref(null)
  const searchKeyword = ref('')
  const selectedCategory = ref('全部')

  const filteredWorkflows = computed(() => {
    let result = workflows.value

    if (selectedCategory.value !== '全部') {
      result = result.filter(w => w.category === selectedCategory.value)
    }

    if (searchKeyword.value) {
      const keyword = searchKeyword.value.toLowerCase()
      result = result.filter(w => 
        w.title.toLowerCase().includes(keyword) ||
        w.description.toLowerCase().includes(keyword) ||
        w.tags.some(tag => tag.toLowerCase().includes(keyword))
      )
    }

    return result
  })

  function getWorkflowById(id) {
    return workflows.value.find(w => w.id === parseInt(id))
  }

  function setSearchKeyword(keyword) {
    searchKeyword.value = keyword
  }

  function setCategory(category) {
    selectedCategory.value = category
  }

  function likeWorkflow(id) {
    const workflow = workflows.value.find(w => w.id === id)
    if (workflow) {
      workflow.likes++
    }
  }

  function unlikeWorkflow(id) {
    const workflow = workflows.value.find(w => w.id === id)
    if (workflow && workflow.likes > 0) {
      workflow.likes--
    }
  }

  function favoriteWorkflow(id) {
    const workflow = workflows.value.find(w => w.id === id)
    if (workflow) {
      workflow.favorites++
    }
  }

  function unfavoriteWorkflow(id) {
    const workflow = workflows.value.find(w => w.id === id)
    if (workflow && workflow.favorites > 0) {
      workflow.favorites--
    }
  }

  return {
    workflows,
    categories,
    currentWorkflow,
    searchKeyword,
    selectedCategory,
    filteredWorkflows,
    getWorkflowById,
    setSearchKeyword,
    setCategory,
    likeWorkflow,
    unlikeWorkflow,
    favoriteWorkflow,
    unfavoriteWorkflow
  }
})
