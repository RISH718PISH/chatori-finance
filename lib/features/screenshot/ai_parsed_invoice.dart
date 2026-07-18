/// Structured result of the `parse-invoice` Edge Function.
///
/// Unlike [ParsedHyperpure] (the legacy on-device path, kept only as an
/// offline fallback), this carries per-item quantity and unit — the data
/// the Inventory module needs and which the old pipeline discarded at the
/// database boundary.
library;

class AiInvoiceItem {
  final String description;
  final String? hsn;
  final double? qty;
  final String? unit; // kg | g | l | ml | pcs | dozen | packet
  final int? unitPricePaise;
  final int amountPaise;
  final String category;

  /// 0..1 as reported by the model. Below [lowConfidenceThreshold] the row
  /// is surfaced for human review rather than trusted silently.
  final double confidence;

  const AiInvoiceItem({
    required this.description,
    required this.amountPaise,
    required this.category,
    this.hsn,
    this.qty,
    this.unit,
    this.unitPricePaise,
    this.confidence = 1.0,
  });

  static const double lowConfidenceThreshold = 0.7;

  bool get isLowConfidence => confidence < lowConfidenceThreshold;

  /// "2 kg" / "500 g" / "3 pcs" — empty when quantity wasn't readable.
  String get qtyLabel {
    if (qty == null) return '';
    final n = qty! % 1 == 0 ? qty!.toInt().toString() : qty!.toString();
    return unit == null ? n : '$n $unit';
  }

  /// Sentinel so `qty` and `unit` can be explicitly cleared. A plain
  /// `qty ?? this.qty` would make it impossible to set them back to null —
  /// which the review screen needs when the user picks the "—" unit or
  /// empties the quantity field.
  static const Object _unset = Object();

  AiInvoiceItem copyWith({
    String? description,
    Object? qty = _unset,
    Object? unit = _unset,
    int? amountPaise,
    String? category,
  }) =>
      AiInvoiceItem(
        description: description ?? this.description,
        hsn: hsn,
        qty: identical(qty, _unset) ? this.qty : qty as double?,
        unit: identical(unit, _unset) ? this.unit : unit as String?,
        unitPricePaise: unitPricePaise,
        amountPaise: amountPaise ?? this.amountPaise,
        category: category ?? this.category,
        confidence: confidence,
      );

  factory AiInvoiceItem.fromJson(Map<String, dynamic> j) => AiInvoiceItem(
        description: (j['description'] as String?)?.trim() ?? '',
        hsn: j['hsn'] as String?,
        qty: (j['qty'] as num?)?.toDouble(),
        unit: j['unit'] as String?,
        unitPricePaise: (j['unit_price_paise'] as num?)?.toInt(),
        amountPaise: (j['amount_paise'] as num?)?.toInt() ?? 0,
        category: (j['suggested_category'] as String?) ?? 'Groceries',
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.5,
      );
}

/// Reconciliation between the sum of parsed items and the invoice total.
///
/// [totalUnknown] is deliberately distinct from a zero [differencePaise].
/// The legacy screen conflated the two — it defaulted the grand total to
/// the item sum, which made the difference structurally zero and meant no
/// warning could ever fire in exactly the case where parsing had failed
/// worst.
class InvoiceReconciliation {
  final int itemsSumPaise;
  final bool totalUnknown;
  final int? differencePaise;
  final bool balanced;

  const InvoiceReconciliation({
    required this.itemsSumPaise,
    required this.totalUnknown,
    required this.differencePaise,
    required this.balanced,
  });

  bool get isShort => (differencePaise ?? 0) > 0;

  factory InvoiceReconciliation.fromJson(Map<String, dynamic> j) =>
      InvoiceReconciliation(
        itemsSumPaise: (j['items_sum_paise'] as num?)?.toInt() ?? 0,
        totalUnknown: j['total_unknown'] as bool? ?? true,
        differencePaise: (j['difference_paise'] as num?)?.toInt(),
        balanced: j['balanced'] as bool? ?? false,
      );
}

class AiParsedInvoice {
  final String? vendorName;
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final int? subtotalPaise;
  final int? taxPaise;
  final int? totalPaise;
  final List<AiInvoiceItem> items;
  final InvoiceReconciliation reconciliation;

  /// True when this came from the legacy on-device parser because the
  /// Edge Function was unreachable. Drives the "review carefully" banner.
  final bool isFallback;

  const AiParsedInvoice({
    required this.items,
    required this.reconciliation,
    this.vendorName,
    this.invoiceNumber,
    this.invoiceDate,
    this.subtotalPaise,
    this.taxPaise,
    this.totalPaise,
    this.isFallback = false,
  });

  int get lowConfidenceCount =>
      items.where((i) => i.isLowConfidence).length;

  factory AiParsedInvoice.fromJson(Map<String, dynamic> j,
      {bool isFallback = false}) {
    final rawDate = j['invoice_date'] as String?;
    return AiParsedInvoice(
      vendorName: j['vendor_name'] as String?,
      invoiceNumber: j['invoice_number'] as String?,
      invoiceDate:
          rawDate == null ? null : DateTime.tryParse(rawDate),
      subtotalPaise: (j['subtotal_paise'] as num?)?.toInt(),
      taxPaise: (j['tax_paise'] as num?)?.toInt(),
      totalPaise: (j['total_paise'] as num?)?.toInt(),
      items: [
        for (final it in (j['items'] as List? ?? const []))
          AiInvoiceItem.fromJson(it as Map<String, dynamic>),
      ],
      reconciliation: InvoiceReconciliation.fromJson(
          (j['reconciliation'] as Map<String, dynamic>?) ?? const {}),
      isFallback: isFallback,
    );
  }
}
