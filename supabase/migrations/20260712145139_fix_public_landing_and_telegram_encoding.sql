-- Keep public landing reads independent from manager-only functions and build Telegram Unicode from UTF-8 bytes.

drop policy if exists "public landing content" on public.landing_content;
create policy "anon landing content read"
on public.landing_content
for select
to anon
using (is_public);

create policy "authenticated landing content read"
on public.landing_content
for select
to authenticated
using (is_public or private.can_manage());

drop policy if exists "public landing media read" on public.landing_media;
create policy "anon landing media read"
on public.landing_media
for select
to anon
using (is_active);

create policy "authenticated landing media read"
on public.landing_media
for select
to authenticated
using (is_active or private.can_manage());

create or replace function private.utf8_text(p_hex text)
returns text
language sql
immutable
strict
set search_path = pg_catalog
as $$
  select convert_from(decode(p_hex, 'hex'), 'UTF8');
$$;

create or replace function private.notify_telegram_booking()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_services text;
  v_message text;
begin
  if new.source <> 'landing_page' then
    return new;
  end if;

  select string_agg(
    private.utf8_text('E280A220')
      || private.telegram_html_escape(service_name)
      || private.utf8_text('20C397')
      || quantity::text
      || case
          when staff_name is null then ''
          else ' (' || private.telegram_html_escape(staff_name) || ')'
        end,
    chr(10) order by service_name, staff_name
  )
  into v_services
  from public.booking_services
  where booking_id = new.id;

  v_message := private.utf8_text('F09F9494203C623E43C39320C490C6A04E2048C3804E47204DE1BB9A4920C490E1BAB6542054E1BBAA204C494E4B204C414E44494E472050414745213C2F623E')
    || chr(10) || private.utf8_text('F09F91A4203C623E4B68C3A163682068C3A06E673A3C2F623E20') || private.telegram_html_escape(new.customer_name)
    || chr(10) || private.utf8_text('F09F939E203C623E53E1BB9120C49169E1BB876E2074686FE1BAA1693A3C2F623E20') || private.telegram_html_escape(new.customer_phone)
    || chr(10) || private.utf8_text('F09F938D203C623EC490E1BB8B61206368E1BB893A3C2F623E20') || private.telegram_html_escape(coalesce(new.branch_name, 'Chilling Barber Shop'))
    || chr(10) || private.utf8_text('E29C82EFB88F203C623E44E1BB8B63682076E1BBA520C491E1BAB7743A3C2F623E')
    || chr(10) || coalesce(v_services, private.utf8_text('E280A2204368C6B0612063C3B32064E1BB8B63682076E1BBA5'))
    || chr(10) || private.utf8_text('F09F92B0203C623E54E1BAA16D2074C3AD6E683A3C2F623E20') || to_char(new.total_amount, 'FM999G999G999G999') || private.utf8_text('C491')
    || chr(10) || private.utf8_text('E28FB0203C623E5468E1BB9D69206769616E3A3C2F623E20') || to_char(new.time_slot, 'HH24:MI') || ' ' || to_char(new.appointment_date, 'DD/MM/YYYY');

  if new.note is not null and btrim(new.note) <> '' then
    v_message := v_message || chr(10) || private.utf8_text('F09F939D203C623E476869206368C3BA3A3C2F623E20') || private.telegram_html_escape(new.note);
  end if;

  perform private.enqueue_telegram_message(v_message);
  return new;
end;
$$;

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
  if not private.enqueue_telegram_message(
    private.utf8_text('E29C85203C623E4348494C4C494E47204241524245522053484F503C2F623E')
      || chr(10)
      || private.utf8_text('4BE1BABF74206EE1BB91692054656C656772616D20C491C3A32073E1BAB56E2073C3A06E67206EE1BAAD6E207468C3B46E672062C3A16F20626F6F6B696E672E')
  ) then
    raise exception 'Chua the gui thu. Kiem tra Bot token, Chat ID va trang thai bat thong bao.';
  end if;
  return jsonb_build_object('queued', true);
end;
$$;

grant execute on function private.test_telegram_notification() to authenticated;
grant execute on function public.test_telegram_notification() to authenticated;
revoke all on function private.utf8_text(text) from public, anon, authenticated;
