-- Run once in the Supabase SQL Editor (for projects that already ran schema.sql).

-- 1. Tasks (gigs) that small businesses and students can post.
create table public.gigs (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 5 and 80),
  details text not null check (char_length(details) between 10 and 400),
  budget text check (char_length(budget) <= 30),
  whatsapp text not null check (whatsapp ~ '^[0-9]{7,15}$'),
  status text not null default 'open' check (status in ('open','closed')),
  created_at timestamptz not null default now()
);
alter table public.gigs enable row level security;
create policy "Anyone can read open gigs" on public.gigs for select to anon, authenticated using (status = 'open');
create policy "Users add their own gigs" on public.gigs for insert to authenticated with check (owner = auth.uid());
create policy "Users edit their own gigs" on public.gigs for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());
create policy "Users delete their own gigs" on public.gigs for delete to authenticated using (owner = auth.uid());

-- 2. Daily usage counter for Jeevanom-IQ. Only the server function can touch it.
create table public.iq_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null default current_date,
  n int not null default 0,
  primary key (user_id, day)
);
alter table public.iq_usage enable row level security; -- no policies on purpose

create function public.iq_use(p_uid uuid) returns int
language plpgsql security definer set search_path = public as $$
declare c int;
begin
  insert into public.iq_usage (user_id, day, n) values (p_uid, current_date, 1)
  on conflict (user_id, day) do update set n = public.iq_usage.n + 1
  returning n into c;
  return c;
end $$;
revoke all on function public.iq_use(uuid) from public, anon, authenticated;
grant execute on function public.iq_use(uuid) to service_role;
