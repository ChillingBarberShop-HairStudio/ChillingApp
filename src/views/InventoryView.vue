<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ArrowDownToLine, ArrowUpFromLine, ClipboardList, PackagePlus, Pencil, Save } from 'lucide-vue-next'
import { getInventory, getInventoryMovements, recordInventoryMovement, saveInventory } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { InventoryItem, InventoryMovement } from '../types/domain'

type StockAction = 'in' | 'out' | 'edit'
type InventoryPanel = 'stock' | 'history'

const items = ref<InventoryItem[]>([])
const movements = ref<InventoryMovement[]>([])
const error = ref('')
const showAction = ref<StockAction | null>(null)
const activePanel = ref<InventoryPanel>('stock')
const importExistingId = ref('')
const importForm = reactive({ name: '', unit: 'hop', quantity: 1, unitCost: 0, fieldOneLabel: '', fieldOneValue: '', fieldTwoLabel: '', fieldTwoValue: '', note: '' })
const exportForm = reactive({ itemId: '', quantity: 1, note: '' })
const editForm = reactive<Partial<InventoryItem>>({})
const totalStockValue = computed(() => items.value.reduce((total, item) => total + item.quantity * item.unit_cost, 0))
const selectedImportItem = computed(() => items.value.find((item) => item.id === importExistingId.value) ?? null)
const money = (value: number) => `${value.toLocaleString('vi-VN')}d`
const today = () => new Date().toLocaleDateString('vi-VN')

async function load() {
  if (!isSupabaseConfigured) return
  try {
    const [inventory, history] = await Promise.all([getInventory(), getInventoryMovements()])
    items.value = inventory
    movements.value = history
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Khong the tai du lieu kho.'
  }
}

function openImport() {
  Object.assign(importForm, { name: '', unit: 'hop', quantity: 1, unitCost: 0, fieldOneLabel: '', fieldOneValue: '', fieldTwoLabel: '', fieldTwoValue: '', note: '' })
  importExistingId.value = ''
  showAction.value = 'in'
}

function openExport() {
  exportForm.itemId = items.value[0]?.id ?? ''
  exportForm.quantity = 1
  exportForm.note = ''
  showAction.value = 'out'
}

function openEdit(item: InventoryItem) {
  Object.assign(editForm, { ...item })
  showAction.value = 'edit'
}

function useExistingItem() {
  const item = selectedImportItem.value
  if (!item) return
  importForm.name = item.name
  importForm.unit = item.unit
}

async function submitEdit() {
  error.value = ''
  try {
    const saved = await saveInventory(editForm)
    const index = items.value.findIndex((item) => item.id === saved.id)
    if (index >= 0) items.value[index] = saved
    showAction.value = null
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Khong the cap nhat ton kho.'
  }
}

async function submitImport() {
  error.value = ''
  if (!isSupabaseConfigured) { error.value = 'Chua co cau hinh Supabase.'; return }
  if (importForm.quantity <= 0 || importForm.unitCost < 0) { error.value = 'So luong va don gia nhap kho khong hop le.'; return }
  try {
    let item = selectedImportItem.value
    if (!item) {
      if (!importForm.name.trim() || !importForm.unit.trim()) { error.value = 'Vui long nhap ten san pham va don vi tinh.'; return }
      item = await saveInventory({
        name: importForm.name.trim(), quantity: 0, unit: importForm.unit.trim(), unit_cost: 0,
        field_one_label: importForm.fieldOneLabel.trim() || null, field_one_value: importForm.fieldOneValue.trim() || null,
        field_two_label: importForm.fieldTwoLabel.trim() || null, field_two_value: importForm.fieldTwoValue.trim() || null,
      })
    }
    await recordInventoryMovement({ itemId: item.id, type: 'in', quantity: importForm.quantity, unitCost: importForm.unitCost, note: importForm.note.trim() || `Nhap kho ${today()}` })
    showAction.value = null
    activePanel.value = 'stock'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Khong the nhap kho.'
  }
}

async function submitExport() {
  error.value = ''
  if (!isSupabaseConfigured) { error.value = 'Chua co cau hinh Supabase.'; return }
  if (!exportForm.itemId || exportForm.quantity <= 0) { error.value = 'Vui long chon san pham va so luong xuat.'; return }
  try {
    await recordInventoryMovement({ itemId: exportForm.itemId, type: 'out', quantity: exportForm.quantity, note: exportForm.note.trim() || `Xuat kho ${today()}` })
    showAction.value = null
    activePanel.value = 'history'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Khong the xuat kho.'
  }
}

