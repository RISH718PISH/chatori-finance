import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/books.dart';
import '../../data/supabase/books_repository.dart';
import '../transaction/transaction_providers.dart';

final booksRepoProvider = Provider<BooksRepository>(
  (ref) => BooksRepository(ref.watch(supabaseClientProvider)),
);

final staffProvider = StreamProvider.autoDispose<List<Staff>>((ref) async* {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) {
    yield const [];
    return;
  }
  yield* ref.watch(booksRepoProvider).watchStaff(biz);
});

final salaryProvider =
    StreamProvider.autoDispose<List<SalaryRecord>>((ref) async* {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) {
    yield const [];
    return;
  }
  yield* ref.watch(booksRepoProvider).watchSalary(biz);
});

final advancesProvider = StreamProvider.autoDispose<List<Advance>>((ref) async* {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) {
    yield const [];
    return;
  }
  yield* ref.watch(booksRepoProvider).watchAdvances(biz);
});

/// Current month key, e.g. "2026-07".
String currentMonthKey() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
}

/// Paise paid to [staffId] in [month] (sum of this month's salary records).
int paidForStaffInMonth(List<SalaryRecord> records, String staffId, String month) {
  var sum = 0;
  for (final r in records) {
    if (r.staffId == staffId && r.month == month) sum += r.amountPaidPaise;
  }
  return sum;
}

/// Advance paise adjusted against [staffId]'s salary in [month].
int adjustedForStaffInMonth(
    List<SalaryRecord> records, String staffId, String month) {
  var sum = 0;
  for (final r in records) {
    if (r.staffId == staffId && r.month == month) {
      sum += r.advanceAdjustedPaise;
    }
  }
  return sum;
}

/// Outstanding advance balance for a staff member (open/partial advances).
int advanceOutstandingForStaff(List<Advance> advances, String staffId) {
  var sum = 0;
  for (final a in advances) {
    if (a.linkedStaffId == staffId && a.status != 'closed') {
      sum += a.outstandingPaise;
    }
  }
  return sum;
}
