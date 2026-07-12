<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { CheckCheck, Clock3, Play, XCircle } from 'lucide-vue-next'
import { useRouter } from 'vue-router'
import { getOnlineBookings, setBookingStatus } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { Booking } from '../types/domain'

const orders = ref<Booking[]>([])
const error = ref('')
const router = useRouter()
const labels = { waiting: 'Chờ phục vụ', serving: 'Đang phục vụ', completed: 'Hoàn thành', cancelled: 'Đã hủy' }
async function load() { if (isSupabaseConfigured) orders.value = await getOnlineBookings() }
async function change(order: Booking, status: Booking['status']) { try { if (isSupabaseConfigured) await setBookingStatus(order.id, status); order.status = status } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Không thể đổi trạng thái.' } }
function goToCheckout(order: Booking) { router.push({ path: '/checkout', query: { booking: order.id } }) }
onMounted(load)
</script>

<template>
  <div class="page-intro"><div><p class="eyebrow">Luồng online</p><h2>Đơn đặt lịch từ landing page</h2><p>Đơn chờ phục vụ được mở ở Thanh toán cùng khách hàng, dịch vụ và nhân viên đã đặt. Trạng thái hoàn thành chỉ được chốt sau khi thanh toán.</p></div></div><p v-if="error" class="error-banner">{{ error }}</p><div class="order-grid"><article v-for="order in orders" :key="order.id" class="order-card"><div class="order-card-top"><span class="status-chip" :class="`status-${order.status}`">{{ labels[order.status] }}</span><code>{{ order.booking_code }}</code></div><h3>{{ order.customer_name }}</h3><p>{{ order.customer_phone }} · {{ new Date(order.appointment_date).toLocaleDateString('vi-VN') }} lúc {{ order.time_slot.slice(0, 5) }}</p><ul><li v-for="service in order.booking_services" :key="service.service_name"><span>{{ service.service_name }}</span><strong>{{ service.staff_name }}</strong></li></ul><div class="order-card-bottom"><strong>{{ order.total_amount.toLocaleString('vi-VN') }}đ</strong><div><button v-if="order.status === 'waiting'" class="secondary-button" @click="change(order, 'serving')"><Play :size="16" /> Nhận phục vụ</button><button v-else-if="order.status === 'serving'" class="primary-button" @click="goToCheckout(order)"><CheckCheck :size="16" /> Chuyển thanh toán</button><span v-else-if="order.status === 'completed'" class="completed-label"><Clock3 :size="16" /> Đã hoàn thành</span><button v-if="order.status !== 'completed'" class="icon-text-button danger" @click="change(order, 'cancelled')"><XCircle :size="16" /> Hủy</button></div></div></article></div>
</template>
