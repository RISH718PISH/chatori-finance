import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/txn.dart';
import '../transaction/transaction_providers.dart';

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

/// A named money bucket used for breakdowns (category, party, etc.).
class Bucket {
  final String label;
  final int paise;
  const Bucket(this.label, this.paise);
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
