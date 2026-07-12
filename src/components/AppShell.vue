<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Bell, ChevronLeft, LogOut, Menu, X } from 'lucide-vue-next'
import { useRoute } from 'vue-router'
import { NAVIGATION, SECONDARY_NAVIGATION } from '../data/navigation'
import { getRecentNotifications } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import { useSession } from '../stores/session'
import type { AdminNotification } from '../types/domain'

const route = useRoute()
const menuOpen = ref(false)
const collapsed = ref(false)
const notificationOpen = ref(false)
const notifications = ref<AdminNotification[]>([])
const notificationError = ref('')
const { signOut } = useSession()
const title = computed(() => route.meta.title ?? 'Chilling OS')
const landingUrl = import.meta.env.VITE_LANDING_URL || 'https://chillingbarbershop-hairstudio.github.io/Chilling/'

async function loadNotifications() {
  if (!isSupabaseConfigured) return
  try { notifications.value = await getRecentNotifications(); notificationError.value = '' }
  catch { notificationError.value = 'Không thể tải thông báo mới.' }
}
async function toggleNotifications() { notificationOpen.value = !notificationOpen.value; if (notificationOpen.value) await loadNotifications() }
async function logout() { await signOut() }

onMounted(loadNotifications)
</script>

<template>
  <div class="admin-shell" :class="{ 'admin-shell--collapsed': collapsed, 'admin-shell--open': menuOpen }">
    <aside class="admin-sidebar">
      <div class="brand-row"><img src="/logo.PNG" alt="Chilling Barber Shop" class="brand-logo" /><div class="brand-copy"><strong>CHILLING</strong><span>BARBER OS</span></div><button class="icon-button sidebar-close" type="button" aria-label="Đóng menu" @click="menuOpen = false"><X :size="20" /></button></div>
      <nav class="sidebar-nav" aria-label="Điều hướng quản trị"><RouterLink v-for="item in NAVIGATION" :key="item.to" :to="item.to" class="nav-link" @click="menuOpen = false"><component :is="item.icon" :size="20" /><span>{{ item.label }}</span><small v-if="item.note">{{ item.note }}</small></RouterLink><p class="nav-label">Hệ thống</p><RouterLink v-for="item in SECONDARY_NAVIGATION" :key="item.to" :to="item.to" class="nav-link" @click="menuOpen = false"><component :is="item.icon" :size="20" /><span>{{ item.label }}</span></RouterLink></nav>
      <div class="sidebar-bottom"><a class="landing-link" :href="landingUrl" target="_blank" rel="noreferrer">Mở landing page</a><button type="button" class="logout-button" @click="logout"><LogOut :size="18" /> Đăng xuất</button><p class="system-copyright">© 2026 Engineered by Vinh | All rights reserved</p></div>
    </aside>
    <div class="admin-backdrop" @click="menuOpen = false"></div>
    <main class="admin-main">
      <header class="admin-header"><div class="header-title"><button type="button" class="icon-button mobile-menu" aria-label="Mở menu" @click="menuOpen = true"><Menu :size="21" /></button><button type="button" class="icon-button collapse-menu" aria-label="Thu gọn thanh menu" @click="collapsed = !collapsed"><ChevronLeft :size="20" /></button><div><p>Chilling Barber Shop</p><h1>{{ title }}</h1></div></div><div class="header-actions"><div class="notification-wrap"><button type="button" class="icon-button notification-button" aria-label="Thông báo" :aria-expanded="notificationOpen" @click="toggleNotifications"><Bell :size="20" /><i v-if="notifications.length"></i></button><div v-if="notificationOpen" class="notification-popover"><div class="notification-heading"><strong>Booking cần xử lý</strong><button type="button" @click="loadNotifications">Làm mới</button></div><p v-if="notificationError" class="notification-empty">{{ notificationError }}</p><ul v-else-if="notifications.length"><li v-for="item in notifications" :key="item.id"><strong>{{ item.customer_name }}</strong><span>{{ item.booking_code }} · {{ new Date(item.appointment_date).toLocaleDateString('vi-VN') }} {{ item.time_slot.slice(0, 5) }}</span></li></ul><p v-else class="notification-empty">Không có booking online đang chờ.</p></div></div><div class="avatar">CB</div></div></header>
      <div class="admin-content"><slot /></div>
    </main>
  </div>
</template>
