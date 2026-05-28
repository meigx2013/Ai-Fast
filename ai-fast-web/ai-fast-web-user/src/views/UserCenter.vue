<template>
  <div class="user-center">
    <div class="page-container">
      <div class="user-profile scroll-reveal">
        <div class="profile-card">
          <div class="profile-banner"></div>
          <div class="profile-body">
            <div class="avatar-wrap">
              <el-avatar :size="88" :src="userStore.userInfo?.avatar">
                <el-icon :size="44"><UserFilled /></el-icon>
              </el-avatar>
            </div>
            <div class="profile-info">
              <h2>{{ userStore.userInfo?.name }}</h2>
              <p class="bio">{{ userStore.userInfo?.bio || '这个人很懒，什么都没写~' }}</p>
              <p class="join-date">
                <el-icon><Calendar /></el-icon>
                加入于 {{ userStore.userInfo?.createdAt }}
              </p>
            </div>
            <el-button type="primary" round @click="showEditDialog = true">
              <el-icon><Edit /></el-icon>
              编辑资料
            </el-button>
          </div>
        </div>
      </div>

      <div class="user-content scroll-reveal" style="--stagger-index: 1">
        <el-tabs v-model="activeTab" class="user-tabs">
          <el-tab-pane label="我的收藏" name="favorites">
            <transition name="tab-fade" mode="out-in">
              <div key="fav-list" v-if="favoriteWorkflows.length" class="workflow-grid">
                <WorkflowCard
                  v-for="(workflow, index) in favoriteWorkflows"
                  :key="workflow.id"
                  :workflow="workflow"
                  class="scroll-reveal"
                  :style="{ '--stagger-index': index }"
                  @click="$router.push(`/workflow/${workflow.id}`)"
                />
              </div>
              <EmptyState v-else key="fav-empty" type="no-data" title="暂无收藏" description="浏览工作流并收藏感兴趣的内容" />
            </transition>
          </el-tab-pane>

          <el-tab-pane label="我的点赞" name="likes">
            <transition name="tab-fade" mode="out-in">
              <div key="like-list" v-if="likedWorkflows.length" class="workflow-grid">
                <WorkflowCard
                  v-for="(workflow, index) in likedWorkflows"
                  :key="workflow.id"
                  :workflow="workflow"
                  class="scroll-reveal"
                  :style="{ '--stagger-index': index }"
                  @click="$router.push(`/workflow/${workflow.id}`)"
                />
              </div>
              <EmptyState v-else key="like-empty" type="no-data" title="暂无点赞" description="为你喜欢的工作流点赞" />
            </transition>
          </el-tab-pane>
        </el-tabs>
      </div>

      <el-dialog
        v-model="showEditDialog"
        title="编辑个人资料"
        width="500px"
        class="edit-dialog"
      >
        <el-form :model="editForm" label-width="80px" class="edit-form">
          <el-form-item label="昵称">
            <el-input v-model="editForm.name" />
          </el-form-item>
          <el-form-item label="邮箱">
            <el-input v-model="editForm.email" />
          </el-form-item>
          <el-form-item label="个人简介">
            <el-input
              v-model="editForm.bio"
              type="textarea"
              :rows="3"
              placeholder="介绍一下自己吧~"
            />
          </el-form-item>
        </el-form>
        <template #footer>
          <el-button @click="showEditDialog = false">取消</el-button>
          <el-button type="primary" @click="handleSaveProfile">保存</el-button>
        </template>
      </el-dialog>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, reactive, onMounted } from 'vue'
import { useUserStore } from '@/stores/user'
import { useWorkflowStore } from '@/stores/workflow'
import { UserFilled, Calendar, Edit } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import WorkflowCard from '@/components/WorkflowCard.vue'
import EmptyState from '@/components/EmptyState.vue'

const userStore = useUserStore()
const workflowStore = useWorkflowStore()

const activeTab = ref('favorites')
const showEditDialog = ref(false)

