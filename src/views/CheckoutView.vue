<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { Banknote, CirclePlus, CreditCard, Minus, Plus, QrCode, ReceiptText, Scissors, X } from 'lucide-vue-next'
import { DEMO_SERVICES, DEMO_STAFF, checkout, getBankAccounts, getBookingForCheckout, getServices, getStaff, saveBankAccount, saveService } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { BankAccount, CheckoutLine, Service, Staff } from '../types/domain'
import { useRoute, useRouter } from 'vue-router'

const services = ref<Service[]>(DEMO_SERVICES)
const staff = ref<Staff[]>(DEMO_STAFF)
const accounts = ref<BankAccount[]>([{ id: 'demo-bank', bank_name: 'MB Bank', bank_bin: '970422', account_number: '0327969930', account_name: 'CHILLING BARBER SHOP', branch_name: 'Bình Dương', is_active: true }])
const customer = reactive({ fullName: '', phone: '' })
const paymentMethod = ref<'cash' | 'bank_transfer'>('cash')
const bankAccountId = ref('demo-bank')
const discountPercent = ref(0)
const lines = ref<CheckoutLine[]>([{ serviceId: 'demo-cut', staffId: 'demo-nam', quantity: 1 }])
const error = ref('')
const success = ref('')
const showAdd = ref<'service' | 'bank' | null>(null)
const bookingId = ref('')
const serviceForm = reactive<Partial<Service>>({ name: '', category: 'Cắt tóc', price: 0, duration_minutes: 30, is_active: true })
const bankForm = reactive<Partial<BankAccount>>({ bank_name: '', bank_bin: '', account_number: '', account_name: '', branch_name: '', is_active: true })
const selectedAccount = computed(() => accounts.value.find((account) => account.id === bankAccountId.value) ?? accounts.value[0])
const resolvedLines = computed(() => lines.value.flatMap((line) => { const service = services.value.find((item) => item.id === line.serviceId); const member = staff.value.find((item) => item.id === line.staffId); return service && member ? [{ ...line, service, member }] : [] }))
const subtotal = computed(() => resolvedLines.value.reduce((sum, line) => sum + line.service.price * line.quantity, 0))
const discountAmount = computed(() => Math.round(subtotal.value * Math.max(0, Math.min(100, discountPercent.value)) / 100))
const total = computed(() => subtotal.value - discountAmount.value)
const transferNote = computed(() => {
  const servicesText = resolvedLines.value.map((line) => line.service.name).join(', ') || 'Thanh toan'
  const phone = customer.phone.replace(/\D/g, '') || 'KHACH'
  return `CHILLING ${phone} ${servicesText}`.slice(0, 140)
})
const qrUrl = computed(() => selectedAccount.value ? `https://img.vietqr.io/image/${selectedAccount.value.bank_bin}-${selectedAccount.value.account_number}-compact2.png?amount=${total.value}&addInfo=${encodeURIComponent(transferNote.value)}` : '')
const money = (value: number) => `${value.toLocaleString('vi-VN')}đ`
const route = useRoute()
const router = useRouter()

async function prefillBooking(id: string) {
  if (!isSupabaseConfigured) return
  const booking = await getBookingForCheckout(id)
  bookingId.value = booking.id
  customer.fullName = booking.customer_name
  customer.phone = booking.customer_phone
  const bookingLines = (booking.booking_services ?? []).flatMap((line) => line.service_id && line.staff_id ? [{ serviceId: line.service_id, staffId: line.staff_id, quantity: line.quantity ?? 1 }] : [])
  if (bookingLines.length) lines.value = bookingLines
}

