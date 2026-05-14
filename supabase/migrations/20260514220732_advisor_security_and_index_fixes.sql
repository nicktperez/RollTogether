revoke execute on function public.rls_auto_enable() from anon, authenticated, public;

create index if not exists blocks_blocked_user_idx on public.blocks(blocked_user_id);
create index if not exists blocks_blocked_listing_idx on public.blocks(blocked_listing_id);
create index if not exists matches_group_listing_idx on public.matches(group_listing_id);
create index if not exists matches_party_listing_idx on public.matches(party_listing_id);
create index if not exists matches_initiated_by_idx on public.matches(initiated_by);
create index if not exists messages_sender_user_idx on public.messages(sender_user_id);
create index if not exists reports_target_profile_idx on public.reports(target_profile_id);
create index if not exists reports_target_listing_idx on public.reports(target_listing_id);
create index if not exists reports_target_message_idx on public.reports(target_message_id);
create index if not exists swipes_owner_listing_idx on public.swipes(owner_listing_id);
create index if not exists swipes_target_listing_idx on public.swipes(target_listing_id);
