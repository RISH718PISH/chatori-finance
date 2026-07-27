import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory.dart';

/// Reads the money side of inventory — stock value and monthly consumption
/// valued at cost.
///
/// Kept in its own class ON PURPOSE. Every query here hits a view that
/// reads the owner-only `purchase_invoice_items`, so for a chef these
/// return zero rows at the database. Isolating them means "which calls can
/// expose a rupee" is answered by one file, not scattered through a mixed
/// repository.
class InventoryValuationRepository {
  InventoryValuationRepository(this._client);
  final SupabaseClient _client;

  Future<List<StockValue>> fetchStockValue(String businessId) async {
    final rows = await _client
        .from('v_stock_value')
        .select()
        .eq('business_id', businessId);
    return rows.map(StockValue.fromJson).toList();
  }

  /// Consumption + wastage for one YYYY-MM, per item.
  Future<List<ConsumptionRow>> fetchConsumption({
    required String businessId,
    required String month,
  }) async {
    final rows = await _client
        .from('v_consumption_by_month')
        .select()
        .eq('business_id', businessId)
        .eq('month', month);
    return rows.map(ConsumptionRow.fromJson).toList();
  }

  /// Consumption grouped by reason (Zomato / Swiggy / Catering …), valued.
  Future<List<ReasonValue>> fetchConsumptionByReason({
    required String businessId,
    required String month,
  }) async {
    final rows = await _client
        .from('v_consumption_by_reason_month')
        .select()
        .eq('business_id', businessId)
        .eq('month', month);
    return rows.map(ReasonValue.fromJson).toList();
  }

  /// Wastage grouped by reason for the month, valued.
  Future<List<ReasonValue>> fetchWastageByReason({
    required String businessId,
    required String month,
  }) async {
    final rows = await _client
        .from('v_wastage_by_month')
        .select()
        .eq('business_id', businessId)
        .eq('month', month);
    return rows.map(ReasonValue.fromJson).toList();
  }
}
