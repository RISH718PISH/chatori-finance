import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categories.dart';
import '../../data/models/bucket.dart';
import '../../data/models/txn.dart';
import '../transaction/transaction_providers.dart';

export '../../data/models/bucket.dart';

/// The month currently shown in Reports (first day of the month).
class SelectedReportMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void prev() => state = DateTime(state.year, state.month - 1);
  void next() => state = DateTime(state.year, state.month + 1);
}

final selectedReportMonthProvider =
    NotifierProvider<SelectedReportMonth, DateTime>(SelectedReportMonth.new);

/// Transactions for the selected report month.
final monthTxnsProvider = FutureProvider.autoDispose<List<Txn>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  final month = ref.watch(selectedReportMonthProvider);
  return ref.watch(transactionRepoProvider).fetchForMonth(biz, month);
});

/// Transactions for the month before the selected one (for MoM deltas).
final prevMonthTxnsProvider =
    FutureProvider.autoDispose<List<Txn>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  final month = ref.watch(selectedReportMonthProvider);
  return ref
      .watch(transactionRepoProvider)
      .fetchForMonth(biz, DateTime(month.year, month.month - 1));
});

/// Structured monthly P&L computed from one month's transactions.
class MonthlyPl {
  final List<Bucket> revenue;
  final List<Bucket> cogs;
  final List<Bucket> operating;

  const MonthlyPl({
    required this.revenue,
    required this.cogs,
    required this.operating,
  });

  int get totalRevenue => revenue.fold(0, (s, b) => s + b.paise);
  int get totalCogs => cogs.fold(0, (s, b) => s + b.paise);
  int get totalOperating => operating.fold(0, (s, b) => s + b.paise);
  int get grossProfit => totalRevenue - totalCogs;
  int get netProfit => grossProfit - totalOperating;

  double get grossMarginPct =>
      totalRevenue == 0 ? 0 : grossProfit / totalRevenue * 100;
  double get netMarginPct =>
      totalRevenue == 0 ? 0 : netProfit / totalRevenue * 100;

  /// COGS ÷ revenue. Above ~40% is a red flag for a kitchen.
  double get foodCostPct =>
      totalRevenue == 0 ? 0 : totalCogs / totalRevenue * 100;

  factory MonthlyPl.fromTxns(Iterable<Txn> txns) {
    final rev = <String, int>{};
    final cog = <String, int>{};
    final op = <String, int>{};
    for (final t in txns) {
      final section = plSectionFor(t.category, isIncome: t.isIncome);
      final map = switch (section) {
        PlSection.revenue => rev,
        PlSection.cogs => cog,
        PlSection.operating => op,
      };
      map.update(t.category, (v) => v + t.amountPaise,
          ifAbsent: () => t.amountPaise);
    }
    List<Bucket> sorted(Map<String, int> m) {
      final list = m.entries.map((e) => Bucket(e.key, e.value)).toList();
      list.sort((a, b) => b.paise.compareTo(a.paise));
      return list;
    }

    return MonthlyPl(
      revenue: sorted(rev),
      cogs: sorted(cog),
      operating: sorted(op),
    );
  }
}

/// Sum [txns] into descending buckets keyed by [key], optionally filtered.
List<Bucket> bucketize(
  Iterable<Txn> txns,
  String Function(Txn) key, {
  bool Function(Txn)? where,
}) {
  final map = <String, int>{};
  for (final t in txns) {
    if (where != null && !where(t)) continue;
    map.update(key(t), (v) => v + t.amountPaise, ifAbsent: () => t.amountPaise);
  }
  final list = map.entries.map((e) => Bucket(e.key, e.value)).toList();
  list.sort((a, b) => b.paise.compareTo(a.paise));
  return list;
}
