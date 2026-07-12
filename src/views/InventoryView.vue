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
const money = (value: number) => `${value.toLocaleString('vi-VN')}đ`
const today = () => new Date().toLocaleDateString('vi-VN')

async function load() {
  if (!isSupabaseConfigured) return
  try {
    const [inventory, history] = await Promise.all([getInventory(), getInventoryMovements()])
    items.value = inventory
    movements.value = history
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể tải dữ liệu kho.'
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
    error.value = cause instanceof Error ? cause.message : 'Không thể cập nhật tồn kho.'
  }
}

async function submitImport() {
  error.value = ''
  if (!isSupabaseConfigured) { error.value = 'Chưa có cấu hình Supabase.'; return }
  if (importForm.quantity <= 0 || importForm.unitCost < 0) { error.value = 'Số lượng và đơn giá nhập kho không hợp lệ.'; return }
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
    await recordInventoryMovement({ itemId: item.id, type: 'in', quantity: importForm.quantity, unitCost: importForm.unitCost, note: importForm.note.trim() || `Nhập kho ${today()}` })
    showAction.value = null
    activePanel.value = 'stock'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể nhập kho.'
  }
}

async function submitExport() {
  error.value = ''
  if (!isSupabaseConfigured) { error.value = 'Chưa có cấu hình Supabase.'; return }
  if (!exportForm.itemId || exportForm.quantity <= 0) { error.value = 'Vui long chon san pham va so luong xuat.'; return }
  try {
    await recordInventoryMovement({ itemId: exportForm.itemId, type: 'out', quantity: exportForm.quantity, note: exportForm.note.trim() || `Xuất kho ${today()}` })
    showAction.value = null
    activePanel.value = 'history'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể xuất kho.'
  }
}

onMounted(load)
</script>

