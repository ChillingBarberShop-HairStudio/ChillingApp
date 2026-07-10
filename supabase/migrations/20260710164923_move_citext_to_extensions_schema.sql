create schema if not exists extensions;
revoke all on schema extensions from public;

do $$
begin
  if exists (
    select 1
    from pg_extension extension
    join pg_namespace schema on schema.oid = extension.extnamespace
    where extension.extname = 'citext' and schema.nspname <> 'extensions'
  ) then
    alter extension citext set schema extensions;
  end if;
end $$;