onMounted(load)
</script>

<template>
  <div class="page-intro compact">
    <div><p class="eyebrow">Van hanh kho</p><h2>Quan ly ton kho</h2><p>Lich su nhap, xuat duoc tu dong don sau 90 ngay; chi phi nhap kho duoc cong vao chi tieu thuc te.</p></div>
    <div class="intro-actions"><button class="secondary-button" @click="openExport"><ArrowUpFromLine :size="17" /> Xuat kho</button><button class="primary-button" @click="openImport"><ArrowDownToLine :size="17" /> Nhap kho</button></div>
  </div>
  <p v-if="error" class="error-banner">{{ error }}</p>
  <section class="inventory-stat-strip"><article><span>Tong mat hang</span><strong>{{ items.length }}</strong></article><article><span>Gia tri ton uoc tinh</span><strong>{{ money(totalStockValue) }}</strong></article><article><span>Lich su hien thi</span><strong>90 ngay gan nhat</strong></article></section>

  <div class="inventory-panel-tabs" role="tablist" aria-label="Du lieu kho"><button type="button" :class="{ active: activePanel === 'stock' }" @click="activePanel = 'stock'">Chi tiet ton kho</button><button type="button" :class="{ active: activePanel === 'history' }" @click="activePanel = 'history'">Lich su hoat dong</button></div>
  <section v-if="activePanel === 'stock'" class="panel table-panel inventory-table"><div class="table-heading"><div><h3>Bang chi tiet ton kho</h3><p>Chon Sua ngay tren dong san pham de cap nhat thong tin; cac o trong bang chi dung de theo doi nhanh.</p></div><PackagePlus :size="22" /></div><table><thead><tr><th>Ma san pham</th><th>Ten san pham</th><th>Ton kho</th><th>Don vi</th><th>Don gia</th><th>Thong tin bo sung</th><th>Thao tac</th></tr></thead><tbody><tr v-for="item in items" :key="item.id"><td><code>{{ item.item_code }}</code></td><td><strong>{{ item.name }}</strong></td><td>{{ item.quantity }}</td><td>{{ item.unit }}</td><td>{{ money(item.unit_cost) }}</td><td><span>{{ item.field_one_label ? `${item.field_one_label}: ${item.field_one_value || '-'}` : '-' }}</span><span v-if="item.field_two_label">{{ item.field_two_label }}: {{ item.field_two_value || '-' }}</span></td><td><button class="inline-action" @click="openEdit(item)"><Pencil :size="16" /> Sua</button></td></tr><tr v-if="!items.length"><td colspan="7" class="empty-table">Chua co san pham trong kho.</td></tr></tbody></table></section>

  <section v-else class="panel table-panel inventory-history"><div class="table-heading"><div><h3>Lich su hoat dong</h3><p>Tu dong xoa sau 90 ngay de du lieu van hanh luon gon nhe.</p></div><ClipboardList :size="22" /></div><table><thead><tr><th>Thoi gian</th><th>San pham</th><th>Loai</th><th>So luong</th><th>Don gia</th><th>Tong tien</th><th>Ghi chu</th></tr></thead><tbody><tr v-for="movement in movements" :key="movement.id"><td>{{ new Date(movement.created_at).toLocaleString('vi-VN') }}</td><td><strong>{{ movement.inventory_items?.name || 'San pham da xoa' }}</strong><span>{{ movement.inventory_items?.item_code }}</span></td><td><span class="movement-badge" :class="`movement-${movement.movement_type}`">{{ movement.movement_type === 'in' ? 'Nhap kho' : 'Xuat kho' }}</span></td><td>{{ movement.quantity }} {{ movement.inventory_items?.unit || '' }}</td><td>{{ movement.movement_type === 'in' ? money(movement.unit_cost) : '-' }}</td><td><strong>{{ movement.movement_type === 'in' ? money(movement.quantity * movement.unit_cost) : '-' }}</strong></td><td>{{ movement.note || '-' }}</td></tr><tr v-if="!movements.length"><td colspan="7" class="empty-table">Chua co lich su hoat dong.</td></tr></tbody></table></section>

  <div v-if="showAction" class="modal-backdrop" @click.self="showAction = null">
    <form v-if="showAction === 'in'" class="modal-card inventory-modal" @submit.prevent="submitImport"><div class="modal-heading"><div><h3>Nhap kho</h3><p>Ma san pham va ngay nhap duoc he thong tu sinh.</p></div><button type="button" @click="showAction = null">x</button></div><div class="form-grid"><label><span>Nhap them vao san pham co san</span><select v-model="importExistingId" @change="useExistingItem"><option value="">Tao san pham moi</option><option v-for="item in items" :key="item.id" :value="item.id">{{ item.item_code }} - {{ item.name }}</option></select></label><label><span>Ten san pham *</span><input v-model="importForm.name" :disabled="!!selectedImportItem" required /></label><label><span>Don vi tinh *</span><input v-model="importForm.unit" :disabled="!!selectedImportItem" required /></label><label><span>So luong nhap *</span><input v-model.number="importForm.quantity" type="number" min="0.01" step="0.01" required /></label><label><span>Don gia nhap *</span><input v-model.number="importForm.unitCost" type="number" min="0" required /></label><label><span>Ngay nhap</span><input :value="today()" disabled /></label><label><span>Ghi chu</span><input v-model="importForm.note" placeholder="Tuy chon" /></label></div><div v-if="!selectedImportItem" class="custom-field-heading"><h4>Thong tin phat sinh</h4><span>Them toi da hai truong tuy chinh cho san pham moi</span></div><div v-if="!selectedImportItem" class="form-grid custom-field-grid"><label><span>Header truong 1</span><input v-model="importForm.fieldOneLabel" placeholder="Vi du: Nha cung cap" /></label><label><span>Du lieu truong 1</span><input v-model="importForm.fieldOneValue" /></label><label><span>Header truong 2</span><input v-model="importForm.fieldTwoLabel" placeholder="Vi du: Han su dung" /></label><label><span>Du lieu truong 2</span><input v-model="importForm.fieldTwoValue" /></label></div><button class="primary-button"><ArrowDownToLine :size="18" /> Xac nhan nhap kho</button></form>
    <form v-else-if="showAction === 'out'" class="modal-card inventory-modal" @submit.prevent="submitExport"><div class="modal-heading"><div><h3>Xuat kho</h3><p>Chi chon san pham da co trong bang ton kho.</p></div><button type="button" @click="showAction = null">x</button></div><div class="form-grid"><label><span>San pham *</span><select v-model="exportForm.itemId" required><option v-for="item in items" :key="item.id" :value="item.id">{{ item.item_code }} - {{ item.name }} (con {{ item.quantity }} {{ item.unit }})</option></select></label><label><span>So luong xuat *</span><input v-model.number="exportForm.quantity" type="number" min="0.01" step="0.01" required /></label><label><span>Ghi chu</span><input v-model="exportForm.note" placeholder="Vi du: Dung cho khach hang" /></label></div><button class="primary-button"><ArrowUpFromLine :size="18" /> Xac nhan xuat kho</button></form>
    <form v-else class="modal-card inventory-modal" @submit.prevent="submitEdit"><div class="modal-heading"><div><h3>Chinh sua san pham</h3><p>Cap nhat toan bo thong tin trong mot thao tac tren dong ton kho.</p></div><button type="button" @click="showAction = null">x</button></div><div class="form-grid"><label><span>Ma san pham</span><input :value="editForm.item_code" disabled /></label><label><span>Ten san pham *</span><input v-model="editForm.name" required /></label><label><span>So luong ton</span><input v-model.number="editForm.quantity" type="number" min="0" required /></label><label><span>Don vi tinh *</span><input v-model="editForm.unit" required /></label><label><span>Don gia</span><input v-model.number="editForm.unit_cost" type="number" min="0" required /></label></div><div class="custom-field-heading"><h4>Thong tin bo sung</h4><span>Co the doi header khi nhu cau van hanh thay doi</span></div><div class="form-grid custom-field-grid"><label><span>Header truong 1</span><input v-model="editForm.field_one_label" /></label><label><span>Du lieu truong 1</span><input v-model="editForm.field_one_value" /></label><label><span>Header truong 2</span><input v-model="editForm.field_two_label" /></label><label><span>Du lieu truong 2</span><input v-model="editForm.field_two_value" /></label></div><button class="primary-button"><Save :size="18" /> Luu thay doi</button></form>
  </div>
</template>
