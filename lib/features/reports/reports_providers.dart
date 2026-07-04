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

/// Transactions for the selected report month — DERIVED from
/// [businessTxnsProvider] so it stays in sync when any entry is added, edited,
/// or deleted anywhere in the app. Previously we did a separate `fetchForMonth`
/// call, which caused the Overview pie / P&L / totals to show stale numbers.
final monthTxnsProvider = FutureProvider.autoDispose<List<Txn>>((ref) async {
  final all = await ref.watch(businessTxnsProvider.future);
  final month = ref.watch(selectedReportMonthProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  return all
      .where((t) =>
          !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end))
      .toList();
});

/// Transactions for the month before the selected one (for MoM deltas).
/// Also derived from [businessTxnsProvider] for the same reason.
final prevMonthTxnsProvider =
    FutureProvider.autoDispose<List<Txn>>((ref) async {
  final all = await ref.watch(businessTxnsProvider.future);
  final month = ref.watch(selectedReportMonthProvider);
  final start = DateTime(month.year, month.month - 1, 1);
  final end = DateTime(month.year, month.month, 1);
  return all
      .where((t) =>
          !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end))
      .toList();
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
/// Blank / whitespace-only keys are collapsed into a single "Uncategorized"
/// bucket so the pie doesn't display an invisible slice.
List<Bucket> bucketize(
  Iterable<Txn> txns,
  String Function(Txn) key, {
  bool Function(Txn)? where,
}) {
  final map = <String, int>{};
  for (final t in txns) {
    if (where != null && !where(t)) continue;
    var k = key(t).trim();
    if (k.isEmpty) k = 'Uncategorized';
    map.update(k, (v) => v + t.amountPaise, ifAbsent: () => t.amountPaise);
  }
  final list = map.entries.map((e) => Bucket(e.key, e.value)).toList();
  list.sort((a, b) => b.paise.compareTo(a.paise));
  return list;
}

/// Percentages for the pie's slice labels. Rounded to whole numbers but
/// adjusted so they sum to exactly 100 — otherwise the slice labels can
/// read "34% + 33% + 33% = 100%" while the biggest slice reads 34% but
/// visually is 34.7% — inconsistent. Returns list matching [buckets] order.
List<int> percentagesSummingTo100(List<Bucket> buckets, int total) {
  if (total <= 0 || buckets.isEmpty) {
    return List<int>.filled(buckets.length, 0);
  }
  // Largest-remainder method.
  final raw = buckets.map((b) => b.paise / total * 100).toList();
  final floored = raw.map((v) => v.floor()).toList();
  var deficit = 100 - floored.reduce((a, b) => a + b);
  final indices = List<int>.generate(buckets.length, (i) => i);
  // Sort indices by descending fractional part, break ties by original order.
  indices.sort((a, b) => (raw[b] - floored[b]).compareTo(raw[a] - floored[a]));
  for (final i in indices) {
    if (deficit == 0) break;
    floored[i] += 1;
    deficit -= 1;
  }
  return floored;
}
