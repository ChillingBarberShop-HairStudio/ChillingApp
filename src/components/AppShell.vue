<script setup lang="ts">
import { computed, ref } from 'vue'
import { Bell, ChevronLeft, LogOut, Menu, X } from 'lucide-vue-next'
import { useRoute } from 'vue-router'
import { NAVIGATION, SECONDARY_NAVIGATION } from '../data/navigation'
import { useSession } from '../stores/session'

const route = useRoute()
const menuOpen = ref(false)
const collapsed = ref(false)
const { signOut } = useSession()
const title = computed(() => route.meta.title ?? 'Chilling OS')
const landingUrl = import.meta.env.VITE_LANDING_URL || 'https://chillingbarbershop-hairstudio.github.io/Chilling/'

async function logout() {
  await signOut()
}
</script>

<template>
  <div class="admin-shell" :class="{ 'admin-shell--collapsed': collapsed, 'admin-shell--open': menuOpen }">
    <aside class="admin-sidebar">
      <div class="brand-row">
        <img src="/logo.PNG" alt="Chilling Barber Shop" class="brand-logo" />
        <div class="brand-copy"><strong>CHILLING</strong><span>BARBER OS</span></div>
        <button class="icon-button sidebar-close" type="button" aria-label="Đóng menu" @click="menuOpen = false"><X :size="20" /></button>
      </div>

      <nav class="sidebar-nav" aria-label="Điều hướng quản trị">
        <RouterLink v-for="item in NAVIGATION" :key="item.to" :to="item.to" class="nav-link" @click="menuOpen = false">
          <component :is="item.icon" :size="20" />
          <span>{{ item.label }}</span><small v-if="item.note">{{ item.note }}</small>
        </RouterLink>
        <p class="nav-label">Hệ thống</p>
        <RouterLink v-for="item in SECONDARY_NAVIGATION" :key="item.to" :to="item.to" class="nav-link" @click="menuOpen = false">
          <component :is="item.icon" :size="20" /><span>{{ item.label }}</span>
        </RouterLink>
      </nav>

      <div class="sidebar-bottom">
        <a class="landing-link" :href="landingUrl" target="_blank" rel="noreferrer">Mở landing page</a>
        <button type="button" class="logout-button" @click="logout"><LogOut :size="18" /> Đăng xuất</button>
      </div>
    </aside>

    <div class="admin-backdrop" @click="menuOpen = false"></div>
    <main class="admin-main">
      <header class="admin-header">
        <div class="header-title">
          <button type="button" class="icon-button mobile-menu" aria-label="Mở menu" @click="menuOpen = true"><Menu :size="21" /></button>
          <button type="button" class="icon-button collapse-menu" aria-label="Thu gọn thanh menu" @click="collapsed = !collapsed"><ChevronLeft :size="20" /></button>
          <div><p>Chilling Barber Shop</p><h1>{{ title }}</h1></div>
        </div>
        <div class="header-actions">
          <button type="button" class="icon-button notification-button" aria-label="Thông báo"><Bell :size="20" /><i></i></button>
          <div class="avatar">CB</div>
        </div>
      </header>
      <div class="admin-content"><slot /></div>
    </main>
  </div>
</template>
