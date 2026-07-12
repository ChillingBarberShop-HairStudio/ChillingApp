<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Search, UsersRound } from 'lucide-vue-next'
import { getCustomers } from '../lib/api'
import { isSupabaseConfigured } from '../lib/supabase'
import type { Customer } from '../types/domain'

const customers = ref<Customer[]>([])
const search = ref('')
const filtered = computed(() => customers.value.filter((customer) => `${customer.full_name} ${customer.phone}`.toLocaleLowerCase().includes(search.value.toLocaleLowerCase())))
onMounted(async () => { if (isSupabaseConfigured) customers.value = await getCustomers() })
</script>

<template>
  <div class="page-intro compact"><div><p class="eyebrow">Hồ sơ khách hàng</p><h2>Khách hàng từ online và offline</h2><p>Mỗi số điện thoại là một hồ sơ duy nhất, liên kết trực tiếp với lịch sử hóa đơn.</p></div><div class="search-input"><Search :size="18" /><input v-model="search" placeholder="Tìm tên hoặc số điện thoại" /></div></div>
  <section class="panel customer-summary"><UsersRound :size="28" /><div><strong>{{ customers.length }}</strong><span>Hồ sơ khách hàng đang hiển thị</span></div></section><section class="panel table-panel"><table><thead><tr><th>Mã khách hàng</th><th>Họ tên</th><th>Số điện thoại</th><th>Ngày tạo</th><th>Liên kết</th></tr></thead><tbody><tr v-for="customer in filtered" :key="customer.id"><td><code>{{ customer.customer_code }}</code></td><td>{{ customer.full_name }}</td><td>{{ customer.phone }}</td><td>{{ new Date(customer.created_at).toLocaleDateString('vi-VN') }}</td><td><button class="inline-action">Xem lịch sử</button></td></tr></tbody></table></section>
</template>
