alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.message_threads;
alter publication supabase_realtime add table public.matches;
alter publication supabase_realtime add table public.notifications;

create or replace function private.touch_thread_on_message()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  update public.message_threads
  set last_message_preview = left(new.body, 160),
      last_message_at = new.created_at,
      updated_at = now()
  where id = new.thread_id;
  return new;
end;
$$;

drop trigger if exists messages_touch_thread on public.messages;
create trigger messages_touch_thread
after insert on public.messages
for each row execute function private.touch_thread_on_message();

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null default '',
  status text not null default 'requested' check (status in ('requested', 'processing', 'completed', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.account_deletion_requests enable row level security;
grant select, insert on public.account_deletion_requests to authenticated;

create policy "Users can view own deletion requests"
  on public.account_deletion_requests for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can request own deletion"
  on public.account_deletion_requests for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create or replace trigger account_deletion_requests_set_updated_at
before update on public.account_deletion_requests
for each row execute function private.set_updated_at();

create or replace function public.search_listings_nearby(
  search_listing_type text,
  origin_lat double precision,
  origin_lon double precision,
  max_miles double precision default 50
)
returns table (id uuid, distance_miles double precision)
language sql
stable
set search_path = ''
as $$
  select l.id,
         3958.7613 * acos(
           least(1, greatest(-1,
             cos(radians(origin_lat)) * cos(radians(l.latitude)) * cos(radians(l.longitude) - radians(origin_lon))
             + sin(radians(origin_lat)) * sin(radians(l.latitude))
           ))
         ) as distance_miles
  from public.listings l
  where l.is_active = true
    and l.listing_type = search_listing_type
    and l.latitude is not null
    and l.longitude is not null
    and 3958.7613 * acos(
      least(1, greatest(-1,
        cos(radians(origin_lat)) * cos(radians(l.latitude)) * cos(radians(l.longitude) - radians(origin_lon))
        + sin(radians(origin_lat)) * sin(radians(l.latitude))
      ))
    ) <= max_miles
  order by distance_miles asc;
$$;

grant execute on function public.search_listings_nearby(text, double precision, double precision, double precision) to authenticated;

create or replace function private.queue_message_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notifications (user_id, notification_type, title, body, payload)
  select recipient_id,
         'message',
         'New party message',
         left(new.body, 180),
         jsonb_build_object('thread_id', new.thread_id, 'message_id', new.id)
  from (
    select case
      when m.group_owner_user_id = new.sender_user_id then m.party_owner_user_id
      else m.group_owner_user_id
    end as recipient_id
    from public.message_threads t
    join public.matches m on m.id = t.match_id
    where t.id = new.thread_id
      and new.sender_user_id is not null
      and new.moderation_status != 'removed'
  ) recipients
  where recipient_id is not null;

  return new;
end;
$$;

drop trigger if exists messages_queue_notification on public.messages;
create trigger messages_queue_notification
after insert on public.messages
for each row execute function private.queue_message_notification();

create or replace function private.queue_match_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notifications (user_id, notification_type, title, body, payload)
  values
    (new.group_owner_user_id, 'match', 'New RollTogether match', 'A party connected with your listing.', jsonb_build_object('match_id', new.id)),
    (new.party_owner_user_id, 'match', 'New RollTogether match', 'A group connected with your listing.', jsonb_build_object('match_id', new.id));
  return new;
end;
$$;

drop trigger if exists matches_queue_notifications on public.matches;
create trigger matches_queue_notifications
after insert on public.matches
for each row execute function private.queue_match_notifications();
