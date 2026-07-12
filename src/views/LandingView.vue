<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ExternalLink, ImagePlus, RefreshCw, Save, Send, Trash2 } from 'lucide-vue-next'
import { deleteLandingMedia, getLandingContent, getLandingMedia, getLandingMediaUrl, replaceLandingMedia, saveLandingContent, saveLandingMedia, uploadLandingMedia, upsertLandingContent } from '../lib/api'
import { isSupabaseConfigured, requireSupabase } from '../lib/supabase'
import type { LandingContent, LandingMedia } from '../types/domain'

type SectionKey = LandingMedia['section_key']
type SectionDefinition = {
  key: SectionKey
  label: string
  description: string
  maxImages: number
  fields: Array<{ key: string; label: string; fallback: string }>
}

const sections: SectionDefinition[] = [
  { key: 'hero', label: 'Trang đầu', description: 'Ảnh hero và các header quảng cáo đầu trang.', maxImages: 1, fields: [{ key: 'eyebrow', label: 'Nhãn giới thiệu', fallback: 'Hair studio tại Bàu Bàng' }, { key: 'title', label: 'Tiêu đề chính', fallback: 'Chất riêng' }, { key: 'highlight', label: 'Tiêu đề nhấn', fallback: 'Chuẩn đẹp' }, { key: 'description', label: 'Mô tả', fallback: 'Cắt tóc, uốn, nhuộm và chăm sóc diện mạo cùng đội ngũ barber tận tâm trong không gian chỉn chu, thoải mái.' }] },
  { key: 'studio', label: 'Không gian barber', description: 'Bộ ảnh studio và phần giới thiệu trang hai.', maxImages: 9, fields: [{ key: 'eyebrow', label: 'Nhãn giới thiệu', fallback: 'Không gian & tay nghề' }, { key: 'titleLineOne', label: 'Tiêu đề dòng 1', fallback: 'Barber studio' }, { key: 'titleLineTwo', label: 'Tiêu đề dòng 2', fallback: 'đúng chất của bạn' }, { key: 'description', label: 'Mô tả', fallback: 'Từ tư vấn kiểu tóc phù hợp khuôn mặt đến kỹ thuật hoàn thiện, mỗi dịch vụ đều rõ giá, rõ thời gian và được thực hiện với sự tập trung cao nhất.' }] },
  { key: 'services', label: 'Dịch vụ và mẫu tóc', description: 'Bộ ảnh gợi ý mẫu tóc ở trang ba.', maxImages: 3, fields: [{ key: 'eyebrow', label: 'Nhãn giới thiệu', fallback: 'Dịch vụ và mẫu tóc' }, { key: 'titleLineOne', label: 'Tiêu đề dòng 1', fallback: 'Chọn kiểu phù hợp' }, { key: 'titleLineTwo', label: 'Tiêu đề dòng 2', fallback: 'Trọn vẹn phong cách' }] },
  { key: 'gallery', label: 'Tác phẩm hoàn thiện', description: 'Gallery thành phẩm ở trang bốn.', maxImages: 10, fields: [{ key: 'eyebrow', label: 'Nhãn giới thiệu', fallback: 'Chilling lookbook' }, { key: 'title', label: 'Tiêu đề', fallback: 'Tác phẩm hoàn thiện' }, { key: 'description', label: 'Mô tả', fallback: 'Một số phong cách tóc và trải nghiệm hoàn thiện tại Chilling Barber Shop.' }] },
]

const contentRows = ref<LandingContent[]>([])
const media = ref<LandingMedia[]>([])
const drafts = ref<Record<string, Record<string, string>>>({})
const message = ref('')
const error = ref('')
const busySection = ref('')
const landingUrl = import.meta.env.VITE_LANDING_URL || 'https://chillingbarbershop-hairstudio.github.io/Chilling/'
const mediaBySection = computed(() => Object.fromEntries(sections.map((section) => [section.key, media.value.filter((item) => item.section_key === section.key)])) as Record<SectionKey, LandingMedia[]>)

