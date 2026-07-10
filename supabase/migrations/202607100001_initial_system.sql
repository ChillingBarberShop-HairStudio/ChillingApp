-- Chilling Barber Shop operational system. Run in the Supabase SQL Editor
-- or through the Supabase CLI before connecting either web application.

create extension if not exists pgcrypto;
create extension if not exists citext;

do $$ begin
  create type public.app_role as enum ('owner', 'manager', 'cashier', 'barber', 'skinner');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.booking_status as enum ('waiting', 'serving', 'completed', 'cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.invoice_status as enum ('paid', 'void', 'refunded');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.payment_method as enum ('cash', 'bank_transfer');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.inventory_movement_type as enum ('in', 'out', 'adjustment');
exception when duplicate_object then null; end $$;

create sequence if not exists public.booking_number_seq;
create sequence if not exists public.invoice_number_seq;

create or replace function public.next_booking_code()
returns text
language sql
volatile
as $$
  select 'CHL-' || to_char(current_date, 'YYMMDD') || '-' || lpad(nextval('public.booking_number_seq')::text, 5, '0')
$$;

create or replace function public.next_invoice_no()
returns text
language sql
volatile
as $$
  select 'INV-' || to_char(current_date, 'YYMMDD') || '-' || lpad(nextval('public.invoice_number_seq')::text, 5, '0')
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email citext unique,
  display_name text not null default '',
  role public.app_role not null default 'barber',
  avatar_url text,
  is_active boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_profiles (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete set null,
  display_name text not null unique,
  position public.app_role not null default 'barber',
  avatar_url text,
  field_one_label text,
  field_one_value text,
  field_two_label text,
  field_two_value text,
  field_three_label text,
  field_three_value text,
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  customer_code text not null unique default ('CUS-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  full_name text not null,
  phone text not null unique check (phone ~ '^0(3|5|7|8|9)[0-9]{8}$'),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text not null,
  price numeric(14,0) not null check (price >= 0),
  duration_minutes integer not null check (duration_minutes > 0),
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_staff (
  service_id uuid not null references public.services(id) on delete cascade,
  staff_id uuid not null references public.staff_profiles(id) on delete cascade,
  primary key (service_id, staff_id)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_code text not null unique default public.next_booking_code(),
  customer_id uuid references public.customers(id) on delete set null,
  customer_phone text not null check (customer_phone ~ '^0(3|5|7|8|9)[0-9]{8}$'),
  customer_name text not null,
  total_guests integer not null default 1 check (total_guests between 1 and 10),
  branch_name text not null,
  appointment_date date not null,
  time_slot time not null,
  status public.booking_status not null default 'waiting',
  subtotal numeric(14,0) not null default 0 check (subtotal >= 0),
  discount numeric(14,0) not null default 0 check (discount >= 0),
  total_amount numeric(14,0) not null default 0 check (total_amount >= 0),
  total_duration_minutes integer not null default 0,
  note text,
  source text not null default 'landing_page' check (source in ('landing_page', 'offline', 'admin')),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.booking_services (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  service_id uuid references public.services(id) on delete set null,
  service_name text not null,
  staff_id uuid references public.staff_profiles(id) on delete set null,
  staff_name text,
  unit_price numeric(14,0) not null check (unit_price >= 0),
  duration_minutes integer not null check (duration_minutes > 0),
  quantity integer not null default 1 check (quantity between 1 and 10),
  created_at timestamptz not null default now()
);

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  item_code text not null unique default ('INV-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  name text not null,
  quantity numeric(14,2) not null default 0 check (quantity >= 0),
  unit text not null,
  unit_cost numeric(14,0) not null default 0 check (unit_cost >= 0),
  field_one_label text,
  field_one_value text,
  field_two_label text,
  field_two_value text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.inventory_items(id) on delete cascade,
  movement_type public.inventory_movement_type not null,
  quantity numeric(14,2) not null check (quantity > 0),
  unit_cost numeric(14,0) not null default 0 check (unit_cost >= 0),
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  expense_date date not null default current_date,
  category text not null,
  amount numeric(14,0) not null check (amount >= 0),
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.bank_accounts (
  id uuid primary key default gen_random_uuid(),
  bank_name text not null,
  bank_bin text not null,
  account_number text not null,
  account_name text not null,
  branch_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (bank_bin, account_number)
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_no text not null unique default public.next_invoice_no(),
  booking_id uuid unique references public.bookings(id) on delete set null,
  customer_id uuid references public.customers(id) on delete set null,
  customer_name text not null,
  customer_phone text not null,
  subtotal numeric(14,0) not null check (subtotal >= 0),
  discount_percent numeric(5,2) not null default 0 check (discount_percent between 0 and 100),
  discount_amount numeric(14,0) not null default 0 check (discount_amount >= 0),
  total_amount numeric(14,0) not null check (total_amount >= 0),
  payment_method public.payment_method not null,
  bank_account_id uuid references public.bank_accounts(id) on delete set null,
  status public.invoice_status not null default 'paid',
  paid_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.invoice_lines (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  service_id uuid references public.services(id) on delete set null,
  service_name text not null,
  staff_id uuid references public.staff_profiles(id) on delete set null,
  staff_name text,
  unit_price numeric(14,0) not null check (unit_price >= 0),
  quantity integer not null default 1 check (quantity between 1 and 10),
  duration_minutes integer not null check (duration_minutes > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  method public.payment_method not null,
  amount numeric(14,0) not null check (amount >= 0),
  bank_account_id uuid references public.bank_accounts(id) on delete set null,
  payment_reference text,
  created_at timestamptz not null default now()
);

create table if not exists public.tax_profiles (
  id uuid primary key default gen_random_uuid(),
  tax_code text not null unique,
  legal_entity_name text not null,
  taxpayer_type text not null check (taxpayer_type in ('household_business', 'company')),
  calculation_mode text not null default 'manual_review',
  config jsonb not null default '{}'::jsonb,
  effective_from date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.landing_content (
  id uuid primary key default gen_random_uuid(),
  content_key text not null unique,
  content_value jsonb not null default '{}'::jsonb,
  is_public boolean not null default true,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists bookings_appointment_status_idx on public.bookings (appointment_date, status);
create index if not exists bookings_customer_idx on public.bookings (customer_id, created_at desc);
create index if not exists booking_services_booking_idx on public.booking_services (booking_id);
create index if not exists service_staff_service_idx on public.service_staff (service_id);
create index if not exists invoice_paid_idx on public.invoices (paid_at desc, status);
create index if not exists invoice_lines_staff_idx on public.invoice_lines (staff_id, created_at desc);
create index if not exists inventory_movements_item_idx on public.inventory_movements (item_id, created_at desc);
create index if not exists audit_logs_created_idx on public.audit_logs (created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
as $$ begin new.updated_at = now(); return new; end $$;

do $$
declare table_name text;
begin
  foreach table_name in array array['profiles', 'staff_profiles', 'customers', 'services', 'inventory_items', 'bank_accounts', 'tax_profiles', 'landing_content']
  loop
    execute format('drop trigger if exists %I on public.%I', 'set_' || table_name || '_updated_at', table_name);
    execute format('create trigger %I before update on public.%I for each row execute function public.set_updated_at()', 'set_' || table_name || '_updated_at', table_name);
  end loop;
end $$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.current_profile_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid() and is_active limit 1
$$;

create or replace function public.is_active_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and is_active)
$$;

create or replace function public.can_operate()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_profile_role() in ('owner', 'manager', 'cashier'), false)
$$;

create or replace function public.can_manage()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_profile_role() in ('owner', 'manager'), false)
$$;

create or replace function public.can_access_booking(p_booking_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.can_operate() or exists (
    select 1
    from public.booking_services bs
    join public.staff_profiles sp on sp.id = bs.staff_id
    where bs.booking_id = p_booking_id and sp.profile_id = auth.uid() and sp.is_active
  )
$$;

insert into public.staff_profiles (display_name, position, field_one_label, field_one_value)
values
  ('Boss Linh', 'owner', 'Vai trò', 'Chủ quán'),
  ('Hương', 'skinner', 'Chuyên môn', 'Skinner'),
  ('Nam', 'barber', 'Chuyên môn', 'Barber'),
  ('Thông', 'barber', 'Chuyên môn', 'Barber')
on conflict (display_name) do nothing;

insert into public.services (name, category, price, duration_minutes)
values
  ('Thợ cắt (được quyền yêu cầu)', 'Cắt tóc', 70000, 35),
  ('Chủ quán cắt', 'Cắt tóc', 100000, 45),
  ('Nhuộm màu thời trang (Free cắt)', 'Uốn - Ép - Tẩy - Nhuộm', 400000, 180),
  ('Nhuộm màu cơ bản (Free cắt)', 'Uốn - Ép - Tẩy - Nhuộm', 300000, 120),
  ('Uốn tóc trending (Free cắt)', 'Uốn - Ép - Tẩy - Nhuộm', 450000, 120),
  ('Uốn tóc cơ bản (Free cắt)', 'Uốn - Ép - Tẩy - Nhuộm', 300000, 90),
  ('Massage mặt, cổ, vai gáy', 'Thư giãn', 100000, 120),
  ('Gội đầu (Shampoo)', 'Thư giãn', 60000, 15),
  ('Massage mặt', 'Thư giãn', 20000, 15),
  ('Đánh mắt', 'Dịch vụ riêng lẻ', 50000, 20),
  ('Cắt móng tay, chân', 'Dịch vụ riêng lẻ', 100000, 20),
  ('Nhổ tóc bạc', 'Dịch vụ riêng lẻ', 50000, 30),
  ('Xông mặt hút mụn', 'Dịch vụ riêng lẻ', 50000, 15),
  ('Se lỗ ghèn', 'Dịch vụ riêng lẻ', 80000, 20),
  ('Nặn mụn', 'Dịch vụ riêng lẻ', 50000, 30)
on conflict (name) do update set price = excluded.price, duration_minutes = excluded.duration_minutes, category = excluded.category;

insert into public.service_staff (service_id, staff_id)
select service.id, staff.id
from (values
  ('Thợ cắt (được quyền yêu cầu)', 'Thông'),
  ('Chủ quán cắt', 'Boss Linh'),
  ('Nhuộm màu thời trang (Free cắt)', 'Nam'), ('Nhuộm màu thời trang (Free cắt)', 'Thông'),
  ('Nhuộm màu cơ bản (Free cắt)', 'Nam'), ('Nhuộm màu cơ bản (Free cắt)', 'Thông'),
  ('Uốn tóc trending (Free cắt)', 'Nam'), ('Uốn tóc trending (Free cắt)', 'Thông'),
  ('Uốn tóc cơ bản (Free cắt)', 'Nam'), ('Uốn tóc cơ bản (Free cắt)', 'Thông'),
  ('Massage mặt, cổ, vai gáy', 'Hương'), ('Massage mặt, cổ, vai gáy', 'Thông'), ('Massage mặt, cổ, vai gáy', 'Nam'),
  ('Gội đầu (Shampoo)', 'Hương'), ('Gội đầu (Shampoo)', 'Thông'), ('Gội đầu (Shampoo)', 'Nam'),
  ('Massage mặt', 'Hương'), ('Massage mặt', 'Thông'), ('Massage mặt', 'Nam'),
  ('Đánh mắt', 'Hương'), ('Đánh mắt', 'Thông'),
  ('Cắt móng tay, chân', 'Hương'), ('Cắt móng tay, chân', 'Thông'),
  ('Nhổ tóc bạc', 'Hương'), ('Nhổ tóc bạc', 'Thông'),
  ('Xông mặt hút mụn', 'Hương'), ('Se lỗ ghèn', 'Hương'), ('Nặn mụn', 'Hương')
) as mapping(service_name, staff_name)
join public.services service on service.name = mapping.service_name
join public.staff_profiles staff on staff.display_name = mapping.staff_name
on conflict do nothing;

insert into public.landing_content (content_key, content_value, is_public)
values
  ('business', '{"name":"Chilling Barber Shop","phone":"0327969930"}'::jsonb, true),
  ('hero', '{"title":"Chất riêng","highlight":"Chuẩn đẹp"}'::jsonb, true)
on conflict (content_key) do nothing;

-- RLS: public visitors can only read active services/public landing data and call the booking RPC.
alter table public.profiles enable row level security;
alter table public.staff_profiles enable row level security;
alter table public.customers enable row level security;
alter table public.services enable row level security;
alter table public.service_staff enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_services enable row level security;
alter table public.inventory_items enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.expenses enable row level security;
alter table public.bank_accounts enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_lines enable row level security;
alter table public.payments enable row level security;
alter table public.tax_profiles enable row level security;
alter table public.landing_content enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles self or manager read" on public.profiles for select to authenticated using (id = auth.uid() or public.can_manage());
create policy "profiles manager write" on public.profiles for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "staff authenticated read" on public.staff_profiles for select to authenticated using (public.is_active_staff());
create policy "staff manager write" on public.staff_profiles for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "customer operations only" on public.customers for all to authenticated using (public.can_operate()) with check (public.can_operate());
create policy "public active services" on public.services for select to anon, authenticated using (is_active or public.can_manage());
create policy "services manager write" on public.services for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "service staff manager only" on public.service_staff for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "booking assigned or operator read" on public.bookings for select to authenticated using (public.can_access_booking(id));
create policy "booking operator update" on public.bookings for update to authenticated using (public.can_operate()) with check (public.can_operate());
create policy "booking service assigned or operator read" on public.booking_services for select to authenticated using (public.can_access_booking(booking_id));
create policy "inventory manager only" on public.inventory_items for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "inventory movement manager only" on public.inventory_movements for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "expenses operator only" on public.expenses for all to authenticated using (public.can_operate()) with check (public.can_operate());
create policy "bank account operator read" on public.bank_accounts for select to authenticated using (public.can_operate());
create policy "bank account manager write" on public.bank_accounts for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "invoices operator read" on public.invoices for select to authenticated using (public.can_operate());
create policy "invoice lines operator read" on public.invoice_lines for select to authenticated using (public.can_operate());
create policy "payments operator read" on public.payments for select to authenticated using (public.can_operate());
create policy "tax manager only" on public.tax_profiles for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "public landing content" on public.landing_content for select to anon, authenticated using (is_public or public.can_manage());
create policy "landing manager write" on public.landing_content for all to authenticated using (public.can_manage()) with check (public.can_manage());
create policy "audit owner only" on public.audit_logs for all to authenticated using (public.current_profile_role() = 'owner') with check (public.current_profile_role() = 'owner');

grant usage on schema public to anon, authenticated;
grant select on public.services, public.landing_content to anon;
grant select, insert, update, delete on public.profiles, public.staff_profiles, public.customers, public.services, public.service_staff, public.bookings, public.booking_services, public.inventory_items, public.inventory_movements, public.expenses, public.bank_accounts, public.invoices, public.invoice_lines, public.payments, public.tax_profiles, public.landing_content, public.audit_logs to authenticated;

create or replace function public.public_booking_catalog()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', service.id,
    'name', service.name,
    'category', service.category,
    'price', service.price,
    'durationMinutes', service.duration_minutes,
    'staffOptions', coalesce((select jsonb_agg(staff.display_name order by staff.display_name) from public.service_staff ss join public.staff_profiles staff on staff.id = ss.staff_id where ss.service_id = service.id and staff.is_active), '[]'::jsonb)
  ) order by service.category, service.name), '[]'::jsonb)
  from public.services service
  where service.is_active
$$;

create or replace function public.create_public_booking(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text := regexp_replace(coalesce(p_payload #>> '{customer,phone}', ''), '[^0-9]', '', 'g');
  v_name text := btrim(coalesce(p_payload #>> '{customer,fullName}', ''));
  v_date date;
  v_slot time;
  v_customer_id uuid;
  v_booking_id uuid;
  v_booking_code text;
  v_line jsonb;
  v_service record;
  v_staff record;
  v_quantity integer;
  v_subtotal numeric(14,0) := 0;
  v_duration integer := 0;
begin
  if v_phone !~ '^0(3|5|7|8|9)[0-9]{8}$' then raise exception 'Số điện thoại không hợp lệ'; end if;
  if char_length(v_name) < 2 then raise exception 'Họ và tên không hợp lệ'; end if;
  if jsonb_typeof(p_payload -> 'services') <> 'array' or jsonb_array_length(p_payload -> 'services') = 0 then raise exception 'Cần chọn ít nhất một dịch vụ'; end if;
  v_date := (p_payload #>> '{appointment,date}')::date;
  v_slot := (p_payload #>> '{appointment,timeSlot}')::time;
  if v_date < current_date then raise exception 'Không thể đặt lịch trong quá khứ'; end if;

  insert into public.customers (full_name, phone)
  values (v_name, v_phone)
  on conflict (phone) do update set full_name = excluded.full_name
  returning id into v_customer_id;

  for v_line in select value from jsonb_array_elements(p_payload -> 'services')
  loop
    select id, name, price, duration_minutes into v_service
    from public.services
    where name = (v_line ->> 'serviceName') and is_active
    limit 1;
    if not found then raise exception 'Dịch vụ không hợp lệ hoặc đã ngừng hoạt động'; end if;
    v_quantity := greatest(1, least(10, coalesce(nullif(v_line ->> 'quantity', '')::integer, 1)));
    v_subtotal := v_subtotal + (v_service.price * v_quantity);
    v_duration := v_duration + (v_service.duration_minutes * v_quantity);
  end loop;

  insert into public.bookings (
    customer_id, customer_phone, customer_name, total_guests, branch_name, appointment_date, time_slot,
    subtotal, discount, total_amount, total_duration_minutes, note, source
  ) values (
    v_customer_id, v_phone, v_name,
    greatest(1, least(10, coalesce(nullif(p_payload #>> '{customer,totalGuests}', '')::integer, 1))),
    coalesce(nullif(p_payload #>> '{branch,name}', ''), 'Chilling Barber Shop - Bàu Bàng'),
    v_date, v_slot, v_subtotal, 0, v_subtotal, v_duration,
    nullif(btrim(coalesce(p_payload ->> 'note', '')), ''), 'landing_page'
  ) returning id, booking_code into v_booking_id, v_booking_code;

  for v_line in select value from jsonb_array_elements(p_payload -> 'services')
  loop
    select id, name, price, duration_minutes into v_service
    from public.services where name = (v_line ->> 'serviceName') and is_active limit 1;
    select id, display_name into v_staff from public.staff_profiles
    where display_name = (v_line ->> 'staffName') and is_active limit 1;
    if not found then raise exception 'Nhân viên không hợp lệ hoặc đã ngừng hoạt động'; end if;
    if not exists (
      select 1 from public.service_staff
      where service_id = v_service.id and staff_id = v_staff.id
    ) then
      raise exception 'Nhân viên không thực hiện dịch vụ đã chọn';
    end if;
    if exists (
      select 1
      from public.bookings booking
      join public.booking_services booking_service on booking_service.booking_id = booking.id
      where booking.appointment_date = v_date
        and booking.time_slot = v_slot
        and booking.id <> v_booking_id
        and booking.status in ('waiting', 'serving')
        and booking_service.staff_id = v_staff.id
    ) then
      raise exception 'Nhân viên đã có lịch trong khung giờ này';
    end if;
    v_quantity := greatest(1, least(10, coalesce(nullif(v_line ->> 'quantity', '')::integer, 1)));
    insert into public.booking_services (booking_id, service_id, service_name, staff_id, staff_name, unit_price, duration_minutes, quantity)
    values (v_booking_id, v_service.id, v_service.name, v_staff.id, v_staff.display_name, v_service.price, v_service.duration_minutes, v_quantity);
  end loop;

  return jsonb_build_object('ok', true, 'bookingCode', v_booking_code, 'bookingId', v_booking_id);
end;
$$;

create or replace function public.checkout_invoice(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
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
  v_method public.payment_method := coalesce(nullif(p_payload ->> 'paymentMethod', '')::public.payment_method, 'cash');
  v_booking_id uuid := nullif(p_payload ->> 'bookingId', '')::uuid;
  v_bank_account_id uuid := nullif(p_payload ->> 'bankAccountId', '')::uuid;
begin
  if not public.can_operate() then raise exception 'Không có quyền thanh toán'; end if;
  if v_phone !~ '^0(3|5|7|8|9)[0-9]{8}$' then raise exception 'Số điện thoại không hợp lệ'; end if;
  if char_length(v_name) < 2 then raise exception 'Họ và tên không hợp lệ'; end if;
  if jsonb_typeof(p_payload -> 'lines') <> 'array' or jsonb_array_length(p_payload -> 'lines') = 0 then raise exception 'Hóa đơn chưa có dịch vụ'; end if;

  insert into public.customers (full_name, phone)
  values (v_name, v_phone)
  on conflict (phone) do update set full_name = excluded.full_name
  returning id into v_customer_id;

  if v_booking_id is not null and not exists (
    select 1 from public.bookings
    where id = v_booking_id
      and customer_id = v_customer_id
      and status in ('waiting', 'serving')
  ) then
    raise exception 'Đơn đặt lịch không hợp lệ hoặc đã được thanh toán';
  end if;

  if v_method = 'bank_transfer' and (
    v_bank_account_id is null or not exists (
      select 1 from public.bank_accounts where id = v_bank_account_id and is_active
    )
  ) then
    raise exception 'Vui lòng chọn tài khoản ngân hàng đang hoạt động';
  end if;
  if v_method = 'cash' then v_bank_account_id := null; end if;

  for v_line in select value from jsonb_array_elements(p_payload -> 'lines')
  loop
    select id, name, price, duration_minutes into v_service from public.services
    where id = (v_line ->> 'serviceId')::uuid and is_active limit 1;
    if not found then raise exception 'Dịch vụ không hợp lệ'; end if;
    select id, display_name into v_staff from public.staff_profiles
    where id = (v_line ->> 'staffId')::uuid and is_active limit 1;
    if not found then raise exception 'Nhân viên không hợp lệ'; end if;
    if not exists (
      select 1 from public.service_staff
      where service_id = v_service.id and staff_id = v_staff.id
    ) then
      raise exception 'Nhân viên không thực hiện dịch vụ đã chọn';
    end if;
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
    insert into public.invoice_lines (invoice_id, service_id, service_name, staff_id, staff_name, unit_price, quantity, duration_minutes)
    values (v_invoice_id, v_service.id, v_service.name, v_staff.id, v_staff.display_name, v_service.price, v_quantity, v_service.duration_minutes);
  end loop;
  insert into public.payments (invoice_id, method, amount, bank_account_id, payment_reference)
  values (v_invoice_id, v_method, v_total, v_bank_account_id, nullif(p_payload ->> 'paymentReference', ''));
  if v_booking_id is not null then update public.bookings set status = 'completed', completed_at = now() where id = v_booking_id; end if;
  return jsonb_build_object('ok', true, 'invoiceId', v_invoice_id, 'invoiceNo', v_invoice_no, 'totalAmount', v_total);
end;
$$;

create or replace function public.dashboard_metrics(p_date date default current_date)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare result jsonb;
begin
  if not public.can_operate() then raise exception 'Không có quyền xem dashboard'; end if;
  select jsonb_build_object(
    'date', p_date,
    'revenue', coalesce((select sum(total_amount) from public.invoices where status = 'paid' and paid_at::date = p_date), 0),
    'bookingCount', coalesce((select count(*) from public.bookings where appointment_date = p_date), 0),
    'invoiceCount', coalesce((select count(*) from public.invoices where status = 'paid' and paid_at::date = p_date), 0),
    'cash', jsonb_build_object('count', coalesce((select count(*) from public.invoices where status = 'paid' and paid_at::date = p_date and payment_method = 'cash'), 0), 'amount', coalesce((select sum(total_amount) from public.invoices where status = 'paid' and paid_at::date = p_date and payment_method = 'cash'), 0)),
    'bankTransfer', jsonb_build_object('count', coalesce((select count(*) from public.invoices where status = 'paid' and paid_at::date = p_date and payment_method = 'bank_transfer'), 0), 'amount', coalesce((select sum(total_amount) from public.invoices where status = 'paid' and paid_at::date = p_date and payment_method = 'bank_transfer'), 0)),
    'expenses', coalesce((select sum(amount) from public.expenses where expense_date = p_date), 0),
    'monthlyRevenue', coalesce((select jsonb_agg(jsonb_build_object('month', to_char(month_start, 'MM/YYYY'), 'revenue', revenue) order by month_start) from (select month_start, coalesce((select sum(i.total_amount) from public.invoices i where i.status = 'paid' and date_trunc('month', i.paid_at) = month_start), 0) as revenue from generate_series(date_trunc('month', p_date) - interval '5 months', date_trunc('month', p_date), interval '1 month') as month_start) m), '[]'::jsonb),
    'staffRank', coalesce((select jsonb_agg(jsonb_build_object('name', name, 'revenue', revenue) order by revenue desc) from (select coalesce(il.staff_name, 'Chưa gán') as name, sum(il.unit_price * il.quantity) as revenue from public.invoice_lines il join public.invoices i on i.id = il.invoice_id where i.status = 'paid' and i.paid_at::date = p_date group by il.staff_name order by revenue desc limit 6) r), '[]'::jsonb),
    'customerRank', coalesce((select jsonb_agg(jsonb_build_object('name', full_name, 'visits', visits) order by visits desc) from (select c.full_name, count(i.id) as visits from public.customers c join public.invoices i on i.customer_id = c.id where i.status = 'paid' group by c.id, c.full_name order by visits desc limit 6) r), '[]'::jsonb),
    'serviceRank', coalesce((select jsonb_agg(jsonb_build_object('name', service_name, 'sold', sold) order by sold desc) from (select il.service_name, sum(il.quantity) as sold from public.invoice_lines il join public.invoices i on i.id = il.invoice_id where i.status = 'paid' and i.paid_at::date = p_date group by il.service_name order by sold desc limit 6) r), '[]'::jsonb)
  ) into result;
  result := jsonb_set(result, '{profit}', to_jsonb((result ->> 'revenue')::numeric - (result ->> 'expenses')::numeric));
  return result;
end;
$$;

create or replace function public.purge_expired_operational_history()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.inventory_movements where created_at < now() - interval '90 days';
  delete from public.audit_logs where created_at < now() - interval '90 days';
end;
$$;

create or replace function public.record_inventory_movement(
  p_item_id uuid,
  p_movement_type public.inventory_movement_type,
  p_quantity numeric,
  p_unit_cost numeric default 0,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare v_item public.inventory_items;
  v_new_quantity numeric;
begin
  if not public.can_manage() then raise exception 'Không có quyền quản lý kho'; end if;
  if p_quantity <= 0 then raise exception 'Số lượng phải lớn hơn 0'; end if;
  select * into v_item from public.inventory_items where id = p_item_id for update;
  if not found then raise exception 'Không tìm thấy mặt hàng'; end if;
  v_new_quantity := case when p_movement_type = 'in' then v_item.quantity + p_quantity else v_item.quantity - p_quantity end;
  if v_new_quantity < 0 then raise exception 'Tồn kho không đủ để xuất'; end if;
  update public.inventory_items
  set quantity = v_new_quantity,
      unit_cost = case when p_movement_type = 'in' and p_unit_cost > 0 then p_unit_cost else unit_cost end
  where id = p_item_id;
  insert into public.inventory_movements (item_id, movement_type, quantity, unit_cost, note, created_by)
  values (p_item_id, p_movement_type, p_quantity, greatest(p_unit_cost, 0), p_note, auth.uid());
  if p_movement_type = 'in' then
    insert into public.expenses (expense_date, category, amount, note, created_by)
    values (current_date, 'Nhập kho', round(p_quantity * greatest(p_unit_cost, 0), 0), coalesce(p_note, v_item.name), auth.uid());
  end if;
  return jsonb_build_object('itemId', p_item_id, 'quantity', v_new_quantity);
end;
$$;

-- Enable pg_cron in Supabase Dashboard > Database > Extensions first. This migration
-- registers the daily purge only when that extension is available. Invoices, payments,
-- bookings and tax records are intentionally retained for accounting/legal traceability.
do $$
declare job_count integer;
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    execute 'select count(*) from cron.job where jobname = ''chilling-purge-operational-history''' into job_count;
    if job_count = 0 then
      execute 'select cron.schedule(''chilling-purge-operational-history'', ''15 2 * * *'', ''select public.purge_expired_operational_history()'')';
    end if;
  end if;
end $$;

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
grant execute on function public.create_public_booking(jsonb) to anon, authenticated;
grant execute on function public.public_booking_catalog() to anon, authenticated;
grant execute on function public.checkout_invoice(jsonb), public.dashboard_metrics(date), public.record_inventory_movement(uuid, public.inventory_movement_type, numeric, numeric, text) to authenticated;
grant execute on function public.current_profile_role(), public.is_active_staff(), public.can_operate(), public.can_manage(), public.can_access_booking(uuid) to authenticated;

-- Bootstrap the first owner after creating their Supabase Auth account:
-- update public.profiles set role = 'owner', is_active = true where email = 'owner@example.com';
