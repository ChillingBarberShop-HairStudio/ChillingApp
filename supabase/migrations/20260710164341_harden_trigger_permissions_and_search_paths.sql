revoke all on function public.rls_auto_enable() from public, anon, authenticated;
alter function public.next_booking_code() set search_path = pg_catalog, public;
alter function public.next_invoice_no() set search_path = pg_catalog, public;
alter function public.set_updated_at() set search_path = pg_catalog;
