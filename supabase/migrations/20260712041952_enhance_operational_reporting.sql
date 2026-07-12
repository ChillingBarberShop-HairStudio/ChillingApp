-- Operational reporting, commission, inventory retention and editable landing media.
-- Privileged work stays in the private schema; public functions remain invoker-only RPC wrappers.

alter table public.staff_profiles alter column position drop default;
alter table public.staff_profiles alter column position type text using position::text;
alter table public.staff_profiles alter column position set default 'Barber';

create table if not exists public.staff_commission_rules (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null unique references public.staff_profiles(id) on delete cascade,
  commission_rate numeric(5,2) not null default 50 check (commission_rate between 0 and 100),
  effective_from date not null default current_date,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.invoice_lines
  add column if not exists commission_rate numeric(5,2) not null default 50 check (commission_rate between 0 and 100),
  add column if not exists staff_commission_amount numeric(14,0) not null default 0 check (staff_commission_amount >= 0),
  add column if not exists owner_commission_amount numeric(14,0) not null default 0 check (owner_commission_amount >= 0);

update public.invoice_lines
set
  staff_commission_amount = round(unit_price * quantity * commission_rate / 100, 0),
  owner_commission_amount = (unit_price * quantity) - round(unit_price * quantity * commission_rate / 100, 0)
where staff_commission_amount = 0 and owner_commission_amount = 0;

insert into public.staff_commission_rules (staff_id, commission_rate)
select id, 50 from public.staff_profiles
on conflict (staff_id) do nothing;

alter table public.staff_commission_rules enable row level security;
create policy "commission rules manager only" on public.staff_commission_rules
  for all to authenticated using (public.can_manage()) with check (public.can_manage());
grant select, insert, update, delete on public.staff_commission_rules to authenticated;

create index if not exists inventory_movements_created_at_idx on public.inventory_movements (created_at desc);
create index if not exists invoice_lines_staff_id_idx on public.invoice_lines (staff_id);
create index if not exists invoices_paid_at_idx on public.invoices (paid_at) where status = 'paid';

create table if not exists public.landing_media (
  id uuid primary key default gen_random_uuid(),
  section_key text not null check (section_key in ('hero', 'studio', 'services', 'gallery')),
  storage_path text not null unique,
  alt_text text not null default 'Hình ảnh Chilling Barber Shop',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.landing_media enable row level security;
create policy "public landing media read" on public.landing_media
  for select to anon, authenticated using (is_active or public.can_manage());
create policy "landing media manager write" on public.landing_media
  for all to authenticated using (public.can_manage()) with check (public.can_manage());
grant select on public.landing_media to anon, authenticated;
grant insert, update, delete on public.landing_media to authenticated;
create index if not exists landing_media_section_order_idx on public.landing_media (section_key, sort_order, created_at);

insert into public.landing_content (content_key, content_value, is_public)
values
  ('hero', '{"eyebrow":"Hair studio tại Bàu Bàng","title":"Chất riêng","highlight":"Chuẩn đẹp","description":"Cắt tóc, uốn, nhuộm và chăm sóc diện mạo cùng đội ngũ barber tận tâm trong không gian chỉn chu, thoải mái."}'::jsonb, true),
  ('studio', '{"eyebrow":"Không gian & tay nghề","titleLineOne":"Barber studio","titleLineTwo":"đúng chất của bạn","description":"Từ tư vấn kiểu tóc phù hợp khuôn mặt đến kỹ thuật hoàn thiện, mỗi dịch vụ đều rõ giá, rõ thời gian và được thực hiện với sự tập trung cao nhất."}'::jsonb, true),
  ('services', '{"eyebrow":"Dịch vụ và mẫu tóc","titleLineOne":"Chọn kiểu phù hợp","titleLineTwo":"Trọn vẹn phong cách"}'::jsonb, true),
  ('gallery', '{"eyebrow":"Chilling lookbook","title":"Tác phẩm hoàn thiện","description":"Một số phong cách tóc và trải nghiệm hoàn thiện tại Chilling Barber Shop."}'::jsonb, true)
on conflict (content_key) do update set is_public = excluded.is_public;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('staff-avatars', 'staff-avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('landing-media', 'landing-media', true, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "manager manages staff avatar objects" on storage.objects;
create policy "manager manages staff avatar objects" on storage.objects
  for all to authenticated
  using (bucket_id = 'staff-avatars' and public.can_manage())
  with check (bucket_id = 'staff-avatars' and public.can_manage());

drop policy if exists "manager manages landing media objects" on storage.objects;
create policy "manager manages landing media objects" on storage.objects
  for all to authenticated
  using (bucket_id = 'landing-media' and public.can_manage())
  with check (bucket_id = 'landing-media' and public.can_manage());

drop function if exists public.dashboard_metrics(date);
drop function if exists private.dashboard_metrics(date);

create function private.dashboard_metrics(
  p_date date default current_date,
  p_scope text default 'day'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  result jsonb;
  v_start date;
  v_end date := coalesce(p_date, current_date);
  v_chart_start date;
begin
  if not private.can_operate() then raise exception 'Không có quyền xem dashboard'; end if;
  if p_scope not in ('day', 'month', 'all') then raise exception 'Phạm vi báo cáo không hợp lệ'; end if;

  if p_scope = 'day' then
    v_start := v_end;
  elsif p_scope = 'month' then
    v_start := date_trunc('month', v_end)::date;
    v_end := (date_trunc('month', v_end) + interval '1 month - 1 day')::date;
  else
    select coalesce(min(entry_date), (v_end - interval '5 months')::date)
    into v_start
    from (
      select min(paid_at::date) as entry_date from public.invoices where status = 'paid'
      union all select min(appointment_date) from public.bookings
      union all select min(expense_date) from public.expenses
    ) periods;
  end if;

  v_chart_start := case
    when p_scope = 'all' then date_trunc('month', v_start)::date
    else (date_trunc('month', v_end) - interval '5 months')::date
  end;

  select jsonb_build_object(
    'date', v_end,
    'scope', p_scope,
    'revenue', coalesce((select sum(total_amount) from public.invoices where status = 'paid' and paid_at::date between v_start and v_end), 0),
    'bookingCount', coalesce((select count(*) from public.bookings where appointment_date between v_start and v_end), 0),
    'invoiceCount', coalesce((select count(*) from public.invoices where status = 'paid' and paid_at::date between v_start and v_end), 0),
    'cash', jsonb_build_object('count', coalesce((select count(*) from public.invoices where status = 'paid' and paid_at::date between v_start and v_end and payment_method = 'cash'), 0), 'amount', coalesce((select sum(total_amount) from public.invoices where status = 'paid' and paid_at::date between v_start and v_end and payment_method = 'cash'), 0)),
    'bankTransfer', jsonb_build_object('count', coalesce((select count(*) from public.invoices where status = 'paid' and paid_at::date between v_start and v_end and payment_method = 'bank_transfer'), 0), 'amount', coalesce((select sum(total_amount) from public.invoices where status = 'paid' and paid_at::date between v_start and v_end and payment_method = 'bank_transfer'), 0)),
    'expenses', coalesce((select sum(amount) from public.expenses where expense_date between v_start and v_end), 0),
    'staffCommission', coalesce((select sum(il.staff_commission_amount) from public.invoice_lines il join public.invoices i on i.id = il.invoice_id where i.status = 'paid' and i.paid_at::date between v_start and v_end), 0),
    'ownerCommission', coalesce((select sum(il.owner_commission_amount) from public.invoice_lines il join public.invoices i on i.id = il.invoice_id where i.status = 'paid' and i.paid_at::date between v_start and v_end), 0),
    'monthlyRevenue', coalesce((
      select jsonb_agg(jsonb_build_object('month', to_char(month_start, 'MM/YYYY'), 'revenue', revenue) order by month_start)
      from (
        select m.month_start, coalesce(sum(i.total_amount), 0) as revenue
        from generate_series(date_trunc('month', v_chart_start), date_trunc('month', v_end), interval '1 month') as m(month_start)
        left join public.invoices i on i.status = 'paid' and date_trunc('month', i.paid_at) = m.month_start
        group by m.month_start
      ) monthly
    ), '[]'::jsonb),
    'staffRank', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'revenue', revenue) order by revenue desc, name asc)
      from (
        select coalesce(il.staff_name, 'Chưa gán') as name, sum(il.unit_price * il.quantity) as revenue
        from public.invoice_lines il join public.invoices i on i.id = il.invoice_id
        where i.status = 'paid' and i.paid_at::date between v_start and v_end
        group by il.staff_name order by revenue desc, name asc limit 5
      ) ranked_staff
    ), '[]'::jsonb),
    'customerRank', coalesce((
      select jsonb_agg(jsonb_build_object('name', full_name, 'visits', visits) order by visits desc, full_name asc)
      from (
        select c.full_name, count(i.id) as visits
        from public.customers c join public.invoices i on i.customer_id = c.id
        where i.status = 'paid' and i.paid_at::date between v_start and v_end
        group by c.id, c.full_name order by visits desc, full_name asc limit 5
      ) ranked_customers
    ), '[]'::jsonb),
    'serviceRank', coalesce((
      select jsonb_agg(jsonb_build_object('name', service_name, 'sold', sold) order by sold desc, service_name asc)
      from (
        select il.service_name, sum(il.quantity) as sold
        from public.invoice_lines il join public.invoices i on i.id = il.invoice_id
        where i.status = 'paid' and i.paid_at::date between v_start and v_end
        group by il.service_name order by sold desc, service_name asc limit 5
      ) ranked_services
    ), '[]'::jsonb)
  ) into result;

  result := jsonb_set(result, '{profit}', to_jsonb((result ->> 'revenue')::numeric - (result ->> 'expenses')::numeric));
  return result;
