revoke all on function public.create_public_booking(jsonb) from anon;
revoke all on function public.public_booking_catalog() from anon;
revoke all on function public.checkout_invoice(jsonb) from anon;
revoke all on function public.dashboard_metrics(date) from anon;
revoke all on function public.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) from anon;
revoke all on function public.handle_new_user() from anon;
revoke all on function public.current_profile_role() from anon;
revoke all on function public.is_active_staff() from anon;
revoke all on function public.can_operate() from anon;
revoke all on function public.can_manage() from anon;
revoke all on function public.can_access_booking(uuid) from anon;
revoke all on function public.purge_expired_operational_history() from anon;

grant execute on function public.create_public_booking(jsonb), public.public_booking_catalog() to anon;
