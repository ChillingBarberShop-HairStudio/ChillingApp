<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Banknote, CalendarDays, CircleDollarSign, CreditCard, ReceiptText, TrendingUp, UsersRound } from 'lucide-vue-next'
import KpiCard from '../components/KpiCard.vue'
import RankList from '../components/RankList.vue'
import RevenueChart from '../components/RevenueChart.vue'
import { DEMO_METRICS, getDashboardMetrics } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { DashboardMetrics, ReportScope } from '../types/domain'

const selectedDate = ref(new Date().toISOString().slice(0, 10))
const selectedScope = ref<ReportScope>('day')
const metrics = ref<DashboardMetrics>(DEMO_METRICS)
const loading = ref(false)
const error = ref('')
const formatMoney = (value: number) => `${value.toLocaleString('vi-VN')}đ`
const profitDetail = computed(() => `Doanh thu ${formatMoney(metrics.value.revenue)} - chi ${formatMoney(metrics.value.expenses)}`)

async function load() {
  if (!isSupabaseConfigured) return
  loading.value = true; error.value = ''
  try { metrics.value = await getDashboardMetrics(selectedDate.value, selectedScope.value) }
  catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể tải dashboard.' }
  finally { loading.value = false }
}

onMounted(load)
</script>

<template>
  <div class="page-intro"><div><p class="eyebrow">Tổng quan vận hành</p><h2>Toàn bộ KPI được tổng hợp từ hóa đơn đã thanh toán và chi phí ghi nhận trong ngày.</h2></div><div class="report-filters"><label class="date-filter"><span>Ngày mốc báo cáo</span><input v-model="selectedDate" type="date" @change="load" /></label><label class="scope-filter"><span>Phạm vi dữ liệu</span><select v-model="selectedScope" @change="load"><option value="day">Theo ngày</option><option value="month">Theo tháng</option><option value="all">Tất cả từ trước đến nay</option></select></label></div></div>
  <p v-if="!isSupabaseConfigured" class="demo-banner">Đang hiển thị dữ liệu minh họa. Kết nối Supabase để dùng dữ liệu cửa hàng thật.</p><p v-if="error" class="error-banner">{{ error }}</p>
  <div class="kpi-grid"><KpiCard :label="selectedScope === 'day' ? 'Đơn đặt trong ngày' : selectedScope === 'month' ? 'Đơn đặt trong tháng' : 'Tổng đơn đặt'" :value="String(metrics.bookingCount)" detail="Bao gồm online và offline" :icon="CalendarDays" tone="blue" /><KpiCard :label="selectedScope === 'day' ? 'Doanh thu trong ngày' : selectedScope === 'month' ? 'Doanh thu trong tháng' : 'Tổng doanh thu'" :value="formatMoney(metrics.revenue)" detail="Từ hóa đơn đã thanh toán" :icon="CircleDollarSign" tone="gold" /><KpiCard label="Hóa đơn thanh toán" :value="String(metrics.invoiceCount)" detail="Đã chốt trong phạm vi chọn" :icon="ReceiptText" tone="green" /><KpiCard label="Lợi nhuận tạm tính" :value="formatMoney(metrics.profit)" :detail="profitDetail" :icon="TrendingUp" tone="rose" /><KpiCard label="Doanh thu chiết khấu thợ" :value="formatMoney(metrics.staffCommission)" :detail="`Chủ shop giữ ${formatMoney(metrics.ownerCommission)}`" :icon="UsersRound" tone="gold" /></div>
  <div class="payment-strip"><article><Banknote :size="24" /><div><span>Tiền mặt</span><strong>{{ metrics.cash.count }} hóa đơn · {{ formatMoney(metrics.cash.amount) }}</strong></div></article><article><CreditCard :size="24" /><div><span>Chuyển khoản</span><strong>{{ metrics.bankTransfer.count }} hóa đơn · {{ formatMoney(metrics.bankTransfer.amount) }}</strong></div></article><article><ReceiptText :size="24" /><div><span>Chi tiêu trong ngày</span><strong>{{ formatMoney(metrics.expenses) }}</strong></div></article></div>
  <RevenueChart :data="metrics.monthlyRevenue" />
  <div class="ranking-grid"><RankList title="KPI nhân viên" :items="metrics.staffRank.map(item => ({ name: item.name, value: item.revenue, suffix: 'đ' }))" /><RankList title="Khách hàng thân thiết" :items="metrics.customerRank.map(item => ({ name: item.name, value: item.visits, suffix: ' lượt' }))" /><RankList title="Dịch vụ bán chạy" :items="metrics.serviceRank.map(item => ({ name: item.name, value: item.sold, suffix: ' lượt' }))" /></div>
  <div v-if="loading" class="loading-line">Đang cập nhật dữ liệu...</div>
</template>
