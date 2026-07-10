<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ data: Array<{ month: string; revenue: number }> }>()
const maxValue = computed(() => Math.max(...props.data.map((item) => item.revenue), 1))
const points = computed(() => props.data.map((item, index) => {
  const x = props.data.length === 1 ? 50 : 8 + (index * 84) / (props.data.length - 1)
  const y = 88 - (item.revenue / maxValue.value) * 68
  return `${x},${y}`
}).join(' '))
</script>

<template>
  <section class="panel revenue-panel"><div class="panel-heading"><div><p class="panel-kicker">Hiệu suất kinh doanh</p><h2>Doanh thu theo tháng</h2></div><span>6 tháng gần nhất</span></div><div class="revenue-chart"><div v-for="item in data" :key="item.month" class="bar-group"><i :style="{ height: `${Math.max(10, item.revenue / maxValue * 100)}%` }"></i><span>{{ item.month }}</span></div><svg viewBox="0 0 100 100" preserveAspectRatio="none" aria-label="Đường xu hướng doanh thu"><polyline :points="points" /></svg></div><div class="chart-caption"><span><i></i> Cột doanh thu</span><span><b></b> Đường biến động</span></div></section>
</template>
