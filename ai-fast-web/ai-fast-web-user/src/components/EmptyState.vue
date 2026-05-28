<template>
  <div class="empty-state" :class="[`type-${type}`]">
    <div class="empty-illustration">
      <div class="illustration-icon">
        <!-- no-data: folder + blank -->
        <template v-if="type === 'no-data'">
          <el-icon :size="48"><FolderOpened /></el-icon>
          <el-icon :size="20" class="sub-icon"><Document /></el-icon>
        </template>
        <!-- no-result: search + exclamation -->
        <template v-else-if="type === 'no-result'">
          <el-icon :size="48"><Search /></el-icon>
          <el-icon :size="18" class="sub-icon"><WarningFilled /></el-icon>
        </template>
        <!-- error: warning + cloud -->
        <template v-else-if="type === 'error'">
          <el-icon :size="48"><WarningFilled /></el-icon>
          <el-icon :size="20" class="sub-icon cloud"><Cloudy /></el-icon>
        </template>
      </div>
    </div>

    <h3 v-if="title" class="empty-title">{{ title }}</h3>
    <p v-if="description" class="empty-desc">{{ description }}</p>

    <el-button
      v-if="actionText"
      type="primary"
      round
      class="empty-action"
      @click="handleAction"
    >
      {{ actionText }}
    </el-button>
  </div>
</template>

<script setup>
import { FolderOpened, Document, Search, WarningFilled, Cloudy } from '@element-plus/icons-vue'

const props = defineProps({
  type: {
    type: String,
    default: 'no-data',
    validator: (v) => ['no-data', 'no-result', 'error'].includes(v)
  },
  title: {
    type: String,
    default: ''
  },
  description: {
    type: String,
    default: ''
  },
  actionText: {
    type: String,
    default: ''
  },
  actionLink: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['action'])

function handleAction() {
  if (props.actionLink) {
    window.location.href = props.actionLink
  }
  emit('action')
}
</script>

<style lang="scss" scoped>
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48px 24px;
  text-align: center;
}

.empty-illustration {
  margin-bottom: 24px;

  .illustration-icon {
    position: relative;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    color: var(--text-tertiary);
    animation: empty-float 3s ease-in-out infinite;

    .sub-icon {
      position: absolute;
      bottom: -4px;
      right: -8px;
      color: var(--accent-primary);
      opacity: 0.7;

      &.cloud {
        color: var(--text-tertiary);
        opacity: 0.4;
      }
    }
  }
}

.type-no-data .illustration-icon {
  color: var(--accent-primary-light);
}

.type-no-result .illustration-icon {
  color: var(--accent-secondary);
}

.type-error .illustration-icon {
  color: var(--el-color-danger, #ef4444);
}

.empty-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 8px;
}

.empty-desc {
  font-size: 14px;
  color: var(--text-tertiary);
  max-width: 360px;
  line-height: 1.6;
  margin-bottom: 24px;
}

.empty-action {
  padding: 10px 28px;
}

@keyframes empty-float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-8px);
  }
}

@media (prefers-reduced-motion: reduce) {
  .empty-illustration .illustration-icon {
    animation: none;
  }
}
</style>
