<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { Banknote, CirclePlus, CreditCard, Landmark, ListChecks, Minus, Pencil, Plus, QrCode, ReceiptText, Scissors, X } from 'lucide-vue-next'
import { checkout, getBankAccounts, getBookingForCheckout, getServices, getStaff, saveBankAccount, saveService, verifyCurrentPassword } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { BankAccount, CheckoutLine, Service, Staff } from '../types/domain'
import { useRoute, useRouter } from 'vue-router'

type Modal = 'service' | 'bank' | 'services' | 'banks' | null

const services = ref<Service[]>([])
const staff = ref<Staff[]>([])
const accounts = ref<BankAccount[]>([])
const customer = reactive({ fullName: '', phone: '' })
const paymentMethod = ref<'cash' | 'bank_transfer'>('cash')
const bankAccountId = ref('')
const discountPercent = ref(0)
const lines = ref<CheckoutLine[]>([{ serviceId: '', staffId: '', quantity: 1 }])
const error = ref('')
const success = ref('')
const showModal = ref<Modal>(null)
const bookingId = ref('')
const bankPassword = ref('')
const serviceForm = reactive<Partial<Service>>({})
const bankForm = reactive<Partial<BankAccount>>({})
const route = useRoute()
const router = useRouter()

const selectedAccount = computed(() => accounts.value.find((account) => account.id === bankAccountId.value) ?? accounts.value[0])
const resolvedLines = computed(() => lines.value.flatMap((line) => {
  const service = services.value.find((item) => item.id === line.serviceId)
  const member = staff.value.find((item) => item.id === line.staffId)
  return service && member ? [{ ...line, service, member }] : []
}))
const subtotal = computed(() => resolvedLines.value.reduce((sum, line) => sum + line.service.price * line.quantity, 0))
const discountAmount = computed(() => Math.round(subtotal.value * Math.max(0, Math.min(100, discountPercent.value)) / 100))
const total = computed(() => subtotal.value - discountAmount.value)
const transferNote = computed(() => {
  const serviceNames = resolvedLines.value.map((line) => line.service.name).join(', ') || 'Thanh toan'
  const phone = customer.phone.replace(/\D/g, '') || 'KHACH'
  return `CHILLING ${phone} ${serviceNames}`.slice(0, 140)
})
const qrUrl = computed(() => selectedAccount.value
  ? `https://img.vietqr.io/image/${selectedAccount.value.bank_bin}-${selectedAccount.value.account_number}-compact2.png?amount=${total.value}&addInfo=${encodeURIComponent(transferNote.value)}`
  : '')
const money = (value: number) => `${value.toLocaleString('vi-VN')}d`

function staffForService(serviceId: string) {
  const providerRole = services.value.find((item) => item.id === serviceId)?.provider_role
  if (!providerRole) return staff.value
  return staff.value.filter((person) => person.position.trim().toLowerCase() === providerRole)
}

function syncLineStaff(line: CheckoutLine) {
  const availableStaff = staffForService(line.serviceId)
  if (!availableStaff.some((person) => person.id === line.staffId)) line.staffId = availableStaff[0]?.id ?? ''
}

function emptyService() {
  Object.assign(serviceForm, { id: undefined, name: '', category: 'Cat toc', price: 0, duration_minutes: 30, provider_role: 'barber', is_active: true })
}

function emptyBank() {
  Object.assign(bankForm, { id: undefined, bank_name: '', bank_bin: '', account_number: '', account_name: '', branch_name: '', is_active: true })
  bankPassword.value = ''
}

function openServiceForm(service?: Service) {
  if (service) Object.assign(serviceForm, { ...service, provider_role: service.provider_role ?? 'barber' })
  else emptyService()
  showModal.value = 'service'
}

function openBankForm(account?: BankAccount) {
  if (account) Object.assign(bankForm, { ...account })
  else emptyBank()
  bankPassword.value = ''
  showModal.value = 'bank'
}

