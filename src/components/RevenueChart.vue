<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ data: Array<{ month: string; revenue: number }> }>()
const maxValue = computed(() => Math.max(...props.data.map((item) => item.revenue), 1))
const chartValues = computed(() => props.data.map((item) => ({ ...item, height: Math.max(8, (item.revenue / maxValue.value) * 100) })))
const points = computed(() => chartValues.value.map((item, index) => {
  const x = props.data.length === 1 ? 50 : 6 + (index * 88) / (props.data.length - 1)
  const y = 100 - item.height
  return `${x},${y}`
}).join(' '))
const formatCompact = (value: number) => value >= 1000000 ? `${(value / 1000000).toLocaleString('vi-VN', { maximumFractionDigits: 1 })}tr` : `${Math.round(value / 1000).toLocaleString('vi-VN')}k`
</script>

<template>
  <section class="panel revenue-panel"><div class="panel-heading"><div><p class="panel-kicker">Hiệu suất kinh doanh</p><h2>Doanh thu theo tháng</h2></div><span>{{ data.length }} tháng dữ liệu</span></div><div class="revenue-chart-scroll"><div class="revenue-chart" :style="{ minWidth: `${Math.max(620, data.length * 112)}px` }"><div v-for="item in chartValues" :key="item.month" class="bar-group" :style="{ '--bar-height': `${item.height}%` }"><strong>{{ formatCompact(item.revenue) }}</strong><i></i><span>{{ item.month }}</span></div><svg viewBox="0 0 100 100" preserveAspectRatio="none" aria-label="Đường xu hướng doanh thu"><polyline :points="points" /></svg></div></div><div class="chart-caption"><span><i></i> Cột doanh thu</span><span><b></b> Đường biến động</span></div></section>
</template>
