<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ArrowDownToLine, ArrowUpFromLine, PackagePlus, Save } from 'lucide-vue-next'
import { DEMO_INVENTORY, getInventory, saveInventory } from '../lib/api'
import { isSupabaseConfigured, requireSupabase } from '../lib/supabase'
import type { InventoryItem } from '../types/domain'

const items = ref<InventoryItem[]>(DEMO_INVENTORY)
const error = ref('')
const movement = reactive({ itemId: '', type: 'in', quantity: 1, unitCost: 0, note: '' })
const newItem = reactive<Partial<InventoryItem>>({ name: '', quantity: 0, unit: 'hộp', unit_cost: 0, field_one_label: 'Nhà cung cấp', field_two_label: 'Vị trí' })
const showNew = ref(false)

async function load() { if (isSupabaseConfigured) items.value = await getInventory(); movement.itemId = items.value[0]?.id ?? '' }
async function saveItem(item: InventoryItem) { try { const saved = await saveInventory(item); const index = items.value.findIndex((row) => row.id === saved.id); if (index >= 0) items.value[index] = saved } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể cập nhật kho.' } }
async function addItem() { try { const saved = await saveInventory(newItem); items.value.unshift(saved); showNew.value = false } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể tạo mặt hàng.' } }
async function recordMovement() { if (!isSupabaseConfigured) { error.value = 'Chế độ demo không ghi dữ liệu.'; return } try { const { error: rpcError } = await requireSupabase().rpc('record_inventory_movement', { p_item_id: movement.itemId, p_movement_type: movement.type, p_quantity: movement.quantity, p_unit_cost: movement.unitCost, p_note: movement.note }); if (rpcError) throw rpcError; await load(); movement.note = '' } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể ghi nhận nhập xuất.' } }

onMounted(load)
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Vận hành kho</p><h2>Kho hàng & chi phí nhập</h2><p>Nhập kho tự sinh chi phí trong KPI; xuất kho kiểm tra tồn trước khi ghi nhận.</p></div><button class="primary-button" @click="showNew = true"><PackagePlus :size="18" /> Thêm mặt hàng</button></div><p v-if="error" class="error-banner">{{ error }}</p>
  <section class="panel movement-panel"><div><h3>Nhập / xuất kho</h3><p>Lịch sử vận hành tự dọn sau 90 ngày, dữ liệu hóa đơn vẫn được giữ lại.</p></div><select v-model="movement.itemId"><option v-for="item in items" :key="item.id" :value="item.id">{{ item.name }}</option></select><select v-model="movement.type"><option value="in">Nhập kho</option><option value="out">Xuất kho</option></select><input v-model.number="movement.quantity" min="1" type="number" placeholder="Số lượng" /><input v-model.number="movement.unitCost" min="0" type="number" placeholder="Đơn giá" /><button class="secondary-button" @click="recordMovement"><ArrowDownToLine v-if="movement.type === 'in'" :size="17" /><ArrowUpFromLine v-else :size="17" /> Ghi nhận</button></section>
  <section class="panel table-panel"><table><thead><tr><th>Mã hàng</th><th>Tên mặt hàng</th><th>Tồn</th><th>Đơn vị</th><th>Đơn giá</th><th>Thông tin thêm</th><th></th></tr></thead><tbody><tr v-for="item in items" :key="item.id"><td><code>{{ item.item_code }}</code></td><td><input v-model="item.name" /></td><td><input v-model.number="item.quantity" type="number" min="0" /></td><td><input v-model="item.unit" /></td><td><input v-model.number="item.unit_cost" type="number" min="0" /></td><td>{{ item.field_one_value || '—' }} · {{ item.field_two_value || '—' }}</td><td><button class="inline-action" @click="saveItem(item)"><Save :size="16" /> Lưu</button></td></tr></tbody></table></section>
  <div v-if="showNew" class="modal-backdrop" @click.self="showNew = false"><form class="modal-card" @submit.prevent="addItem"><div class="modal-heading"><h3>Thêm mặt hàng</h3><button type="button" @click="showNew = false">×</button></div><div class="form-grid"><label><span>Tên sản phẩm *</span><input v-model="newItem.name" required /></label><label><span>Đơn vị *</span><input v-model="newItem.unit" required /></label><label><span>Số lượng</span><input v-model.number="newItem.quantity" type="number" min="0" /></label><label><span>Đơn giá</span><input v-model.number="newItem.unit_cost" type="number" min="0" /></label><label><span>Nhà cung cấp</span><input v-model="newItem.field_one_value" /></label><label><span>Vị trí lưu</span><input v-model="newItem.field_two_value" /></label></div><button class="primary-button">Tạo mặt hàng</button></form></div>
</template>