end;
$$;

create function public.dashboard_metrics(
  p_date date default current_date,
  p_scope text default 'day'
)
returns jsonb
language sql
security invoker
set search_path = pg_catalog, private
as $$ select private.dashboard_metrics(p_date, p_scope) $$;

create function private.commission_metrics(
  p_date date default current_date,
  p_scope text default 'day'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_start date;
  v_end date := coalesce(p_date, current_date);
begin
  if not private.can_operate() then raise exception 'Không có quyền xem chiết khấu'; end if;
  if p_scope not in ('day', 'month', 'all') then raise exception 'Phạm vi báo cáo không hợp lệ'; end if;
  if p_scope = 'day' then
    v_start := v_end;
  elsif p_scope = 'month' then
    v_start := date_trunc('month', v_end)::date;
    v_end := (date_trunc('month', v_end) + interval '1 month - 1 day')::date;
  else
    select coalesce(min(paid_at::date), v_end) into v_start from public.invoices where status = 'paid';
  end if;

  return jsonb_build_object(
    'date', v_end,
    'scope', p_scope,
    'revenue', coalesce((select sum(total_amount) from public.invoices where status = 'paid' and paid_at::date between v_start and v_end), 0),
    'staffShare', coalesce((select sum(il.staff_commission_amount) from public.invoice_lines il join public.invoices i on i.id = il.invoice_id where i.status = 'paid' and i.paid_at::date between v_start and v_end), 0),
    'ownerShare', coalesce((select sum(il.owner_commission_amount) from public.invoice_lines il join public.invoices i on i.id = il.invoice_id where i.status = 'paid' and i.paid_at::date between v_start and v_end), 0),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object('staffId', staff_id, 'name', name, 'revenue', revenue, 'rate', rate, 'staffShare', staff_share, 'ownerShare', owner_share) order by staff_share desc, name asc)
      from (
        select
          il.staff_id as staff_id,
          coalesce(max(il.staff_name), 'Chưa gán') as name,
          sum(il.unit_price * il.quantity) as revenue,
          case when sum(il.staff_commission_amount + il.owner_commission_amount) = 0 then 0 else round(sum(il.staff_commission_amount) * 100 / sum(il.staff_commission_amount + il.owner_commission_amount), 2) end as rate,
          sum(il.staff_commission_amount) as staff_share,
          sum(il.owner_commission_amount) as owner_share
        from public.invoice_lines il join public.invoices i on i.id = il.invoice_id
        where i.status = 'paid' and i.paid_at::date between v_start and v_end
        group by il.staff_id
      ) commission_rows
    ), '[]'::jsonb)
  );
