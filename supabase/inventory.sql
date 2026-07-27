-- ═══════════════════════════════════════════════════════════════
-- INVENTORY — stock ledger, valuation views, RLS, and the stock-aware
-- purchase-save RPC.
--
-- Run once: Supabase dashboard → SQL Editor → New query → Run.
-- Safe to re-run. Mirrored into schema.sql section 12.
--
-- Design notes that matter:
--  • stock_movements is an APPEND-ONLY, SIGNED ledger. On-hand is literally
--    sum(qty_milli). There is no update/delete policy — corrections are new
--    rows. This is what makes every number traceable to a cause.
--  • stock_movements carries NO cost. RLS is row-level and column-blind, so
--    a price on any chef-readable row would leak. Cost lives only on
--    purchase_invoice_items, which is owner-only.
--  • Quantities are integer milli-units of the dimension's base unit
--    (mass→mg, volume→µL, count→milli-piece). Mirrors lib/core/quantity.dart.
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Item catalogue ─────────────────────────────────────────
create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null,
  dimension text not null,                 -- mass | volume | count
  display_unit text not null,              -- kg g | l ml | pcs dozen
  category text,                           -- one of the 26 expense heads
  reorder_level_milli bigint not null default 0
    check (reorder_level_milli >= 0),
  archived boolean not null default false,
  created_by uuid references auth.users (id) default auth.uid(),
  created_at timestamptz not null default now(),
  constraint inventory_items_dimension_ck
    check (dimension in ('mass', 'volume', 'count')),
  -- The display unit must belong to the dimension, or Quantity.formatAs
  -- would render a mass in litres.
  constraint inventory_items_unit_matches_dimension_ck check (
    (dimension = 'mass'   and display_unit in ('kg', 'g'))  or
    (dimension = 'volume' and display_unit in ('l', 'ml'))  or
    (dimension = 'count'  and display_unit in ('pcs', 'dozen'))
  )
);

-- Case/whitespace-insensitive uniqueness so auto-create can't spawn
-- "Butter", "butter" and "Butter " as three items. The stock-save RPC's
-- ON CONFLICT restates this exact expression.
create unique index if not exists inventory_items_biz_name
  on public.inventory_items (business_id, lower(btrim(name)));
create index if not exists inventory_items_biz
  on public.inventory_items (business_id, archived);


-- ── 2. Append-only signed ledger ──────────────────────────────
create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  item_id uuid not null
    references public.inventory_items (id) on delete cascade,
  movement_type text not null,             -- purchase|opening|consumption|wastage|adjustment|return
  -- SIGNED delta in milli-units. + into stock, − out. On-hand = sum().
  qty_milli bigint not null check (qty_milli <> 0),
  occurred_on date not null
    default (now() at time zone 'Asia/Kolkata')::date,
  invoice_item_id uuid
    references public.purchase_invoice_items (id) on delete set null,
  event_id uuid references public.events (id) on delete set null,
  note text,
  created_by uuid not null references auth.users (id) default auth.uid(),
  created_at timestamptz not null default now(),
  constraint stock_movements_type_ck check (movement_type in
    ('purchase', 'opening', 'consumption', 'wastage', 'adjustment', 'return')),
  -- With no update/delete policy a wrong-signed row can only be offset, so
  -- refuse it at write time.
  constraint stock_movements_sign_matches_type_ck check (
    case movement_type
      when 'purchase'    then qty_milli > 0
      when 'opening'     then qty_milli > 0
      when 'consumption' then qty_milli < 0
      when 'wastage'     then qty_milli < 0
      when 'return'      then qty_milli < 0
      when 'adjustment'  then true
    end
  )
);

-- Idempotency: a retried save or double-tap can't post the same invoice
-- line twice. With no delete policy this is the only guard across retries.
create unique index if not exists stock_movements_invoice_item_uq
  on public.stock_movements (invoice_item_id)
  where invoice_item_id is not null;

create index if not exists stock_movements_biz_item_date
  on public.stock_movements (business_id, item_id, occurred_on desc);
create index if not exists stock_movements_biz_date
  on public.stock_movements (business_id, occurred_on desc);


-- ── 3. Learned invoice-description → item mappings ────────────
create table if not exists public.item_aliases (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  item_id uuid not null
    references public.inventory_items (id) on delete cascade,
  alias text not null,                     -- vendor description, verbatim
  vendor_name text,
  hsn text,
  hit_count int not null default 1,
  created_at timestamptz not null default now()
);
-- Unique on (business, alias), NOT including item_id: one vendor string must
-- resolve to exactly one item. Re-mapping overwrites item_id.
create unique index if not exists item_aliases_biz_alias
  on public.item_aliases (business_id, lower(btrim(alias)));
create index if not exists item_aliases_item
  on public.item_aliases (item_id);


-- ── 4. Close the FK section 9 left dangling ───────────────────
do $$ begin
  alter table public.purchase_invoice_items
    add constraint purchase_invoice_items_inventory_item_fk
    foreign key (inventory_item_id)
    references public.inventory_items (id) on delete set null;
