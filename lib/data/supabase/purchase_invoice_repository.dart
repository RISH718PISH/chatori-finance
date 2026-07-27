import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/quantity.dart';
import '../../features/screenshot/ai_parsed_invoice.dart';

/// How one invoice line should affect stock, decided on the review screen.
class StockTarget {
  /// Map to this existing catalogue item.
  final String? inventoryItemId;

  /// Else create/find an item with this name.
  final String? newItemName;

  /// False → expense only, no stock movement.
  final bool track;

  const StockTarget.matched(String this.inventoryItemId)
      : newItemName = null,
        track = true;
  const StockTarget.create(String this.newItemName)
      : inventoryItemId = null,
        track = true;
  const StockTarget.untracked()
      : inventoryItemId = null,
        newItemName = null,
        track = false;
}

/// Persists a scanned invoice: the invoice header, its line items, the
/// per-category expense rows, and — when [stockTargets] is given — the
/// inventory items and stock movements.
///
/// Everything goes through a single RPC so it lands in one database
/// transaction. Three sequential client calls could leave a half-saved
/// invoice, and a retry after a partial failure would duplicate the money
/// rows or double-count stock.
class PurchaseInvoiceRepository {
  PurchaseInvoiceRepository(this._client);
  final SupabaseClient _client;

  Future<String> save({
    required String businessId,
    required AiParsedInvoice invoice,
    required List<AiInvoiceItem> items,
    required String paymentMode,
    required DateTime occurredAt,
    String? partyName,
    String? eventId,
    String? attachmentPath,
    List<StockTarget>? stockTargets,
  }) async {
    final withStock = stockTargets != null;
    final payload = [
      for (var i = 0; i < items.length; i++)
        _itemJson(items[i], withStock ? stockTargets[i] : null),
    ];

    // The stock-aware RPC is a superset; call it only when we have targets
    // so an older backend without it still works for a plain save.
    final rpc =
        withStock ? 'save_purchase_invoice_with_stock' : 'save_purchase_invoice';

    final id = await _client.rpc(rpc, params: {
      'p_business_id': businessId,
      'p_vendor': invoice.vendorName,
      'p_invoice_no': invoice.invoiceNumber,
      'p_invoice_date': invoice.invoiceDate?.toIso8601String().substring(0, 10),
      'p_subtotal': invoice.subtotalPaise,
      'p_tax': invoice.taxPaise,
      'p_total': invoice.totalPaise,
      'p_attachment': attachmentPath,
      'p_raw_json': null,
      'p_parse_source': invoice.isFallback ? 'fallback' : 'ai',
      'p_items': payload,
      'p_payment_mode': paymentMode,
      'p_party': partyName,
      'p_event_id': eventId,
      'p_occurred_at': occurredAt.toUtc().toIso8601String(),
    });

    return id as String;
  }

  Map<String, dynamic> _itemJson(AiInvoiceItem it, StockTarget? target) {
    // Quantity is stored as integer milli-units so that buying in kg and
    // consuming in g reconcile exactly. When the unit is unreadable we
    // store nulls rather than guessing a dimension.
    final parsed = parseQuantity(it.qty, it.unit);
    return {
      'description': it.description,
      'hsn': it.hsn,
      'qty_milli': parsed?.milli,
      'dimension': parsed?.dimension.name,
      'display_unit': parsed?.displayUnit,
      'unit_price_paise': it.unitPricePaise,
      'line_total_paise': it.amountPaise,
      'category': it.category,
      'confidence': it.confidence,
      if (target != null) ...{
        'inventory_item_id': target.inventoryItemId,
        'new_item_name': target.newItemName,
        // A line with no parsed quantity can't post to stock regardless of
        // the user's choice — guard it here too.
        'track_stock': target.track && parsed != null,
      },
    };
  }
}
