/// Plain transaction model backed by the Supabase `transactions` table.
class Txn {
  final String id;
  final String type; // income | expense
  final String category;
  final int amountPaise;
  final DateTime occurredAt;
  final String paymentMode;
  final String? partyName;
  final String? notes;
  final String? tag;
  final String source;
  final String? eventId;
  final String? attachmentPath;

  /// When [paymentMode] == 'Cash+UPI', these hold the split.
  /// Invariant: cashPaise + upiPaise == amountPaise. Null on non-split rows.
  final int? cashPaise;
  final int? upiPaise;

  const Txn({
    required this.id,
    required this.type,
    required this.category,
    required this.amountPaise,
    required this.occurredAt,
    required this.paymentMode,
    this.partyName,
    this.notes,
    this.tag,
    this.source = 'manual',
    this.eventId,
    this.attachmentPath,
    this.cashPaise,
    this.upiPaise,
  });

  bool get isSplit => paymentMode == 'Cash+UPI';

  bool get isIncome => type == 'income';

  /// How much of this transaction was paid in cash — 0 for pure-UPI/Bank/etc,
  /// full amount for cash, the cash slice for a split. Used by report buckets.
  int get cashPortionPaise {
    if (isSplit) return cashPaise ?? 0;
    return paymentMode == 'Cash' ? amountPaise : 0;
  }

  /// Complement of [cashPortionPaise] — everything non-cash counts as digital.
  int get digitalPortionPaise => amountPaise - cashPortionPaise;

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        type: j['type'] as String,
        category: j['category'] as String,
        amountPaise: (j['amount_paise'] as num).toInt(),
        occurredAt: DateTime.parse(j['occurred_at'] as String).toLocal(),
        paymentMode: j['payment_mode'] as String,
        partyName: j['party_name'] as String?,
        notes: j['notes'] as String?,
        tag: j['tag'] as String?,
        source: (j['source'] as String?) ?? 'manual',
        eventId: j['event_id'] as String?,
        attachmentPath: j['attachment_path'] as String?,
        cashPaise: (j['cash_paise'] as num?)?.toInt(),
        upiPaise: (j['upi_paise'] as num?)?.toInt(),
      );
}

/// Aggregated income/expense for a period (values in paise).
class Totals {
  final int incomePaise;
  final int expensePaise;
  const Totals(this.incomePaise, this.expensePaise);

  int get netPaise => incomePaise - expensePaise;
  static const zero = Totals(0, 0);

  factory Totals.fromTxns(Iterable<Txn> txns) {
    var income = 0;
    var expense = 0;
    for (final t in txns) {
      if (t.isIncome) {
        income += t.amountPaise;
      } else {
        expense += t.amountPaise;
      }
    }
    return Totals(income, expense);
  }
}
