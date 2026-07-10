<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { BriefcaseBusiness, Plus, Trash2, UserRound } from 'lucide-vue-next'
import { DEMO_STAFF, deleteStaff, getStaff, saveStaff } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { AppRole, Staff } from '../types/domain'

const staff = ref<Staff[]>(DEMO_STAFF)
const showForm = ref(false)
const error = ref('')
const form = reactive<Partial<Staff>>({ position: 'barber', is_active: true, field_one_label: 'Ngày vào làm', field_two_label: 'Quê quán', field_three_label: 'Số điện thoại' })
const roleLabel: Record<AppRole, string> = { owner: 'Boss / Chủ quán', manager: 'Quản lý', cashier: 'Thu ngân', barber: 'Barber', skinner: 'Skinner' }

async function load() { if (isSupabaseConfigured) staff.value = await getStaff() }
function openNew() { Object.assign(form, { id: undefined, display_name: '', position: 'barber', phone: '', field_one_label: 'Ngày vào làm', field_one_value: '', field_two_label: 'Quê quán', field_two_value: '', field_three_label: 'Số điện thoại', field_three_value: '', is_active: true }); showForm.value = true }
async function save() { error.value = ''; try { const saved = await saveStaff(form); const index = staff.value.findIndex((item) => item.id === saved.id); if (index >= 0) staff.value[index] = saved; else staff.value.unshift(saved); showForm.value = false } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể lưu nhân viên.' } }
async function remove(id: string) { if (!confirm('Xóa nhân viên này khỏi hệ thống?')) return; try { await deleteStaff(id); staff.value = staff.value.filter((item) => item.id !== id) } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể xóa nhân viên.' } }

onMounted(load)
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Đội ngũ Chilling</p><h2>Nhân viên và hiệu suất dịch vụ</h2><p>Mỗi nhân viên liên kết với lịch sử order, doanh thu và KPI theo từng dịch vụ đã thực hiện.</p></div><button class="primary-button" @click="openNew"><Plus :size="18" /> Thêm nhân viên</button></div><p v-if="error" class="error-banner">{{ error }}</p>
  <div class="staff-grid"><article v-for="person in staff" :key="person.id" class="staff-card"><div class="staff-card-top"><div class="staff-avatar"><img v-if="person.avatar_url" :src="person.avatar_url" :alt="person.display_name" /><UserRound v-else :size="34" /></div><div><span class="role-badge">{{ roleLabel[person.position] }}</span><h3>{{ person.display_name }}</h3><p>{{ person.phone || 'Chưa cập nhật số điện thoại' }}</p></div></div><dl><div><dt>{{ person.field_one_label || 'Thông tin 1' }}</dt><dd>{{ person.field_one_value || '—' }}</dd></div><div><dt>{{ person.field_two_label || 'Thông tin 2' }}</dt><dd>{{ person.field_two_value || '—' }}</dd></div><div><dt>{{ person.field_three_label || 'Thông tin 3' }}</dt><dd>{{ person.field_three_value || '—' }}</dd></div></dl><div class="staff-card-bottom"><span><BriefcaseBusiness :size="16" /> KPI và lịch sử order</span><button type="button" aria-label="Xóa nhân viên" @click="remove(person.id)"><Trash2 :size="17" /></button></div></article></div>
  <div v-if="showForm" class="modal-backdrop" @click.self="showForm = false"><form class="modal-card" @submit.prevent="save"><div class="modal-heading"><h3>Thêm nhân viên</h3><button type="button" @click="showForm = false">×</button></div><div class="form-grid"><label><span>Họ tên *</span><input v-model="form.display_name" required /></label><label><span>Vị trí *</span><select v-model="form.position"><option value="owner">Boss / Chủ quán</option><option value="manager">Quản lý</option><option value="cashier">Thu ngân</option><option value="barber">Barber</option><option value="skinner">Skinner</option></select></label><label><span>Số điện thoại</span><input v-model="form.phone" /></label><label><span>{{ form.field_one_label }}</span><input v-model="form.field_one_value" /></label><label><span>{{ form.field_two_label }}</span><input v-model="form.field_two_value" /></label><label><span>{{ form.field_three_label }}</span><input v-model="form.field_three_value" /></label></div><button class="primary-button">Lưu nhân viên</button></form></div>
</template>