async function prefillBooking(id: string) {
  if (!isSupabaseConfigured) return
  const booking = await getBookingForCheckout(id)
  bookingId.value = booking.id
  customer.fullName = booking.customer_name
  customer.phone = booking.customer_phone
  const bookingLines = (booking.booking_services ?? []).flatMap((line) => line.service_id && line.staff_id
    ? [{ serviceId: line.service_id, staffId: line.staff_id, quantity: line.quantity ?? 1 }]
    : [])
  if (bookingLines.length) lines.value = bookingLines
}

async function load() {
  if (!isSupabaseConfigured) return
  ;[services.value, staff.value, accounts.value] = await Promise.all([getServices(), getStaff(), getBankAccounts()])
  const firstService = services.value[0]?.id ?? ''
  const firstLine = { serviceId: firstService, staffId: '', quantity: 1 }
  syncLineStaff(firstLine)
  lines.value = [firstLine]
  bankAccountId.value = accounts.value[0]?.id ?? ''
  const booking = typeof route.query.booking === 'string' ? route.query.booking : ''
  if (booking) await prefillBooking(booking)
}

function addLine() {
  const line = { serviceId: services.value[0]?.id ?? '', staffId: '', quantity: 1 }
  syncLineStaff(line)
  lines.value.push(line)
}

function removeLine(index: number) {
  if (lines.value.length > 1) lines.value.splice(index, 1)
}

async function pay() {
  error.value = ''
  success.value = ''
  if (!isSupabaseConfigured) { error.value = 'Chua co cau hinh Supabase.'; return }
  try {
    const result = await checkout({
      bookingId: bookingId.value || null,
      customer,
      paymentMethod: paymentMethod.value,
      bankAccountId: paymentMethod.value === 'bank_transfer' ? bankAccountId.value : null,
      paymentReference: paymentMethod.value === 'bank_transfer' ? transferNote.value : null,
      discountPercent: discountPercent.value,
      lines: lines.value,
    })
    success.value = `Da tao hoa don ${String(result.invoiceNo)} - ${money(Number(result.totalAmount))}`
    customer.fullName = ''
    customer.phone = ''
    discountPercent.value = 0
    bookingId.value = ''
    await router.replace({ path: '/checkout' })
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Thanh toan khong thanh cong.'
  }
}

async function saveServiceEntry() {
  error.value = ''
  try {
    const saved = await saveService(serviceForm)
    const index = services.value.findIndex((service) => service.id === saved.id)
    if (index >= 0) services.value[index] = saved
    else services.value.push(saved)
    showModal.value = null
    success.value = serviceForm.id ? 'Da cap nhat dich vu va gia ban.' : 'Da them dich vu moi.'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Khong the luu dich vu.'
  }
}

async function saveBankEntry() {
  error.value = ''
  try {
    if (bankForm.id) {
      if (!bankPassword.value) throw new Error('Nhap mat khau dang nhap de xac nhan sua tai khoan ngan hang.')
      await verifyCurrentPassword(bankPassword.value)
    }
    const saved = await saveBankAccount(bankForm)
    const index = accounts.value.findIndex((account) => account.id === saved.id)
    if (index >= 0) accounts.value[index] = saved
    else accounts.value.push(saved)
    bankAccountId.value = saved.id
    showModal.value = null
    success.value = bankForm.id ? 'Da xac thuc va cap nhat tai khoan ngan hang.' : 'Da them tai khoan ngan hang.'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Khong the luu tai khoan ngan hang.'
  }
}

onMounted(load)
watch(() => route.query.booking, async (value) => {
  if (typeof value === 'string' && value && value !== bookingId.value) await prefillBooking(value)
})
</script>

