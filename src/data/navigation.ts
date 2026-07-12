import type { Component } from 'vue'
import { BadgeDollarSign, Bot, Boxes, CalendarClock, ChartNoAxesCombined, FileText, LayoutDashboard, PackageSearch, ReceiptText, Settings2, ShoppingCart, UsersRound } from 'lucide-vue-next'

export type NavigationItem = { label: string; to: string; icon: Component; note?: string }

export const NAVIGATION: NavigationItem[] = [
  { label: 'Dashboard', to: '/', icon: LayoutDashboard },
  { label: 'Nhân viên', to: '/staff', icon: UsersRound },
  { label: 'Kho hàng', to: '/inventory', icon: PackageSearch },
  { label: 'Khách hàng', to: '/customers', icon: UsersRound },
  { label: 'Đơn online', to: '/online-orders', icon: CalendarClock, note: 'Mới' },
  { label: 'Thanh toán', to: '/checkout', icon: ShoppingCart },
  { label: 'Hóa đơn', to: '/invoices', icon: ReceiptText },
  { label: 'Thuế & báo cáo', to: '/tax', icon: ChartNoAxesCombined },
  { label: 'Landing page', to: '/landing', icon: Settings2 },
  { label: 'Chiết khấu chủ & thợ', to: '/commissions', icon: BadgeDollarSign },
  { label: 'Telegram Bot', to: '/telegram', icon: Bot },
]

export const SECONDARY_NAVIGATION: NavigationItem[] = [
  { label: 'Thiết lập hệ thống', to: '/settings', icon: Boxes },
  { label: 'Tài liệu vận hành', to: '/docs', icon: FileText },
]
