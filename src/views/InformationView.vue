<script setup lang="ts">
import { useRoute } from 'vue-router'
import { BookOpenCheck, ShieldCheck, Workflow } from 'lucide-vue-next'
const route = useRoute()
</script>

<template>
  <div class="page-intro"><div><p class="eyebrow">Chilling OS</p><h2>{{ route.meta.title }}</h2><p>Không gian này dành cho thiết lập vận hành, phân quyền và tài liệu triển khai an toàn.</p></div></div><section class="info-grid"><article class="panel"><ShieldCheck :size="28" /><h3>Bảo mật theo vai trò</h3><p>Owner, manager, cashier, barber và skinner được kiểm soát bằng Supabase Auth + RLS. Không có Service Role Key trong trình duyệt.</p></article><article class="panel"><BookOpenCheck :size="28" /><h3>Tài liệu vận hành</h3><p>Thực hiện đúng luồng online, offline, kho, chiết khấu và PDF trong file <code>OPERATIONS_GUIDE.md</code> của repo.</p></article><article class="panel"><Workflow :size="28" /><h3>Kiểm tra cuối ngày</h3><p>Đối chiếu tiền mặt/chuyển khoản, chi phí nhập kho, đơn đang phục vụ và các hóa đơn cần xuất PDF trước khi chốt ca.</p></article></section>
</template>
