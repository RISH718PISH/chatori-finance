import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/quantity.dart';
import '../models/inventory.dart';

/// Everything a member (owner or chef) may touch: the catalogue, the
/// append-only movement ledger, on-hand quantities, and aliases.
///
/// Money never appears here. Valuation lives in
/// [InventoryValuationRepository], which reads owner-only views — keeping
/// the two apart makes "who can see cost" a single auditable boundary.
class InventoryRepository {
  InventoryRepository(this._client);
  final SupabaseClient _client;

  // ── Catalogue ────────────────────────────────────────────────
  Future<List<InventoryItem>> fetchItems(String businessId) async {
    final rows = await _client
        .from('inventory_items')
        .select()
        .eq('business_id', businessId)
        .eq('archived', false)
        .order('name');
    return rows.map(InventoryItem.fromJson).toList();
  }

  Future<String> createItem({
    required String businessId,
    required String name,
    required QtyDimension dimension,
    required String displayUnit,
    String? category,
    int reorderLevelMilli = 0,
  }) async {
    final row = await _client
        .from('inventory_items')
        .insert({
          'business_id': businessId,
          'name': name.trim(),
          'dimension': dimension.name,
          'display_unit': displayUnit,
          'category': category,
          'reorder_level_milli': reorderLevelMilli,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateItem({
    required String id,
    String? name,
    String? displayUnit,
    String? category,
    int? reorderLevelMilli,
    bool? archived,
  }) async {
    await _client.from('inventory_items').update({
      if (name != null) 'name': name.trim(),
      'display_unit': ?displayUnit,
      'category': ?category,
      'reorder_level_milli': ?reorderLevelMilli,
      'archived': ?archived,
    }).eq('id', id);
  }

  // ── On-hand (server-computed view) ───────────────────────────
  Future<List<StockOnHand>> fetchOnHand(String businessId) async {
    final rows = await _client
        .from('v_stock_on_hand')
        .select()
        .eq('business_id', businessId)
        .order('name');
    return rows.map(StockOnHand.fromJson).toList();
  }

  // ── Movement ledger ──────────────────────────────────────────
  /// Server-filtered by item — never fetch the whole ledger and slice in
  /// Dart; at ~25k rows/yr PostgREST would truncate at 1000 and the balance
  /// would silently drift.
  Future<List<StockMovement>> fetchMovements(String itemId,
      {int limit = 100}) async {
    final rows = await _client
        .from('stock_movements')
        .select()
        .eq('item_id', itemId)
        .order('occurred_on', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(StockMovement.fromJson).toList();
  }

  /// Records one movement. The DB rejects a sign that contradicts the type,
  /// so callers pass an already-signed [qtyMilli].
  Future<void> addMovement({
    required String businessId,
    required String itemId,
    required StockMovementType type,
    required int qtyMilli,
    DateTime? occurredOn,
    String? note,
    String? eventId,
    int? costPaise,
    String? reason,
  }) async {
    await _client.from('stock_movements').insert({
      'business_id': businessId,
      'item_id': itemId,
      'movement_type': type.dbValue,
      'qty_milli': qtyMilli,
      if (occurredOn != null)
        'occurred_on': occurredOn.toIso8601String().substring(0, 10),
      'note': note,
      'event_id': eventId,
      'cost_paise': costPaise,
      'reason': reason,
      // created_by defaults to auth.uid() in the DB and is pinned there by
      // the insert policy, so it is deliberately not sent from the client.
    });
  }

  /// Batch insert for the daily-consumption and opening-count screens: one
  /// round trip for the whole kitchen.
  Future<void> addMovements(
      List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('stock_movements').insert(rows);
  }

  // ── Aliases ──────────────────────────────────────────────────
  Future<List<ItemAlias>> fetchAliases(String businessId) async {
    final rows = await _client
        .from('item_aliases')
        .select('id, item_id, alias, vendor_name, hsn')
        .eq('business_id', businessId);
    return rows.map(ItemAlias.fromJson).toList();
  }

  /// Point an alias at a different item — the recovery path when a bill
  /// mapped a line to the wrong product.
  Future<void> remapAlias({
    required String businessId,
    required String alias,
    required String itemId,
  }) async {
    await _client.from('item_aliases').upsert({
      'business_id': businessId,
      'alias': alias.trim(),
      'item_id': itemId,
    }, onConflict: 'business_id, alias');
  }
}

/// Lightweight alias row for the in-Dart matcher.
class ItemAlias {
  final String id;
  final String itemId;
  final String alias;
  final String? vendorName;
  final String? hsn;

  const ItemAlias({
    required this.id,
    required this.itemId,
    required this.alias,
    this.vendorName,
    this.hsn,
  });

  factory ItemAlias.fromJson(Map<String, dynamic> j) => ItemAlias(
        id: j['id'] as String,
        itemId: j['item_id'] as String,
        alias: j['alias'] as String,
        vendorName: j['vendor_name'] as String?,
        hsn: j['hsn'] as String?,
      );
}