exception when duplicate_object then null; end $$;


-- ── 5. Views (security_invoker so underlying RLS applies) ─────
create or replace view public.v_stock_on_hand
  with (security_invoker = true) as
select
  i.id            as item_id,
  i.business_id,
  i.name,
  i.dimension,
  i.display_unit,
  i.category,
  i.reorder_level_milli,
  coalesce(sum(m.qty_milli), 0)::bigint as on_hand_milli,
  coalesce(sum(m.qty_milli) filter
    (where m.movement_type in ('purchase', 'opening')), 0)::bigint as in_milli,
  coalesce(-sum(m.qty_milli) filter
    (where m.movement_type in ('consumption', 'wastage')), 0)::bigint as out_milli,
  max(m.occurred_on) filter (where m.movement_type = 'purchase')    as last_in_on,
  max(m.occurred_on) filter (where m.movement_type = 'consumption') as last_out_on
from public.inventory_items i
left join public.stock_movements m on m.item_id = i.id
where i.archived = false
group by i.id;

-- Weighted average cost. NUMERIC, never rounded here: atta at ₹40/kg is
-- 0.004 paise/mg, which an integer column would store as 0. Reads the
-- owner-only purchase table, so a chef selecting this gets zero rows.
create or replace view public.v_item_wac
  with (security_invoker = true) as
select
  pii.business_id,
  pii.inventory_item_id as item_id,
  sum(pii.line_total_paise)::bigint as spent_paise,
  sum(pii.qty_milli)::bigint        as qty_milli,
  sum(pii.line_total_paise)::numeric / nullif(sum(pii.qty_milli), 0)
    as paise_per_milli
from public.purchase_invoice_items pii
where pii.inventory_item_id is not null and pii.qty_milli > 0
group by 1, 2;

-- On-hand valued at WAC. INNER JOIN so an item with only opening stock (no
-- purchase cost) is absent rather than valued at ₹0 — the UI reports those
-- as "not valued".
create or replace view public.v_stock_value
  with (security_invoker = true) as
select
  s.business_id, s.item_id, s.name, s.dimension, s.display_unit,
  s.on_hand_milli, w.paise_per_milli,
  round(s.on_hand_milli * w.paise_per_milli)::bigint as value_paise
from public.v_stock_on_hand s
join public.v_item_wac w on w.item_id = s.item_id;

-- Monthly consumption, aggregated server-side — never sum the ledger in
-- Dart (PostgREST caps at 1000 rows → silently wrong from ~week 5).
create or replace view public.v_consumption_by_month
  with (security_invoker = true) as
select
  m.business_id, m.item_id, i.name, i.dimension, i.display_unit,
  to_char(m.occurred_on, 'YYYY-MM') as month,
  coalesce(-sum(m.qty_milli) filter
    (where m.movement_type = 'consumption'), 0)::bigint as consumed_milli,
  coalesce(-sum(m.qty_milli) filter
    (where m.movement_type = 'wastage'), 0)::bigint as wasted_milli
from public.stock_movements m
join public.inventory_items i on i.id = m.item_id
where m.movement_type in ('consumption', 'wastage')
group by 1, 2, 3, 4, 5, 6;

grant select on
  public.v_stock_on_hand, public.v_item_wac,
  public.v_stock_value, public.v_consumption_by_month
  to authenticated;


-- ── 6. RLS ────────────────────────────────────────────────────
alter table public.inventory_items enable row level security;
alter table public.stock_movements enable row level security;
alter table public.item_aliases    enable row level security;

-- inventory_items: all members read/insert/update (a chef creates items
-- mid-count and sets reorder levels). No money here, so nothing leaks.
-- DELETE is owner-only.
drop policy if exists inv_items_read on public.inventory_items;
create policy inv_items_read on public.inventory_items for select
  using (business_id in (select public.my_business_ids()));
drop policy if exists inv_items_insert on public.inventory_items;
create policy inv_items_insert on public.inventory_items for insert
  with check (business_id in (select public.my_business_ids()));
drop policy if exists inv_items_update on public.inventory_items;
create policy inv_items_update on public.inventory_items for update
  using (business_id in (select public.my_business_ids()))
  with check (business_id in (select public.my_business_ids()));
drop policy if exists inv_items_delete on public.inventory_items;
create policy inv_items_delete on public.inventory_items for delete
  using (business_id in (select public.my_owner_business_ids()));

-- stock_movements: SELECT + INSERT ONLY. The ABSENCE of update/delete is
-- the append-only guarantee — even an owner cannot edit a row. Insert
-- forces created_by = auth.uid() so attribution can't be forged.
drop policy if exists stock_mov_read on public.stock_movements;
create policy stock_mov_read on public.stock_movements for select
  using (business_id in (select public.my_business_ids()));
drop policy if exists stock_mov_insert on public.stock_movements;
create policy stock_mov_insert on public.stock_movements for insert
  with check (business_id in (select public.my_business_ids())
              and created_by = auth.uid());

