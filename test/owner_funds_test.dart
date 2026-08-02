import 'package:chatori_finance/data/models/txn.dart';
import 'package:chatori_finance/features/reports/reports_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Owner capital (funds in / withdrawals out) must never touch income,
/// expense, or profit — only its own running total.
void main() {
  Txn t(String type, String category, int rupees) => Txn(
        id: '$category-$rupees',
        type: type,
        category: category,
        amountPaise: rupees * 100,
        occurredAt: DateTime(2026, 7, 3),
        paymentMode: 'UPI',
      );

  final txns = [
    t('income', 'Catering', 175000),
    t('expense', 'Veggies', 11500),
    t('income', "Owner's Funds", 50000), // capital in
    t('expense', "Owner's Withdrawal", 8000), // capital out
  ];

  test('Totals ignore owner capital', () {
    final tot = Totals.fromTxns(txns);
    expect(tot.incomePaise, 175000 * 100);
    expect(tot.expensePaise, 11500 * 100);
    expect(tot.netPaise, (175000 - 11500) * 100);
  });

  test('ownerFundsNetPaise nets funds in minus withdrawals', () {
    expect(ownerFundsNetPaise(txns), (50000 - 8000) * 100);
  });

  test('MonthlyPl keeps capital out of revenue and in its own bucket', () {
    final pl = MonthlyPl.fromTxns(txns);
    expect(pl.totalRevenue, 175000 * 100); // NOT 225000
    expect(pl.netProfit, (175000 - 11500) * 100);
    expect(pl.totalCapital, (50000 - 8000) * 100);
  });

  test('bucketize drops capital categories from breakdowns', () {
    final income = bucketize(txns, (t) => t.category, where: (t) => t.isIncome);
    expect(income.map((b) => b.label), ['Catering']);
  });
}
