import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/txn.dart';
import '../../data/supabase/auth_repository.dart';
import '../../data/supabase/transaction_repository.dart';

final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authRepoProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final transactionRepoProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(supabaseClientProvider)),
);

/// Rebuilds whenever auth state changes (sign in / out).
final authChangeProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepoProvider).onAuthChange,
);

/// The current user's business id. Cached for the session — it does not depend
/// on auth *ticks* (token refreshes), which previously caused every dependent
/// stream to re-subscribe and flicker. It's invalidated on sign-out.
final businessIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(authRepoProvider).currentBusinessId();
});

/// Live stream of all the business's transactions (one realtime subscription
/// that both the recent list and today's totals are derived from).
final businessTxnsProvider = StreamProvider.autoDispose<List<Txn>>((ref) async* {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) {
    yield const [];
    return;
  }
  yield* ref.watch(transactionRepoProvider).watchForBusiness(biz);
});

/// Most recent transactions (derived from the live stream).
final recentTransactionsProvider =
    Provider.autoDispose<AsyncValue<List<Txn>>>((ref) {
  return ref
      .watch(businessTxnsProvider)
      .whenData((all) => all.take(12).toList());
});

/// Income/expense/net totals for today (derived from the live stream).
final todayTotalsProvider = Provider.autoDispose<Totals>((ref) {
  final all = ref.watch(businessTxnsProvider).asData?.value ?? const [];
  final now = DateTime.now();
  final todays = all.where((t) =>
      t.occurredAt.year == now.year &&
      t.occurredAt.month == now.month &&
      t.occurredAt.day == now.day);
  return Totals.fromTxns(todays);
});
