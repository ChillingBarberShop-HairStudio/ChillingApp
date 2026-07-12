-- Editable records for legacy landing images and encrypted Telegram configuration.
-- Delivery of customer booking data is intentionally activated in a later, approved migration.

alter table public.landing_media
  add column if not exists public_url text;

insert into public.landing_media (section_key, storage_path, public_url, alt_text, sort_order, is_active)
values
  ('hero', 'legacy/hero/anh1.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh1.PNG', 'Anh trang dau Chilling Barber Shop', 1, true),
  ('studio', 'legacy/studio/anh2.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2.PNG', 'Anh khong gian Chilling Barber Shop 1', 1, true),
  ('studio', 'legacy/studio/anh2-1.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2-1.PNG', 'Anh khong gian Chilling Barber Shop 2', 2, true),
  ('studio', 'legacy/studio/anh2-2.jpg', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2-2.jpg', 'Anh khong gian Chilling Barber Shop 3', 3, true),
  ('studio', 'legacy/studio/anh2-3.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2-3.PNG', 'Anh khong gian Chilling Barber Shop 4', 4, true),
  ('studio', 'legacy/studio/anh2-4.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2-4.PNG', 'Anh khong gian Chilling Barber Shop 5', 5, true),
  ('studio', 'legacy/studio/anh2-5.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2-5.PNG', 'Anh khong gian Chilling Barber Shop 6', 6, true),
  ('studio', 'legacy/studio/anh2-7.jpg', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2-7.jpg', 'Anh khong gian Chilling Barber Shop 7', 7, true),
  ('studio', 'legacy/studio/anh2-8.jpg', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2-8.jpg', 'Anh khong gian Chilling Barber Shop 8', 8, true),
  ('studio', 'legacy/studio/anh2-9.jpg', 'https://chillingbarbershop-hairstudio.github.io/Chilling/landing/anh2-9.jpg', 'Anh khong gian Chilling Barber Shop 9', 9, true),
  ('services', 'legacy/services/ivy-league.jpg', 'https://chillingbarbershop-hairstudio.github.io/Chilling/Form/IVY%20LEAGUE.jpg', 'Mau toc Ivy League', 1, true),
  ('services', 'legacy/services/side-part.jpg', 'https://chillingbarbershop-hairstudio.github.io/Chilling/Form/SIDE%20PART.jpg', 'Mau toc Side Part', 2, true),
  ('services', 'legacy/services/under-cut.jpg', 'https://chillingbarbershop-hairstudio.github.io/Chilling/Form/UNDER%20CUT.jpg', 'Mau toc Under Cut', 3, true),
  ('gallery', 'legacy/gallery/sample-1.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%201.PNG', 'Tac pham hoan thien 1', 1, true),
  ('gallery', 'legacy/gallery/sample-2.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%202.PNG', 'Tac pham hoan thien 2', 2, true),
  ('gallery', 'legacy/gallery/sample-3.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%203.PNG', 'Tac pham hoan thien 3', 3, true),
  ('gallery', 'legacy/gallery/sample-4.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%204.PNG', 'Tac pham hoan thien 4', 4, true),
  ('gallery', 'legacy/gallery/sample-5.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%205.PNG', 'Tac pham hoan thien 5', 5, true),
  ('gallery', 'legacy/gallery/sample-6.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%206.PNG', 'Tac pham hoan thien 6', 6, true),
  ('gallery', 'legacy/gallery/sample-7.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%207.PNG', 'Tac pham hoan thien 7', 7, true),
  ('gallery', 'legacy/gallery/sample-8.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%208.PNG', 'Tac pham hoan thien 8', 8, true),
  ('gallery', 'legacy/gallery/sample-9.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%209.PNG', 'Tac pham hoan thien 9', 9, true),
  ('gallery', 'legacy/gallery/sample-10.PNG', 'https://chillingbarbershop-hairstudio.github.io/Chilling/sample/sample%2010.PNG', 'Tac pham hoan thien 10', 10, true)
on conflict (storage_path) do update
  set public_url = excluded.public_url,
      alt_text = excluded.alt_text,
      sort_order = excluded.sort_order,
      is_active = true;

create table if not exists public.telegram_settings (
  setting_key text primary key default 'primary' check (setting_key = 'primary'),
  bot_token_secret_id uuid,
  chat_id text,
  is_enabled boolean not null default false,
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.telegram_settings enable row level security;
drop policy if exists "telegram settings manager only" on public.telegram_settings;
create policy "telegram settings manager only" on public.telegram_settings
  for all to authenticated
  using (public.can_manage())
  with check (public.can_manage());
revoke all on table public.telegram_settings from anon, authenticated;

create or replace function private.telegram_config_status()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_secret_id uuid;
  v_chat_id text;
  v_enabled boolean;
  v_updated_at timestamptz;
begin
  if not private.can_manage() then
    raise exception 'Khong co quyen quan ly Telegram';
  end if;

  select bot_token_secret_id, chat_id, is_enabled, updated_at
  into v_secret_id, v_chat_id, v_enabled, v_updated_at
  from public.telegram_settings
  where setting_key = 'primary';

  return jsonb_build_object(
    'configured', v_secret_id is not null,
    'chatId', v_chat_id,
    'enabled', coalesce(v_enabled, false),
    'updatedAt', v_updated_at
  );
end;
$$;

create or replace function private.configure_telegram(
  p_bot_token text,
  p_chat_id text,
  p_enabled boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_secret_id uuid;
  v_token text := btrim(coalesce(p_bot_token, ''));
  v_chat_id text := btrim(coalesce(p_chat_id, ''));
begin
  if not private.can_manage() then
    raise exception 'Khong co quyen quan ly Telegram';
  end if;

  select bot_token_secret_id
  into v_secret_id
  from public.telegram_settings
  where setting_key = 'primary';

  if v_token <> '' then
    if v_token !~ '^[0-9]{6,12}:[A-Za-z0-9_-]{20,}$' then
      raise exception 'Bot token khong dung dinh dang Telegram';
    end if;
    if v_secret_id is null then
      select vault.create_secret(v_token, 'chilling_telegram_bot_token', 'Telegram bot token for Chilling booking notifications') into v_secret_id;
    else
      perform vault.update_secret(v_secret_id, v_token, 'chilling_telegram_bot_token', 'Telegram bot token for Chilling booking notifications');
    end if;
  end if;

  if v_chat_id <> '' and v_chat_id !~ '^-?[0-9]+$' then
    raise exception 'Chat ID chi duoc chua chu so, co the bat dau bang dau tru cho group';
  end if;
  if p_enabled and (v_secret_id is null or v_chat_id = '') then
    raise exception 'Can bot token va Chat ID truoc khi bat thong bao';
  end if;

  insert into public.telegram_settings (setting_key, bot_token_secret_id, chat_id, is_enabled, updated_by, updated_at)
  values ('primary', v_secret_id, nullif(v_chat_id, ''), p_enabled, auth.uid(), now())
  on conflict (setting_key) do update
    set bot_token_secret_id = coalesce(excluded.bot_token_secret_id, public.telegram_settings.bot_token_secret_id),
        chat_id = excluded.chat_id,
        is_enabled = excluded.is_enabled,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;

  return private.telegram_config_status();
end;
$$;

create or replace function public.telegram_config_status()
returns jsonb
language sql
security invoker
set search_path = pg_catalog, private
as $$ select private.telegram_config_status() $$;

create or replace function public.configure_telegram(
  p_bot_token text,
  p_chat_id text,
  p_enabled boolean default false
)
returns jsonb
language sql
security invoker
set search_path = pg_catalog, private
as $$ select private.configure_telegram(p_bot_token, p_chat_id, p_enabled) $$;

revoke all on function private.telegram_config_status() from public, anon, authenticated;
revoke all on function private.configure_telegram(text, text, boolean) from public, anon, authenticated;
revoke all on function public.telegram_config_status() from public, anon;
revoke all on function public.configure_telegram(text, text, boolean) from public, anon;

grant execute on function private.telegram_config_status(), private.configure_telegram(text, text, boolean) to authenticated;
grant execute on function public.telegram_config_status(), public.configure_telegram(text, text, boolean) to authenticated;
