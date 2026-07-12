<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { CircleDollarSign, Percent, Save, UserRound } from 'lucide-vue-next'
import KpiCard from '../components/KpiCard.vue'
import { DEMO_STAFF, getCommissionMetrics, getCommissionRules, getStaff, saveCommissionRule } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { CommissionMetrics, CommissionRule, ReportScope, Staff } from '../types/domain'

const selectedDate = ref(new Date().toISOString().slice(0, 10))
const selectedScope = ref<ReportScope>('day')
const staff = ref<Staff[]>(DEMO_STAFF)
const rules = ref<CommissionRule[]>([])
const rates = ref<Record<string, number>>({})
const metrics = ref<CommissionMetrics>({ date: selectedDate.value, scope: 'day', revenue: 4380000, staffShare: 2190000, ownerShare: 2190000, items: [{ staffId: 'demo-nam', name: 'Nam', revenue: 2200000, rate: 50, staffShare: 1100000, ownerShare: 1100000 }, { staffId: 'demo-huong', name: 'Hương', revenue: 2180000, rate: 50, staffShare: 1090000, ownerShare: 1090000 }] })
const error = ref('')
const savingId = ref('')
const money = (value: number) => `${value.toLocaleString('vi-VN')}đ`

function setupRates() {
  rates.value = Object.fromEntries(staff.value.map((person) => [person.id, rules.value.find((rule) => rule.staff_id === person.id)?.commission_rate ?? 50]))
}

async function load() {
  if (!isSupabaseConfigured) { setupRates(); return }
  error.value = ''
  try {
    const [team, currentRules, report] = await Promise.all([getStaff(), getCommissionRules(), getCommissionMetrics(selectedDate.value, selectedScope.value)])
    staff.value = team
    rules.value = currentRules
    metrics.value = report
    setupRates()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể tải dữ liệu chiết khấu.'
  }
}

async function saveRate(person: Staff) {
  if (!isSupabaseConfigured) { error.value = 'Chế độ demo không ghi dữ liệu.'; return }
  const commissionRate = Math.max(0, Math.min(100, Number(rates.value[person.id] ?? 50)))
  const existing = rules.value.find((rule) => rule.staff_id === person.id)
  savingId.value = person.id
  try {
    const saved = await saveCommissionRule(existing ? { id: existing.id, commission_rate: commissionRate, effective_from: new Date().toISOString().slice(0, 10) } : { staff_id: person.id, commission_rate: commissionRate, effective_from: new Date().toISOString().slice(0, 10) })
    const index = rules.value.findIndex((rule) => rule.staff_id === person.id)
    if (index >= 0) rules.value[index] = saved
    else rules.value.push(saved)
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'Không thể lưu mức chiết khấu.'
  } finally {
    savingId.value = ''
  }
}

onMounted(load)
</script>

<template>
  <div class="page-intro"><div><p class="eyebrow">Chia sẻ doanh thu</p><h2>Chiết khấu chủ shop và thợ</h2><p>Thiết lập tỷ lệ riêng cho từng nhân viên. Hóa đơn mới sẽ lưu tỷ lệ tại thời điểm thanh toán để báo cáo lịch sử không bị thay đổi.</p></div><div class="report-filters"><label class="date-filter"><span>Ngày mốc báo cáo</span><input v-model="selectedDate" type="date" @change="load" /></label><label class="scope-filter"><span>Phạm vi dữ liệu</span><select v-model="selectedScope" @change="load"><option value="day">Theo ngày</option><option value="month">Theo tháng</option><option value="all">Tất cả từ trước đến nay</option></select></label></div></div>
  <p v-if="error" class="error-banner">{{ error }}</p>
  <div class="kpi-grid commission-kpis"><KpiCard label="Doanh thu được chia" :value="money(metrics.revenue)" detail="Sau giảm giá trên hóa đơn" :icon="CircleDollarSign" tone="gold" /><KpiCard label="Phần chiết khấu thợ" :value="money(metrics.staffShare)" detail="Theo tỷ lệ từng nhân viên" :icon="UserRound" tone="blue" /><KpiCard label="Phần doanh thu chủ shop" :value="money(metrics.ownerShare)" detail="Phần còn lại sau chiết khấu" :icon="Percent" tone="green" /></div>
  <section class="panel commission-table"><div class="table-heading"><div><h3>Thiết lập và đối soát theo thợ</h3><p>Tỷ lệ mặc định là 50/50 nhưng không bị khóa cứng.</p></div><Percent :size="22" /></div><table><thead><tr><th>Nhân viên</th><th>Vị trí</th><th>Tỷ lệ thợ (%)</th><th>Doanh thu kỳ chọn</th><th>Phần thợ</th><th>Phần chủ shop</th><th></th></tr></thead><tbody><tr v-for="person in staff" :key="person.id"><td><strong>{{ person.display_name }}</strong></td><td><span class="role-badge">{{ person.position }}</span></td><td><div class="rate-input"><input v-model.number="rates[person.id]" type="number" min="0" max="100" /><span>%</span></div></td><td>{{ money(metrics.items.find((item) => item.staffId === person.id)?.revenue ?? 0) }}</td><td><strong>{{ money(metrics.items.find((item) => item.staffId === person.id)?.staffShare ?? 0) }}</strong></td><td>{{ money(metrics.items.find((item) => item.staffId === person.id)?.ownerShare ?? 0) }}</td><td><button class="inline-action" :disabled="savingId === person.id" @click="saveRate(person)"><Save :size="16" /> {{ savingId === person.id ? 'Đang lưu' : 'Lưu' }}</button></td></tr></tbody></table></section>
</template>
