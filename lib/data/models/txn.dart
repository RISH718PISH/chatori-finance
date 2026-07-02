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
  });

  bool get isIncome => type == 'income';

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
