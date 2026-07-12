import { requireSupabase } from './supabase'
import type { BankAccount, Booking, CommissionMetrics, CommissionRule, Customer, DashboardMetrics, InventoryItem, InventoryMovement, Invoice, LandingContent, LandingMedia, ReportScope, Service, Staff } from '../types/domain'

export const DEMO_METRICS: DashboardMetrics = {
  date: new Date().toISOString().slice(0, 10),
  scope: 'day',
  revenue: 4380000,
  bookingCount: 18,
  invoiceCount: 14,
  expenses: 750000,
  profit: 3630000,
  staffCommission: 1815000,
  ownerCommission: 1815000,
  cash: { count: 9, amount: 2460000 },
  bankTransfer: { count: 5, amount: 1920000 },
  monthlyRevenue: [
    { month: '02/2026', revenue: 21000000 }, { month: '03/2026', revenue: 25400000 },
    { month: '04/2026', revenue: 22700000 }, { month: '05/2026', revenue: 29600000 },
    { month: '06/2026', revenue: 31800000 }, { month: '07/2026', revenue: 26700000 },
  ],
  staffRank: [{ name: 'Nam', revenue: 11600000 }, { name: 'Thông', revenue: 9900000 }, { name: 'Boss Linh', revenue: 7500000 }, { name: 'Hương', revenue: 5300000 }, { name: 'Minh', revenue: 4200000 }],
  customerRank: [{ name: 'Nguyễn Minh', visits: 12 }, { name: 'Trần Nam', visits: 9 }, { name: 'Lê Khánh', visits: 8 }, { name: 'Phạm Anh', visits: 7 }, { name: 'Hoàng Long', visits: 6 }],
  serviceRank: [{ name: 'Thợ cắt', sold: 56 }, { name: 'Gội đầu', sold: 39 }, { name: 'Uốn tóc trending', sold: 22 }, { name: 'Massage mặt', sold: 18 }, { name: 'Nhuộm màu cơ bản', sold: 15 }],
}

export const DEMO_STAFF: Staff[] = [
  { id: 'demo-boss', display_name: 'Boss Linh', position: 'owner', avatar_url: null, phone: '0327969930', field_one_label: 'Ngày vào làm', field_one_value: '01/01/2020', field_two_label: 'Quê quán', field_two_value: 'Bình Dương', field_three_label: 'Chuyên môn', field_three_value: 'Chủ quán', is_active: true },
  { id: 'demo-huong', display_name: 'Hương', position: 'skinner', avatar_url: null, phone: '0900000001', field_one_label: 'Ngày vào làm', field_one_value: '03/06/2023', field_two_label: 'Quê quán', field_two_value: 'Bình Dương', field_three_label: 'Chuyên môn', field_three_value: 'Skinner', is_active: true },
  { id: 'demo-nam', display_name: 'Nam', position: 'barber', avatar_url: null, phone: '0900000002', field_one_label: 'Ngày vào làm', field_one_value: '15/09/2022', field_two_label: 'Quê quán', field_two_value: 'TP.HCM', field_three_label: 'Chuyên môn', field_three_value: 'Barber', is_active: true },
]

export const DEMO_SERVICES: Service[] = [
  { id: 'demo-cut', name: 'Thợ cắt (được quyền yêu cầu)', category: 'Cắt tóc', price: 70000, duration_minutes: 35, is_active: true },
  { id: 'demo-owner', name: 'Chủ quán cắt', category: 'Cắt tóc', price: 100000, duration_minutes: 45, is_active: true },
  { id: 'demo-perm', name: 'Uốn tóc trending (Free cắt)', category: 'Uốn - Nhuộm', price: 450000, duration_minutes: 120, is_active: true },
  { id: 'demo-shampoo', name: 'Gội đầu (Shampoo)', category: 'Thư giãn', price: 60000, duration_minutes: 15, is_active: true },
]

