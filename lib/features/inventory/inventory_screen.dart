import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';
import 'widgets/item_picker_sheet.dart';

/// Inventory home — the chef's landing screen and an owner section.
///
/// The item tiles show quantities only and are byte-identical for both
/// roles; the sole owner-only element is the stock-value card, which a chef
/// never receives data for. No `if (isOwner)` around a money widget that a
/// chef could otherwise see half-rendered — the value simply isn't there.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stockOnHandProvider);
    final low = ref.watch(lowStockProvider);
    final isOwner = ref.watch(isOwnerProvider);
    final valueTotal = ref.watch(stockValueTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Stock report',
              icon: const Icon(Icons.assessment_outlined),
              onPressed: () => context.push('/inventory/report'),
            ),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'opening' => context.push('/inventory/opening'),
              'add' => showItemPicker(context, ref),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'add', child: Text('Add an item')),
              PopupMenuItem(
                  value: 'opening', child: Text('Count opening stock')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/consumption'),
        icon: const Icon(Icons.remove_shopping_cart_outlined),
        label: const Text('Record usage'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) return _empty(context, ref);
          return RefreshIndicator(
            onRefresh: () async {
              refreshInventory(ref);
              try {
                await ref.read(stockOnHandProvider.future);
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    _statCard(context, 'Items tracked', '${items.length}'),
                    const SizedBox(width: 12),
                    if (isOwner)
                      _statCard(
                        context,
                        'Stock value',
                        valueTotal == null
                            ? '—'
                            : Money.format(valueTotal, decimals: false),
                        color: AppSemantics.income,
                      ),
                  ],
                ),
                if (low.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: LabelUpper('Running low (${low.length})')),
                      TextButton.icon(
                        onPressed: () => _copyOrderList(context, low),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy list'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final s in low) _ItemTile(stock: s),
                ],
                const SizedBox(height: 20),
                const LabelUpper('All items'),
                const SizedBox(height: 4),
                for (final s in items) _ItemTile(stock: s),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      {Color? color}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelUpper(label),
              const SizedBox(height: 6),
              DataNumber(value, size: DataSize.lg, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No items yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Your stock list builds itself from the bills you scan. To start '
              'now, count what is already in the store.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/inventory/opening'),
              icon: const Icon(Icons.checklist),
              label: const Text('Count opening stock'),
            ),
            TextButton(
              onPressed: () => showItemPicker(context, ref),
              child: const Text('Add a single item'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyOrderList(BuildContext context, List<StockOnHand> low) {
    final text = [
      'Order list — Chatori Kitchen',
      for (final s in low)
        '• ${s.name} (${s.isOut ? 'out' : 'low, ${s.onHandLabel} left'})',
    ].join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('Order list copied — paste into WhatsApp'),
    ));
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.stock});
  final StockOnHand stock;

  @override
  Widget build(BuildContext context) {
    final color = stock.isOut
        ? AppSemantics.expense
        : (stock.isLow ? AppSemantics.warning : null);
    return Card(
      child: ListTile(
        onTap: () => context.push('/inventory/item/${stock.itemId}'),
        leading: CircleAvatar(
          backgroundColor:
              (color ?? Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.15),
          child: Icon(Icons.inventory_2_outlined, color: color),
        ),
        title: Text(stock.name),
        subtitle: Text([
          stock.category ?? 'Uncategorised',
          if (stock.isOut)
            'out of stock'
          else if (stock.isLow)
            'low — reorder at ${Quantity.format(stock.reorderLevelMilli, stock.dimension)}',
        ].join(' · ')),
        trailing: DataNumber(stock.onHandLabel,
            size: DataSize.sm, color: color),
      ),
    );
  }
}
