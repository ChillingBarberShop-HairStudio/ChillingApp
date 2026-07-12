-- Present public booking notifications consistently and escape user-supplied values.

create or replace function private.telegram_html_escape(p_value text)
returns text
language sql
immutable
strict
set search_path = pg_catalog
as $$
  select replace(replace(replace(replace(replace(p_value, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;');
$$;

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
    body := jsonb_build_object(
      'chat_id', v_chat_id,
      'text', left(p_text, 4096),
      'parse_mode', 'HTML',
      'disable_web_page_preview', true
    ),
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
  v_message text;
begin
  if new.source <> 'landing_page' then
    return new;
  end if;

  select string_agg(
    format('• %s ×%s%s',
      private.telegram_html_escape(service_name),
      quantity,
      case when staff_name is null then '' else format(' (%s)', private.telegram_html_escape(staff_name)) end
    ),
    E'\n' order by service_name, staff_name
  )
  into v_services
  from public.booking_services
  where booking_id = new.id;

  v_message := format(
    '🔔 <b>CÓ ĐƠN HÀNG MỚI ĐẶT TỪ LINK LANDING PAGE!</b>\n👤 <b>Khách hàng:</b> %s\n📞 <b>Số điện thoại:</b> %s\n📍 <b>Địa chỉ:</b> %s\n✂️ <b>Dịch vụ đặt:</b>\n%s\n💰 <b>Tạm tính:</b> %sđ\n⏰ <b>Thời gian:</b> %s',
    private.telegram_html_escape(new.customer_name),
    private.telegram_html_escape(new.customer_phone),
    private.telegram_html_escape(coalesce(new.branch_name, 'Chilling Barber Shop')),
    coalesce(v_services, '• Chưa có dịch vụ'),
    to_char(new.total_amount, 'FM999G999G999G999'),
    to_char(new.time_slot, 'HH24:MI') || ' ' || to_char(new.appointment_date, 'DD/MM/YYYY')
  );

  if new.note is not null and btrim(new.note) <> '' then
    v_message := v_message || E'\n📝 <b>Ghi chú:</b> ' || private.telegram_html_escape(new.note);
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
    raise exception 'Không có quyền quản lý Telegram';
  end if;
  if not private.enqueue_telegram_message('✅ <b>CHILLING BARBER SHOP</b>\nKết nối Telegram đã sẵn sàng nhận thông báo booking.') then
    raise exception 'Chưa thể gửi thử. Kiểm tra Bot token, Chat ID và trạng thái bật thông báo.';
  end if;
  return jsonb_build_object('queued', true);
end;
$$;

revoke all on function private.telegram_html_escape(text) from public, anon, authenticated;
revoke all on function private.enqueue_telegram_message(text) from public, anon, authenticated;
revoke all on function private.notify_telegram_booking() from public, anon, authenticated;
revoke all on function private.test_telegram_notification() from public, anon, authenticated;
