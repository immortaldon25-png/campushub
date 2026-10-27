-- CampusHub: identity checks (KYC), chat file delivery, and settings for card-scheme compliance.
-- Run once in the SQL Editor, after marketplace.sql and paystack_payouts.sql. Clear the box first.

-- 1. Settings: sellers must be verified before an order can be created; buyers above the threshold too.
alter table public.app_settings
  add column if not exists require_seller_kyc boolean not null default true,
  add column if not exists buyer_kyc_threshold_minor bigint not null default 5000000;  -- 5,000,000 kobo = NGN 50,000

-- 2. Identity status. The BVN itself is never stored. Paystack checks it; we keep only the result.
create table public.kyc_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  status text not null default 'none' check (status in ('none','pending','verified','failed')),
  full_name text,
  customer_code text,
  reason text,
  attempts int not null default 0,
  last_attempt_at timestamptz,
  verified_at timestamptz,
  updated_at timestamptz not null default now()
);
alter table public.kyc_profiles enable row level security;
create policy "Users read their own identity status" on public.kyc_profiles
  for select to authenticated using (user_id = auth.uid());
-- No write policies: only the kyc-verify function and the Paystack webhook (service role) change this table.

create or replace function public.is_kyc_verified(p_user uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.kyc_profiles where user_id = p_user and status = 'verified');
$$;
revoke all on function public.is_kyc_verified(uuid) from public, anon, authenticated;

-- 3. create_order again, now with the identity rules.
create or replace function public.create_order(p_conv uuid, p_amount_minor bigint) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_me uuid := auth.uid(); c public.conversations; s public.app_settings; v_id uuid; v_fee bigint;
begin
  if v_me is null then raise exception 'Sign in first.'; end if;
  select * into c from public.conversations where id = p_conv and buyer_id = v_me;
  if not found then raise exception 'Only the buyer can create an order.'; end if;
  if p_amount_minor is null or p_amount_minor <= 0 or p_amount_minor > 100000000000 then
    raise exception 'Enter a valid amount.';
  end if;
  select * into s from public.app_settings limit 1;
  if s.require_seller_kyc and not public.is_kyc_verified(c.seller_id) then
    raise exception 'The seller has not completed identity checks yet. Ask them to verify their identity in CampusHub first.';
  end if;
  if p_amount_minor >= s.buyer_kyc_threshold_minor and not public.is_kyc_verified(v_me) then
    raise exception 'Orders of this size need identity verification first. Open the Earn tab and tap Verify my identity.';
  end if;
  v_fee := (p_amount_minor * s.platform_fee_bps) / 10000;
  insert into public.orders (conversation_id, buyer_id, seller_id, title, amount_minor, currency, fee_minor)
    values (c.id, c.buyer_id, c.seller_id, c.subject, p_amount_minor, s.currency, v_fee) returning id into v_id;
  insert into public.messages (conversation_id, kind, body) values (c.id, 'system',
    'Order created for ' || s.currency || ' ' || to_char(p_amount_minor / 100.0, 'FM999,999,999,990.00') ||
    '. Buyer: pay to hold the money safely. Seller: start only after payment is held.');
  update public.conversations set last_message_at = now() where id = c.id;
  return v_id;
exception when unique_violation then
  raise exception 'There is already an open order in this chat.';
end $$;

-- 4. File delivery inside the chat (private storage, members only).
alter table public.messages
  add column if not exists file_path text,
  add column if not exists file_name text,
  add column if not exists file_size int;

do $$ declare r record; begin
  for r in select conname from pg_constraint
           where conrelid = 'public.messages'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%kind%'
  loop
    execute format('alter table public.messages drop constraint %I', r.conname);
  end loop;
end $$;
alter table public.messages add constraint messages_kind_check check (kind in ('user','system','file'));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-files', 'chat-files', false, 10485760, array[
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/plain', 'image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do nothing;

create policy "Chat members read files" on storage.objects for select to authenticated
  using (bucket_id = 'chat-files' and exists (
    select 1 from public.conversations c
    where c.id::text = (storage.foldername(name))[1] and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())));
create policy "Chat members upload files" on storage.objects for insert to authenticated
  with check (bucket_id = 'chat-files' and exists (
    select 1 from public.conversations c
    where c.id::text = (storage.foldername(name))[1] and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())));

create or replace function public.send_file(p_conv uuid, p_path text, p_name text, p_size int) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_me uuid := auth.uid(); c public.conversations; v_name text := btrim(coalesce(p_name, '')); v_recent int;
begin
  if v_me is null then return jsonb_build_object('ok', false, 'error', 'signin'); end if;
  select * into c from public.conversations where id = p_conv and (buyer_id = v_me or seller_id = v_me);
  if not found then return jsonb_build_object('ok', false, 'error', 'notfound'); end if;
  if left(coalesce(p_path, ''), 37) <> p_conv::text || '/' then return jsonb_build_object('ok', false, 'error', 'path'); end if;
  if char_length(v_name) < 1 or char_length(v_name) > 120 or p_size is null or p_size <= 0 or p_size > 10485760 then
    return jsonb_build_object('ok', false, 'error', 'file');
  end if;
  select count(*) into v_recent from public.messages where sender_id = v_me and created_at > now() - interval '1 minute';
  if v_recent >= 20 then return jsonb_build_object('ok', false, 'error', 'slow'); end if;
  if public.contact_check(v_name) is not null then
    return jsonb_build_object('ok', false, 'error', 'blocked', 'rule', public.contact_check(v_name));
  end if;
  if v_me = c.seller_id and not exists (
       select 1 from public.orders o where o.conversation_id = c.id and o.status in ('funded','delivered','completed','disputed')) then
    return jsonb_build_object('ok', false, 'error', 'unpaid');
  end if;
  insert into public.messages (conversation_id, sender_id, kind, body, file_path, file_name, file_size)
    values (c.id, v_me, 'file', v_name, p_path, v_name, p_size);
  update public.conversations set last_message_at = now() where id = c.id;
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.send_file(uuid, text, text, int) from public, anon;
grant execute on function public.send_file(uuid, text, text, int) to authenticated;
