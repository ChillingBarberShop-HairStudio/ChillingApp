<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { BriefcaseBusiness, ImagePlus, Pencil, Plus, Trash2, UserRound } from 'lucide-vue-next'
import { deleteStaff, getStaff, saveStaff, uploadStaffAvatar } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { Staff } from '../types/domain'

const staff = ref<Staff[]>([])
const showForm = ref(false)
const error = ref('')
const avatarFile = ref<File | null>(null)
const avatarPreview = ref('')
const form = reactive<Partial<Staff>>({ position: 'Barber', is_active: true })

async function load() { if (isSupabaseConfigured) staff.value = await getStaff() }
function openNew() { Object.assign(form, { id: undefined, display_name: '', position: 'Barber', phone: '', avatar_url: null, field_one_label: '', field_one_value: '', field_two_label: '', field_two_value: '', field_three_label: null, field_three_value: null, is_active: true }); avatarFile.value = null; avatarPreview.value = ''; showForm.value = true }
function openEdit(person: Staff) { Object.assign(form, { ...person }); avatarFile.value = null; avatarPreview.value = person.avatar_url ?? ''; showForm.value = true }
function selectAvatar(event: Event) { const file = (event.target as HTMLInputElement).files?.[0]; if (!file) return; avatarFile.value = file; avatarPreview.value = URL.createObjectURL(file) }
async function save() { error.value = ''; try { if (avatarFile.value) form.avatar_url = await uploadStaffAvatar(avatarFile.value); const saved = await saveStaff(form); const index = staff.value.findIndex((item) => item.id === saved.id); if (index >= 0) staff.value[index] = saved; else staff.value.unshift(saved); showForm.value = false } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể lưu nhân viên.' } }
async function remove(id: string) { if (!confirm('Xóa nhân viên này khỏi hệ thống?')) return; try { await deleteStaff(id); staff.value = staff.value.filter((item) => item.id !== id) } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể xóa nhân viên.' } }

onMounted(load)
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Đội ngũ Chilling</p><h2>Nhân viên và hiệu suất dịch vụ</h2></div><button class="primary-button" @click="openNew"><Plus :size="18" /> Thêm nhân viên</button></div><p v-if="error" class="error-banner">{{ error }}</p>
  <div class="staff-grid"><article v-for="person in staff" :key="person.id" class="staff-card"><div class="staff-card-top"><div class="staff-avatar"><img v-if="person.avatar_url" :src="person.avatar_url" :alt="person.display_name" /><UserRound v-else :size="34" /></div><div><span class="role-badge">{{ person.position || 'Chưa cập nhật vị trí' }}</span><h3>{{ person.display_name }}</h3><p>{{ person.phone || 'Chưa cập nhật số điện thoại' }}</p></div></div><dl><div v-if="person.field_one_label"><dt>{{ person.field_one_label }}</dt><dd>{{ person.field_one_value || '—' }}</dd></div><div v-if="person.field_two_label"><dt>{{ person.field_two_label }}</dt><dd>{{ person.field_two_value || '—' }}</dd></div><div v-if="person.field_three_label"><dt>{{ person.field_three_label }}</dt><dd>{{ person.field_three_value || '—' }}</dd></div></dl><div class="staff-card-bottom"><span><BriefcaseBusiness :size="16" /> KPI và lịch sử order</span><div class="staff-card-actions"><button type="button" aria-label="Sửa nhân viên" @click="openEdit(person)"><Pencil :size="17" /></button><button type="button" aria-label="Xóa nhân viên" @click="remove(person.id)"><Trash2 :size="17" /></button></div></div></article></div>
  <div v-if="showForm" class="modal-backdrop" @click.self="showForm = false"><form class="modal-card" @submit.prevent="save"><div class="modal-heading"><h3>{{ form.id ? 'Chỉnh sửa nhân viên' : 'Thêm nhân viên' }}</h3><button type="button" @click="showForm = false">×</button></div><div class="staff-avatar-upload"><div class="staff-avatar"><img v-if="avatarPreview" :src="avatarPreview" alt="Xem trước ảnh nhân viên" /><UserRound v-else :size="34" /></div><label class="upload-button"><ImagePlus :size="17" /> {{ form.id ? 'Thay ảnh nhân viên' : 'Thêm ảnh nhân viên' }}<input type="file" accept="image/png,image/jpeg,image/webp" @change="selectAvatar" /></label><span>JPG, PNG hoặc WebP · tối đa 5MB</span></div><div class="form-grid"><label><span>Họ tên *</span><input v-model="form.display_name" required /></label><label><span>Vị trí *</span><input v-model="form.position" placeholder="Ví dụ: Boss, Barber, Skinner" required /></label><label><span>Số điện thoại</span><input v-model="form.phone" inputmode="tel" /></label></div><div class="custom-field-heading"><h4>Thông tin bổ sung</h4><span>Tùy chọn, có thể tự đặt header theo nhu cầu</span></div><div class="form-grid custom-field-grid"><label><span>Header trường 1</span><input v-model="form.field_one_label" placeholder="Ví dụ: Ngày vào làm" /></label><label><span>Dữ liệu trường 1</span><input v-model="form.field_one_value" placeholder="Ví dụ: 01/01/2026" /></label><label><span>Header trường 2</span><input v-model="form.field_two_label" placeholder="Ví dụ: Quê quán" /></label><label><span>Dữ liệu trường 2</span><input v-model="form.field_two_value" placeholder="Ví dụ: Bình Dương" /></label></div><button class="primary-button">{{ form.id ? 'Lưu thay đổi' : 'Lưu nhân viên' }}</button></form></div>
</template>
