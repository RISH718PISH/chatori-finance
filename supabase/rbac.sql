-- ═══════════════════════════════════════════════════════════════
-- ROLE-BASED ACCESS CONTROL — owner + chef
--
-- Run once: Supabase dashboard → SQL Editor → New query → Run.
-- Safe to re-run. Mirrored into schema.sql section 11.
--
-- Before this, every data policy was `for all using (business_id in
-- my_business_ids())` — membership-only and entirely role-blind, so any
-- member could read and write every table. This makes the finance tables
-- owner-only while leaving inventory (section 12) open to both roles.
-- ═══════════════════════════════════════════════════════════════

-- ── 0. Pre-flight ─────────────────────────────────────────────
-- Every existing row must be 'owner' or nobody loses access. Should print
-- one line: owner | 6
do $$
declare r record;
begin
  for r in select role, count(*) as n from public.business_members group by 1
  loop
    raise notice 'business_members role=% count=%', r.role, r.n;
  end loop;
end $$;


-- ── 1. Finance tables become owner-only ───────────────────────
-- my_owner_business_ids() already exists (section 8). It is parameterless
-- and set-returning on purpose: Postgres hoists it into a once-per-
-- statement InitPlan. A my_role_in(business_id) shape would take the row's
-- column as an argument, making it correlated — one function call PER ROW.
do $$
declare t text;
begin
  foreach t in array array[
    'transactions', 'staff', 'salary_records', 'advance_records', 'events'
  ]
  loop
    -- Drop the old role-blind policy from section 4.
    execute format('drop policy if exists %I_rw on public.%I;', t, t);
    execute format('drop policy if exists %I_owner_rw on public.%I;', t, t);
    execute format($f$
      create policy %1$I_owner_rw on public.%1$I
        for all
        using (business_id in (select public.my_owner_business_ids()))
        with check (business_id in (select public.my_owner_business_ids()));
    $f$, t);
  end loop;
end $$;

-- businesses: a chef still needs to read the business row (its name is in
-- the app bar), so this stays membership-scoped.
drop policy if exists biz_read on public.businesses;
create policy biz_read on public.businesses
  for select using (id in (select public.my_business_ids()));

-- business_members: every member may read the roster — "added by X"
-- attribution needs it, and it carries no financial data.
drop policy if exists mem_read on public.business_members;
create policy mem_read on public.business_members
  for select using (business_id in (select public.my_business_ids()));

-- Deliberately NO update/delete policy on business_members. A `for update`
-- policy without a matching column restriction would let an owner move a
-- row to another business or rewrite user_id. Role changes go through the
-- RPCs below, which are narrower.


-- ── 2. set_member_role ────────────────────────────────────────
-- SECURITY DEFINER so it can write a table with no update policy.
-- Asserts caller-is-owner-of-that-business and blocks self-demotion, which
-- would otherwise let the last owner lock everyone out of their own books.
create or replace function public.set_member_role(
  p_user_id uuid,
  p_role text
) returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_biz uuid;
begin
  if p_role not in ('owner', 'chef') then
    raise exception 'Unknown role: %', p_role;
  end if;

  select business_id into v_biz
    from public.business_members
   where user_id = auth.uid() and role = 'owner'
   order by created_at
   limit 1;

  if v_biz is null then
    raise exception 'Only an owner can change roles';
  end if;

  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;

  update public.business_members
     set role = p_role
   where business_id = v_biz and user_id = p_user_id;

  if not found then
    raise exception 'That person is not a member of your business';
  end if;
end;
$$;


-- ── 3. remove_member ──────────────────────────────────────────
create or replace function public.remove_member(p_user_id uuid)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_biz uuid;
  v_owners int;
begin
  select business_id into v_biz
    from public.business_members
   where user_id = auth.uid() and role = 'owner'
   order by created_at
   limit 1;

  if v_biz is null then
    raise exception 'Only an owner can remove members';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'You cannot remove yourself';
  end if;

  select count(*) into v_owners
    from public.business_members
   where business_id = v_biz and role = 'owner';

  if v_owners <= 1 and exists (
    select 1 from public.business_members
     where business_id = v_biz and user_id = p_user_id and role = 'owner'
  ) then
    raise exception 'A business must keep at least one owner';
  end if;

  delete from public.business_members
   where business_id = v_biz and user_id = p_user_id;

  -- Their entries stay in the books; transactions.created_by is a plain
  -- FK to auth.users and is untouched by removing a membership.
end;
$$;


-- ── 4. add_member_by_email ────────────────────────────────────
-- business_invites.role is only read by handle_new_user() at SIGNUP. So a
-- role picker on the invite dialog silently does nothing for anyone who
-- already has an account — which is exactly the common case when adding a
-- chef who is already using another app. This closes that gap.
--
-- Returns: 'added' | 'updated' | 'invited'
create or replace function public.add_member_by_email(
  p_email text,
  p_role text
) returns text
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_biz uuid;
  v_uid uuid;
  v_email text := lower(btrim(p_email));
begin
  if p_role not in ('owner', 'chef') then
    raise exception 'Unknown role: %', p_role;
  end if;

  select business_id into v_biz
    from public.business_members
   where user_id = auth.uid() and role = 'owner'
   order by created_at
   limit 1;

  if v_biz is null then
    raise exception 'Only an owner can add members';
  end if;

  select id into v_uid from auth.users where lower(email) = v_email limit 1;

  if v_uid is null then
    -- No account yet: fall back to the invite row, which handle_new_user
    -- consumes when they sign up.
    insert into public.business_invites (email, business_id, role, invited_by)
    values (v_email, v_biz, p_role, auth.uid())
    on conflict (email) do update
      set business_id = excluded.business_id,
          role        = excluded.role,
          invited_by  = excluded.invited_by;
    return 'invited';
  end if;

  if exists (
    select 1 from public.business_members
     where business_id = v_biz and user_id = v_uid
  ) then
    update public.business_members
       set role = p_role
     where business_id = v_biz and user_id = v_uid;
    return 'updated';
  end if;

  insert into public.business_members (business_id, user_id, role, display_name)
  values (v_biz, v_uid, p_role, split_part(v_email, '@', 1));

  -- If they signed up alone earlier they own an empty auto-created
  -- business. Drop that membership and the business if it is now orphaned,
  -- so they land in the right books instead of their own empty ones.
  delete from public.business_members bm
   where bm.user_id = v_uid
     and bm.business_id <> v_biz
     and not exists (
       select 1 from public.transactions t where t.business_id = bm.business_id
     );

  delete from public.businesses b
   where b.created_by = v_uid
     and b.id <> v_biz
     and not exists (
       select 1 from public.business_members m where m.business_id = b.id
     );

  return 'added';
end;
$$;

revoke all on function public.set_member_role(uuid, text) from public;
revoke all on function public.remove_member(uuid) from public;
revoke all on function public.add_member_by_email(text, text) from public;
grant execute on function public.set_member_role(uuid, text) to authenticated;
grant execute on function public.remove_member(uuid) to authenticated;
grant execute on function public.add_member_by_email(text, text) to authenticated;


-- ── 5. Verify ─────────────────────────────────────────────────
-- Finance tables should each show one *_owner_rw policy.
select tablename, policyname, cmd
  from pg_policies
 where schemaname = 'public'
   and tablename in ('transactions','staff','salary_records',
                     'advance_records','events','business_members')
 order by tablename, policyname;
