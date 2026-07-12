export type AppRole = 'owner' | 'manager' | 'cashier' | 'barber' | 'skinner'
export type ReportScope = 'day' | 'month' | 'all'
export type BookingStatus = 'waiting' | 'serving' | 'completed' | 'cancelled'
export type PaymentMethod = 'cash' | 'bank_transfer'

export type Staff = {
  id: string
  display_name: string
  position: string
  avatar_url: string | null
  phone: string | null
  field_one_label: string | null
  field_one_value: string | null
  field_two_label: string | null
  field_two_value: string | null
  field_three_label: string | null
  field_three_value: string | null
  is_active: boolean
}

export type Service = {
  id: string
  name: string
  category: string
  price: number
  duration_minutes: number
  provider_role: 'barber' | 'skinner' | null
  is_active: boolean
}

export type InventoryItem = {
  id: string
  item_code: string
  name: string
  quantity: number
  unit: string
  unit_cost: number
  field_one_label: string | null
  field_one_value: string | null
  field_two_label: string | null
  field_two_value: string | null
}

export type InventoryMovement = {
  id: string
  item_id: string
  movement_type: 'in' | 'out'
  quantity: number
  unit_cost: number
  note: string | null
  created_at: string
  inventory_items?: Pick<InventoryItem, 'item_code' | 'name' | 'unit'> | null
}

export type Customer = {
  id: string
  customer_code: string
  full_name: string
  phone: string
  created_at: string
}

export type Booking = {
  id: string
  booking_code: string
  customer_name: string
  customer_phone: string
  appointment_date: string
  time_slot: string
  total_amount: number
  status: BookingStatus
  created_at: string
  booking_services?: Array<{ service_id?: string | null; staff_id?: string | null; service_name: string; staff_name: string | null; quantity?: number }>
}

export type Invoice = {
  id: string
  invoice_no: string
  customer_name: string
  customer_phone: string
  subtotal: number
  discount_percent: number
  discount_amount: number
  total_amount: number
  payment_method: PaymentMethod
  paid_at: string
  status: 'paid' | 'void' | 'refunded'
  invoice_lines?: Array<{ service_name: string; quantity: number; unit_price: number; staff_name: string | null }>
}

export type DashboardMetrics = {
  date: string
  scope: ReportScope
  revenue: number
  bookingCount: number
  invoiceCount: number
  expenses: number
  profit: number
  staffCommission: number
  ownerCommission: number
  cash: { count: number; amount: number }
  bankTransfer: { count: number; amount: number }
  monthlyRevenue: Array<{ month: string; revenue: number }>
  monthlyExpenses: Array<{ month: string; revenue: number }>
  staffRank: Array<{ name: string; revenue: number }>
  customerRank: Array<{ name: string; visits: number }>
  serviceRank: Array<{ name: string; sold: number }>
}

export type CommissionRule = {
  id: string
  staff_id: string
  commission_rate: number
  effective_from: string
}

export type CommissionMetrics = {
  date: string
  scope: ReportScope
  revenue: number
  staffShare: number
  ownerShare: number
  items: Array<{ staffId: string | null; name: string; revenue: number; rate: number; staffShare: number; ownerShare: number }>
}

export type TelegramConfigStatus = {
  configured: boolean
  chatId: string | null
  enabled: boolean
  updatedAt: string | null
}

export type AdminNotification = {
  id: string
  booking_code: string
  customer_name: string
  appointment_date: string
  time_slot: string
  status: BookingStatus
  created_at: string
}

export type CheckoutLine = {
  serviceId: string
  staffId: string
  quantity: number
}

export type BankAccount = {
  id: string
  bank_name: string
  bank_bin: string
  account_number: string
  account_name: string
  branch_name: string | null
  is_active: boolean
}

export type LandingContent = {
  id: string
  content_key: string
  content_value: Record<string, unknown>
  is_public: boolean
}

export type LandingMedia = {
  id: string
  section_key: 'hero' | 'studio' | 'services' | 'gallery'
  storage_path: string
  public_url: string | null
  alt_text: string
  sort_order: number
  is_active: boolean
}
