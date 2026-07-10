<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Banknote, CalendarDays, CircleDollarSign, CreditCard, ReceiptText, TrendingUp } from 'lucide-vue-next'
import KpiCard from '../components/KpiCard.vue'
import RankList from '../components/RankList.vue'
import RevenueChart from '../components/RevenueChart.vue'
import { DEMO_METRICS, getDashboardMetrics } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { DashboardMetrics } from '../types/domain'

const selectedDate = ref(new Date().toISOString().slice(0, 10))
const metrics = ref<DashboardMetrics>(DEMO_METRICS)
const loading = ref(false)
const error = ref('')
const formatMoney = (value: number) => `${value.toLocaleString('vi-VN')}đ`
const profitDetail = computed(() => `Doanh thu ${formatMoney(metrics.value.revenue)} - chi ${formatMoney(metrics.value.expenses)}`)

async function load() {
  if (!isSupabaseConfigured) return
  loading.value = true; error.value = ''
  try { metrics.value = await getDashboardMetrics(selectedDate.value) }
  catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể tải dashboard.' }
  finally { loading.value = false }
}

onMounted(load)
</script>

<template>
  <div class="page-intro"><div><p class="eyebrow">Tổng quan vận hành</p><h2>Ngày làm việc rõ ràng, quyết định nhanh hơn.</h2><p>Toàn bộ KPI được tổng hợp từ hóa đơn đã thanh toán và chi phí ghi nhận trong ngày.</p></div><label class="date-filter"><span>Ngày xem báo cáo</span><input v-model="selectedDate" type="date" @change="load" /></label></div>
  <p v-if="!isSupabaseConfigured" class="demo-banner">Đang hiển thị dữ liệu minh họa. Kết nối Supabase để dùng dữ liệu cửa hàng thật.</p><p v-if="error" class="error-banner">{{ error }}</p>
  <div class="kpi-grid"><KpiCard label="Đơn đặt trong ngày" :value="String(metrics.bookingCount)" detail="Bao gồm online và offline" :icon="CalendarDays" tone="blue" /><KpiCard label="Doanh thu trong ngày" :value="formatMoney(metrics.revenue)" detail="Từ hóa đơn đã thanh toán" :icon="CircleDollarSign" tone="gold" /><KpiCard label="Hóa đơn thanh toán" :value="String(metrics.invoiceCount)" detail="Đã chốt trong ngày" :icon="ReceiptText" tone="green" /><KpiCard label="Lợi nhuận tạm tính" :value="formatMoney(metrics.profit)" :detail="profitDetail" :icon="TrendingUp" tone="rose" /></div>
  <div class="payment-strip"><article><Banknote :size="24" /><div><span>Tiền mặt</span><strong>{{ metrics.cash.count }} hóa đơn · {{ formatMoney(metrics.cash.amount) }}</strong></div></article><article><CreditCard :size="24" /><div><span>Chuyển khoản</span><strong>{{ metrics.bankTransfer.count }} hóa đơn · {{ formatMoney(metrics.bankTransfer.amount) }}</strong></div></article><article><ReceiptText :size="24" /><div><span>Chi tiêu trong ngày</span><strong>{{ formatMoney(metrics.expenses) }}</strong></div></article></div>
  <RevenueChart :data="metrics.monthlyRevenue" />
  <div class="ranking-grid"><RankList title="KPI nhân viên" :items="metrics.staffRank.map(item => ({ name: item.name, value: item.revenue, suffix: 'đ' }))" /><RankList title="Khách hàng thân thiết" :items="metrics.customerRank.map(item => ({ name: item.name, value: item.visits, suffix: ' lượt' }))" /><RankList title="Dịch vụ bán chạy" :items="metrics.serviceRank.map(item => ({ name: item.name, value: item.sold, suffix: ' lượt' }))" /></div>
  <div v-if="loading" class="loading-line">Đang cập nhật dữ liệu...</div>
</template>
