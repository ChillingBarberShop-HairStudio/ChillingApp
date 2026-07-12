<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { Bot, CheckCircle2, KeyRound, MessageCircle, Save, ShieldCheck } from 'lucide-vue-next'
import { getTelegramConfigStatus, saveTelegramConfig } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { TelegramConfigStatus } from '../types/domain'

const status = ref<TelegramConfigStatus | null>(null)
const form = reactive({ botToken: '', chatId: '', enabled: false })
const saving = ref(false)
const error = ref('')
const success = ref('')

async function load() {
  if (!isSupabaseConfigured) {
    error.value = 'Chưa có cấu hình Supabase cho Chilling OS.'
    return
  }
  try {
    status.value = await getTelegramConfigStatus()
    form.chatId = status.value.chatId ?? ''
    form.enabled = status.value.enabled
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể tải cấu hình Telegram.'
  }
}

async function save() {
  error.value = ''
  success.value = ''
  saving.value = true
  try {
    status.value = await saveTelegramConfig(form)
    form.botToken = ''
    form.chatId = status.value.chatId ?? ''
    form.enabled = status.value.enabled
    success.value = 'Đã lưu cấu hình. Token được mã hóa trong Supabase Vault và không hiển thị lại trong hệ thống.'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể lưu cấu hình Telegram.'
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page-intro compact">
    <div><p class="eyebrow">Thông báo booking</p><h2>Telegram Bot</h2><p>Lưu an toàn Bot token và Chat ID để chuẩn bị nhận thông báo booking. Token không được lưu trong trình duyệt, bảng dữ liệu công khai hoặc mã nguồn.</p></div>
  </div>
  <p v-if="error" class="error-banner">{{ error }}</p><p v-if="success" class="success-banner">{{ success }}</p>
  <section class="telegram-layout">
    <article class="panel telegram-setup">
      <div class="table-heading"><div><h3>Cấu hình bot</h3><p>Chỉ tài khoản Owner hoặc Manager mới có thể thay đổi cấu hình này.</p></div><Bot :size="24" /></div>
      <div class="telegram-status" :class="{ active: status?.configured }"><CheckCircle2 :size="18" /><span>{{ status?.configured ? 'Token và Chat ID đã được lưu mã hóa, chờ kích hoạt gửi booking' : 'Chưa có bot Telegram được cấu hình' }}</span></div>
      <form class="form-grid" @submit.prevent="save">
        <label><span>Bot token</span><input v-model="form.botToken" type="password" autocomplete="off" :placeholder="status?.configured ? 'Để trống để giữ token hiện tại, chỉ nhập khi thay token' : '123456789:AA... từ BotFather'" /></label>
        <label><span>Chat ID nhận thông báo *</span><input v-model.trim="form.chatId" inputmode="numeric" placeholder="Ví dụ: 123456789 hoặc -1001234567890" required /></label>
        <label class="telegram-toggle"><input v-model="form.enabled" type="checkbox" /><span>Đánh dấu sẵn sàng bật thông báo booking</span></label>
        <div class="telegram-actions"><button class="primary-button" :disabled="saving"><Save :size="17" /> {{ saving ? 'Đang lưu...' : 'Lưu bot Telegram' }}</button></div>
      </form>
    </article>

    <article class="panel telegram-guide">
      <div class="table-heading"><div><h3>Hướng dẫn lấy Bot token và Chat ID</h3><p>Thiết lập một lần, sau đó dùng nút Gửi thử để xác nhận trước khi nhận booking thật.</p></div><MessageCircle :size="24" /></div>
      <ol class="telegram-steps">
        <li><b>Tạo bot:</b> mở Telegram, tìm <code>@BotFather</code>, gửi <code>/newbot</code>, đặt tên và username cho bot. BotFather trả về một Bot token.</li>
        <li><b>Kích hoạt chat:</b> mở bot vừa tạo và gửi <code>/start</code>. Nếu muốn nhận trong nhóm, thêm bot vào nhóm rồi gửi một tin nhắn trong nhóm.</li>
        <li><b>Lấy Chat ID:</b> trên máy cá nhân, gọi API <code>https://api.telegram.org/bot&lt;TOKEN&gt;/getUpdates</code> sau khi đã gửi tin nhắn. Tìm giá trị <code>message.chat.id</code>; nhóm thường là một số bắt đầu bằng <code>-100</code>.</li>
        <li><b>Lưu cấu hình:</b> nhập token cùng Chat ID và lưu. Token được mã hóa ngay trong Supabase Vault; màn hình này không hiển thị token sau khi lưu.</li>
      </ol>
      <div class="telegram-security"><ShieldCheck :size="19" /><div><strong>Lưu ý bảo mật</strong><p>Không gửi token cho người khác hoặc đưa token vào GitHub. Chỉ nhập token trong màn hình này; sau khi lưu, trường token luôn để trống và hệ thống chỉ giữ bản mã hóa trong Supabase Vault. Việc bật gửi booking ra Telegram cần được Owner xác nhận riêng vì tin nhắn chứa dữ liệu khách hàng.</p></div></div>
      <div class="telegram-security"><KeyRound :size="19" /><div><strong>Đổi token</strong><p>Khi cần thay token, tạo token mới trong BotFather rồi nhập lại tại đây. Tắt thông báo trước khi xử lý sự cố để không gửi dữ liệu booking sang chat cũ.</p></div></div>
    </article>
  </section>
</template>