export const DEMO_INVENTORY: InventoryItem[] = [
  { id: 'demo-pomade', item_code: 'INV-POMADE', name: 'Sáp tạo kiểu', quantity: 18, unit: 'hộp', unit_cost: 135000, field_one_label: 'Nhà cung cấp', field_one_value: 'Local Brand', field_two_label: 'Vị trí', field_two_value: 'Kệ A1' },
  { id: 'demo-shampoo', item_code: 'INV-SHAMPOO', name: 'Dầu gội', quantity: 12, unit: 'chai', unit_cost: 98000, field_one_label: 'Nhà cung cấp', field_one_value: 'Hair Care', field_two_label: 'Vị trí', field_two_value: 'Kệ B2' },
]

function unwrap<T>({ data, error }: { data: T | null; error: { message: string } | null }): T {
  if (error) throw new Error(error.message)
  return data as T
}

export async function getDashboardMetrics(date: string, scope: ReportScope = 'day'): Promise<DashboardMetrics> {
  const client = requireSupabase()
  const { data, error } = await client.rpc('dashboard_metrics', { p_date: date, p_scope: scope })
  return unwrap<DashboardMetrics>({ data: data as DashboardMetrics | null, error })
}

export async function getStaff(): Promise<Staff[]> {
  const { data, error } = await requireSupabase().from('staff_profiles').select('*').order('display_name')
  return unwrap<Staff[]>({ data: data as Staff[] | null, error })
}

export async function saveStaff(staff: Partial<Staff>): Promise<Staff> {
  const client = requireSupabase()
  if (staff.id?.startsWith('demo-')) throw new Error('Chế độ demo không ghi dữ liệu.')
  const { data, error } = staff.id
    ? await client.from('staff_profiles').update(staff).eq('id', staff.id).select().single()
    : await client.from('staff_profiles').insert(staff).select().single()
  return unwrap<Staff>({ data: data as Staff | null, error })
}

export async function uploadStaffAvatar(file: File): Promise<string> {
  if (!file.type.startsWith('image/') || file.size > 5 * 1024 * 1024) throw new Error('Ảnh nhân viên phải là ảnh JPG, PNG hoặc WebP và không vượt quá 5MB.')
  const extension = file.name.split('.').pop()?.toLowerCase() || 'jpg'
  const path = `staff/${crypto.randomUUID()}.${extension}`
  const { error } = await requireSupabase().storage.from('staff-avatars').upload(path, file, { cacheControl: '31536000', upsert: false, contentType: file.type })
  if (error) throw new Error(error.message)
  return requireSupabase().storage.from('staff-avatars').getPublicUrl(path).data.publicUrl
}

export async function deleteStaff(id: string): Promise<void> {
  const { error } = await requireSupabase().from('staff_profiles').delete().eq('id', id)
  if (error) throw new Error(error.message)
}

export async function getServices(): Promise<Service[]> {
  const { data, error } = await requireSupabase().from('services').select('*').eq('is_active', true).order('category').order('name')
  return unwrap<Service[]>({ data: data as Service[] | null, error })
}

export async function saveService(service: Partial<Service>): Promise<Service> {
  const client = requireSupabase()
  const { data, error } = service.id?.startsWith('demo-')
    ? { data: null, error: { message: 'Chế độ demo không ghi dữ liệu.' } }
    : service.id
      ? await client.from('services').update(service).eq('id', service.id).select().single()
      : await client.from('services').insert(service).select().single()
  return unwrap<Service>({ data: data as Service | null, error })
}

export async function getBankAccounts(): Promise<BankAccount[]> {
  const { data, error } = await requireSupabase().from('bank_accounts').select('*').eq('is_active', true).order('bank_name')
  return unwrap<BankAccount[]>({ data: data as BankAccount[] | null, error })
}

export async function saveBankAccount(account: Partial<BankAccount>): Promise<BankAccount> {
  const client = requireSupabase()
  const { data, error } = account.id
    ? await client.from('bank_accounts').update(account).eq('id', account.id).select().single()
    : await client.from('bank_accounts').insert(account).select().single()
  return unwrap<BankAccount>({ data: data as BankAccount | null, error })
}