<template>
  <div class="page-intro compact">
    <div><p class="eyebrow">Vận hành kho</p><h2>Quản lý tồn kho</h2><p>Lịch sử nhập, xuất được tự động dọn sau 90 ngày; chi phí nhập kho được cộng vào chi tiêu thực tế.</p></div>
    <div class="intro-actions"><button class="secondary-button" @click="openExport"><ArrowUpFromLine :size="17" /> Xuất kho</button><button class="primary-button" @click="openImport"><ArrowDownToLine :size="17" /> Nhập kho</button></div>
  </div>
  <p v-if="error" class="error-banner">{{ error }}</p>
  <section class="inventory-stat-strip"><article><span>Tổng mặt hàng</span><strong>{{ items.length }}</strong></article><article><span>Giá trị tồn ước tính</span><strong>{{ money(totalStockValue) }}</strong></article><article><span>Lịch sử hiển thị</span><strong>90 ngày gần nhất</strong></article></section>

  <div class="inventory-panel-tabs" role="tablist" aria-label="Dữ liệu kho"><button type="button" :class="{ active: activePanel === 'stock' }" @click="activePanel = 'stock'">Chi tiết tồn kho</button><button type="button" :class="{ active: activePanel === 'history' }" @click="activePanel = 'history'">Lịch sử hoạt động</button></div>
  <section v-if="activePanel === 'stock'" class="panel table-panel inventory-table"><div class="table-heading"><div><h3>Bảng chi tiết tồn kho</h3><p>Chọn Sửa ngay trên dòng sản phẩm để cập nhật thông tin; các ô trong bảng chỉ dùng để theo dõi nhanh.</p></div><PackagePlus :size="22" /></div><table><thead><tr><th>Mã sản phẩm</th><th>Tên sản phẩm</th><th>Tồn kho</th><th>Đơn vị</th><th>Đơn giá</th><th>Thông tin bổ sung</th><th>Thao tác</th></tr></thead><tbody><tr v-for="item in items" :key="item.id"><td><code>{{ item.item_code }}</code></td><td><strong>{{ item.name }}</strong></td><td>{{ item.quantity }}</td><td>{{ item.unit }}</td><td>{{ money(item.unit_cost) }}</td><td><span>{{ item.field_one_label ? `${item.field_one_label}: ${item.field_one_value || '-'}` : '-' }}</span><span v-if="item.field_two_label">{{ item.field_two_label }}: {{ item.field_two_value || '-' }}</span></td><td><button class="inline-action" @click="openEdit(item)"><Pencil :size="16" /> Sửa</button></td></tr><tr v-if="!items.length"><td colspan="7" class="empty-table">Chưa có sản phẩm trong kho.</td></tr></tbody></table></section>

  <section v-else class="panel table-panel inventory-history"><div class="table-heading"><div><h3>Lịch sử hoạt động</h3><p>Tự động xóa sau 90 ngày để dữ liệu vận hành luôn gọn nhẹ.</p></div><ClipboardList :size="22" /></div><table><thead><tr><th>Thời gian</th><th>Sản phẩm</th><th>Loại</th><th>Số lượng</th><th>Đơn giá</th><th>Tổng tiền</th><th>Ghi chú</th></tr></thead><tbody><tr v-for="movement in movements" :key="movement.id"><td>{{ new Date(movement.created_at).toLocaleString('vi-VN') }}</td><td><strong>{{ movement.inventory_items?.name || 'Sản phẩm đã xóa' }}</strong><span>{{ movement.inventory_items?.item_code }}</span></td><td><span class="movement-badge" :class="`movement-${movement.movement_type}`">{{ movement.movement_type === 'in' ? 'Nhập kho' : 'Xuất kho' }}</span></td><td>{{ movement.quantity }} {{ movement.inventory_items?.unit || '' }}</td><td>{{ movement.movement_type === 'in' ? money(movement.unit_cost) : '-' }}</td><td><strong>{{ movement.movement_type === 'in' ? money(movement.quantity * movement.unit_cost) : '-' }}</strong></td><td>{{ movement.note || '-' }}</td></tr><tr v-if="!movements.length"><td colspan="7" class="empty-table">Chưa có lịch sử hoạt động.</td></tr></tbody></table></section>

  <div v-if="showAction" class="modal-backdrop" @click.self="showAction = null">
    <form v-if="showAction === 'in'" class="modal-card inventory-modal" @submit.prevent="submitImport"><div class="modal-heading"><div><h3>Nhập kho</h3><p>Mã sản phẩm và ngày nhập được hệ thống tự sinh.</p></div><button type="button" @click="showAction = null">x</button></div><div class="form-grid"><label><span>Nhập thêm vào sản phẩm có sẵn</span><select v-model="importExistingId" @change="useExistingItem"><option value="">Tạo sản phẩm mới</option><option v-for="item in items" :key="item.id" :value="item.id">{{ item.item_code }} - {{ item.name }}</option></select></label><label><span>Tên sản phẩm *</span><input v-model="importForm.name" :disabled="!!selectedImportItem" required /></label><label><span>Đơn vị tính *</span><input v-model="importForm.unit" :disabled="!!selectedImportItem" required /></label><label><span>Số lượng nhập *</span><input v-model.number="importForm.quantity" type="number" min="0.01" step="0.01" required /></label><label><span>Đơn giá nhập *</span><input v-model.number="importForm.unitCost" type="number" min="0" required /></label><label><span>Ngày nhập</span><input :value="today()" disabled /></label><label><span>Ghi chú</span><input v-model="importForm.note" placeholder="Tùy chọn" /></label></div><div v-if="!selectedImportItem" class="custom-field-heading"><h4>Thông tin phát sinh</h4><span>Thêm tối đa hai trường tùy chỉnh cho sản phẩm mới</span></div><div v-if="!selectedImportItem" class="form-grid custom-field-grid"><label><span>Header trường 1</span><input v-model="importForm.fieldOneLabel" placeholder="Ví dụ: Nhà cung cấp" /></label><label><span>Dữ liệu trường 1</span><input v-model="importForm.fieldOneValue" /></label><label><span>Header trường 2</span><input v-model="importForm.fieldTwoLabel" placeholder="Ví dụ: Hạn sử dụng" /></label><label><span>Dữ liệu trường 2</span><input v-model="importForm.fieldTwoValue" /></label></div><button class="primary-button"><ArrowDownToLine :size="18" /> Xác nhận nhập kho</button></form>
    <form v-else-if="showAction === 'out'" class="modal-card inventory-modal" @submit.prevent="submitExport"><div class="modal-heading"><div><h3>Xuất kho</h3><p>Chỉ chọn sản phẩm đã có trong bảng tồn kho.</p></div><button type="button" @click="showAction = null">x</button></div><div class="form-grid"><label><span>Sản phẩm *</span><select v-model="exportForm.itemId" required><option v-for="item in items" :key="item.id" :value="item.id">{{ item.item_code }} - {{ item.name }} (còn {{ item.quantity }} {{ item.unit }})</option></select></label><label><span>Số lượng xuất *</span><input v-model.number="exportForm.quantity" type="number" min="0.01" step="0.01" required /></label><label><span>Ghi chú</span><input v-model="exportForm.note" placeholder="Ví dụ: Dùng cho khách hàng" /></label></div><button class="primary-button"><ArrowUpFromLine :size="18" /> Xác nhận xuất kho</button></form>
    <form v-else class="modal-card inventory-modal" @submit.prevent="submitEdit"><div class="modal-heading"><div><h3>Chỉnh sửa sản phẩm</h3><p>Cập nhật toàn bộ thông tin trong một thao tác trên dòng tồn kho.</p></div><button type="button" @click="showAction = null">x</button></div><div class="form-grid"><label><span>Mã sản phẩm</span><input :value="editForm.item_code" disabled /></label><label><span>Tên sản phẩm *</span><input v-model="editForm.name" required /></label><label><span>Số lượng tồn</span><input v-model.number="editForm.quantity" type="number" min="0" required /></label><label><span>Đơn vị tính *</span><input v-model="editForm.unit" required /></label><label><span>Đơn giá</span><input v-model.number="editForm.unit_cost" type="number" min="0" required /></label></div><div class="custom-field-heading"><h4>Thông tin bổ sung</h4><span>Có thể đổi header khi nhu cầu vận hành thay đổi</span></div><div class="form-grid custom-field-grid"><label><span>Header trường 1</span><input v-model="editForm.field_one_label" /></label><label><span>Dữ liệu trường 1</span><input v-model="editForm.field_one_value" /></label><label><span>Header trường 2</span><input v-model="editForm.field_two_label" /></label><label><span>Dữ liệu trường 2</span><input v-model="editForm.field_two_value" /></label></div><button class="primary-button"><Save :size="18" /> Lưu thay đổi</button></form>
  </div>
</template>
