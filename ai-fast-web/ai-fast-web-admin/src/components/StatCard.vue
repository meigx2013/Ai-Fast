<template>
  <div class="stat-card">
    <div
      class="stat-card__icon"
      :style="{
        background: `linear-gradient(135deg, ${gradientFrom}, ${gradientTo})`
      }"
    >
      <el-icon :size="28">
        <component :is="icon" />
      </el-icon>
    </div>
    <div class="stat-card__info">
      <div class="stat-card__title">{{ title }}</div>
      <div class="stat-card__value">
        {{ formattedValue }}
        <span v-if="suffix" class="stat-card__suffix">{{ suffix }}</span>
      </div>
      <div v-if="todayNew !== undefined" class="stat-card__today">
        今日 +{{ todayNew }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  title: { type: String, required: true },
  value: { type: Number, required: true },
  suffix: { type: String, default: '' },
  todayNew: { type: Number, default: undefined },
  icon: { type: String, required: true },
  gradientFrom: { type: String, required: true },
  gradientTo: { type: String, required: true }
})

const formattedValue = computed(() => {
  return props.value.toLocaleString()
})
</script>

<style scoped lang="scss">
.stat-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px 24px;
  background-color: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
  transition: all var(--duration-normal) var(--ease-standard);

  &:hover {
    box-shadow: var(--shadow-md);
    transform: translateY(-2px);
  }

  &__icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: var(--stat-icon-size);
    height: var(--stat-icon-size);
    border-radius: var(--radius-md);
    color: #ffffff;
    flex-shrink: 0;
  }

  &__info {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
  }

  &__title {
    font-size: 14px;
    color: var(--text-tertiary);
    line-height: 1.4;
  }

  &__value {
    font-size: 28px;
    font-weight: 700;
    color: var(--text-primary);
    line-height: 1.3;
    letter-spacing: -0.5px;
  }

  &__suffix {
    font-size: 14px;
    font-weight: 400;
    color: var(--text-tertiary);
    margin-left: 2px;
  }

  &__today {
    font-size: 13px;
    color: var(--status-published);
    font-weight: 500;
  }
}
</style>
