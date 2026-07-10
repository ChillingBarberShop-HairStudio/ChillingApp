import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
import StaffView from '../views/StaffView.vue'
import InventoryView from '../views/InventoryView.vue'
import CustomersView from '../views/CustomersView.vue'
import OnlineOrdersView from '../views/OnlineOrdersView.vue'
import CheckoutView from '../views/CheckoutView.vue'
import InvoicesView from '../views/InvoicesView.vue'
import TaxView from '../views/TaxView.vue'
import LandingView from '../views/LandingView.vue'
import InformationView from '../views/InformationView.vue'

export default createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: DashboardView, meta: { title: 'Dashboard' } },
    { path: '/staff', component: StaffView, meta: { title: 'Quản lý nhân viên' } },
    { path: '/inventory', component: InventoryView, meta: { title: 'Quản lý kho hàng' } },
    { path: '/customers', component: CustomersView, meta: { title: 'Quản lý khách hàng' } },
    { path: '/online-orders', component: OnlineOrdersView, meta: { title: 'Đơn hàng online' } },
    { path: '/checkout', component: CheckoutView, meta: { title: 'Thanh toán' } },
    { path: '/invoices', component: InvoicesView, meta: { title: 'Quản lý hóa đơn' } },
    { path: '/tax', component: TaxView, meta: { title: 'Thuế & báo cáo' } },
    { path: '/landing', component: LandingView, meta: { title: 'Quản lý landing page' } },
    { path: '/settings', component: InformationView, meta: { title: 'Thiết lập hệ thống' } },
    { path: '/docs', component: InformationView, meta: { title: 'Tài liệu vận hành' } },
  ],
})
