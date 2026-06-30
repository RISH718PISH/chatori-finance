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

/// The current user's business id (cached for the session).
final businessIdProvider = FutureProvider<String?>(
  (ref) {
    ref.watch(authChangeProvider); // refetch on login/logout
    return ref.watch(authRepoProvider).currentBusinessId();
  },
);

/// Most recent transactions for the dashboard.
final recentTransactionsProvider =
    FutureProvider.autoDispose<List<Txn>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  return ref.watch(transactionRepoProvider).recent(biz);
});

/// Income/expense/net totals for today.
final todayTotalsProvider = FutureProvider.autoDispose<Totals>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return Totals.zero;
  final txns =
      await ref.watch(transactionRepoProvider).forDay(biz, DateTime.now());
  return Totals.fromTxns(txns);
});

/// Call after adding/editing/deleting to refresh the dashboard.
void refreshTransactions(WidgetRef ref) {
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(todayTotalsProvider);
}
