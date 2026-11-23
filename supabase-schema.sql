-- AUREX-ESP Supabase schema. Run the entire script in Supabase SQL Editor.
-- Then replace the example email below with the exact email you will use as site admin.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default 'Player' check (char_length(username) between 1 and 24),
  game text not null default 'Blood Strike',
  avatar_url text,
  bio text not null default '' check (char_length(bio) <= 240),
  social_link text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_emails (
  email text primary key check (email = lower(email))
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 80),
  game text not null,
  event_date timestamptz not null,
  status text not null default 'Upcoming',
  description text not null default '',
  event_link text,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 100),
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

create table if not exists public.site_settings (
  key text primary key check (key in ('discord','youtube','tiktok','instagram')),
  value text not null default ''
);

-- A safe helper: checks the signed-in user's verified JWT email against the private allowlist.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_emails a
    where a.email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- Create a profile automatically when someone registers.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(nullif(new.raw_user_meta_data ->> 'username',''), split_part(new.email,'@',1)))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.admin_emails enable row level security;
alter table public.events enable row level security;
alter table public.announcements enable row level security;
alter table public.site_settings enable row level security;

-- Profiles are publicly readable; each member can only edit their own profile.
drop policy if exists "Profiles are public" on public.profiles;
create policy "Profiles are public" on public.profiles for select using (true);
drop policy if exists "Members create own profile" on public.profiles;
create policy "Members create own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "Members update own profile" on public.profiles;
create policy "Members update own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "Admins update any profile" on public.profiles;
create policy "Admins update any profile" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- The allowlist has RLS enabled and intentionally has no client-facing policies.
-- Manage admin emails only in the Supabase SQL Editor.

-- Events and announcements are public to read, admin-only to change.
drop policy if exists "Events are public" on public.events;
create policy "Events are public" on public.events for select using (true);
drop policy if exists "Admins manage events" on public.events;
create policy "Admins manage events" on public.events for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Announcements are public" on public.announcements;
create policy "Announcements are public" on public.announcements for select using (true);
drop policy if exists "Admins manage announcements" on public.announcements;
create policy "Admins manage announcements" on public.announcements for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Settings are public" on public.site_settings;
create policy "Settings are public" on public.site_settings for select using (true);
drop policy if exists "Admins manage settings" on public.site_settings;
create policy "Admins manage settings" on public.site_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Add your own admin email here after changing it. Add more emails with another INSERT.
insert into public.admin_emails (email) values ('YOUR_ADMIN_EMAIL@example.com')
on conflict (email) do nothing;