drop policy if exists item_aliases_read on public.item_aliases;
create policy item_aliases_read on public.item_aliases for select
  using (business_id in (select public.my_business_ids()));
drop policy if exists item_aliases_insert on public.item_aliases;
create policy item_aliases_insert on public.item_aliases for insert
  with check (business_id in (select public.my_business_ids()));
drop policy if exists item_aliases_update on public.item_aliases;
create policy item_aliases_update on public.item_aliases for update
  using (business_id in (select public.my_business_ids()))
  with check (business_id in (select public.my_business_ids()));


-- ── 7. Stock-aware purchase save ──────────────────────────────
-- Superset of save_purchase_invoice: additionally resolves each line to an
-- inventory item (existing id, or create-by-name), posts a `purchase`
-- movement, and learns the alias — all in ONE transaction, so a bill can
-- never half-post. The old RPC is kept so an older client build still works.
--
-- Each element of p_items may carry, beyond the finance fields:
--   inventory_item_id  uuid  -- map to this existing item
--   new_item_name      text  -- else create/find an item with this name
--   track_stock        bool  -- false → expense only, no movement
-- A line posts stock only when it resolves to an item AND qty_milli > 0.
create or replace function public.save_purchase_invoice_with_stock(
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
  it record;
  v_item_id uuid;
  v_pii_id uuid;
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

  for it in
    select * from jsonb_to_recordset(p_items) as x(
      description       text,
      hsn               text,
      qty_milli         bigint,
      dimension         text,
      display_unit      text,
      unit_price_paise  bigint,
      line_total_paise  bigint,
      category          text,
      confidence        numeric,
      inventory_item_id uuid,
      new_item_name     text,
      track_stock       boolean
    )
  loop
    -- Resolve the inventory item, if this line is tracked.
    v_item_id := null;
    if coalesce(it.track_stock, false)
       and it.qty_milli is not null and it.qty_milli > 0
       and it.dimension is not null and it.display_unit is not null then

      if it.inventory_item_id is not null then
        v_item_id := it.inventory_item_id;
      elsif it.new_item_name is not null and btrim(it.new_item_name) <> '' then
        insert into public.inventory_items
          (business_id, name, dimension, display_unit, category)
        values
          (p_business_id, btrim(it.new_item_name), it.dimension,
           it.display_unit, it.category)
        on conflict (business_id, lower(btrim(name))) do nothing;

        select id into v_item_id from public.inventory_items
         where business_id = p_business_id
           and lower(btrim(name)) = lower(btrim(it.new_item_name))
         limit 1;
      end if;
    end if;

    -- Line detail (cost lives here — owner-only), linked to the item.
    insert into public.purchase_invoice_items (
      business_id, invoice_id, description, hsn, qty_milli, dimension,
      display_unit, unit_price_paise, line_total_paise, category,
      confidence, inventory_item_id
    ) values (
      p_business_id, v_invoice_id, it.description, it.hsn, it.qty_milli,
      it.dimension, it.display_unit, it.unit_price_paise, it.line_total_paise,
      it.category, it.confidence, v_item_id
    )
    returning id into v_pii_id;

    if v_item_id is not null then
      -- Stock in.
      insert into public.stock_movements (
        business_id, item_id, movement_type, qty_milli,
        occurred_on, invoice_item_id
      ) values (
        p_business_id, v_item_id, 'purchase', it.qty_milli,
        coalesce(p_occurred_at::date,
                 (now() at time zone 'Asia/Kolkata')::date),
        v_pii_id
      )
      on conflict (invoice_item_id) do nothing;

      -- Learn the mapping for next time.
      insert into public.item_aliases
        (business_id, item_id, alias, vendor_name, hsn)
      values
        (p_business_id, v_item_id, btrim(it.description), p_vendor, it.hsn)
      on conflict (business_id, lower(btrim(alias))) do update
        set item_id = excluded.item_id,
            hit_count = public.item_aliases.hit_count + 1;
    end if;
  end loop;

  -- One expense row per category — byte-identical to the old flow, so the
  -- P&L is unchanged.
  insert into public.transactions (
    business_id, type, category, amount_paise, occurred_at, payment_mode,
    party_name, notes, source, event_id, attachment_path, source_invoice_id
  )
  select
    p_business_id, 'expense', x.category, sum(x.line_total_paise),
    coalesce(p_occurred_at, now()), p_payment_mode, p_party,
    coalesce(p_invoice_no, 'Invoice') || E'\n' ||
      string_agg('• ' || x.description, E'\n' order by x.description),
    'screenshot', p_event_id, p_attachment, v_invoice_id
  from jsonb_to_recordset(p_items) as x(
    description text, line_total_paise bigint, category text
  )
  group by x.category;

  return v_invoice_id;
end;
$$;


-- ── 8. Verify ─────────────────────────────────────────────────
select tablename, rowsecurity from pg_tables
 where schemaname = 'public'
   and tablename in ('inventory_items', 'stock_movements', 'item_aliases')
 order by tablename;

select viewname from pg_views
 where schemaname = 'public' and viewname like 'v_%'
 order by viewname;