async function load() {
  if (!isSupabaseConfigured) return
  [services.value, staff.value, accounts.value] = await Promise.all([getServices(), getStaff(), getBankAccounts()])
  lines.value = [{ serviceId: services.value[0]?.id ?? '', staffId: staff.value[0]?.id ?? '', quantity: 1 }]
  bankAccountId.value = accounts.value[0]?.id ?? ''
  const booking = typeof route.query.booking === 'string' ? route.query.booking : ''
  if (booking) await prefillBooking(booking)
}
function addLine() { lines.value.push({ serviceId: services.value[0]?.id ?? '', staffId: staff.value[0]?.id ?? '', quantity: 1 }) }
function removeLine(index: number) { if (lines.value.length > 1) lines.value.splice(index, 1) }
async function pay() { error.value = ''; success.value = ''; if (!isSupabaseConfigured) { error.value = 'Chế độ demo không tạo hóa đơn.'; return } try { const result = await checkout({ bookingId: bookingId.value || null, customer, paymentMethod: paymentMethod.value, bankAccountId: paymentMethod.value === 'bank_transfer' ? bankAccountId.value : null, paymentReference: paymentMethod.value === 'bank_transfer' ? transferNote.value : null, discountPercent: discountPercent.value, lines: lines.value }); success.value = `Đã tạo hóa đơn ${String(result.invoiceNo)} · ${money(Number(result.totalAmount))}`; customer.fullName = ''; customer.phone = ''; discountPercent.value = 0; bookingId.value = ''; await router.replace({ path: '/checkout' }) } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Thanh toán không thành công.' } }
async function addService() { try { const saved = await saveService(serviceForm); services.value.push(saved); showAdd.value = null } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể thêm dịch vụ.' } }
async function addBank() { try { const saved = await saveBankAccount(bankForm); accounts.value.push(saved); bankAccountId.value = saved.id; showAdd.value = null } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể thêm tài khoản.' } }
onMounted(load)
watch(() => route.query.booking, async (value) => { if (typeof value === 'string' && value && value !== bookingId.value) await prefillBooking(value) })
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Quầy thanh toán</p><h2>Chốt hóa đơn, cập nhật toàn hệ thống</h2><p>{{ bookingId ? 'Đơn online đã được điền sẵn theo lịch đặt, có thể kiểm tra trước khi thu tiền.' : 'Thanh toán online và offline dùng cùng một luồng, tự đồng bộ doanh thu, khách hàng và KPI nhân viên.' }}</p></div><div class="intro-actions"><button class="secondary-button" @click="showAdd = 'service'"><CirclePlus :size="17" /> Dịch vụ mới</button><button class="secondary-button" @click="showAdd = 'bank'"><CirclePlus :size="17" /> Tài khoản ngân hàng</button></div></div><p v-if="error" class="error-banner">{{ error }}</p><p v-if="success" class="success-banner">{{ success }}</p>
  <div class="checkout-layout"><section class="panel checkout-form"><div class="checkout-section"><h3>Khách hàng</h3><div class="form-grid two"><label><span>Họ và tên *</span><input v-model="customer.fullName" placeholder="Tên khách hàng" /></label><label><span>Số điện thoại *</span><input v-model="customer.phone" inputmode="tel" placeholder="03x xxx xxxx" /></label></div></div><div class="checkout-section"><div class="line-heading"><h3>Dịch vụ</h3><button class="text-button" @click="addLine"><Plus :size="17" /> Thêm dịch vụ</button></div><div v-for="(line, index) in lines" :key="index" class="checkout-line"><select v-model="line.serviceId"><option v-for="service in services" :key="service.id" :value="service.id">{{ service.name }} · {{ money(service.price) }}</option></select><select v-model="line.staffId"><option v-for="person in staff" :key="person.id" :value="person.id">{{ person.display_name }} · {{ person.position }}</option></select><div class="quantity-control"><button @click="line.quantity = Math.max(1, line.quantity - 1)"><Minus :size="16" /></button><span>{{ line.quantity }}</span><button @click="line.quantity += 1"><Plus :size="16" /></button></div><button class="line-remove" :disabled="lines.length === 1" @click="removeLine(index)"><X :size="17" /></button></div></div><div class="checkout-section"><h3>Thanh toán</h3><div class="payment-methods"><button :class="{ active: paymentMethod === 'cash' }" @click="paymentMethod = 'cash'"><Banknote :size="19" /> Tiền mặt</button><button :class="{ active: paymentMethod === 'bank_transfer' }" @click="paymentMethod = 'bank_transfer'"><CreditCard :size="19" /> Chuyển khoản</button></div><div class="form-grid two"><label><span>Giảm giá (%)</span><input v-model.number="discountPercent" type="number" min="0" max="100" /></label><label v-if="paymentMethod === 'bank_transfer'"><span>Tài khoản nhận</span><select v-model="bankAccountId"><option v-for="account in accounts" :key="account.id" :value="account.id">{{ account.bank_name }} · {{ account.account_number }}</option></select></label></div></div></section><aside class="invoice-preview"><div class="invoice-brand"><img src="/logo.PNG" alt="" /><div><strong>Chilling Barber Shop</strong><span>Hóa đơn tạm tính</span></div></div><div class="invoice-lines"><div v-for="line in resolvedLines" :key="line.service.id + line.member.id" class="invoice-line"><div><strong>{{ line.service.name }}</strong><span>{{ line.member.display_name }} · {{ line.quantity }} x {{ money(line.service.price) }}</span></div><b>{{ money(line.service.price * line.quantity) }}</b></div></div><div class="invoice-totals"><div><span>Tạm tính</span><strong>{{ money(subtotal) }}</strong></div><div><span>Giảm giá</span><strong>-{{ money(discountAmount) }}</strong></div><div class="invoice-total"><span>Tổng thanh toán</span><strong>{{ money(total) }}</strong></div></div><div v-if="paymentMethod === 'bank_transfer'" class="qr-payment"><img v-if="qrUrl" :src="qrUrl" class="vietqr" alt="Mã VietQR thanh toán" /><p><span>Nội dung chuyển khoản</span><strong>{{ transferNote }}</strong></p><a v-if="qrUrl" :href="qrUrl" target="_blank" rel="noreferrer"><QrCode :size="16" /> Mở QR</a></div><button class="checkout-submit" @click="pay"><ReceiptText :size="19" /> Xác nhận thanh toán</button></aside></div>
  <div v-if="showAdd" class="modal-backdrop" @click.self="showAdd = null"><form v-if="showAdd === 'service'" class="modal-card" @submit.prevent="addService"><div class="modal-heading"><h3>Thêm dịch vụ mới</h3><button type="button" @click="showAdd = null">×</button></div><div class="form-grid"><label><span>Tên dịch vụ *</span><input v-model="serviceForm.name" required /></label><label><span>Loại dịch vụ *</span><input v-model="serviceForm.category" required /></label><label><span>Giá *</span><input v-model.number="serviceForm.price" type="number" min="0" required /></label><label><span>Thời gian dự kiến (phút) *</span><input v-model.number="serviceForm.duration_minutes" type="number" min="1" required /></label></div><button class="primary-button"><Scissors :size="18" /> Lưu dịch vụ</button></form><form v-else class="modal-card" @submit.prevent="addBank"><div class="modal-heading"><h3>Thêm tài khoản ngân hàng</h3><button type="button" @click="showAdd = null">×</button></div><div class="form-grid"><label><span>Tên ngân hàng *</span><input v-model="bankForm.bank_name" required /></label><label><span>Bank BIN *</span><input v-model="bankForm.bank_bin" required /></label><label><span>Số tài khoản *</span><input v-model="bankForm.account_number" required /></label><label><span>Chủ tài khoản *</span><input v-model="bankForm.account_name" required /></label><label><span>Chi nhánh</span><input v-model="bankForm.branch_name" /></label></div><button class="primary-button"><QrCode :size="18" /> Lưu tài khoản</button></form></div>
</template>
