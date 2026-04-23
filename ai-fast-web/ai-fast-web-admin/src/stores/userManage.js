import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import adminData from '@/data/admin.json'

export const useUserManageStore = defineStore('userManage', () => {
  const users = ref([...adminData.users])
  const searchKeyword = ref('')
  const filterStatus = ref('all')
  const filterRole = ref('all')

  const filteredUsers = computed(() => {
    let result = users.value

    if (filterStatus.value !== 'all') {
      result = result.filter(u => u.status === filterStatus.value)
    }

    if (filterRole.value !== 'all') {
      result = result.filter(u => u.role === filterRole.value)
    }

    if (searchKeyword.value) {
      const keyword = searchKeyword.value.toLowerCase()
      result = result.filter(u =>
        u.name.toLowerCase().includes(keyword) ||
        u.username.toLowerCase().includes(keyword) ||
        u.email.toLowerCase().includes(keyword)
      )
    }

    return result
  })

  function getUserById(id) {
    return users.value.find(u => u.id === parseInt(id))
  }

  function updateUserStatus(id, status) {
    const user = users.value.find(u => u.id === parseInt(id))
    if (user) {
      user.status = status
    }
  }

  function updateUserRole(id, role) {
    const user = users.value.find(u => u.id === parseInt(id))
    if (user) {
      user.role = role
    }
  }

  function deleteUser(id) {
    const index = users.value.findIndex(u => u.id === parseInt(id))
    if (index !== -1) {
      users.value.splice(index, 1)
    }
  }

  function setSearchKeyword(keyword) {
    searchKeyword.value = keyword
  }

  function setFilterStatus(status) {
    filterStatus.value = status
  }

  function setFilterRole(role) {
    filterRole.value = role
  }

  return {
    users,
    searchKeyword,
    filterStatus,
    filterRole,
    filteredUsers,
    getUserById,
    updateUserStatus,
    updateUserRole,
    deleteUser,
    setSearchKeyword,
    setFilterStatus,
    setFilterRole
  }
})