export async function getInventory(): Promise<InventoryItem[]> {
  const { data, error } = await requireSupabase().from('inventory_items').select('*').eq('is_active', true).order('name')
  return unwrap<InventoryItem[]>({ data: data as InventoryItem[] | null, error })
}

export async function getInventoryMovements(): Promise<InventoryMovement[]> {
  const { data, error } = await requireSupabase().from('inventory_movements').select('*, inventory_items(item_code, name, unit)').order('created_at', { ascending: false }).limit(200)
  return unwrap<InventoryMovement[]>({ data: data as InventoryMovement[] | null, error })
}

export async function saveInventory(item: Partial<InventoryItem>): Promise<InventoryItem> {
  const client = requireSupabase()
  const { data, error } = item.id?.startsWith('demo-')
    ? { data: null, error: { message: 'Chế độ demo không ghi dữ liệu.' } }
    : item.id
      ? await client.from('inventory_items').update(item).eq('id', item.id).select().single()
      : await client.from('inventory_items').insert(item).select().single()
  return unwrap<InventoryItem>({ data: data as InventoryItem | null, error })
}

export async function recordInventoryMovement(payload: { itemId: string; type: 'in' | 'out'; quantity: number; unitCost?: number; note?: string }) {
  const { data, error } = await requireSupabase().rpc('record_inventory_movement', {
    p_item_id: payload.itemId,
    p_movement_type: payload.type,
    p_quantity: payload.quantity,
    p_unit_cost: payload.unitCost ?? 0,
    p_note: payload.note ?? null,
  })
  return unwrap<Record<string, unknown>>({ data: data as Record<string, unknown> | null, error })
}

export async function getCustomers(): Promise<Customer[]> {
  const { data, error } = await requireSupabase().from('customers').select('*').order('created_at', { ascending: false }).limit(100)
  return unwrap<Customer[]>({ data: data as Customer[] | null, error })
}

export async function getOnlineBookings(): Promise<Booking[]> {
  const { data, error } = await requireSupabase().from('bookings').select('*, booking_services(service_id, staff_id, service_name, staff_name, quantity)').eq('source', 'landing_page').order('created_at', { ascending: false }).limit(100)
  return unwrap<Booking[]>({ data: data as Booking[] | null, error })
}

export async function getBookingForCheckout(id: string): Promise<Booking> {
  const { data, error } = await requireSupabase().from('bookings').select('*, booking_services(service_id, staff_id, service_name, staff_name, quantity)').eq('id', id).single()
  return unwrap<Booking>({ data: data as Booking | null, error })
}

export async function setBookingStatus(id: string, status: Booking['status']): Promise<void> {
  const { error } = await requireSupabase().from('bookings').update({ status, completed_at: status === 'completed' ? new Date().toISOString() : null }).eq('id', id)
  if (error) throw new Error(error.message)
}

export async function getInvoices(): Promise<Invoice[]> {
  const { data, error } = await requireSupabase().from('invoices').select('*, invoice_lines(service_name, quantity, unit_price, staff_name)').order('paid_at', { ascending: false }).limit(100)
  return unwrap<Invoice[]>({ data: data as Invoice[] | null, error })
}

export async function checkout(payload: Record<string, unknown>) {
  const { data, error } = await requireSupabase().rpc('checkout_invoice', { p_payload: payload })
  return unwrap<Record<string, unknown>>({ data: data as Record<string, unknown> | null, error })
}

export async function getCommissionRules(): Promise<CommissionRule[]> {
  const { data, error } = await requireSupabase().from('staff_commission_rules').select('id, staff_id, commission_rate, effective_from').order('effective_from', { ascending: false })
  return unwrap<CommissionRule[]>({ data: data as CommissionRule[] | null, error })
}

