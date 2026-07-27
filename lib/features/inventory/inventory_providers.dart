import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/inventory.dart';
import '../../data/supabase/inventory_repository.dart';
import '../../data/supabase/inventory_valuation_repository.dart';
import '../transaction/transaction_providers.dart';

final inventoryRepoProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(ref.watch(supabaseClientProvider)),
);

final inventoryValuationRepoProvider = Provider<InventoryValuationRepository>(
  (ref) => InventoryValuationRepository(ref.watch(supabaseClientProvider)),
);

/// On-hand for every item, from the server view. The single source the
/// inventory home, low-stock list, and item picker all derive from.
final stockOnHandProvider = FutureProvider<List<StockOnHand>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  return ref.watch(inventoryRepoProvider).fetchOnHand(biz);
});

/// The catalogue (items regardless of stock level) — for the picker and
/// the matcher.
final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  return ref.watch(inventoryRepoProvider).fetchItems(biz);
});

final itemAliasesProvider = FutureProvider<List<ItemAlias>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  return ref.watch(inventoryRepoProvider).fetchAliases(biz);
});

/// Items at or below their reorder level, worst first (most-negative /
/// most-depleted at the top). Derived, so it stays in sync with on-hand.
final lowStockProvider = Provider<List<StockOnHand>>((ref) {
  final all = ref.watch(stockOnHandProvider).asData?.value ?? const [];
  final low = all.where((s) => s.isLow || s.isOut).toList()
    ..sort((a, b) => a.onHandMilli.compareTo(b.onHandMilli));
  return low;
});

final itemMovementsProvider =
    FutureProvider.family<List<StockMovement>, String>((ref, itemId) async {
  return ref.watch(inventoryRepoProvider).fetchMovements(itemId);
});

/// Owner-only in effect: for a chef the underlying view returns nothing, so
/// this resolves to an empty list and value UI simply doesn't render.
final stockValueProvider = FutureProvider<List<StockValue>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  return ref.watch(inventoryValuationRepoProvider).fetchStockValue(biz);
});

/// Total stock value in paise (owner only). Null while loading.
final stockValueTotalProvider = Provider<int?>((ref) {
  final v = ref.watch(stockValueProvider).asData?.value;
  if (v == null) return null;
  return v.fold<int>(0, (s, r) => s + r.valuePaise);
});

final consumptionForMonthProvider =
    FutureProvider.family<List<ConsumptionRow>, String>((ref, month) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  return ref
      .watch(inventoryValuationRepoProvider)
      .fetchConsumption(businessId: biz, month: month);
});

/// Invalidated after any stock write. Mirrors refreshTransactions/Books.
void refreshInventory(WidgetRef ref) {
  ref.invalidate(stockOnHandProvider);
  ref.invalidate(inventoryItemsProvider);
  ref.invalidate(itemAliasesProvider);
  ref.invalidate(stockValueProvider);
}