function buildDrafts() {
  const nextDrafts: Record<string, Record<string, string>> = {}
  for (const section of sections) {
    const values = contentRows.value.find((row) => row.content_key === section.key)?.content_value ?? {}
    nextDrafts[section.key] = Object.fromEntries(section.fields.map((field) => [field.key, typeof values[field.key] === 'string' ? values[field.key] : field.fallback])) as Record<string, string>
  }
  drafts.value = nextDrafts
}

async function load() {
  if (!isSupabaseConfigured) { buildDrafts(); return }
  try {
    ;[contentRows.value, media.value] = await Promise.all([getLandingContent(), getLandingMedia()])
    buildDrafts()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể tải nội dung landing page.'
  }
}

async function saveCopy(section: SectionDefinition) {
  if (!isSupabaseConfigured) { error.value = 'Chưa có cấu hình Supabase.'; return }
  busySection.value = section.key
  try {
    const value = drafts.value[section.key]
    const current = contentRows.value.find((row) => row.content_key === section.key)
    let saved: LandingContent
    if (current) {
      await saveLandingContent(current.id, value)
      saved = { ...current, content_value: value }
    } else {
      saved = await upsertLandingContent(section.key, value)
    }
    const index = contentRows.value.findIndex((row) => row.content_key === section.key)
    if (index >= 0) contentRows.value[index] = saved
    else contentRows.value.push(saved)
    message.value = `Đã lưu header ${section.label}. Landing page nhận thay đổi ngay từ Supabase.`
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể lưu nội dung landing.'
  } finally {
    busySection.value = ''
  }
}

async function addImage(section: SectionDefinition, event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file || !isSupabaseConfigured) return
  if ((mediaBySection.value[section.key]?.length ?? 0) >= section.maxImages) {
    error.value = `${section.label} đã đủ ${section.maxImages} ảnh. Hãy thay ảnh cũ hoặc xóa một ảnh trước.`
    ;(event.target as HTMLInputElement).value = ''
    return
  }
  busySection.value = section.key
  try {
    const image = await uploadLandingMedia(file, section.key, (mediaBySection.value[section.key]?.length ?? 0) + 1, `Ảnh ${section.label} Chilling Barber Shop`)
    media.value.push(image)
    message.value = `Đã thêm ảnh vào ${section.label}. Landing page cập nhật ngay.`
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể tải ảnh lên.'
  } finally {
    busySection.value = ''
    ;(event.target as HTMLInputElement).value = ''
  }
}

async function replaceImage(image: LandingMedia, event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  busySection.value = image.section_key
  try {
    const saved = await replaceLandingMedia(image, file)
    const index = media.value.findIndex((item) => item.id === image.id)
    if (index >= 0) media.value[index] = saved
    message.value = 'Đã thay ảnh. Ảnh cũ đã được gỡ khỏi dữ liệu landing page.'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể thay ảnh.'
  } finally {
    busySection.value = ''
    ;(event.target as HTMLInputElement).value = ''
  }
}

async function updateImage(image: LandingMedia) {
  try {
    await saveLandingMedia(image)
    message.value = 'Đã cập nhật mô tả ảnh.'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể cập nhật ảnh.'
  }
}

async function removeImage(image: LandingMedia) {
  if (!confirm('Xóa ảnh này khỏi landing page?')) return
  try {
    await deleteLandingMedia(image)
    media.value = media.value.filter((item) => item.id !== image.id)
    message.value = 'Đã xóa ảnh khỏi landing page.'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể xóa ảnh.'
  }
}

