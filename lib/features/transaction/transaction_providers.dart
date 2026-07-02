import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/txn.dart';
import '../../data/supabase/attachment_repository.dart';
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

final attachmentRepoProvider = Provider<AttachmentRepository>(
  (ref) => AttachmentRepository(ref.watch(supabaseClientProvider)),
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

/// Income/expense totals for today (derived).
final todayTotalsProvider = Provider<Totals>((ref) {
  final all = ref.watch(businessTxnsProvider).asData?.value ?? const [];
  final now = DateTime.now();
  final todays = all.where((t) =>
      t.occurredAt.year == now.year &&
      t.occurredAt.month == now.month &&
      t.occurredAt.day == now.day);
  return Totals.fromTxns(todays);
});

/// Customer advances (income category "Customer Advance"), newest first.
final customerAdvancesProvider = Provider<List<Txn>>((ref) {
  final all = ref.watch(businessTxnsProvider).asData?.value ?? const [];
  return all.where((t) => t.category == 'Customer Advance').toList();
});

/// Call after adding / editing / deleting a transaction.
void refreshTransactions(WidgetRef ref) {
  ref.invalidate(businessTxnsProvider);
}
