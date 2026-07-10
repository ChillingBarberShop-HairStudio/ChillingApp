export type AppRole = 'owner' | 'manager' | 'cashier' | 'barber' | 'skinner'
export type BookingStatus = 'waiting' | 'serving' | 'completed' | 'cancelled'
export type PaymentMethod = 'cash' | 'bank_transfer'

export type Staff = {
  id: string
  display_name: string
  position: AppRole
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
  booking_services?: Array<{ service_name: string; staff_name: string | null }>
}

export type Invoice = {
  id: string
  invoice_no: string
  customer_name: string
  customer_phone: string
  subtotal: number
  discount_amount: number
  total_amount: number
  payment_method: PaymentMethod
  paid_at: string
  status: 'paid' | 'void' | 'refunded'
  invoice_lines?: Array<{ service_name: string; quantity: number; unit_price: number; staff_name: string | null }>
}

export type DashboardMetrics = {
  date: string
  revenue: number
  bookingCount: number
  invoiceCount: number
  expenses: number
  profit: number
  cash: { count: number; amount: number }
  bankTransfer: { count: number; amount: number }
  monthlyRevenue: Array<{ month: string; revenue: number }>
  staffRank: Array<{ name: string; revenue: number }>
  customerRank: Array<{ name: string; visits: number }>
  serviceRank: Array<{ name: string; sold: number }>
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