const editForm = reactive({
  name: '',
  email: '',
  bio: ''
})

const favoriteWorkflows = computed(() => {
  const favorites = userStore.userInfo?.favorites || []
  return workflowStore.workflows.filter(w => favorites.includes(w.id))
})

const likedWorkflows = computed(() => {
  const likes = userStore.userInfo?.likes || []
  return workflowStore.workflows.filter(w => likes.includes(w.id))
})

onMounted(() => {
  if (userStore.userInfo) {
    editForm.name = userStore.userInfo.name
    editForm.email = userStore.userInfo.email
    editForm.bio = userStore.userInfo.bio || ''
  }
})

function handleSaveProfile() {
  userStore.updateUserInfo(editForm)
  showEditDialog.value = false
  ElMessage.success('资料更新成功')
}
</script>

<style lang="scss" scoped>
.user-center {
  background: var(--bg-secondary);
  min-height: calc(100vh - 68px);
}

.page-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px;
}

.profile-card {
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-lg);
  overflow: hidden;
  margin-bottom: 24px;
  transition: box-shadow var(--duration-fast) var(--ease-standard), transform var(--duration-fast) var(--ease-standard);

  &:hover {
    box-shadow: var(--shadow-md);
  }

  .profile-banner {
    height: 140px;
    background: var(--accent-gradient);
    position: relative;

    &::after {
      content: '';
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 40px;
      background: linear-gradient(transparent, rgba(0, 0, 0, 0.05));
    }
  }

  .profile-body {
    display: flex;
    align-items: center;
    gap: 24px;
    padding: 0 32px 28px;
    margin-top: -44px;

    @media (max-width: 768px) {
      flex-direction: column;
      text-align: center;
    }

    .avatar-wrap {
      border: 4px solid var(--bg-card);
      border-radius: 50%;
      flex-shrink: 0;
      transition: transform var(--duration-fast) var(--ease-spring);

      &:hover {
        transform: scale(1.05);
      }
    }

    .profile-info {
      flex: 1;

      h2 {
        font-size: 24px;
        font-weight: 600;
        color: var(--text-primary);
        margin-bottom: 8px;
      }

      .bio {
        color: var(--text-secondary);
        margin-bottom: 8px;
        font-size: 14px;
      }

      .join-date {
        display: flex;
        align-items: center;
        gap: 6px;
        color: var(--text-tertiary);
        font-size: 14px;

        @media (max-width: 768px) {
          justify-content: center;
        }
      }
    }

    .el-button {
      flex-shrink: 0;
      transition: transform var(--duration-fast) var(--ease-spring);

      &:hover {
        transform: translateY(-2px);
      }
    }
  }
}

.user-content {
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-lg);
  padding: 24px;
  transition: box-shadow var(--duration-fast) var(--ease-standard);

  &:hover {
    box-shadow: var(--shadow-md);
  }

  .workflow-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
    gap: 24px;
    margin-top: 16px;
  }
}

/* Tab transition */
.tab-fade-enter-active {
  transition: all var(--duration-normal) var(--ease-decelerate);
}

.tab-fade-leave-active {
  transition: all var(--duration-normal) var(--ease-accelerate);
}

.tab-fade-enter-from {
  opacity: 0;
  transform: translateY(12px);
}

.tab-fade-leave-to {
  opacity: 0;
  transform: translateY(-12px);
}

/* Edit dialog form card hover */
.edit-form {
  :deep(.el-form-item) {
    padding: 8px 12px;
    border-radius: var(--radius-sm);
    transition: background var(--duration-fast) var(--ease-standard);

    &:hover {
      background: var(--bg-tertiary);
    }
  }
}

@media (max-width: 768px) {
  .page-container {
    padding: 16px;
  }

  .profile-card .profile-body {
    padding: 0 16px 20px;
  }

  .user-content {
    padding: 16px;
  }
}
</style>
