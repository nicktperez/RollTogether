-- Production backend hardening for server-authoritative matches, moderation, realtime broadcasts, and abuse controls.

alter table public.listings
  add column if not exists moderation_status text not null default 'approved' check (moderation_status in ('pending', 'approved', 'flagged', 'removed')),
  add column if not exists moderation_reason text not null default '';

create table if not exists public.moderation_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  subject text not null check (subject in ('profile', 'listing', 'message')),
  target_listing_id uuid references public.listings(id) on delete cascade,
  target_message_id uuid references public.messages(id) on delete cascade,
  status text not null check (status in ('approved', 'flagged', 'removed')),
  reason text not null default '',
  created_at timestamptz not null default now()
);

alter table public.moderation_events enable row level security;
grant select, insert on public.moderation_events to authenticated;

create policy "Users can create own moderation events"
  on public.moderation_events for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can read own moderation events"
  on public.moderation_events for select
  to authenticated
  using ((select auth.uid()) = user_id);

create index if not exists moderation_events_user_idx on public.moderation_events(user_id);
create index if not exists moderation_events_listing_idx on public.moderation_events(target_listing_id);
create index if not exists moderation_events_message_idx on public.moderation_events(target_message_id);

create table if not exists private.rate_limits (
  user_id uuid not null,
  action text not null,
  requested_at timestamptz not null default now()
);

create index if not exists rate_limits_user_action_requested_idx
  on private.rate_limits(user_id, action, requested_at desc);

create or replace function private.enforce_rate_limit(action_name text, max_requests integer, window_seconds integer)
returns void
language plpgsql
set search_path = ''
as $$
declare
  request_count integer;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;

  delete from private.rate_limits
  where requested_at < now() - interval '1 hour';

  select count(*) into request_count
  from private.rate_limits
  where user_id = (select auth.uid())
    and action = action_name
    and requested_at >= now() - make_interval(secs => window_seconds);

  if request_count >= max_requests then
    raise exception 'Rate limit exceeded for %', action_name;
  end if;

  insert into private.rate_limits(user_id, action) values ((select auth.uid()), action_name);
end;
$$;

create or replace function private.thread_participant(thread_uuid uuid, profile_uuid uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.message_threads t
    join public.matches m on m.id = t.match_id
    where t.id = thread_uuid
      and (m.group_owner_user_id = profile_uuid or m.party_owner_user_id = profile_uuid)
      and m.status = 'active'
  );
$$;

create or replace function public.create_match_thread(
  p_group_listing_id uuid,
  p_party_listing_id uuid,
  p_score integer default 0
)
returns table(match_id uuid, thread_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  group_owner uuid;
  party_owner uuid;
  created_match_id uuid;
  created_thread_id uuid;
begin
  perform private.enforce_rate_limit('create_match_thread', 30, 300);

  select owner_user_id into group_owner
  from public.listings
  where id = p_group_listing_id
    and listing_type = 'group'
    and is_active = true
    and moderation_status <> 'removed';

  select owner_user_id into party_owner
  from public.listings
  where id = p_party_listing_id
    and listing_type = 'party'
    and is_active = true
    and moderation_status <> 'removed';

  if group_owner is null or party_owner is null then
    raise exception 'Active group and party listings are required';
  end if;

  if (select auth.uid()) not in (group_owner, party_owner) then
    raise exception 'Only listing owners can create this match';
  end if;

  insert into public.matches(group_listing_id, party_listing_id, group_owner_user_id, party_owner_user_id, score, initiated_by, status)
  values (p_group_listing_id, p_party_listing_id, group_owner, party_owner, greatest(0, least(100, p_score)), (select auth.uid()), 'active')
  on conflict (group_listing_id, party_listing_id)
  do update set updated_at = now(), status = 'active'
  returning id into created_match_id;

  insert into public.message_threads(match_id, last_message_preview)
  values (created_match_id, 'Connection opened.')
  on conflict (match_id)
  do update set updated_at = now()
  returning id into created_thread_id;

  match_id := created_match_id;
  thread_id := created_thread_id;
  return next;
end;
$$;

grant execute on function public.create_match_thread(uuid, uuid, integer) to authenticated;

create or replace function private.broadcast_message_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.moderation_status <> 'removed' then
    perform realtime.send(
      'thread:' || new.thread_id::text || ':messages',
      'message_inserted',
      jsonb_build_object(
        'id', new.id,
        'thread_id', new.thread_id,
        'sender_user_id', new.sender_user_id,
        'body', new.body,
        'moderation_status', new.moderation_status,
        'created_at', new.created_at
      ),
      true
    );
  end if;
  return new;
end;
$$;

drop trigger if exists messages_broadcast_event on public.messages;
create trigger messages_broadcast_event
  after insert on public.messages
  for each row execute function private.broadcast_message_event();

create or replace function private.broadcast_match_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform realtime.send(
    'user:' || new.group_owner_user_id::text || ':matches',
    'match_created',
    jsonb_build_object('match_id', new.id, 'group_listing_id', new.group_listing_id, 'party_listing_id', new.party_listing_id, 'score', new.score),
    true
  );
  perform realtime.send(
    'user:' || new.party_owner_user_id::text || ':matches',
    'match_created',
    jsonb_build_object('match_id', new.id, 'group_listing_id', new.group_listing_id, 'party_listing_id', new.party_listing_id, 'score', new.score),
    true
  );
  return new;
end;
$$;

drop trigger if exists matches_broadcast_event on public.matches;
create trigger matches_broadcast_event
  after insert on public.matches
  for each row execute function private.broadcast_match_event();

create or replace function private.realtime_thread_from_topic(topic text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
declare
  parts text[];
begin
  parts := string_to_array(topic, ':');
  if array_length(parts, 1) = 3 and parts[1] = 'thread' and parts[3] = 'messages' then
    return parts[2]::uuid;
  end if;
  return null;
exception when others then
  return null;
end;
$$;

create or replace function private.realtime_user_from_topic(topic text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
declare
  parts text[];
begin
  parts := string_to_array(topic, ':');
  if array_length(parts, 1) = 3 and parts[1] = 'user' and parts[3] = 'matches' then
    return parts[2]::uuid;
  end if;
  return null;
exception when others then
  return null;
end;
$$;

drop policy if exists "QuestBond users can receive authorized realtime broadcasts" on realtime.messages;
create policy "QuestBond users can receive authorized realtime broadcasts"
  on realtime.messages
  for select
  to authenticated
  using (
    realtime.messages.extension = 'broadcast'
    and (
      private.thread_participant(private.realtime_thread_from_topic((select realtime.topic())), (select auth.uid()))
      or private.realtime_user_from_topic((select realtime.topic())) = (select auth.uid())
    )
  );

drop policy if exists "QuestBond users can send authorized realtime broadcasts" on realtime.messages;
create policy "QuestBond users can send authorized realtime broadcasts"
  on realtime.messages
  for insert
  to authenticated
  with check (
    realtime.messages.extension = 'broadcast'
    and (
      private.thread_participant(private.realtime_thread_from_topic((select realtime.topic())), (select auth.uid()))
      or private.realtime_user_from_topic((select realtime.topic())) = (select auth.uid())
    )
  );
