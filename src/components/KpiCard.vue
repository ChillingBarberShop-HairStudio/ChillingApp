<script setup lang="ts">
import type { Component } from 'vue'

defineProps<{ label: string; value: string; detail: string; icon: Component; tone?: 'gold' | 'blue' | 'green' | 'rose' }>()
</script>

<template>
  <article class="kpi-card" :class="`kpi-card--${tone ?? 'gold'}`">
    <div class="kpi-icon"><component :is="icon" :size="22" /></div>
    <p>{{ label }}</p><strong>{{ value }}</strong><span>{{ detail }}</span>
  </article>
</template>
