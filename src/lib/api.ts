import { requireSupabase } from './supabase'
import type { BankAccount, Booking, CommissionMetrics, CommissionRule, Customer, DashboardMetrics, InventoryItem, InventoryMovement, Invoice, LandingContent, LandingMedia, ReportScope, Service, Staff, TelegramConfigStatus } from '../types/domain'

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
  const { data, error } = service.id
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
  const { data, error } = item.id
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

export async function getTelegramConfigStatus(): Promise<TelegramConfigStatus> {
  const { data, error } = await requireSupabase().rpc('telegram_config_status')
  return unwrap<TelegramConfigStatus>({ data: data as TelegramConfigStatus | null, error })
}

export async function saveTelegramConfig(payload: { botToken: string; chatId: string; enabled: boolean }): Promise<TelegramConfigStatus> {
  const { data, error } = await requireSupabase().rpc('configure_telegram', {
    p_bot_token: payload.botToken,
    p_chat_id: payload.chatId,
    p_enabled: payload.enabled,
  })
  return unwrap<TelegramConfigStatus>({ data: data as TelegramConfigStatus | null, error })
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
  const { data, error } = await requireSupabase().from('landing_media').select('id, section_key, storage_path, public_url, alt_text, sort_order, is_active').eq('is_active', true).order('section_key').order('sort_order').order('created_at')
  return unwrap<LandingMedia[]>({ data: data as LandingMedia[] | null, error })
}

function validateLandingImage(file: File) {
  if (!file.type.startsWith('image/') || file.size > 10 * 1024 * 1024) throw new Error('Ảnh landing phải là JPG, PNG hoặc WebP và không vượt quá 10MB.')
}

function landingMediaPath(file: File, sectionKey: LandingMedia['section_key']) {
  const extension = file.name.split('.').pop()?.toLowerCase() || 'jpg'
  return `${sectionKey}/${crypto.randomUUID()}.${extension}`
}

export async function uploadLandingMedia(file: File, sectionKey: LandingMedia['section_key'], sortOrder: number, altText: string): Promise<LandingMedia> {
  validateLandingImage(file)
  const storagePath = landingMediaPath(file, sectionKey)
  const client = requireSupabase()
  const { error: uploadError } = await client.storage.from('landing-media').upload(storagePath, file, { cacheControl: '31536000', upsert: false, contentType: file.type })
  if (uploadError) throw new Error(uploadError.message)
  const { data, error } = await client.from('landing_media').insert({ section_key: sectionKey, storage_path: storagePath, public_url: null, alt_text: altText || 'Hình ảnh Chilling Barber Shop', sort_order: sortOrder }).select('id, section_key, storage_path, public_url, alt_text, sort_order, is_active').single()
  if (error) {
    await client.storage.from('landing-media').remove([storagePath])
    throw new Error(error.message)
  }
  return data as LandingMedia
}

export async function replaceLandingMedia(media: LandingMedia, file: File): Promise<LandingMedia> {
  validateLandingImage(file)
  const storagePath = landingMediaPath(file, media.section_key)
  const client = requireSupabase()
  const { error: uploadError } = await client.storage.from('landing-media').upload(storagePath, file, { cacheControl: '31536000', upsert: false, contentType: file.type })
  if (uploadError) throw new Error(uploadError.message)
  const { data, error } = await client.from('landing_media').update({ storage_path: storagePath, public_url: null }).eq('id', media.id).select('id, section_key, storage_path, public_url, alt_text, sort_order, is_active').single()
  if (error) {
    await client.storage.from('landing-media').remove([storagePath])
    throw new Error(error.message)
  }
  if (!media.public_url && !media.storage_path.startsWith('legacy/')) await client.storage.from('landing-media').remove([media.storage_path])
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
  if (!media.public_url && !media.storage_path.startsWith('legacy/')) {
    const { error: storageError } = await client.storage.from('landing-media').remove([media.storage_path])
    if (storageError) throw new Error(storageError.message)
  }
}

export function getLandingMediaUrl(media: Pick<LandingMedia, 'storage_path' | 'public_url'>): string {
  return media.public_url || requireSupabase().storage.from('landing-media').getPublicUrl(media.storage_path).data.publicUrl
}
