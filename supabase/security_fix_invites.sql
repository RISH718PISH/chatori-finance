-- ═══════════════════════════════════════════════════════════════
-- SECURITY FIX — lock down business_invites
--
-- Run this once: Supabase dashboard → SQL Editor → New query → Run.
-- Safe to re-run. Also folded into schema.sql section 8.
--
-- WHAT WAS WRONG
-- business_invites was created without RLS enabled and without any
-- policy. Any authenticated Supabase user could therefore:
--   1. read every invite row in the database, and
--   2. insert {email: <their own>, business_id: <your business>,
--      role: 'owner'} — after which handle_new_user() would honour it
--      on signup and make them an owner of your books.
-- ═══════════════════════════════════════════════════════════════

-- Step 0 (diagnostic) — run this on its own first and read the output.
-- Every row should say 'owner'. If anything else appears, stop and
-- report it before continuing; the CHECK below will skip itself.
--
--   select role, count(*) from public.business_members group by 1;


-- ── 1. Owner-scoped helper ────────────────────────────────────
-- Parameterless and set-returning on purpose: Postgres hoists this into
-- a once-per-statement InitPlan. A my_role_in(business_id) variant would
-- be correlated and get called once PER ROW.
create or replace function public.my_owner_business_ids()
  returns setof uuid
  language sql
  security definer
  stable
  set search_path = public
as $$
  select business_id
    from public.business_members
   where user_id = auth.uid()
     and role = 'owner';
$$;


-- ── 2. Enable RLS and add owner-only policies ─────────────────
alter table public.business_invites enable row level security;

-- Remove the earlier member-level policy. Permissive policies combine with
-- OR, so leaving a `for all` membership policy in place would nullify the
-- owner-only policies below.
drop policy if exists invites_member_rw on public.business_invites;

drop policy if exists inv_owner_read on public.business_invites;
create policy inv_owner_read on public.business_invites
  for select using (business_id in (select public.my_owner_business_ids()));

drop policy if exists inv_owner_insert on public.business_invites;
create policy inv_owner_insert on public.business_invites
  for insert with check (business_id in (select public.my_owner_business_ids()));

-- Needed because inviteMember() upserts (INSERT ... ON CONFLICT DO UPDATE).
drop policy if exists inv_owner_update on public.business_invites;
create policy inv_owner_update on public.business_invites
  for update using (business_id in (select public.my_owner_business_ids()))
  with check (business_id in (select public.my_owner_business_ids()));

drop policy if exists inv_owner_delete on public.business_invites;
create policy inv_owner_delete on public.business_invites
  for delete using (business_id in (select public.my_owner_business_ids()));

-- handle_new_user() is SECURITY DEFINER, so signup still reads and
-- deletes the invite row regardless of these policies.


-- ── 3. Constrain role to values the app understands ───────────
-- Guarded: reports instead of failing if unexpected values exist.
do $$
begin
  if exists (
    select 1 from public.business_members where role not in ('owner', 'chef')
  ) then
    raise notice
      'SKIPPED business_members role CHECK — unexpected role values present. Inspect with: select role, count(*) from public.business_members group by 1;';
  else
    alter table public.business_members
      drop constraint if exists business_members_role_check;
    alter table public.business_members
      add constraint business_members_role_check check (role in ('owner', 'chef'));
  end if;

  if exists (
    select 1 from public.business_invites where role not in ('owner', 'chef')
  ) then
    raise notice
      'SKIPPED business_invites role CHECK — unexpected role values present.';
  else
    alter table public.business_invites
      drop constraint if exists business_invites_role_check;
    alter table public.business_invites
      add constraint business_invites_role_check check (role in ('owner', 'chef'));
  end if;
end $$;


-- ── 4. Verify ─────────────────────────────────────────────────
-- rowsecurity must be true for business_invites.
select tablename, rowsecurity
  from pg_tables
 where schemaname = 'public'
   and tablename in ('business_invites', 'business_members', 'transactions')
 order by tablename;

-- Should list the four inv_owner_* policies.
select policyname, cmd
  from pg_policies
 where schemaname = 'public'
   and tablename = 'business_invites'
 order by policyname;
