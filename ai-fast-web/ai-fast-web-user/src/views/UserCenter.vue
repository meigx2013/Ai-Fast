<template>
  <div class="user-center">
    <div class="page-container">
      <div class="user-profile">
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

      <div class="user-content">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="我的收藏" name="favorites">
            <div class="workflow-grid" v-if="favoriteWorkflows.length">
              <WorkflowCard
                v-for="workflow in favoriteWorkflows"
                :key="workflow.id"
                :workflow="workflow"
                @click="$router.push(`/workflow/${workflow.id}`)"
              />
            </div>
            <el-empty v-else description="暂无收藏的工作流" />
          </el-tab-pane>

          <el-tab-pane label="我的点赞" name="likes">
            <div class="workflow-grid" v-if="likedWorkflows.length">
              <WorkflowCard
                v-for="workflow in likedWorkflows"
                :key="workflow.id"
                :workflow="workflow"
                @click="$router.push(`/workflow/${workflow.id}`)"
              />
            </div>
            <el-empty v-else description="暂无点赞的工作流" />
          </el-tab-pane>
        </el-tabs>
      </div>

      <el-dialog
        v-model="showEditDialog"
        title="编辑个人资料"
        width="500px"
      >
        <el-form :model="editForm" label-width="80px">
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
  border-radius: var(--radius-md);
  overflow: hidden;
  margin-bottom: 24px;

  .profile-banner {
    height: 120px;
    background: var(--accent-gradient);
  }

  .profile-body {
    display: flex;
    align-items: center;
    gap: 24px;
    padding: 0 32px 24px;
    margin-top: -44px;

    @media (max-width: 768px) {
      flex-direction: column;
      text-align: center;
    }

    .avatar-wrap {
      border: 4px solid var(--bg-card);
      border-radius: 50%;
      flex-shrink: 0;
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
  }
}

.user-content {
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-md);
  padding: 24px;

  .workflow-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
    gap: 24px;
    margin-top: 16px;
  }
}

@media (max-width: 768px) {
  .page-container {
    padding: 16px;
  }
}
</style>
