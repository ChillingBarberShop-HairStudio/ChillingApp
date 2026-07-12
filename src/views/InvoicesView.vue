<script setup lang="ts">
import { computed, nextTick, onMounted, ref } from 'vue'
import { Eye, FileDown, ReceiptText, Send } from 'lucide-vue-next'
import { getInvoices } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { Invoice } from '../types/domain'

const invoices = ref<Invoice[]>([])
const selected = ref<Invoice | null>(null)
const exportingPdf = ref(false)
const money = (value: number) => `${value.toLocaleString('vi-VN')}đ`
const paymentText = (value: Invoice['payment_method']) => value === 'cash' ? 'Tiền mặt' : 'Chuyển khoản'
const activeInvoice = computed(() => selected.value ?? invoices.value[0] ?? null)
async function load() { if (isSupabaseConfigured) invoices.value = await getInvoices() }
function printInvoice(invoice: Invoice) { selected.value = invoice; setTimeout(() => window.print(), 0) }
async function downloadPdf(invoice: Invoice) {
  selected.value = invoice
  exportingPdf.value = true
  try {
    await nextTick()
    const documentNode = document.getElementById('invoice-document')
    if (!documentNode) throw new Error('Không tìm thấy hóa đơn để xuất.')
    const [{ default: html2canvas }, { jsPDF }] = await Promise.all([import('html2canvas'), import('jspdf')])
    const canvas = await html2canvas(documentNode, { backgroundColor: '#ffffff', scale: 2, useCORS: true })
    const image = canvas.toDataURL('image/png')
    const pdf = new jsPDF({ unit: 'mm', format: 'a4' })
    const margin = 10
    const width = 210 - margin * 2
    const pageHeight = 297 - margin * 2
    const height = (canvas.height * width) / canvas.width
    let remaining = height
    let position = margin
    pdf.addImage(image, 'PNG', margin, position, width, height)
    remaining -= pageHeight
    while (remaining > 0) {
      position = remaining - height + margin
      pdf.addPage()
      pdf.addImage(image, 'PNG', margin, position, width, height)
      remaining -= pageHeight
    }
    pdf.save(`${invoice.invoice_no}.pdf`)
  } finally {
    exportingPdf.value = false
  }
}
function shareInvoice(invoice: Invoice) { const text = `Hóa đơn ${invoice.invoice_no} - Chilling Barber Shop - ${money(invoice.total_amount)}`; if (navigator.share) navigator.share({ title: invoice.invoice_no, text }); else navigator.clipboard.writeText(text) }
onMounted(load)
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Dữ liệu kế toán</p><h2>Hóa đơn thanh toán</h2><p>Hóa đơn được lưu với số tự sinh, có thể xuất file PDF, in hoặc chia sẻ nội dung đến khách hàng.</p></div></div><div class="invoices-layout"><section class="panel table-panel"><table><thead><tr><th>Mã hóa đơn</th><th>Khách hàng</th><th>Thời gian</th><th>Thanh toán</th><th>Tổng tiền</th><th></th></tr></thead><tbody><tr v-for="invoice in invoices" :key="invoice.id" :class="{ selected: activeInvoice?.id === invoice.id }"><td><code>{{ invoice.invoice_no }}</code></td><td><strong>{{ invoice.customer_name }}</strong><span>{{ invoice.customer_phone }}</span></td><td>{{ new Date(invoice.paid_at).toLocaleString('vi-VN') }}</td><td>{{ paymentText(invoice.payment_method) }}</td><td><strong>{{ money(invoice.total_amount) }}</strong></td><td><div class="row-actions"><button @click="selected = invoice" aria-label="Xem hóa đơn"><Eye :size="17" /></button><button :disabled="exportingPdf" @click="downloadPdf(invoice)" aria-label="Tải PDF"><FileDown :size="17" /></button><button @click="shareInvoice(invoice)" aria-label="Chia sẻ hóa đơn"><Send :size="17" /></button></div></td></tr></tbody></table></section><aside v-if="activeInvoice" id="invoice-document" class="invoice-document print-document"><div class="receipt-header"><img src="/logo.PNG" alt="Chilling Barber Shop" /><h3>CHILLING BARBER SHOP</h3><p>Đường D13-5A, KCN Bàu Bàng, Bình Dương<br />Hotline: 032 796 9930</p></div><div class="receipt-title"><span>HÓA ĐƠN</span><code>{{ activeInvoice.invoice_no }}</code></div><p><b>Khách hàng:</b> {{ activeInvoice.customer_name }}<br /><b>Số điện thoại:</b> {{ activeInvoice.customer_phone }}</p><div class="receipt-lines"><div v-for="line in activeInvoice.invoice_lines" :key="line.service_name"><span>{{ line.service_name }}<small>{{ line.staff_name }} · {{ line.quantity }} x {{ money(line.unit_price) }}</small></span><b>{{ money(line.quantity * line.unit_price) }}</b></div></div><div class="receipt-total"><span>Tổng thanh toán</span><strong>{{ money(activeInvoice.total_amount) }}</strong></div><p class="receipt-thanks">Cảm ơn quý khách đã tin tưởng Chilling Barber Shop.<br />Hẹn gặp lại anh/chị!</p><div class="receipt-actions print-hide"><button class="secondary-button" :disabled="exportingPdf" @click="downloadPdf(activeInvoice)"><FileDown :size="17" /> {{ exportingPdf ? 'Đang tạo PDF...' : 'Tải PDF' }}</button><button class="secondary-button" @click="printInvoice(activeInvoice)"><ReceiptText :size="17" /> In hóa đơn</button></div></aside></div>
</template>
