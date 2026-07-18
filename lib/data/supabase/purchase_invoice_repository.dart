import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/quantity.dart';
import '../../features/screenshot/ai_parsed_invoice.dart';

/// Persists a scanned invoice: the invoice header, its line items, and the
/// per-category expense rows.
///
/// All three go through a single `save_purchase_invoice` RPC so they land
/// in one database transaction. Three sequential client calls could leave a
/// half-saved invoice, and retrying after a partial failure would duplicate
/// the money rows.
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
  }) async {
    final payload = [
      for (final it in items) _itemJson(it),
    ];

    final id = await _client.rpc('save_purchase_invoice', params: {
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

  Map<String, dynamic> _itemJson(AiInvoiceItem it) {
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
    };
  }
}
