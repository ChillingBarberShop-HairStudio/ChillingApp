revoke all on table public.profiles, public.staff_profiles, public.customers, public.service_staff, public.bookings, public.booking_services, public.inventory_items, public.inventory_movements, public.expenses, public.bank_accounts, public.invoices, public.invoice_lines, public.payments, public.tax_profiles, public.audit_logs from anon;
grant select on table public.services, public.landing_content to anon;

revoke all on function public.create_public_booking(jsonb) from public;
revoke all on function public.public_booking_catalog() from public;
revoke all on function public.checkout_invoice(jsonb) from public;
revoke all on function public.dashboard_metrics(date) from public;
revoke all on function public.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) from public;
revoke all on function public.handle_new_user() from public;
revoke all on function public.current_profile_role() from public;
revoke all on function public.is_active_staff() from public;
revoke all on function public.can_operate() from public;
revoke all on function public.can_manage() from public;
revoke all on function public.can_access_booking(uuid) from public;
revoke all on function public.purge_expired_operational_history() from public;

grant execute on function public.create_public_booking(jsonb), public.public_booking_catalog() to anon, authenticated;
grant execute on function public.checkout_invoice(jsonb), public.dashboard_metrics(date), public.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) to authenticated;
grant execute on function public.current_profile_role(), public.is_active_staff(), public.can_operate(), public.can_manage(), public.can_access_booking(uuid) to authenticated;

alter default privileges for role postgres in schema public revoke select, insert, update, delete on tables from anon;
alter default privileges for role postgres in schema public revoke execute on functions from public;
