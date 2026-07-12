-- Reporting, service roles and approved Telegram delivery for public bookings.

create or replace function public.dashboard_metrics(
  p_date date default current_date,
  p_scope text default 'day'
)
returns jsonb
language sql
security invoker
set search_path = pg_catalog, private, public
as $$
  with source as (
    select private.dashboard_metrics(p_date, p_scope) as metrics
  ), chart_months as (
    select chart.ordinality, chart.value ->> 'month' as month
    from source
    cross join lateral jsonb_array_elements(source.metrics -> 'monthlyRevenue') with ordinality as chart(value, ordinality)
  ), monthly_expenses as (
    select chart_months.ordinality, chart_months.month, coalesce(sum(expenses.amount), 0) as amount
    from chart_months
    left join public.expenses expenses
      on to_char(date_trunc('month', expenses.expense_date), 'MM/YYYY') = chart_months.month
    group by chart_months.ordinality, chart_months.month
  )
  select jsonb_set(
    source.metrics,
    '{monthlyExpenses}',
    coalesce((
      select jsonb_agg(jsonb_build_object('month', month, 'revenue', amount) order by ordinality)
      from monthly_expenses
    ), '[]'::jsonb),
    true
  )
  from source;
$$;

alter table public.services
  add column if not exists provider_role text
  check (provider_role is null or lower(provider_role) in ('barber', 'skinner'));

create or replace function private.sync_service_staff_by_provider_role()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if new.provider_role is null then
    return new;
  end if;

  if tg_op = 'UPDATE' and new.provider_role is not distinct from old.provider_role then
    return new;
  end if;

  delete from public.service_staff where service_id = new.id;
  insert into public.service_staff (service_id, staff_id)
  select new.id, staff.id
  from public.staff_profiles staff
  where staff.is_active
    and lower(btrim(staff.position)) = lower(btrim(new.provider_role))
  on conflict do nothing;
  return new;
end;
$$;

create or replace function private.sync_staff_to_role_services()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  delete from public.service_staff link
  using public.services service
  where link.service_id = service.id
    and link.staff_id = new.id
    and service.provider_role is not null;

  if new.is_active then
    insert into public.service_staff (service_id, staff_id)
    select service.id, new.id
    from public.services service
    where service.is_active
      and service.provider_role is not null
      and lower(btrim(service.provider_role)) = lower(btrim(new.position))
    on conflict do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists services_sync_staff_by_provider_role on public.services;
create trigger services_sync_staff_by_provider_role
after insert or update of provider_role on public.services
for each row execute function private.sync_service_staff_by_provider_role();

drop trigger if exists staff_sync_role_services on public.staff_profiles;
create trigger staff_sync_role_services
after insert or update of position, is_active on public.staff_profiles
for each row execute function private.sync_staff_to_role_services();

create or replace function private.public_booking_catalog()
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', service.id,
    'name', service.name,
    'category', service.category,
    'price', service.price,
    'durationMinutes', service.duration_minutes,
    'providerRole', lower(service.provider_role),
    'staffOptions', coalesce((
      select jsonb_agg(staff.display_name order by staff.display_name)
      from public.service_staff service_staff
      join public.staff_profiles staff on staff.id = service_staff.staff_id
      where service_staff.service_id = service.id
        and staff.is_active
    ), '[]'::jsonb)
  ) order by service.category, service.name), '[]'::jsonb)
  from public.services service
  where service.is_active;
$$;

create extension if not exists pg_net;

create or replace function private.enqueue_telegram_message(p_text text)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_bot_token text;
  v_chat_id text;
begin
  select secrets.decrypted_secret, settings.chat_id
  into v_bot_token, v_chat_id
  from public.telegram_settings settings
  join vault.decrypted_secrets secrets on secrets.id = settings.bot_token_secret_id
  where settings.setting_key = 'primary'
    and settings.is_enabled;

  if coalesce(v_bot_token, '') = '' or coalesce(v_chat_id, '') = '' then
    return false;
  end if;

  perform net.http_post(
    url := 'https://api.telegram.org/bot' || v_bot_token || '/sendMessage',
    body := jsonb_build_object('chat_id', v_chat_id, 'text', left(p_text, 4096), 'disable_web_page_preview', true),
    headers := '{"Content-Type":"application/json"}'::jsonb
  );
  return true;
exception when others then
  raise warning 'Telegram notification could not be queued: %', sqlerrm;
  return false;
end;
$$;

create or replace function private.notify_telegram_booking()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_services text;
begin
  if new.source <> 'landing_page' then
    return new;
  end if;

  select string_agg(
    format('- %s x%s (%s)', service_name, quantity, coalesce(staff_name, 'Chua gan nhan vien')),
    E'\n' order by service_name, staff_name
  ) into v_services
  from public.booking_services
  where booking_id = new.id;

  perform private.enqueue_telegram_message(format(
    'CHILLING BARBER SHOP - LICH DAT MOI\nMa: %s\nKhach: %s\nSDT: %s\nLich: %s %s\nDich vu:\n%s\nTong: %s VND%s',
    new.booking_code,
    new.customer_name,
    new.customer_phone,
    to_char(new.appointment_date, 'DD/MM/YYYY'),
    to_char(new.time_slot, 'HH24:MI'),
    coalesce(v_services, '- Chua co dich vu'),
    to_char(new.total_amount, 'FM999G999G999G999'),
    case when new.note is null then '' else E'\nGhi chu: ' || new.note end
  ));
  return new;
end;
$$;

drop trigger if exists booking_telegram_notification on public.bookings;
create constraint trigger booking_telegram_notification
after insert on public.bookings
deferrable initially deferred
for each row execute function private.notify_telegram_booking();

create or replace function private.test_telegram_notification()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if not private.can_manage() then
    raise exception 'Khong co quyen quan ly Telegram';
  end if;
  if not private.enqueue_telegram_message('CHILLING BARBER SHOP - ket noi Telegram da duoc gui thu thanh cong.') then
    raise exception 'Chua the gui thu. Kiem tra bot token, Chat ID va trang thai bat thong bao.';
  end if;
  return jsonb_build_object('queued', true);
end;
$$;

create or replace function public.test_telegram_notification()
returns jsonb
language sql
security invoker
set search_path = pg_catalog, private
as $$ select private.test_telegram_notification() $$;

revoke all on function private.enqueue_telegram_message(text) from public, anon, authenticated;
revoke all on function private.notify_telegram_booking() from public, anon, authenticated;
revoke all on function private.test_telegram_notification() from public, anon, authenticated;
revoke all on function public.test_telegram_notification() from public, anon;
revoke all on function public.dashboard_metrics(date, text) from public, anon;
grant execute on function private.test_telegram_notification() to authenticated;
grant execute on function public.test_telegram_notification() to authenticated;
grant execute on function public.dashboard_metrics(date, text) to authenticated;