end;
$$;

create function public.commission_metrics(
  p_date date default current_date,
  p_scope text default 'day'
)
returns jsonb
language sql
security invoker
set search_path = pg_catalog, private
as $$ select private.commission_metrics(p_date, p_scope) $$;

create or replace function private.checkout_invoice(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_phone text := regexp_replace(coalesce(p_payload #>> '{customer,phone}', ''), '[^0-9]', '', 'g');
  v_name text := btrim(coalesce(p_payload #>> '{customer,fullName}', ''));
  v_customer_id uuid;
  v_invoice_id uuid;
  v_invoice_no text;
  v_line jsonb;
  v_service record;
  v_staff record;
  v_quantity integer;
  v_subtotal numeric(14,0) := 0;
  v_discount_percent numeric(5,2) := greatest(0, least(100, coalesce(nullif(p_payload ->> 'discountPercent', '')::numeric, 0)));
  v_discount_amount numeric(14,0);
  v_total numeric(14,0);
  v_line_net_amount numeric(14,0);
  v_commission_rate numeric(5,2);
  v_staff_share numeric(14,0);
  v_owner_share numeric(14,0);
  v_method public.payment_method := coalesce(nullif(p_payload ->> 'paymentMethod', '')::public.payment_method, 'cash');
  v_booking_id uuid := nullif(p_payload ->> 'bookingId', '')::uuid;
  v_bank_account_id uuid := nullif(p_payload ->> 'bankAccountId', '')::uuid;
begin
  if not private.can_operate() then raise exception 'Không có quyền thanh toán'; end if;
  if v_phone !~ '^0(3|5|7|8|9)[0-9]{8}$' then raise exception 'Số điện thoại không hợp lệ'; end if;
  if char_length(v_name) < 2 then raise exception 'Họ và tên không hợp lệ'; end if;
  if jsonb_typeof(p_payload -> 'lines') <> 'array' or jsonb_array_length(p_payload -> 'lines') = 0 then raise exception 'Hóa đơn chưa có dịch vụ'; end if;

  insert into public.customers (full_name, phone)
  values (v_name, v_phone)
  on conflict (phone) do update set full_name = excluded.full_name
  returning id into v_customer_id;

  if v_booking_id is not null and not exists (
    select 1 from public.bookings
    where id = v_booking_id and customer_id = v_customer_id and status in ('waiting', 'serving')
  ) then raise exception 'Đơn đặt lịch không hợp lệ hoặc đã được thanh toán'; end if;

  if v_method = 'bank_transfer' and (
    v_bank_account_id is null or not exists (select 1 from public.bank_accounts where id = v_bank_account_id and is_active)
  ) then raise exception 'Vui lòng chọn tài khoản ngân hàng đang hoạt động'; end if;
  if v_method = 'cash' then v_bank_account_id := null; end if;

  for v_line in select value from jsonb_array_elements(p_payload -> 'lines')
  loop
    select id, name, price, duration_minutes into v_service from public.services where id = (v_line ->> 'serviceId')::uuid and is_active limit 1;
    if not found then raise exception 'Dịch vụ không hợp lệ'; end if;
    select id, display_name into v_staff from public.staff_profiles where id = (v_line ->> 'staffId')::uuid and is_active limit 1;
    if not found then raise exception 'Nhân viên không hợp lệ'; end if;
    if not exists (select 1 from public.service_staff where service_id = v_service.id and staff_id = v_staff.id) then raise exception 'Nhân viên không thực hiện dịch vụ đã chọn'; end if;
    v_quantity := greatest(1, least(10, coalesce(nullif(v_line ->> 'quantity', '')::integer, 1)));
    v_subtotal := v_subtotal + (v_service.price * v_quantity);
  end loop;

  v_discount_amount := round(v_subtotal * v_discount_percent / 100, 0);
  v_total := v_subtotal - v_discount_amount;
  insert into public.invoices (booking_id, customer_id, customer_name, customer_phone, subtotal, discount_percent, discount_amount, total_amount, payment_method, bank_account_id, created_by)
  values (v_booking_id, v_customer_id, v_name, v_phone, v_subtotal, v_discount_percent, v_discount_amount, v_total, v_method, v_bank_account_id, auth.uid())
  returning id, invoice_no into v_invoice_id, v_invoice_no;

  for v_line in select value from jsonb_array_elements(p_payload -> 'lines')
  loop
    select id, name, price, duration_minutes into v_service from public.services where id = (v_line ->> 'serviceId')::uuid limit 1;
    select id, display_name into v_staff from public.staff_profiles where id = (v_line ->> 'staffId')::uuid limit 1;
    v_quantity := greatest(1, least(10, coalesce(nullif(v_line ->> 'quantity', '')::integer, 1)));
    select coalesce((select commission_rate from public.staff_commission_rules where staff_id = v_staff.id), 50) into v_commission_rate;
    v_line_net_amount := round(v_service.price * v_quantity * (100 - v_discount_percent) / 100, 0);
    v_staff_share := round(v_line_net_amount * v_commission_rate / 100, 0);
    v_owner_share := v_line_net_amount - v_staff_share;
    insert into public.invoice_lines (invoice_id, service_id, service_name, staff_id, staff_name, unit_price, quantity, duration_minutes, commission_rate, staff_commission_amount, owner_commission_amount)
    values (v_invoice_id, v_service.id, v_service.name, v_staff.id, v_staff.display_name, v_service.price, v_quantity, v_service.duration_minutes, v_commission_rate, v_staff_share, v_owner_share);
  end loop;

  insert into public.payments (invoice_id, method, amount, bank_account_id, payment_reference)
  values (v_invoice_id, v_method, v_total, v_bank_account_id, nullif(p_payload ->> 'paymentReference', ''));
  if v_booking_id is not null then update public.bookings set status = 'completed', completed_at = now() where id = v_booking_id; end if;
  return jsonb_build_object('ok', true, 'invoiceId', v_invoice_id, 'invoiceNo', v_invoice_no, 'totalAmount', v_total);
end;
$$;

create extension if not exists pg_cron with schema extensions;
do $$
begin
  if not exists (select 1 from cron.job where jobname = 'chilling-purge-operational-history') then
    perform cron.schedule('chilling-purge-operational-history', '15 2 * * *', 'select private.purge_expired_operational_history()');
  end if;
end;
$$;

revoke all on function private.dashboard_metrics(date, text) from public, anon, authenticated;
revoke all on function private.commission_metrics(date, text) from public, anon, authenticated;
revoke all on function public.dashboard_metrics(date, text) from public, anon;
revoke all on function public.commission_metrics(date, text) from public, anon;
grant execute on function private.dashboard_metrics(date, text), private.commission_metrics(date, text) to authenticated;
grant execute on function public.dashboard_metrics(date, text), public.commission_metrics(date, text) to authenticated;