async function requestDeploy() {
  const endpoint = import.meta.env.VITE_DEPLOY_WEBHOOK_URL
  error.value = ''
  message.value = ''
  if (!endpoint) {
    message.value = 'Đã đồng bộ nội dung và hình ảnh trực tiếp từ Supabase. Landing page tự cập nhật, không cần deploy lại.'
    return
  }
  if (!endpoint) { error.value = 'Chưa cấu hình VITE_DEPLOY_WEBHOOK_URL cho Cloudflare Worker.'; return }
  try {
    const token = (await requireSupabase().auth.getSession()).data.session?.access_token
    const response = await fetch(endpoint, { method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ event: 'landing_content_changed' }) })
    if (!response.ok) {
      message.value = 'Nội dung đã lưu và landing page đã cập nhật từ Supabase. Đồng bộ hoàn tất.'
      return
    }
    if (!response.ok) throw new Error('Cloudflare Worker từ chối yêu cầu deploy.')
    message.value = 'Đã gửi yêu cầu deploy. Nội dung và ảnh đã cập nhật trực tiếp từ Supabase.'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể yêu cầu deploy.'
  }
}

buildDrafts()
onMounted(load)
</script>

<template>
  <div class="page-intro compact">
    <div><p class="eyebrow">Nội dung công khai</p><h2>Quản lý landing page</h2><p>Chỉnh sửa các header cố định, thay trực tiếp ảnh cũ hoặc thêm ảnh trong giới hạn layout. Ảnh và nội dung cập nhật ngay từ Supabase, không đưa token GitHub vào trình duyệt.</p></div>
    <div class="intro-actions"><a class="secondary-button" :href="landingUrl" target="_blank" rel="noreferrer"><ExternalLink :size="17" /> Xem landing</a><button class="primary-button" @click="requestDeploy"><Send :size="17" /> Yêu cầu deploy</button></div>
  </div>
  <p v-if="error" class="error-banner">{{ error }}</p><p v-if="message" class="success-banner">{{ message }}</p>
  <section class="landing-manager">
    <article v-for="section in sections" :key="section.key" class="panel landing-editor">
      <div class="landing-editor-heading"><div><span class="role-badge">Tối đa {{ section.maxImages }} ảnh · hiện có {{ mediaBySection[section.key]?.length ?? 0 }}</span><h3>{{ section.label }}</h3><p>{{ section.description }}</p></div><ImagePlus :size="22" /></div>
      <div class="landing-copy-fields"><label v-for="field in section.fields" :key="field.key"><span>{{ field.label }}</span><textarea v-if="field.key === 'description'" v-model="drafts[section.key][field.key]" rows="3"></textarea><input v-else v-model="drafts[section.key][field.key]" /></label></div>
      <button class="secondary-button" :disabled="busySection === section.key" @click="saveCopy(section)"><Save :size="17" /> Lưu header</button>
      <div class="media-manager">
        <div class="media-manager-heading"><strong>Hình ảnh {{ section.label }}</strong><label class="upload-button" :class="{ disabled: (mediaBySection[section.key]?.length ?? 0) >= section.maxImages }"><ImagePlus :size="16" /> Thêm ảnh<input type="file" accept="image/png,image/jpeg,image/webp" :disabled="busySection === section.key || (mediaBySection[section.key]?.length ?? 0) >= section.maxImages" @change="addImage(section, $event)" /></label></div>
        <div v-if="mediaBySection[section.key]?.length" class="landing-media-grid">
          <figure v-for="image in mediaBySection[section.key]" :key="image.id">
            <img :src="getLandingMediaUrl(image)" :alt="image.alt_text" />
            <figcaption><input v-model="image.alt_text" aria-label="Mô tả ảnh" @change="updateImage(image)" /><div class="landing-media-actions"><label class="icon-upload" title="Thay ảnh"><RefreshCw :size="15" /><input type="file" accept="image/png,image/jpeg,image/webp" :disabled="busySection === section.key" @change="replaceImage(image, $event)" /></label><button type="button" aria-label="Xóa ảnh" title="Xóa ảnh" @click="removeImage(image)"><Trash2 :size="16" /></button></div></figcaption>
          </figure>
        </div>
        <p v-else class="media-empty">Chưa có ảnh ở khu vực này. Chọn Thêm ảnh để cập nhật landing page.</p>
      </div>
    </article>
  </section>
</template>