<template>
  <div class="page-intro compact">
    <div><p class="eyebrow">Quay thanh toan</p><h2>Chot hoa don, cap nhat toan he thong</h2><p>{{ bookingId ? 'Don online da duoc dien san theo lich dat, co the kiem tra truoc khi thu tien.' : 'Thanh toan online va offline dung cung mot luong, tu dong dong bo doanh thu, khach hang va KPI nhan vien.' }}</p></div>
    <div class="intro-actions"><button class="secondary-button" @click="openServiceForm()"><CirclePlus :size="17" /> Dich vu moi</button><button class="secondary-button" @click="showModal = 'services'"><ListChecks :size="17" /> Quan ly dich vu</button><button class="secondary-button" @click="showModal = 'banks'"><Landmark :size="17" /> Tai khoan ngan hang</button></div>
  </div>
  <p v-if="error" class="error-banner">{{ error }}</p><p v-if="success" class="success-banner">{{ success }}</p>
  <div class="checkout-layout">
    <section class="panel checkout-form">
      <div class="checkout-section"><h3>Khach hang</h3><div class="form-grid two"><label><span>Ho va ten *</span><input v-model="customer.fullName" placeholder="Ten khach hang" /></label><label><span>So dien thoai *</span><input v-model="customer.phone" inputmode="tel" placeholder="03x xxx xxxx" /></label></div></div>
      <div class="checkout-section"><div class="line-heading"><h3>Dich vu</h3><button class="text-button" @click="addLine"><Plus :size="17" /> Them dich vu</button></div><div v-for="(line, index) in lines" :key="index" class="checkout-line"><select v-model="line.serviceId" @change="syncLineStaff(line)"><option v-for="service in services" :key="service.id" :value="service.id">{{ service.name }} - {{ money(service.price) }}</option></select><select v-model="line.staffId"><option v-for="person in staffForService(line.serviceId)" :key="person.id" :value="person.id">{{ person.display_name }} - {{ person.position }}</option></select><div class="quantity-control"><button @click="line.quantity = Math.max(1, line.quantity - 1)"><Minus :size="16" /></button><span>{{ line.quantity }}</span><button @click="line.quantity += 1"><Plus :size="16" /></button></div><button class="line-remove" :disabled="lines.length === 1" @click="removeLine(index)"><X :size="17" /></button></div></div>
      <div class="checkout-section"><h3>Thanh toan</h3><div class="payment-methods"><button :class="{ active: paymentMethod === 'cash' }" @click="paymentMethod = 'cash'"><Banknote :size="19" /> Tien mat</button><button :class="{ active: paymentMethod === 'bank_transfer' }" @click="paymentMethod = 'bank_transfer'"><CreditCard :size="19" /> Chuyen khoan</button></div><div class="form-grid two"><label><span>Giam gia (%)</span><input v-model.number="discountPercent" type="number" min="0" max="100" /></label><label v-if="paymentMethod === 'bank_transfer'"><span>Tai khoan nhan</span><select v-model="bankAccountId"><option v-for="account in accounts" :key="account.id" :value="account.id">{{ account.bank_name }} - {{ account.account_number }}</option></select></label></div></div>
    </section>
    <aside class="invoice-preview"><div class="invoice-brand"><img src="/logo.PNG" alt="" /><div><strong>Chilling Barber Shop</strong><span>Hoa don tam tinh</span></div></div><div class="invoice-lines"><div v-for="line in resolvedLines" :key="line.service.id + line.member.id" class="invoice-line"><div><strong>{{ line.service.name }}</strong><span>{{ line.member.display_name }} - {{ line.quantity }} x {{ money(line.service.price) }}</span></div><b>{{ money(line.service.price * line.quantity) }}</b></div></div><div class="invoice-totals"><div><span>Tam tinh</span><strong>{{ money(subtotal) }}</strong></div><div><span>Giam gia</span><strong>-{{ money(discountAmount) }}</strong></div><div class="invoice-total"><span>Tong thanh toan</span><strong>{{ money(total) }}</strong></div></div><div v-if="paymentMethod === 'bank_transfer'" class="qr-payment"><img v-if="qrUrl" :src="qrUrl" class="vietqr" alt="Ma VietQR thanh toan" /><p><span>Noi dung chuyen khoan</span><strong>{{ transferNote }}</strong></p><a v-if="qrUrl" :href="qrUrl" target="_blank" rel="noreferrer"><QrCode :size="16" /> Mo QR</a></div><button class="checkout-submit" @click="pay"><ReceiptText :size="19" /> Xac nhan thanh toan</button></aside>
  </div>

  <div v-if="showModal" class="modal-backdrop" @click.self="showModal = null">
    <form v-if="showModal === 'service'" class="modal-card" @submit.prevent="saveServiceEntry"><div class="modal-heading"><h3>{{ serviceForm.id ? 'Chinh sua dich vu' : 'Them dich vu moi' }}</h3><button type="button" @click="showModal = null">x</button></div><div class="form-grid"><label><span>Ten dich vu *</span><input v-model="serviceForm.name" required /></label><label><span>Loai dich vu *</span><input v-model="serviceForm.category" required /></label><label><span>Nguoi thuc hien *</span><select v-model="serviceForm.provider_role" required><option value="barber">Barber</option><option value="skinner">Skinner</option></select></label><label><span>Gia *</span><input v-model.number="serviceForm.price" type="number" min="0" required /></label><label><span>Thoi gian du kien (phut) *</span><input v-model.number="serviceForm.duration_minutes" type="number" min="1" required /></label></div><button class="primary-button"><Scissors :size="18" /> {{ serviceForm.id ? 'Luu thay doi' : 'Luu dich vu' }}</button></form>
    <form v-else-if="showModal === 'bank'" class="modal-card" @submit.prevent="saveBankEntry"><div class="modal-heading"><h3>{{ bankForm.id ? 'Chinh sua tai khoan ngan hang' : 'Them tai khoan ngan hang' }}</h3><button type="button" @click="showModal = null">x</button></div><div class="form-grid"><label><span>Ten ngan hang *</span><input v-model="bankForm.bank_name" required /></label><label><span>Bank BIN *</span><input v-model="bankForm.bank_bin" required /></label><label><span>So tai khoan *</span><input v-model="bankForm.account_number" required /></label><label><span>Chu tai khoan *</span><input v-model="bankForm.account_name" required /></label><label><span>Chi nhanh</span><input v-model="bankForm.branch_name" /></label><label v-if="bankForm.id"><span>Mat khau dang nhap de xac nhan *</span><input v-model="bankPassword" type="password" autocomplete="current-password" required /></label></div><button class="primary-button"><QrCode :size="18" /> {{ bankForm.id ? 'Xac thuc va luu' : 'Luu tai khoan' }}</button></form>
    <section v-else-if="showModal === 'services'" class="modal-card manager-modal"><div class="modal-heading"><h3>Danh sach dich vu</h3><button type="button" @click="showModal = null">x</button></div><div class="manager-list"><article v-for="service in services" :key="service.id"><div><strong>{{ service.name }}</strong><span>{{ service.category }} - {{ money(service.price) }} - {{ service.provider_role === 'skinner' ? 'Skinner' : 'Barber' }}</span></div><button class="inline-action" @click="openServiceForm(service)"><Pencil :size="16" /> Sua</button></article><p v-if="!services.length" class="monthly-chart-empty">Chua co dich vu.</p></div><button class="primary-button" @click="openServiceForm()"><CirclePlus :size="17" /> Them dich vu</button></section>
    <section v-else class="modal-card manager-modal"><div class="modal-heading"><h3>Tai khoan ngan hang</h3><button type="button" @click="showModal = null">x</button></div><div class="manager-list"><article v-for="account in accounts" :key="account.id"><div><strong>{{ account.bank_name }} - {{ account.account_number }}</strong><span>{{ account.account_name }}{{ account.branch_name ? ` - ${account.branch_name}` : '' }}</span></div><button class="inline-action" @click="openBankForm(account)"><Pencil :size="16" /> Sua</button></article><p v-if="!accounts.length" class="monthly-chart-empty">Chua co tai khoan ngan hang.</p></div><button class="primary-button" @click="openBankForm()"><CirclePlus :size="17" /> Them tai khoan</button></section>
  </div>
</template>
