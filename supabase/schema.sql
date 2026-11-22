-- Wunderwelt Wandersteine – Datenbankschema V1
-- In Supabase > SQL Editor ausführen.
-- Sichere öffentliche Schreibzugriffe werden später über Edge Functions implementiert.

create extension if not exists pgcrypto;

create table if not exists public.stones (
  id text primary key check (id ~ '^[0-9]{6}$'),
  title text check (char_length(title) <= 100),
  description text check (char_length(description) <= 2000),
  photo_path text,
  created_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active','hidden')),
  constraint stones_photo_required check (photo_path is not null and length(photo_path)>0)
);

create table if not exists public.stone_reservations (
  id text primary key check (id ~ '^[0-9]{6}$'),
  renewal_code_hash text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 days'),
  max_expires_at timestamptz not null default (now() + interval '1 year'),
  optional_photo_path text,
  constraint reservation_expiry_valid check (expires_at <= max_expires_at)
);

create table if not exists public.stone_finds (
  id uuid primary key default gen_random_uuid(),
  stone_id text not null references public.stones(id) on delete cascade,
  found_on date not null default current_date,
  location_label text check (char_length(location_label) <= 180),
  latitude numeric(9,6) check (latitude between -90 and 90),
  longitude numeric(9,6) check (longitude between -180 and 180),
  photo_path text not null check (length(photo_path)>0),
  story text check (char_length(story) <= 2000),
  created_at timestamptz not null default now(),
  status text not null default 'pending' check (status in ('pending','approved','hidden'))
);
create index if not exists stone_finds_stone_id_idx on public.stone_finds(stone_id);
create index if not exists stone_finds_created_at_idx on public.stone_finds(created_at desc);

alter table public.stones enable row level security;
alter table public.stone_reservations enable row level security;
alter table public.stone_finds enable row level security;

-- Nur aktive Steine und freigegebene Fundmeldungen sind öffentlich lesbar.
drop policy if exists "Read active stones" on public.stones;
create policy "Read active stones" on public.stones for select to anon, authenticated
using (status = 'active');

drop policy if exists "Read approved finds" on public.stone_finds;
create policy "Read approved finds" on public.stone_finds for select to anon, authenticated
using (status = 'approved');

-- Keine öffentlichen Schreibrechte oder Leserechte für Reservierungscodes.
-- Erstellen, Reservieren, Verlängern und Fund melden erfolgen später über
-- geprüfte serverseitige Endpunkte (Supabase Edge Functions).
