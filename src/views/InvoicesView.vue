<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Eye, FileDown, ReceiptText, Send } from 'lucide-vue-next'
import { getInvoices } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { Invoice } from '../types/domain'

const invoices = ref<Invoice[]>([{ id: 'demo-invoice', invoice_no: 'INV-260710-00001', customer_name: 'Nguyễn Minh', customer_phone: '0327969930', subtotal: 160000, discount_amount: 0, total_amount: 160000, payment_method: 'cash', paid_at: new Date().toISOString(), status: 'paid', invoice_lines: [{ service_name: 'Thợ cắt', quantity: 1, unit_price: 70000, staff_name: 'Nam' }, { service_name: 'Gội đầu', quantity: 1, unit_price: 60000, staff_name: 'Hương' }] }])
const selected = ref<Invoice | null>(null)
const money = (value: number) => `${value.toLocaleString('vi-VN')}đ`
const paymentText = (value: Invoice['payment_method']) => value === 'cash' ? 'Tiền mặt' : 'Chuyển khoản'
const activeInvoice = computed(() => selected.value ?? invoices.value[0] ?? null)
async function load() { if (isSupabaseConfigured) invoices.value = await getInvoices() }
function printInvoice(invoice: Invoice) { selected.value = invoice; setTimeout(() => window.print(), 0) }
function shareInvoice(invoice: Invoice) { const text = `Hóa đơn ${invoice.invoice_no} - Chilling Barber Shop - ${money(invoice.total_amount)}`; if (navigator.share) navigator.share({ title: invoice.invoice_no, text }); else navigator.clipboard.writeText(text) }
onMounted(load)
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Dữ liệu kế toán</p><h2>Hóa đơn thanh toán</h2><p>Hóa đơn được lưu với số tự sinh, có thể xem, in thành PDF hoặc chia sẻ nội dung đến khách hàng.</p></div></div><div class="invoices-layout"><section class="panel table-panel"><table><thead><tr><th>Mã hóa đơn</th><th>Khách hàng</th><th>Thời gian</th><th>Thanh toán</th><th>Tổng tiền</th><th></th></tr></thead><tbody><tr v-for="invoice in invoices" :key="invoice.id" :class="{ selected: activeInvoice?.id === invoice.id }"><td><code>{{ invoice.invoice_no }}</code></td><td><strong>{{ invoice.customer_name }}</strong><span>{{ invoice.customer_phone }}</span></td><td>{{ new Date(invoice.paid_at).toLocaleString('vi-VN') }}</td><td>{{ paymentText(invoice.payment_method) }}</td><td><strong>{{ money(invoice.total_amount) }}</strong></td><td><div class="row-actions"><button @click="selected = invoice" aria-label="Xem hóa đơn"><Eye :size="17" /></button><button @click="printInvoice(invoice)" aria-label="Xuất PDF"><FileDown :size="17" /></button><button @click="shareInvoice(invoice)" aria-label="Chia sẻ hóa đơn"><Send :size="17" /></button></div></td></tr></tbody></table></section><aside v-if="activeInvoice" class="invoice-document print-document"><div class="receipt-header"><img src="/logo.PNG" alt="Chilling Barber Shop" /><h3>CHILLING BARBER SHOP</h3><p>Đường D13-5A, KCN Bàu Bàng, Bình Dương<br />Hotline: 032 796 9930</p></div><div class="receipt-title"><span>HÓA ĐƠN</span><code>{{ activeInvoice.invoice_no }}</code></div><p><b>Khách hàng:</b> {{ activeInvoice.customer_name }}<br /><b>Số điện thoại:</b> {{ activeInvoice.customer_phone }}</p><div class="receipt-lines"><div v-for="line in activeInvoice.invoice_lines" :key="line.service_name"><span>{{ line.service_name }}<small>{{ line.staff_name }} · {{ line.quantity }} x {{ money(line.unit_price) }}</small></span><b>{{ money(line.quantity * line.unit_price) }}</b></div></div><div class="receipt-total"><span>Tổng thanh toán</span><strong>{{ money(activeInvoice.total_amount) }}</strong></div><p class="receipt-thanks">Cảm ơn quý khách đã tin tưởng Chilling Barber Shop.<br />Hẹn gặp lại anh/chị!</p><button class="secondary-button print-hide" @click="printInvoice(activeInvoice)"><ReceiptText :size="17" /> Xuất PDF</button></aside></div>
</template>
