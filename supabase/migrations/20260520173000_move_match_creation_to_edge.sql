revoke execute on function public.create_match_thread(uuid, uuid, integer) from anon;
revoke execute on function public.create_match_thread(uuid, uuid, integer) from authenticated;
drop function if exists public.create_match_thread(uuid, uuid, integer);
