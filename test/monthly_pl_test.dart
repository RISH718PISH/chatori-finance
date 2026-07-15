import 'package:chatori_finance/data/models/txn.dart';
import 'package:chatori_finance/features/reports/reports_providers.dart';
import 'package:flutter_test/flutter_test.dart';

Txn _txn(String type, String category, int paise) => Txn(
      id: category + paise.toString(),
      type: type,
      category: category,
      amountPaise: paise,
      occurredAt: DateTime(2026, 7, 10),
      paymentMode: 'Cash',
    );

void main() {
  test('MonthlyPl splits revenue / COGS / operating and computes margins', () {
    final pl = MonthlyPl.fromTxns([
      _txn('income', 'Catering', 100000 * 100), // ₹1,00,000
      _txn('income', 'Cloud Kitchen', 20000 * 100),
      _txn('expense', 'Groceries', 30000 * 100), // COGS
      _txn('expense', 'Veggies', 10000 * 100), // COGS
      _txn('expense', 'Salaries', 25000 * 100), // operating
      _txn('expense', 'Rent', 15000 * 100), // operating
    ]);

    expect(pl.totalRevenue, 120000 * 100);
    expect(pl.totalCogs, 40000 * 100);
    expect(pl.totalOperating, 40000 * 100);
    expect(pl.grossProfit, 80000 * 100);
    expect(pl.netProfit, 40000 * 100);
    expect(pl.grossMarginPct, closeTo(66.67, 0.01));
    expect(pl.netMarginPct, closeTo(33.33, 0.01));
    expect(pl.foodCostPct, closeTo(33.33, 0.01));
  });

  test('unknown categories default to operating (expense) / revenue (income)',
      () {
    final pl = MonthlyPl.fromTxns([
      _txn('income', 'Some Custom Income', 1000),
      _txn('expense', 'Some Custom Expense', 500),
    ]);
    expect(pl.totalRevenue, 1000);
    expect(pl.totalOperating, 500);
    expect(pl.totalCogs, 0);
  });

  test('empty month produces zeroes without dividing by zero', () {
    final pl = MonthlyPl.fromTxns(const []);
    expect(pl.netProfit, 0);
    expect(pl.grossMarginPct, 0);
    expect(pl.foodCostPct, 0);
  });

  test('salary from the separate ledger folds into operating and net', () {
    // Salaries are NOT transactions; they arrive via salaryForMonthPaise.
    final pl = MonthlyPl.fromTxns(
      [
        _txn('income', 'Catering', 100000 * 100),
        _txn('expense', 'Groceries', 30000 * 100), // COGS
        _txn('expense', 'Rent', 15000 * 100), // operating
      ],
      salaryForMonthPaise: 25000 * 100, // full salary (cash + advance adj.)
    );

    expect(pl.totalRevenue, 100000 * 100);
    expect(pl.totalCogs, 30000 * 100);
    // Rent ₹15,000 + injected Salaries ₹25,000 = ₹40,000 operating.
    expect(pl.totalOperating, 40000 * 100);
    // Net = 100000 - 30000 - 40000 = ₹30,000. Without the salary fold-in
    // this used to read ₹55,000 — the bug the owner spotted.
    expect(pl.netProfit, 30000 * 100);
    final salaries =
        pl.operating.firstWhere((b) => b.label == 'Salaries');
    expect(salaries.paise, 25000 * 100);
  });

  test('injected salary merges with a manual Salaries transaction (no dup)',
      () {
    final pl = MonthlyPl.fromTxns(
      [_txn('expense', 'Salaries', 10000 * 100)],
      salaryForMonthPaise: 25000 * 100,
    );
    // One combined Salaries line, summed — not two separate lines.
    final salaryLines =
        pl.operating.where((b) => b.label == 'Salaries').toList();
    expect(salaryLines.length, 1);
    expect(salaryLines.single.paise, 35000 * 100);
  });
}
