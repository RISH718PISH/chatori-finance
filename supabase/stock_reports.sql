-- ═══════════════════════════════════════════════════════════════
-- STOCK REPORTS — channel/wastage breakdowns and a "last moved" stamp.
-- Apply once (done via CLI). Mirrored into schema.sql §15.
-- ═══════════════════════════════════════════════════════════════

-- ── 1. "Last moved" on each item ──────────────────────────────
-- Recreate v_stock_on_hand with a single last_moved_on across ALL movement
-- types (the old last_in_on / last_out_on only covered purchase and
-- consumption), so the stock list can show when each item last changed.
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
  max(m.occurred_on) filter (where m.movement_type = 'consumption') as last_out_on,
  max(m.created_at) as last_moved_at
from public.inventory_items i
left join public.stock_movements m on m.item_id = i.id
where i.archived = false
group by i.id;

-- ── 2. Consumption by reason, per month, valued at WAC ────────
-- Channel breakdown the owner asked for (Zomato vs Swiggy vs Catering …).
create or replace view public.v_consumption_by_reason_month
  with (security_invoker = true) as
select
  m.business_id,
  to_char(m.occurred_on, 'YYYY-MM')       as month,
  coalesce(nullif(btrim(m.reason), ''), 'Unspecified') as reason,
  count(*)                                 as lines,
  (-sum(m.qty_milli))::bigint              as qty_milli,
  round(sum(-m.qty_milli * coalesce(w.paise_per_milli, 0)))::bigint
                                           as value_paise
from public.stock_movements m
left join public.v_item_wac w on w.item_id = m.item_id
where m.movement_type = 'consumption'
group by 1, 2, 3;

-- ── 3. Wastage per month, valued ──────────────────────────────
create or replace view public.v_wastage_by_month
  with (security_invoker = true) as
select
  m.business_id,
  to_char(m.occurred_on, 'YYYY-MM')       as month,
  coalesce(nullif(btrim(m.reason), ''), 'Unspecified') as reason,
  (-sum(m.qty_milli))::bigint              as qty_milli,
  round(sum(-m.qty_milli * coalesce(w.paise_per_milli, 0)))::bigint
                                           as value_paise
from public.stock_movements m
left join public.v_item_wac w on w.item_id = m.item_id
where m.movement_type = 'wastage'
group by 1, 2, 3;

grant select on
  public.v_consumption_by_reason_month, public.v_wastage_by_month
  to authenticated;

select 'stock reports applied' as status;
