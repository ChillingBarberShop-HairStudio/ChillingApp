-- Cache auth.uid() once per query while preserving self-or-manager profile access.
drop policy if exists "profiles self or manager read" on public.profiles;
create policy "profiles self or manager read" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id or private.can_manage());
