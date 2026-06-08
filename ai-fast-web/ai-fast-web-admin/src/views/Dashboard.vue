<template>
  <div class="dashboard">
    <!-- 统计卡片 -->
    <div class="dashboard__stats">
      <StatCard
        title="总用户数"
        :value="statsStore.stats.totalUsers"
        :today-new="statsStore.stats.todayNewUsers"
        icon="User"
        gradient-from="#6366f1"
        gradient-to="#818cf8"
      />
      <StatCard
        title="总工作流"
        :value="statsStore.stats.totalWorkflows"
        :today-new="statsStore.stats.todayNewWorkflows"
        icon="SetUp"
        gradient-from="#8b5cf6"
        gradient-to="#a78bfa"
      />
      <StatCard
        title="总浏览量"
        :value="statsStore.stats.totalViews"
        :today-new="statsStore.stats.todayViews"
        icon="View"
        gradient-from="#ec4899"
        gradient-to="#f472b6"
      />
      <StatCard
        title="总点赞数"
        :value="statsStore.stats.totalLikes"
        icon="Star"
        gradient-from="#f59e0b"
        gradient-to="#fbbf24"
      />
    </div>

    <!-- 趋势折线图 -->
    <div class="dashboard__chart-card">
      <h3 class="dashboard__chart-title">7天趋势</h3>
      <div ref="trendChartRef" class="dashboard__chart"></div>
    </div>

    <!-- 分类分布饼图 -->
    <div class="dashboard__chart-card">
      <h3 class="dashboard__chart-title">分类分布</h3>
      <div ref="pieChartRef" class="dashboard__chart"></div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import * as echarts from 'echarts'
import StatCard from '@/components/StatCard.vue'
import { useStatsStore } from '@/stores/stats'
import { useThemeStore } from '@/stores/theme'

const statsStore = useStatsStore()
const themeStore = useThemeStore()

const trendChartRef = ref(null)
const pieChartRef = ref(null)
let trendChart = null
let pieChart = null

// 图表颜色配置
const chartColors = {
  light: {
    textColor: '#4a4a6a',
    splitLineColor: '#ecf0f5',
    series: ['#6366f1', '#8b5cf6', '#ec4899']
  },
  dark: {
    textColor: '#b0b0cc',
    splitLineColor: '#2a2a40',
    series: ['#818cf8', '#a78bfa', '#f472b6']
  }
}

function getChartColors() {
  return themeStore.isDark ? chartColors.dark : chartColors.light
}

// 趋势折线图配置
function getTrendOption() {
  const colors = getChartColors()
  const weeklyData = statsStore.stats.weeklyData || []
  const dates = weeklyData.map(d => d.date)
  const users = weeklyData.map(d => d.users)
  const workflows = weeklyData.map(d => d.workflows)
  const views = weeklyData.map(d => d.views)

  return {
    tooltip: {
      trigger: 'axis',
      backgroundColor: themeStore.isDark ? '#1a1a2e' : '#ffffff',
      borderColor: themeStore.isDark ? '#2a2a40' : '#e8ecf1',
      textStyle: { color: themeStore.isDark ? '#e8e8f0' : '#1a1a2e' }
    },
    legend: {
      data: ['用户增长', '工作流增长', '浏览量'],
      textStyle: { color: colors.textColor },
      top: 0,
      right: 0
    },
    grid: {
      top: 40,
      left: 10,
      right: 10,
      bottom: 10,
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: dates,
      axisLine: { lineStyle: { color: colors.splitLineColor } },
      axisLabel: { color: colors.textColor },
      boundaryGap: false
    },
    yAxis: [
      {
        type: 'value',
        name: '数量',
        nameTextStyle: { color: colors.textColor },
        axisLabel: { color: colors.textColor },
        splitLine: { lineStyle: { color: colors.splitLineColor } }
      },
      {
        type: 'value',
        name: '浏览量',
        nameTextStyle: { color: colors.textColor },
        axisLabel: { color: colors.textColor },
        splitLine: { show: false }
      }
    ],
    series: [
      {
        name: '用户增长',
        type: 'line',
        data: users,
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { width: 2, color: colors.series[0] },
        itemStyle: { color: colors.series[0] },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: colors.series[0] + '33' },
            { offset: 1, color: colors.series[0] + '05' }
          ])
        }
      },
      {
        name: '工作流增长',
        type: 'line',
        data: workflows,
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { width: 2, color: colors.series[1] },
        itemStyle: { color: colors.series[1] },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: colors.series[1] + '33' },
            { offset: 1, color: colors.series[1] + '05' }
          ])
        }
      },
      {
        name: '浏览量',
        type: 'line',
        yAxisIndex: 1,
        data: views,
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { width: 2, color: colors.series[2] },
        itemStyle: { color: colors.series[2] },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: colors.series[2] + '33' },
            { offset: 1, color: colors.series[2] + '05' }
          ])
        }
      }
    ]
  }
}

// 饼图配置
function getPieOption() {
  const colors = getChartColors()
  const categoryData = statsStore.stats.categoryDistribution || []

  return {
    tooltip: {
      trigger: 'item',
      backgroundColor: themeStore.isDark ? '#1a1a2e' : '#ffffff',
      borderColor: themeStore.isDark ? '#2a2a40' : '#e8ecf1',
      textStyle: { color: themeStore.isDark ? '#e8e8f0' : '#1a1a2e' },
      formatter: '{b}: {c} ({d}%)'
    },
    legend: {
      orient: 'horizontal',
      bottom: 0,
      textStyle: { color: colors.textColor }
    },
    color: colors.series,
    series: [
      {
        type: 'pie',
        radius: ['40%', '65%'],
        center: ['50%', '45%'],
        avoidLabelOverlap: true,
        itemStyle: {
          borderRadius: 6,
          borderColor: themeStore.isDark ? '#1a1a2e' : '#ffffff',
          borderWidth: 2
        },
        label: {
          color: colors.textColor,
          formatter: '{b}\n{d}%'
        },
        emphasis: {
          label: { show: true, fontSize: 14, fontWeight: 'bold' }
        },
        data: categoryData
      }
    ]
  }
}

// 初始化图表
function initCharts() {
  if (trendChartRef.value) {
    trendChart = echarts.init(trendChartRef.value)
    trendChart.setOption(getTrendOption())
  }
  if (pieChartRef.value) {
    pieChart = echarts.init(pieChartRef.value)
    pieChart.setOption(getPieOption())
  }
}

// 更新图表配色
function updateCharts() {
  if (trendChart) {
    trendChart.setOption(getTrendOption(), { notMerge: false })
  }
  if (pieChart) {
    pieChart.setOption(getPieOption(), { notMerge: false })
  }
}

// 监听主题变化
watch(() => themeStore.isDark, () => {
  nextTick(updateCharts)
})

// 窗口大小变化时 resize
function handleResize() {
  trendChart?.resize()
  pieChart?.resize()
}

onMounted(() => {
  initCharts()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  trendChart?.dispose()
  pieChart?.dispose()
})
</script>

<style scoped lang="scss">
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 24px;

  &__stats {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 20px;
  }

  &__chart-card {
    background-color: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    padding: 20px 24px;
    box-shadow: var(--shadow-sm);
  }

  &__chart-title {
    font-size: 16px;
    font-weight: 600;
    color: var(--text-primary);
    margin-bottom: 12px;
  }

  &__chart {
    width: 100%;
    height: 360px;
  }
}

/* 响应式 */
@media (max-width: 1200px) {
  .dashboard__stats {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .dashboard__stats {
    grid-template-columns: 1fr;
  }

  .dashboard__chart {
    height: 280px;
  }
}
</style>
