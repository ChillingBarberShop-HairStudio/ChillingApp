<script setup lang="ts">
import { useRoute } from 'vue-router'
import { BookOpenCheck, ShieldCheck } from 'lucide-vue-next'
const route = useRoute()
</script>

<template>
  <div class="page-intro"><div><p class="eyebrow">Chilling OS</p><h2>{{ route.meta.title }}</h2><p>Không gian này dành cho thiết lập vận hành, phân quyền và tài liệu triển khai an toàn.</p></div></div><section class="info-grid"><article class="panel"><ShieldCheck :size="28" /><h3>Bảo mật theo vai trò</h3><p>Owner, manager, cashier, barber và skinner được kiểm soát bằng Supabase Auth + RLS. Không có Service Role Key trong trình duyệt.</p></article><article class="panel"><BookOpenCheck :size="28" /><h3>Tài liệu triển khai</h3><p>Chạy migration Supabase, tạo owner, cấu hình Cloudflare Worker secrets rồi deploy từng web app tách biệt.</p></article></section>
</template>
