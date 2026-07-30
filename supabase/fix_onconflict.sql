-- ═══════════════════════════════════════════════════════════════
-- FIX 42P10 on save_purchase_invoice_with_stock.
--
-- stock_movements_invoice_item_uq is a PARTIAL unique index
-- (... WHERE invoice_item_id is not null). ON CONFLICT that targets a
-- partial index MUST restate the same predicate, or Postgres raises
-- "no unique or exclusion constraint matching the ON CONFLICT
-- specification" and the whole save fails. Adds the WHERE clause.
--
-- Apply once (done via CLI). Mirrored into schema.sql §16.
-- ═══════════════════════════════════════════════════════════════
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
  security definer
  set search_path = public
as $$
declare
  v_invoice_id uuid;
  it record;
  v_item_id uuid;
  v_pii_id uuid;
begin
  if p_business_id not in (
    select business_id from public.business_members where user_id = auth.uid()
  ) then
    raise exception 'Not a member of that business';
  end if;

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
      insert into public.stock_movements (
        business_id, item_id, movement_type, qty_milli,
        occurred_on, invoice_item_id, cost_paise, created_by
      ) values (
        p_business_id, v_item_id, 'purchase', it.qty_milli,
        coalesce(p_occurred_at::date,
                 (now() at time zone 'Asia/Kolkata')::date),
        v_pii_id, it.line_total_paise, auth.uid()
      )
      -- Restate the partial index predicate so ON CONFLICT can infer it.
      on conflict (invoice_item_id) where invoice_item_id is not null
        do nothing;

      insert into public.item_aliases
        (business_id, item_id, alias, vendor_name, hsn)
      values
        (p_business_id, v_item_id, btrim(it.description), p_vendor, it.hsn)
      on conflict (business_id, lower(btrim(alias))) do update
        set item_id = excluded.item_id,
            hit_count = public.item_aliases.hit_count + 1;
    end if;
  end loop;

  insert into public.transactions (
    business_id, type, category, amount_paise, occurred_at, payment_mode,
    party_name, notes, source, event_id, attachment_path, source_invoice_id,
    created_by
  )
  select
    p_business_id, 'expense', x.category, sum(x.line_total_paise),
    coalesce(p_occurred_at, now()), p_payment_mode, p_party,
    coalesce(p_invoice_no, 'Invoice') || E'\n' ||
      string_agg('• ' || x.description, E'\n' order by x.description),
    'screenshot', p_event_id, p_attachment, v_invoice_id, auth.uid()
  from jsonb_to_recordset(p_items) as x(
    description text, line_total_paise bigint, category text
  )
  group by x.category;

  return v_invoice_id;
end;
$$;

select 'onconflict fix applied' as status;
