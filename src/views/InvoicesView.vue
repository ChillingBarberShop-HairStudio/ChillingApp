<script setup lang="ts">
import { computed, nextTick, onMounted, ref } from 'vue'
import { Eye, FileDown, ReceiptText, Send } from 'lucide-vue-next'
import { getInvoices } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { Invoice } from '../types/domain'

const invoices = ref<Invoice[]>([])
const selected = ref<Invoice | null>(null)
const exportingPdf = ref(false)
const money = (value: number) => `${value.toLocaleString('vi-VN')}d`
const paymentText = (value: Invoice['payment_method']) => value === 'cash' ? 'Tien mat' : 'Chuyen khoan'
const activeInvoice = computed(() => selected.value ?? invoices.value[0] ?? null)

async function load() {
  if (isSupabaseConfigured) invoices.value = await getInvoices()
}

function printInvoice(invoice: Invoice) {
  selected.value = invoice
  setTimeout(() => window.print(), 0)
}

async function downloadPdf(invoice: Invoice) {
  selected.value = invoice
  exportingPdf.value = true
  try {
    await nextTick()
    const documentNode = document.getElementById('invoice-document')
    if (!documentNode) throw new Error('Khong tim thay hoa don de xuat.')
    const [{ default: html2canvas }, { jsPDF }] = await Promise.all([import('html2canvas'), import('jspdf')])
    const excludedNodes = [...documentNode.querySelectorAll<HTMLElement>('[data-pdf-exclude]')]
    const previousDisplays = excludedNodes.map((node) => node.style.display)
    let canvas: HTMLCanvasElement
    try {
      excludedNodes.forEach((node) => { node.style.display = 'none' })
      canvas = await html2canvas(documentNode, { backgroundColor: '#ffffff', scale: 2, useCORS: true })
    } finally {
      excludedNodes.forEach((node, index) => { node.style.display = previousDisplays[index] })
    }
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

function shareInvoice(invoice: Invoice) {
  const text = `Hoa don ${invoice.invoice_no} - Chilling Barber Shop - ${money(invoice.total_amount)}`
  if (navigator.share) navigator.share({ title: invoice.invoice_no, text })
  else navigator.clipboard.writeText(text)
}

onMounted(load)
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Du lieu ke toan</p><h2>Hoa don thanh toan</h2><p>Hoa don duoc luu voi so tu sinh, co the xuat file PDF, in hoac chia se noi dung den khach hang.</p></div></div>
  <div class="invoices-layout">
    <section class="panel table-panel"><table><thead><tr><th>Ma hoa don</th><th>Khach hang</th><th>Thoi gian</th><th>Thanh toan</th><th>Tong tien</th><th></th></tr></thead><tbody><tr v-for="invoice in invoices" :key="invoice.id" :class="{ selected: activeInvoice?.id === invoice.id }"><td><code>{{ invoice.invoice_no }}</code></td><td><strong>{{ invoice.customer_name }}</strong><span>{{ invoice.customer_phone }}</span></td><td>{{ new Date(invoice.paid_at).toLocaleString('vi-VN') }}</td><td>{{ paymentText(invoice.payment_method) }}</td><td><strong>{{ money(invoice.total_amount) }}</strong></td><td><div class="row-actions"><button @click="selected = invoice" aria-label="Xem hoa don"><Eye :size="17" /></button><button :disabled="exportingPdf" @click="downloadPdf(invoice)" aria-label="Tai PDF"><FileDown :size="17" /></button><button @click="shareInvoice(invoice)" aria-label="Chia se hoa don"><Send :size="17" /></button></div></td></tr></tbody></table></section>
    <aside v-if="activeInvoice" id="invoice-document" class="invoice-document print-document"><div class="receipt-header"><img src="/logo.PNG" alt="Chilling Barber Shop" /><h3>CHILLING BARBER SHOP</h3><p>Duong D13-5A, KCN Bau Bang, Binh Duong<br />Hotline: 032 796 9930</p></div><div class="receipt-title"><span>HOA DON</span><code>{{ activeInvoice.invoice_no }}</code></div><p><b>Ngay xuat hoa don:</b> {{ new Date(activeInvoice.paid_at).toLocaleString('vi-VN') }}<br /><b>Khach hang:</b> {{ activeInvoice.customer_name }}<br /><b>So dien thoai:</b> {{ activeInvoice.customer_phone }}</p><div class="receipt-lines"><div v-for="line in activeInvoice.invoice_lines" :key="line.service_name"><span>{{ line.service_name }}<small>{{ line.staff_name }} - {{ line.quantity }} x {{ money(line.unit_price) }}</small></span><b>{{ money(line.quantity * line.unit_price) }}</b></div></div><div class="receipt-breakdown"><div><span>Tam tinh</span><strong>{{ money(activeInvoice.subtotal) }}</strong></div><div v-if="activeInvoice.discount_amount"><span>Giam gia{{ activeInvoice.discount_percent ? ` (${activeInvoice.discount_percent}%)` : '' }}</span><strong>-{{ money(activeInvoice.discount_amount) }}</strong></div></div><div class="receipt-total"><span>Tong thanh toan</span><strong>{{ money(activeInvoice.total_amount) }}</strong></div><p class="receipt-thanks">Cam on quy khach da tin tuong Chilling Barber Shop.<br />Hen gap lai anh/chi!</p><div class="receipt-actions print-hide" data-pdf-exclude><button class="secondary-button" :disabled="exportingPdf" @click="downloadPdf(activeInvoice)"><FileDown :size="17" /> {{ exportingPdf ? 'Dang tao PDF...' : 'Tai PDF' }}</button><button class="secondary-button" @click="printInvoice(activeInvoice)"><ReceiptText :size="17" /> In hoa don</button></div></aside>
  </div>
</template>
