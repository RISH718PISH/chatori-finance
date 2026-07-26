-- Chatori Finance — Supabase schema, security, and signup bootstrap.
-- Run this once in the Supabase dashboard → SQL Editor → New query → Run.
-- Safe to re-run (idempotent).

-- ─────────────────────────────────────────────────────────────
-- 1. Core workspace tables
-- ─────────────────────────────────────────────────────────────
create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Chatori Kitchen',
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now()
);

create table if not exists public.business_members (
  business_id uuid not null references public.businesses (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'owner',          -- owner | accountant | staff
  display_name text,
  created_at timestamptz not null default now(),
  primary key (business_id, user_id)
);

-- Pending members: an email is linked to a business before that person signs up.
create table if not exists public.business_invites (
  email text primary key,
  business_id uuid not null references public.businesses (id) on delete cascade,
  role text not null default 'owner',
  invited_by uuid references auth.users (id),
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────
-- 2. Data tables (all scoped to a business)
-- ─────────────────────────────────────────────────────────────
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  type text not null,                          -- income | expense
  category text not null,
  subcategory text,
  amount_paise bigint not null,
  occurred_at timestamptz not null default now(),
  payment_mode text not null,
  party_name text,
  notes text,
  source text not null default 'manual',
  tag text,
  attachment_path text,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists transactions_business_time
  on public.transactions (business_id, occurred_at desc);

create table if not exists public.staff (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null,
  role text,
  monthly_salary_paise bigint not null default 0,
  joined_date date,
  active_status boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.salary_records (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  staff_id uuid references public.staff (id) on delete set null,
  amount_paid_paise bigint not null,
  month text not null,                         -- YYYY-MM
  payment_date date not null,
  payment_mode text not null,
  notes text,
  advance_adjusted_paise bigint not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.advance_records (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  person_name text not null,
  person_type text not null,                   -- staff | vendor | helper | other
  amount_paise bigint not null,
  date date not null,
  reason text,
  recovered_amount_paise bigint not null default 0,
  status text not null default 'open',         -- open | partial | closed
  linked_staff_id uuid references public.staff (id) on delete set null,
  linked_salary_record_id uuid,
  created_at timestamptz not null default now()
);

-- Catering events/parties — per-event P&L is computed from transactions
-- linked via transactions.event_id.
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null,                       -- e.g. "Sharma wedding — 15 Aug"
  customer_name text,
  event_date date not null,
  guest_count int,
  quoted_amount_paise bigint not null default 0,
  status text not null default 'upcoming',  -- upcoming | done | settled
  notes text,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now()
);
create index if not exists events_business_date
  on public.events (business_id, event_date desc);

alter table public.transactions
  add column if not exists event_id uuid references public.events (id) on delete set null;

-- ─────────────────────────────────────────────────────────────
-- 3. Helper: business ids the current user belongs to
--    (SECURITY DEFINER avoids RLS recursion on business_members)
-- ─────────────────────────────────────────────────────────────
create or replace function public.my_business_ids()
  returns setof uuid
  language sql
  security definer
  stable
  set search_path = public
as $$
  select business_id from public.business_members where user_id = auth.uid();
$$;

-- ─────────────────────────────────────────────────────────────
-- 4. Row-Level Security
-- ─────────────────────────────────────────────────────────────
alter table public.businesses       enable row level security;
alter table public.business_members enable row level security;
alter table public.transactions      enable row level security;
alter table public.staff             enable row level security;
alter table public.salary_records    enable row level security;
alter table public.advance_records   enable row level security;
alter table public.events            enable row level security;

-- businesses: members can read; creator can update
drop policy if exists biz_read on public.businesses;
create policy biz_read on public.businesses
  for select using (id in (select public.my_business_ids()));

-- members: a user can see the membership rows of businesses they belong to
drop policy if exists mem_read on public.business_members;
create policy mem_read on public.business_members
  for select using (business_id in (select public.my_business_ids()));

-- generic helper to (re)create full-access member policies on a data table
do $$
declare t text;
begin
  foreach t in array array['transactions','staff','salary_records','advance_records','events']
  loop
    execute format('drop policy if exists %I_rw on public.%I;', t, t);
    execute format($f$
      create policy %1$I_rw on public.%1$I
        for all
        using (business_id in (select public.my_business_ids()))
        with check (business_id in (select public.my_business_ids()));
    $f$, t);
  end loop;
end $$;

-- ─────────────────────────────────────────────────────────────
-- 5. On signup: link an invited email to its business, otherwise
--    create a fresh business and make the user its owner.
-- ─────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  inv public.business_invites;
  new_biz uuid;
begin
  select * into inv from public.business_invites where email = new.email;
  if found then
    insert into public.business_members (business_id, user_id, role, display_name)
      values (inv.business_id, new.id, inv.role, split_part(new.email, '@', 1));
    delete from public.business_invites where email = new.email;
  else
    insert into public.businesses (name, created_by)
      values ('Chatori Kitchen', new.id)
      returning id into new_biz;
    insert into public.business_members (business_id, user_id, role, display_name)
      values (new_biz, new.id, 'owner', split_part(new.email, '@', 1));
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- 6. Attachments bucket (bill photos). Private; members of a business can
--    read/write only their business's folder (path: <business_id>/<file>).
-- ─────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
  values ('attachments', 'attachments', false)
  on conflict (id) do nothing;

drop policy if exists attachments_member_rw on storage.objects;
create policy attachments_member_rw on storage.objects
  for all
  using (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] in
        (select public.my_business_ids()::text)
  )
  with check (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] in
        (select public.my_business_ids()::text)
  );

-- ─────────────────────────────────────────────────────────────
-- 7. Split-payment columns on transactions. Used only when
--    payment_mode = 'Cash+UPI'. Both must sum to amount_paise.
-- ─────────────────────────────────────────────────────────────
alter table public.transactions
  add column if not exists cash_paise bigint;
alter table public.transactions
  add column if not exists upi_paise bigint;

-- ─────────────────────────────────────────────────────────────
-- 8. SECURITY FIX — lock down business_invites.
--
--    business_invites was created in section 1 but never had RLS
--    enabled and never had any policy. With RLS off, ANY authenticated
--    user could:
--      • read every invite row in the database (leaking business ids
--        and the email of everyone invited), and
--      • insert {email: <their own>, business_id: <someone else's>,
--        role: 'owner'} — after which handle_new_user() (SECURITY
--        DEFINER, section 5) would honour it on signup and hand them
--        ownership of a business they were never invited to.
--
--    Invites are an owner-only concern, so all four verbs are gated on
--    ownership of the target business.
-- ─────────────────────────────────────────────────────────────

-- Businesses where the current user is specifically an OWNER (not just a
-- member). Parameterless + set-returning on purpose: Postgres hoists this
-- into a once-per-statement InitPlan, exactly like my_business_ids().
-- A my_role_in(business_id) style helper would be correlated and get
-- called once PER ROW.
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

-- UPDATE is required because AuthRepository.inviteMember() uses upsert
-- (INSERT ... ON CONFLICT DO UPDATE); without it, re-inviting an email
-- that already has a pending invite would fail.
drop policy if exists inv_owner_update on public.business_invites;
create policy inv_owner_update on public.business_invites
  for update using (business_id in (select public.my_owner_business_ids()))
  with check (business_id in (select public.my_owner_business_ids()));

drop policy if exists inv_owner_delete on public.business_invites;
create policy inv_owner_delete on public.business_invites
  for delete using (business_id in (select public.my_owner_business_ids()));

-- handle_new_user() is SECURITY DEFINER, so it still reads and deletes
-- the invite row during signup regardless of these policies.

-- Constrain role to the values the app actually understands. The original
-- comment on business_members.role said "owner | accountant | staff", but
-- nothing ever wrote those; the app ships owner + chef. Guarded so that
-- re-running this on a database with unexpected roles reports instead of
-- failing the whole script.
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

-- ─────────────────────────────────────────────────────────────
-- 9. Purchase invoices — item-level capture from the AI OCR path.
--
--    The old pipeline threw line items away: addBatch() accepted only
--    (category, amount_paise, notes), so quantity was parsed and then
--    discarded, and unit of measure was never extracted at all. These
--    two tables keep the detail; the per-category `transactions` rows
--    are still written exactly as before, so the P&L is unchanged.
--
--    BOTH tables are OWNER-ONLY. RLS is row-level and column-blind — if
--    cost sits on a row a chef can read, the chef has the price no
--    matter what the Dart UI does. Keeping cost here (and off
--    stock_movements in section 10) is what actually enforces
--    "chef sees quantities, not rupees".
-- ─────────────────────────────────────────────────────────────
create table if not exists public.purchase_invoices (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  vendor_name text,
  invoice_number text,
  invoice_date date,
  subtotal_paise bigint,
  tax_paise bigint,
  total_paise bigint,
  attachment_path text,
  raw_ocr_json jsonb,
  parse_source text not null default 'ai',      -- ai | fallback | manual
  status text not null default 'confirmed',     -- draft | confirmed
  created_by uuid references auth.users (id) default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists purchase_invoices_business_date
  on public.purchase_invoices (business_id, invoice_date desc);

create table if not exists public.purchase_invoice_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  invoice_id uuid not null
    references public.purchase_invoices (id) on delete cascade,
  description text not null,
  hsn text,
  -- Quantity as integer milli-units of the dimension's base unit
  -- (mass->mg, volume->uL, count->milli-piece). See lib/core/quantity.dart.
  -- Nullable because a unit is not always readable on the invoice.
  qty_milli bigint,
  dimension text,                                -- mass | volume | count
  display_unit text,                             -- kg | g | l | ml | pcs | dozen
  unit_price_paise bigint,
  line_total_paise bigint not null,
  category text not null,
  confidence numeric(3, 2),
  inventory_item_id uuid,                        -- FK added in section 10
  created_at timestamptz not null default now()
);

create index if not exists purchase_invoice_items_invoice
  on public.purchase_invoice_items (invoice_id);

-- Link the money rows back to the invoice they came from.
alter table public.transactions
  add column if not exists source_invoice_id uuid
    references public.purchase_invoices (id) on delete set null;

alter table public.purchase_invoices      enable row level security;
alter table public.purchase_invoice_items enable row level security;

do $$
declare t text;
begin
  foreach t in array array['purchase_invoices', 'purchase_invoice_items']
  loop
    execute format('drop policy if exists %I_owner_rw on public.%I;', t, t);
    execute format($f$
      create policy %1$I_owner_rw on public.%1$I
        for all
        using (business_id in (select public.my_owner_business_ids()))
        with check (business_id in (select public.my_owner_business_ids()));
    $f$, t);
  end loop;
end $$;

-- Saves an invoice, its line items, and the per-category expense rows in
-- ONE transaction. Doing this as three sequential client calls risks a
-- half-saved invoice, and a retry after a partial failure would duplicate
-- the money rows. SECURITY INVOKER (the default) so the owner-only RLS
-- policies above still apply to the caller.
create or replace function public.save_purchase_invoice(
  p_business_id   uuid,
  p_vendor        text,
  p_invoice_no    text,
  p_invoice_date  date,
  p_subtotal      bigint,
  p_tax           bigint,
  p_total         bigint,
  p_attachment    text,
  p_raw_json      jsonb,
  p_parse_source  text,
  p_items         jsonb,
  p_payment_mode  text,
  p_party         text,
  p_event_id      uuid,
  p_occurred_at   timestamptz
) returns uuid
  language plpgsql
as $$
declare
  v_invoice_id uuid;
begin
  insert into public.purchase_invoices (
    business_id, vendor_name, invoice_number, invoice_date,
    subtotal_paise, tax_paise, total_paise,
    attachment_path, raw_ocr_json, parse_source
  ) values (
    p_business_id, p_vendor, p_invoice_no, p_invoice_date,
    p_subtotal, p_tax, p_total,
    p_attachment, p_raw_json, coalesce(p_parse_source, 'ai')
  )
  returning id into v_invoice_id;

  insert into public.purchase_invoice_items (
    business_id, invoice_id, description, hsn, qty_milli, dimension,
    display_unit, unit_price_paise, line_total_paise, category, confidence
  )
  select
    p_business_id, v_invoice_id,
    it.description, it.hsn, it.qty_milli, it.dimension,
    it.display_unit, it.unit_price_paise, it.line_total_paise,
    it.category, it.confidence
  from jsonb_to_recordset(p_items) as it(
    description      text,
    hsn              text,
    qty_milli        bigint,
    dimension        text,
    display_unit     text,
    unit_price_paise bigint,
    line_total_paise bigint,
    category         text,
    confidence       numeric
  );

  -- One expense row per category, exactly as the previous split flow
  -- produced, so Reports and the P&L behave identically.
  insert into public.transactions (
    business_id, type, category, amount_paise, occurred_at, payment_mode,
    party_name, notes, source, event_id, attachment_path, source_invoice_id
  )
  select
    p_business_id,
    'expense',
    it.category,
    sum(it.line_total_paise),
    coalesce(p_occurred_at, now()),
    p_payment_mode,
    p_party,
    coalesce(p_invoice_no, 'Invoice') || E'\n' ||
      string_agg('• ' || it.description, E'\n' order by it.description),
    'screenshot',
    p_event_id,
    p_attachment,
    v_invoice_id
  from jsonb_to_recordset(p_items) as it(
    description      text,
    line_total_paise bigint,
    category         text
  )
  group by it.category;

  return v_invoice_id;
end;
$$;

-- ──────────────────────────────────────────────────────────
-- 11. Role-based access control (owner + chef).
--
--     Before this every data policy was membership-only and role-blind, so
--     any member could read and write every table. Finance tables become
--     owner-only here; inventory (section 12) stays open to both roles.
--
--     Also mirrored standalone in supabase/rbac.sql.
-- ──────────────────────────────────────────────────────────
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


