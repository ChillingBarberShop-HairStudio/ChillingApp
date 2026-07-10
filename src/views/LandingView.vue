<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ExternalLink, ImagePlus, Save, Send } from 'lucide-vue-next'
import { getLandingContent, saveLandingContent } from '../lib/api'
import { isSupabaseConfigured, requireSupabase } from '../lib/supabase'

type ContentRow = { id: string; content_key: string; content_value: Record<string, unknown>; is_public: boolean }
const rows = ref<ContentRow[]>([{ id: 'demo-business', content_key: 'business', content_value: { name: 'Chilling Barber Shop', phone: '0327969930' }, is_public: true }, { id: 'demo-hero', content_key: 'hero', content_value: { title: 'Chất riêng', highlight: 'Chuẩn đẹp' }, is_public: true }])
const drafts = ref<Record<string, string>>({})
const message = ref('')
const error = ref('')
const landingUrl = import.meta.env.VITE_LANDING_URL || 'https://chillingbarbershop-hairstudio.github.io/Chilling/'
function syncDrafts() { drafts.value = Object.fromEntries(rows.value.map((row) => [row.id, JSON.stringify(row.content_value, null, 2)])) }
async function load() { if (isSupabaseConfigured) rows.value = await getLandingContent(); syncDrafts() }
async function save(row: ContentRow) { try { if (!isSupabaseConfigured) throw new Error('Chế độ demo không ghi dữ liệu.'); const contentValue = JSON.parse(drafts.value[row.id] || '{}') as Record<string, unknown>; await saveLandingContent(row.id, contentValue); row.content_value = contentValue; message.value = `Đã lưu ${row.content_key}. Landing page sẽ nhận dữ liệu mới mà không cần lộ token GitHub.` } catch (cause) { error.value = cause instanceof Error ? cause.message : 'JSON không hợp lệ hoặc không thể lưu nội dung.' } }
async function requestDeploy() { const endpoint = import.meta.env.VITE_DEPLOY_WEBHOOK_URL; if (!endpoint) { error.value = 'Chưa cấu hình VITE_DEPLOY_WEBHOOK_URL cho Cloudflare Worker.'; return } try { const token = (await requireSupabase().auth.getSession()).data.session?.access_token; const response = await fetch(endpoint, { method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ event: 'landing_content_changed' }) }); if (!response.ok) throw new Error('Cloudflare Worker từ chối yêu cầu deploy.'); message.value = 'Đã gửi yêu cầu deploy qua Cloudflare Worker.' } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể yêu cầu deploy.' } }
onMounted(load)
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Nội dung công khai</p><h2>Quản lý landing page</h2><p>Nội dung và dịch vụ được lưu trong Supabase; hình ảnh nên tải qua Storage. Website đọc dữ liệu động nên không phải commit secret vào GitHub.</p></div><div class="intro-actions"><a class="secondary-button" :href="landingUrl" target="_blank" rel="noreferrer"><ExternalLink :size="17" /> Xem landing</a><button class="primary-button" @click="requestDeploy"><Send :size="17" /> Deploy qua Worker</button></div></div><p v-if="error" class="error-banner">{{ error }}</p><p v-if="message" class="success-banner">{{ message }}</p><section class="landing-settings"><article v-for="row in rows" :key="row.id" class="panel landing-row"><div class="landing-row-heading"><div><span class="role-badge">{{ row.is_public ? 'Công khai' : 'Nội bộ' }}</span><h3>{{ row.content_key }}</h3></div><ImagePlus :size="21" /></div><textarea v-model="drafts[row.id]" spellcheck="false"></textarea><button class="secondary-button" @click="save(row)"><Save :size="17" /> Lưu thay đổi</button></article></section>
</template>
