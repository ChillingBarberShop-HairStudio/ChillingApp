<script setup lang="ts">
defineProps<{ title: string; items: Array<{ name: string; value: number; suffix?: string }>; accent?: string }>()
</script>

<template>
  <section class="panel rank-panel"><div class="panel-heading"><h2>{{ title }}</h2><span>Top {{ items.length }}</span></div><ol class="rank-list"><li v-for="(item, index) in items" :key="item.name"><b>{{ index + 1 }}</b><span>{{ item.name }}</span><strong>{{ item.value.toLocaleString('vi-VN') }}{{ item.suffix ?? '' }}</strong></li></ol></section>
</template>
