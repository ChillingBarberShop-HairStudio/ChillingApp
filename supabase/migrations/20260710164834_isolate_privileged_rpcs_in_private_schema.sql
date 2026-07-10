create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated;

alter function public.current_profile_role() set schema private;
alter function public.is_active_staff() set schema private;
alter function public.can_operate() set schema private;
alter function public.can_manage() set schema private;
alter function public.can_access_booking(uuid) set schema private;
alter function public.handle_new_user() set schema private;
alter function public.purge_expired_operational_history() set schema private;
alter function public.public_booking_catalog() set schema private;
alter function public.create_public_booking(jsonb) set schema private;
alter function public.checkout_invoice(jsonb) set schema private;
alter function public.dashboard_metrics(date) set schema private;
alter function public.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) set schema private;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    update cron.job
    set command = 'select private.purge_expired_operational_history()'
    where jobname = 'chilling-purge-operational-history';
  end if;
end $$;

create function public.current_profile_role()
returns public.app_role language sql stable security invoker set search_path = pg_catalog, private
as $$ select private.current_profile_role() $$;

create function public.is_active_staff()
returns boolean language sql stable security invoker set search_path = pg_catalog, private
as $$ select private.is_active_staff() $$;

create function public.can_operate()
returns boolean language sql stable security invoker set search_path = pg_catalog, private
as $$ select private.can_operate() $$;

create function public.can_manage()
returns boolean language sql stable security invoker set search_path = pg_catalog, private
as $$ select private.can_manage() $$;

create function public.can_access_booking(p_booking_id uuid)
returns boolean language sql stable security invoker set search_path = pg_catalog, private
as $$ select private.can_access_booking(p_booking_id) $$;

create function public.public_booking_catalog()
returns jsonb language sql security invoker set search_path = pg_catalog, private
as $$ select private.public_booking_catalog() $$;

create function public.create_public_booking(p_payload jsonb)
returns jsonb language sql security invoker set search_path = pg_catalog, private
as $$ select private.create_public_booking(p_payload) $$;

create function public.checkout_invoice(p_payload jsonb)
returns jsonb language sql security invoker set search_path = pg_catalog, private
as $$ select private.checkout_invoice(p_payload) $$;

create function public.dashboard_metrics(p_date date default current_date)
returns jsonb language sql security invoker set search_path = pg_catalog, private
as $$ select private.dashboard_metrics(p_date) $$;

create function public.record_inventory_movement(
  p_item_id uuid,
  p_movement_type public.inventory_movement_type,
  p_quantity numeric,
  p_unit_cost numeric default 0,
  p_note text default null
)
returns jsonb language sql security invoker set search_path = pg_catalog, private
as $$ select private.record_inventory_movement(p_item_id, p_movement_type, p_quantity, p_unit_cost, p_note) $$;

revoke all on function private.current_profile_role() from public, anon, authenticated;
revoke all on function private.is_active_staff() from public, anon, authenticated;
revoke all on function private.can_operate() from public, anon, authenticated;
revoke all on function private.can_manage() from public, anon, authenticated;
revoke all on function private.can_access_booking(uuid) from public, anon, authenticated;
revoke all on function private.handle_new_user() from public, anon, authenticated;
revoke all on function private.purge_expired_operational_history() from public, anon, authenticated;
revoke all on function private.public_booking_catalog() from public, anon, authenticated;
revoke all on function private.create_public_booking(jsonb) from public, anon, authenticated;
revoke all on function private.checkout_invoice(jsonb) from public, anon, authenticated;
revoke all on function private.dashboard_metrics(date) from public, anon, authenticated;
revoke all on function private.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) from public, anon, authenticated;

grant execute on function private.current_profile_role(), private.is_active_staff(), private.can_operate(), private.can_manage(), private.can_access_booking(uuid) to authenticated;
grant execute on function private.public_booking_catalog(), private.create_public_booking(jsonb) to anon, authenticated;
grant execute on function private.checkout_invoice(jsonb), private.dashboard_metrics(date), private.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) to authenticated;

revoke all on function public.current_profile_role() from public, anon, authenticated;
revoke all on function public.is_active_staff() from public, anon, authenticated;
revoke all on function public.can_operate() from public, anon, authenticated;
revoke all on function public.can_manage() from public, anon, authenticated;
revoke all on function public.can_access_booking(uuid) from public, anon, authenticated;
revoke all on function public.public_booking_catalog() from public, anon, authenticated;
revoke all on function public.create_public_booking(jsonb) from public, anon, authenticated;
revoke all on function public.checkout_invoice(jsonb) from public, anon, authenticated;
revoke all on function public.dashboard_metrics(date) from public, anon, authenticated;
revoke all on function public.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) from public, anon, authenticated;

grant execute on function public.current_profile_role(), public.is_active_staff(), public.can_operate(), public.can_manage(), public.can_access_booking(uuid) to authenticated;
grant execute on function public.public_booking_catalog(), public.create_public_booking(jsonb) to anon, authenticated;
grant execute on function public.checkout_invoice(jsonb), public.dashboard_metrics(date), public.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) to authenticated;
