<script setup lang="ts">
import { ref } from 'vue'
import { LockKeyhole, Mail, Scissors } from 'lucide-vue-next'
import { useSession } from '../stores/session'

const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')
const { configured, signIn } = useSession()

async function submit() {
  error.value = ''
  loading.value = true
  try { await signIn(email.value, password.value) }
  catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể đăng nhập.' }
  finally { loading.value = false }
}
</script>

<template>
  <main class="login-page">
    <section class="login-visual"><div class="login-pole"></div><div class="login-brand"><img src="/logo.PNG" alt="Chilling Barber Shop" /><p>CHILLING BARBER SHOP</p><h1>Chilling OS</h1></div></section>
    <section class="login-panel"><form class="login-card" @submit.prevent="submit"><div class="login-icon"><Scissors :size="26" /></div><p class="eyebrow">Khu vực nội bộ</p><h2>Đăng nhập hệ thống</h2><p class="login-copy">Mỗi tài khoản được phân quyền theo vai trò để bảo vệ dữ liệu vận hành.</p><template v-if="configured"><label><span>Email</span><div class="input-icon"><Mail :size="18" /><input v-model.trim="email" type="email" autocomplete="email" required placeholder="owner@chilling.vn" /></div></label><label><span>Mật khẩu</span><div class="input-icon"><LockKeyhole :size="18" /><input v-model="password" type="password" autocomplete="current-password" required placeholder="••••••••" /></div></label><p v-if="error" class="form-error">{{ error }}</p><button class="primary-button" :disabled="loading">{{ loading ? 'Đang xác thực...' : 'Đăng nhập an toàn' }}</button></template><div v-else class="config-message"><strong>Chưa kết nối Supabase</strong><p>Tạo file <code>.env</code> từ <code>.env.example</code>, sau đó điền URL và Anon Key. Không bao giờ đưa Service Role Key vào web app.</p></div></form></section>
  </main>
</template>