export async function saveCommissionRule(rule: Partial<CommissionRule>): Promise<CommissionRule> {
  const client = requireSupabase()
  const { data, error } = rule.id
    ? await client.from('staff_commission_rules').update(rule).eq('id', rule.id).select('id, staff_id, commission_rate, effective_from').single()
    : await client.from('staff_commission_rules').insert(rule).select('id, staff_id, commission_rate, effective_from').single()
  return unwrap<CommissionRule>({ data: data as CommissionRule | null, error })
}

export async function getCommissionMetrics(date: string, scope: ReportScope): Promise<CommissionMetrics> {
  const { data, error } = await requireSupabase().rpc('commission_metrics', { p_date: date, p_scope: scope })
  return unwrap<CommissionMetrics>({ data: data as CommissionMetrics | null, error })
}

export async function getLandingContent() {
  const { data, error } = await requireSupabase().from('landing_content').select('*').order('content_key')
  return unwrap<LandingContent[]>({ data: data as LandingContent[] | null, error })
}

export async function saveLandingContent(id: string, content_value: Record<string, unknown>) {
  const { error } = await requireSupabase().from('landing_content').update({ content_value }).eq('id', id)
  if (error) throw new Error(error.message)
}

export async function upsertLandingContent(contentKey: string, contentValue: Record<string, unknown>): Promise<LandingContent> {
  const { data, error } = await requireSupabase().from('landing_content').upsert({ content_key: contentKey, content_value: contentValue, is_public: true }, { onConflict: 'content_key' }).select('*').single()
  return unwrap<LandingContent>({ data: data as LandingContent | null, error })
}

export async function getLandingMedia(): Promise<LandingMedia[]> {
  const { data, error } = await requireSupabase().from('landing_media').select('id, section_key, storage_path, alt_text, sort_order, is_active').eq('is_active', true).order('section_key').order('sort_order').order('created_at')
  return unwrap<LandingMedia[]>({ data: data as LandingMedia[] | null, error })
}

export async function uploadLandingMedia(file: File, sectionKey: LandingMedia['section_key'], sortOrder: number, altText: string): Promise<LandingMedia> {
  if (!file.type.startsWith('image/') || file.size > 10 * 1024 * 1024) throw new Error('Ảnh landing phải là JPG, PNG hoặc WebP và không vượt quá 10MB.')
  const extension = file.name.split('.').pop()?.toLowerCase() || 'jpg'
  const storagePath = `${sectionKey}/${crypto.randomUUID()}.${extension}`
  const client = requireSupabase()
  const { error: uploadError } = await client.storage.from('landing-media').upload(storagePath, file, { cacheControl: '31536000', upsert: false, contentType: file.type })
  if (uploadError) throw new Error(uploadError.message)
  const { data, error } = await client.from('landing_media').insert({ section_key: sectionKey, storage_path: storagePath, alt_text: altText || 'Hình ảnh Chilling Barber Shop', sort_order: sortOrder }).select('id, section_key, storage_path, alt_text, sort_order, is_active').single()
  if (error) {
    await client.storage.from('landing-media').remove([storagePath])
    throw new Error(error.message)
  }
  return data as LandingMedia
}

export async function saveLandingMedia(media: Pick<LandingMedia, 'id' | 'alt_text' | 'sort_order'>): Promise<void> {
  const { error } = await requireSupabase().from('landing_media').update({ alt_text: media.alt_text, sort_order: media.sort_order }).eq('id', media.id)
  if (error) throw new Error(error.message)
}

export async function deleteLandingMedia(media: LandingMedia): Promise<void> {
  const client = requireSupabase()
  const { error } = await client.from('landing_media').delete().eq('id', media.id)
  if (error) throw new Error(error.message)
  const { error: storageError } = await client.storage.from('landing-media').remove([media.storage_path])
  if (storageError) throw new Error(storageError.message)
}

export function getLandingMediaUrl(storagePath: string): string {
  return requireSupabase().storage.from('landing-media').getPublicUrl(storagePath).data.publicUrl
}
