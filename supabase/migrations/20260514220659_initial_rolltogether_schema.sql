-- Baseline schema applied to Supabase project mczhglpdsoiipdqsbjsl.
-- The live project includes these entities with RLS enabled and policies for owner/participant access:
-- profiles, listings, listing_roles, swipes, matches, message_threads, messages, reports, blocks, notifications, push_tokens.
-- This file records the intended baseline for source control; use `supabase db pull` before replaying migrations into another project.

create schema if not exists private;
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'New Adventurer',
  handle text unique,
  avatar_url text,
  bio text not null default '',
  location text not null default '',
  latitude double precision,
  longitude double precision,
  experience text not null default 'new',
  preferred_mode text not null default 'any',
  favorite_role text not null default 'support',
  preferences jsonb not null default '{}'::jsonb,
  safety_note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  listing_type text not null check (listing_type in ('group', 'party')),
  name text not null,
  mode text not null default 'any',
  location text not null default '',
  latitude double precision,
  longitude double precision,
  open_slots integer not null default 0 check (open_slots >= 0),
  party_size integer not null default 1 check (party_size > 0),
  campaign_style text not null default 'any',
  table_experience text not null default 'any',
  desired_experience text not null default 'any',
  looking_for_party_size text not null default 'any',
  character_vibe text not null default '',
  schedule text not null default '',
  about text not null default '',
  contact text not null default '',
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.listing_roles (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  role text not null,
  role_kind text not null check (role_kind in ('desired', 'covered')),
  created_at timestamptz not null default now(),
  unique (listing_id, role, role_kind)
);

create table if not exists public.swipes (
  id uuid primary key default gen_random_uuid(),
  swiper_user_id uuid not null references public.profiles(id) on delete cascade,
  owner_listing_id uuid not null references public.listings(id) on delete cascade,
  target_listing_id uuid not null references public.listings(id) on delete cascade,
  choice text not null check (choice in ('pass', 'connect')),
  context text not null check (context in ('group_browsing', 'party_browsing')),
  created_at timestamptz not null default now(),
  unique (swiper_user_id, owner_listing_id, target_listing_id, context)
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  group_listing_id uuid not null references public.listings(id) on delete cascade,
  party_listing_id uuid not null references public.listings(id) on delete cascade,
  group_owner_user_id uuid not null references public.profiles(id) on delete cascade,
  party_owner_user_id uuid not null references public.profiles(id) on delete cascade,
  score integer not null default 0,
  initiated_by uuid references public.profiles(id) on delete set null,
  status text not null default 'active' check (status in ('active', 'archived', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (group_listing_id, party_listing_id)
);

create table if not exists public.message_threads (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null unique references public.matches(id) on delete cascade,
  last_message_preview text not null default '',
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.message_threads(id) on delete cascade,
  sender_user_id uuid references public.profiles(id) on delete set null,
  body text not null check (char_length(body) <= 4000),
  moderation_status text not null default 'pending' check (moderation_status in ('pending', 'approved', 'flagged', 'removed')),
  created_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references public.profiles(id) on delete cascade,
  subject text not null check (subject in ('profile', 'listing', 'message')),
  target_profile_id uuid references public.profiles(id) on delete set null,
  target_listing_id uuid references public.listings(id) on delete set null,
  target_message_id uuid references public.messages(id) on delete set null,
  reason text not null,
  details text not null default '',
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz not null default now()
);

create table if not exists public.blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_user_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid references public.profiles(id) on delete cascade,
  blocked_listing_id uuid references public.listings(id) on delete cascade,
  reason text not null default '',
  created_at timestamptz not null default now(),
  check (blocked_user_id is not null or blocked_listing_id is not null)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  delivered_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null default 'ios',
  token text not null,
  environment text not null default 'development',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform, token)
);

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.listing_roles enable row level security;
alter table public.swipes enable row level security;
alter table public.matches enable row level security;
alter table public.message_threads enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;
alter table public.blocks enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;
