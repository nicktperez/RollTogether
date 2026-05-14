# Supabase Backend Plan

This app should stay local-first for prototyping, then move the social layer to Supabase when a project is available.

## Recommended Services

- Supabase Auth for email, Apple Sign-In, and Google Sign-In.
- Postgres for profiles, listings, swipes, matches, chat threads, messages, reports, and blocks.
- Supabase Realtime private channels for live chat updates.
- Supabase Storage for profile photos, party banners, and listing images.
- Edge Functions for push notifications, moderation hooks, and match-created side effects.
- Apple Push Notification service for match/message alerts.

## Also Useful

- Apple Push Notifications: new match and message alerts.
- MapKit or location autocomplete: in-person group discovery.
- OpenAI moderation or similar: message/profile safety checks.
- Sentry: crash/error tracking.
- RevenueCat: subscriptions later, if premium filters or boosts are added.
- Cloudflare Turnstile or similar abuse protection: useful if spam becomes an issue.

Supabase docs checked for this plan:

- Realtime private channels and Swift client usage: https://supabase.com/docs/guides/realtime/getting_started
- Realtime authorization/RLS for private channels: https://supabase.com/docs/guides/realtime/authorization
- Product security index: https://supabase.com/docs/guides/security/product-security

## Tables

```sql
create type public.listing_kind as enum ('group', 'party');
create type public.session_mode as enum ('online', 'in_person', 'hybrid');
create type public.experience_level as enum ('new', 'intermediate', 'veteran');
create type public.swipe_choice as enum ('pass', 'connect');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  handle text unique,
  location_text text,
  bio text,
  preferred_mode public.session_mode,
  favorite_role text,
  safety_note text,
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Supabase Auth's auth.users table is the source of truth for account identity.
-- The public.profiles row stores public/social profile fields for each auth user.

create table public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  kind public.listing_kind not null,
  title text not null,
  session_mode public.session_mode not null,
  location_text text,
  schedule_text text,
  party_size int,
  open_slots int,
  campaign_style text,
  experience public.experience_level,
  looking_for text,
  vibe text,
  about text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.listing_roles (
  listing_id uuid not null references public.listings(id) on delete cascade,
  role text not null,
  role_kind text not null check (role_kind in ('covered', 'wanted')),
  primary key (listing_id, role, role_kind)
);

create table public.swipes (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references public.profiles(id) on delete cascade,
  source_listing_id uuid not null references public.listings(id) on delete cascade,
  target_listing_id uuid not null references public.listings(id) on delete cascade,
  choice public.swipe_choice not null,
  created_at timestamptz not null default now(),
  unique (actor_id, source_listing_id, target_listing_id)
);

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  group_listing_id uuid not null references public.listings(id) on delete cascade,
  party_listing_id uuid not null references public.listings(id) on delete cascade,
  score int not null check (score between 0 and 100),
  created_at timestamptz not null default now(),
  unique (group_listing_id, party_listing_id)
);

create table public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null unique references public.matches(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now(),
  edited_at timestamptz
);

create table public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_profile_id uuid references public.profiles(id) on delete set null,
  message_id uuid references public.messages(id) on delete set null,
  reason text not null,
  details text,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('new_match', 'new_message', 'listing_interest', 'system')),
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  sent_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
```

## RLS Policy Shape

Enable RLS on every public table.

- `profiles`: authenticated users can read public profile fields; users can update only their own profile.
- `listings`: anyone authenticated can read active listings; owners can insert/update/delete their own listings.
- `swipes`: users can insert/read only their own swipes.
- `matches`: users can read matches where they own either listing.
- `chat_threads`: users can read threads attached to their matches.
- `messages`: users can read/send messages only in threads attached to their matches.
- `blocks`: users can manage only their own block rows.
- `reports`: users can create reports; only admins/moderators read all reports.
- `notifications`: users can read/update only their own notifications; Edge Functions insert/send notifications.

For Realtime, use private channels named `thread:<thread_id>:messages`, and authorize access against thread membership. Avoid broad policies on `realtime.messages` in production.

## Client Integration Steps

1. Add `supabase-swift` to the Xcode project.
2. Store the Supabase URL and publishable key in a local config file excluded from git.
3. Add Auth screens and replace the local `currentUser` with the authenticated profile.
4. Replace `QuestBondStore` persistence calls with repository methods backed by Supabase.
5. Subscribe to private Realtime channels only while a chat thread is open.
6. Use Edge Functions for push notifications and automated match/thread creation.
