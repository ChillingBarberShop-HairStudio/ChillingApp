<script setup lang="ts">
import { onMounted } from 'vue'
import AppShell from './components/AppShell.vue'
import LoginView from './components/LoginView.vue'
import { useSession } from './stores/session'

const { session, loading, configured, initialize } = useSession()
onMounted(initialize)
</script>

<template>
  <div v-if="loading" class="app-loading">Đang khởi tạo Chilling OS...</div>
  <LoginView v-else-if="configured && !session" />
  <AppShell v-else><RouterView /></AppShell>
</template>
