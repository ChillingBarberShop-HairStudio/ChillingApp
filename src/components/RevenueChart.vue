<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ data: Array<{ month: string; revenue: number }> }>()

const plotHeight = 220
const columnWidth = 112
const maxValue = computed(() => Math.max(...props.data.map((item) => item.revenue), 1))
const chartWidth = computed(() => Math.max(620, props.data.length * columnWidth))
const chartValues = computed(() => props.data.map((item) => ({
  ...item,
  height: Math.max(8, (item.revenue / maxValue.value) * 100),
})))
const columnTemplate = computed(() => `repeat(${Math.max(props.data.length, 1)}, ${columnWidth}px)`)
const points = computed(() => chartValues.value.map((item, index) => {
  const x = index * columnWidth + columnWidth / 2
  const y = Math.max(4, plotHeight - (item.height / 100) * plotHeight)
  return `${x},${y}`
}).join(' '))
const formatCompact = (value: number) => value >= 1000000
  ? `${(value / 1000000).toLocaleString('vi-VN', { maximumFractionDigits: 1 })}tr`
  : `${Math.round(value / 1000).toLocaleString('vi-VN')}k`
</script>

<template>
  <section class="panel revenue-panel">
    <div class="panel-heading">
      <div><p class="panel-kicker">Hiệu suất kinh doanh</p><h2>Doanh thu theo tháng</h2></div>
      <span>{{ data.length }} tháng dữ liệu</span>
    </div>
    <div v-if="data.length" class="revenue-chart-scroll">
      <div class="monthly-revenue-chart" :style="{ width: `${chartWidth}px` }">
        <div class="monthly-revenue-plot">
          <div class="monthly-bar-grid" :style="{ gridTemplateColumns: columnTemplate }">
            <div v-for="item in chartValues" :key="item.month" class="monthly-bar-group" :style="{ '--bar-height': `${item.height}%` }">
              <strong>{{ formatCompact(item.revenue) }}</strong>
              <i></i>
            </div>
          </div>
          <svg class="monthly-trend-line" :viewBox="`0 0 ${chartWidth} ${plotHeight}`" preserveAspectRatio="none" aria-label="Đường xu hướng doanh thu">
            <polyline :points="points" />
          </svg>
        </div>
        <div class="monthly-chart-axis" :style="{ gridTemplateColumns: columnTemplate }">
          <span v-for="item in chartValues" :key="item.month">{{ item.month }}</span>
        </div>
      </div>
    </div>
    <p v-else class="monthly-chart-empty">Chưa có hóa đơn đã thanh toán trong phạm vi đã chọn.</p>
    <div class="chart-caption"><span><i></i> Cột doanh thu</span><span><b></b> Đường biến động</span></div>
  </section>
</template>
