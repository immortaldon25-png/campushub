-- Run once in the Supabase SQL Editor. Adds sponsored/curated opportunities and privacy-light click reports.

create table public.opportunities (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 3 and 80),
  kind text not null check (kind in ('Scholarship','Free tools','Learning','Compete')),
  blurb text not null check (char_length(blurb) between 10 and 220),
  url text not null check (url ~ '^https://'),
  sponsored boolean not null default false,
  sponsor_name text check (char_length(sponsor_name) <= 40),
  active boolean not null default true,
  starts_on date,
  ends_on date,
  created_at timestamptz not null default now()
);
alter table public.opportunities enable row level security;
create policy "Anyone can read active opportunities"
  on public.opportunities for select to anon, authenticated
  using (active and (starts_on is null or starts_on <= current_date) and (ends_on is null or ends_on >= current_date));
-- No insert/update policies on purpose: you add and edit rows in the Supabase Table Editor.

-- One row per device, per day, per item and event type, so repeat taps are not counted twice.
create table public.opp_events (
  opp_id uuid not null references public.opportunities(id) on delete cascade,
  day date not null default current_date,
  device text not null check (char_length(device) between 8 and 64),
  kind text not null check (kind in ('view','click')),
  primary key (opp_id, day, device, kind)
);
alter table public.opp_events enable row level security; -- no policies: only the function below writes

create function public.opp_track(p_id uuid, p_kind text, p_device text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_kind not in ('view','click') or p_device is null or char_length(p_device) not between 8 and 64 then return; end if;
  insert into public.opp_events (opp_id, kind, device) values (p_id, p_kind, p_device) on conflict do nothing;
exception when foreign_key_violation then null;
end $$;
revoke all on function public.opp_track(uuid, text, text) from public;
grant execute on function public.opp_track(uuid, text, text) to anon, authenticated;

-- Your report for sponsors. Read it in the SQL Editor:  select * from public.sponsor_report;
create view public.sponsor_report with (security_invoker = true) as
select o.sponsor_name, o.name, o.id,
       count(*) filter (where e.kind = 'view')  as unique_views,
       count(*) filter (where e.kind = 'click') as unique_clicks
from public.opportunities o left join public.opp_events e on e.opp_id = o.id
group by o.id;
revoke all on public.sponsor_report from anon, authenticated;
