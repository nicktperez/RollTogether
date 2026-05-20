alter table private.rate_limits add column if not exists id uuid default gen_random_uuid();
update private.rate_limits set id = gen_random_uuid() where id is null;
alter table private.rate_limits alter column id set not null;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'rate_limits_pkey'
      and conrelid = 'private.rate_limits'::regclass
  ) then
    alter table private.rate_limits add constraint rate_limits_pkey primary key (id);
  end if;
end $$;
