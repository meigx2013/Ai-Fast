import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import agentData from '@/data/agents.json'

export const useAgentStore = defineStore('agent', () => {
  const agents = ref(agentData.agents)
  const categories = ref(agentData.categories)
  const searchKeyword = ref('')
  const selectedCategory = ref('全部')

  const hotAgents = computed(() => {
    return agents.value.filter(a => a.isHot)
  })

  const filteredAgents = computed(() => {
    let result = agents.value

    if (selectedCategory.value !== '全部') {
      result = result.filter(a => a.category === selectedCategory.value)
    }

    if (searchKeyword.value) {
      const keyword = searchKeyword.value.toLowerCase()
      result = result.filter(a =>
        a.name.toLowerCase().includes(keyword) ||
        a.description.toLowerCase().includes(keyword) ||
        a.tags.some(tag => tag.toLowerCase().includes(keyword))
      )
    }

    return result
  })

  function setSearchKeyword(keyword) {
    searchKeyword.value = keyword
  }

  function setCategory(category) {
    selectedCategory.value = category
  }

  function getAgentById(id) {
    return agents.value.find(a => a.id === parseInt(id))
  }

  function likeAgent(id) {
    const agent = agents.value.find(a => a.id === id)
    if (agent) {
      agent.likes++
    }
  }

  return {
    agents,
    categories,
    searchKeyword,
    selectedCategory,
    hotAgents,
    filteredAgents,
    setSearchKeyword,
    setCategory,
    getAgentById,
    likeAgent
  }
})
