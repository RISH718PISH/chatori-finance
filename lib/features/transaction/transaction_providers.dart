import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/txn.dart';
import '../../data/supabase/attachment_repository.dart';
import '../../data/supabase/auth_repository.dart';
import '../../data/supabase/purchase_invoice_repository.dart';
import '../../data/supabase/transaction_repository.dart';
import '../screenshot/invoice_ai_client.dart';

final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authRepoProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final transactionRepoProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(supabaseClientProvider)),
);

final attachmentRepoProvider = Provider<AttachmentRepository>(
  (ref) => AttachmentRepository(ref.watch(supabaseClientProvider)),
);

/// Reads invoice line items via the `parse-invoice` Edge Function.
final invoiceAiClientProvider = Provider<InvoiceAiClient>(
  (ref) => InvoiceAiClient(ref.watch(supabaseClientProvider)),
);

final purchaseInvoiceRepoProvider = Provider<PurchaseInvoiceRepository>(
  (ref) => PurchaseInvoiceRepository(ref.watch(supabaseClientProvider)),
);

/// Rebuilds whenever auth state changes (sign in / out).
final authChangeProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepoProvider).onAuthChange,
);

/// The current user's business id. Cached for the session — stable across
/// token refreshes so dependent screens don't reload on every auth tick.
final businessIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(authRepoProvider).currentBusinessId();
});

/// Cached one-shot fetch of the recent transactions for this business.
/// Refreshed via [refreshTransactions] after any save.
final businessTxnsProvider = FutureProvider<List<Txn>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  return ref.watch(transactionRepoProvider).recent(biz);
});

/// Top-N transactions for the "Recent" list on Home.
final recentTransactionsProvider =
    Provider<AsyncValue<List<Txn>>>((ref) {
  return ref
      .watch(businessTxnsProvider)
      .whenData((all) => all.take(12).toList());
});

/// Start of the day for [t] in local time (midnight).
DateTime _startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

/// Monday of the calendar week containing [t] (local time).
DateTime _startOfWeek(DateTime t) {
  final d = _startOfDay(t);
  // DateTime.weekday: Mon=1..Sun=7
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Income/expense totals for today (local-time, timezone-safe).
final todayTotalsProvider = Provider<Totals>((ref) {
  final all = ref.watch(businessTxnsProvider).asData?.value ?? const [];
  final start = _startOfDay(DateTime.now());
  final end = start.add(const Duration(days: 1));
  return Totals.fromTxns(all.where((t) =>
      !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end)));
});

/// Weekly totals for THIS calendar week (Mon → now) plus the delta vs
/// the SAME slice of the previous week (Mon → same weekday & time last week).
/// Comparing "same day of the week" is a fairer trend signal than comparing
/// a partial week to a full one.
class WeeklyTotals {
  final Totals current;
  final Totals previous;
  const WeeklyTotals(this.current, this.previous);

  int get netDelta => current.netPaise - previous.netPaise;
  int get incomeDelta => current.incomePaise - previous.incomePaise;
  int get expenseDelta => current.expensePaise - previous.expensePaise;
}

final weekTotalsProvider = Provider<WeeklyTotals>((ref) {
  final all = ref.watch(businessTxnsProvider).asData?.value ?? const [];
  final now = DateTime.now();
  final thisWeekStart = _startOfWeek(now);
  final prevWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  // "So far this week" = Mon→now; comparison = Mon→now-7d.
  final currentEnd = now;
  final previousEnd = now.subtract(const Duration(days: 7));
  bool inRange(Txn t, DateTime start, DateTime end) =>
      !t.occurredAt.isBefore(start) && !t.occurredAt.isAfter(end);
  final current = Totals.fromTxns(
      all.where((t) => inRange(t, thisWeekStart, currentEnd)));
  final previous = Totals.fromTxns(
      all.where((t) => inRange(t, prevWeekStart, previousEnd)));
  return WeeklyTotals(current, previous);
});

/// Map of user_id → display_name for the current business. Powers the
/// "added by X" attribution shown on transaction tiles. Only refetched when
/// the business changes or the user updates their display name in Settings.
final businessMembersProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const {};
  return ref.watch(authRepoProvider).fetchMembersMap(biz);
});

/// Renders the "by X" suffix for a transaction. Returns null when there's no
/// author, only one member in the business (single-user, so attribution is
/// noise), or the map hasn't loaded yet.
String? attributionFor(Map<String, String>? members, String? userId) {
  if (members == null || members.length < 2 || userId == null) return null;
  final name = members[userId];
  if (name == null || name.isEmpty) return 'by a member';
  return 'by $name';
}

/// Call after adding / editing / deleting a transaction.
void refreshTransactions(WidgetRef ref) {
  ref.invalidate(businessTxnsProvider);
}
