import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onHand = ref.watch(stockOnHandProvider).asData?.value ?? const [];
    final matches = onHand.where((s) => s.itemId == itemId).toList();
    final movements = ref.watch(itemMovementsProvider(itemId));
    final canViewValue =
        ref.watch(myRoleProvider).can(Permission.viewInventoryValue);
    final values = ref.watch(stockValueProvider).asData?.value ?? const [];

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found.')),
      );
    }
    final stock = matches.first;
    final value = values.where((v) => v.itemId == itemId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(stock.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'addstock' => _addStock(context, ref, stock),
              'adjust' => _adjust(context, ref, stock),
              'wastage' => _wastage(context, ref, stock),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'addstock', child: Text('Add stock')),
              PopupMenuItem(
                  value: 'adjust', child: Text('Correct to a counted amount')),
              PopupMenuItem(value: 'wastage', child: Text('Record wastage')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LabelUpper('On hand'),
                  const SizedBox(height: 6),
                  DataNumber(
                    stock.onHandLabel,
                    size: DataSize.lg,
                    color: stock.isOut
                        ? AppSemantics.expense
                        : (stock.isLow ? AppSemantics.warning : null),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      _stat(context, 'In (all time)',
                          Quantity.format(stock.inMilli, stock.dimension)),
                      _stat(context, 'Out (all time)',
                          Quantity.format(stock.outMilli, stock.dimension)),
                      _stat(
                          context,
                          'Reorder at',
                          stock.reorderLevelMilli > 0
                              ? Quantity.format(
                                  stock.reorderLevelMilli, stock.dimension)
                              : '—'),
                    ],
                  ),
                  if (canViewValue) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        _stat(
                            context,
                            'Stock value',
                            value == null
                                ? 'not valued'
                                : Money.format(value.valuePaise,
                                    decimals: false)),
                        _stat(
                            context,
                            'Avg cost',
                            value == null
                                ? '—'
                                : '${Money.format(value.avgCostPerUnitPaise(stock.unit), decimals: false)}/${stock.displayUnit}'),
                      ],
                    ),
                    if (value == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Not valued yet — value appears once this item is '
                          'bought on a scanned bill.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const LabelUpper('Movements'),
          const SizedBox(height: 8),
          movements.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No movements yet.'))
                : Column(
                    children: [
                      for (final m in list)
                        _MovementRow(movement: m, dimension: stock.dimension),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          DataNumber(value, size: DataSize.sm),
        ],
      ),
    );
  }

  /// Manually add stock not captured on a scanned bill — a cash purchase,
  /// say. Quantity plus an optional total price, recorded as a priced
  /// `purchase` movement so it flows into the average cost.
  Future<void> _addStock(
      BuildContext context, WidgetRef ref, StockOnHand stock) async {
    final qtyCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add stock — ${stock.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity',
                suffixText: stock.displayUnit,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price for this quantity (optional)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    final qty = double.tryParse(qtyCtl.text.trim());
    if (qty == null || qty <= 0) return;
    final price = double.tryParse(priceCtl.text.trim());
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    await ref.read(inventoryRepoProvider).addMovement(
          businessId: biz,
          itemId: stock.itemId,
          type: StockMovementType.purchase,
          qtyMilli: Quantity.toMilli(qty, stock.unit),
          costPaise:
              (price != null && price > 0) ? (price * 100).round() : null,
          note: 'Manual add',
        );
    refreshInventory(ref);
    ref.invalidate(itemMovementsProvider(stock.itemId));
  }

  Future<void> _adjust(
      BuildContext context, WidgetRef ref, StockOnHand stock) async {
    final counted = await _askQuantity(
      context,
      title: 'Counted amount',
      helper: 'Enter the quantity actually in the store (${stock.displayUnit}). '
          'A correction is recorded for the difference.',
      unit: stock.displayUnit,
    );
    if (counted == null) return;
    final countedMilli = Quantity.toMilli(counted, stock.unit);
    final delta = countedMilli - stock.onHandMilli;
    if (delta == 0) return;
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    await ref.read(inventoryRepoProvider).addMovement(
          businessId: biz,
          itemId: stock.itemId,
          type: StockMovementType.adjustment,
          qtyMilli: delta,
          note: 'Stock take',
        );
    refreshInventory(ref);
    ref.invalidate(itemMovementsProvider(stock.itemId));
  }

  Future<void> _wastage(
      BuildContext context, WidgetRef ref, StockOnHand stock) async {
    final qty = await _askQuantity(
      context,
      title: 'Record wastage',
      helper: 'How much was spoiled or thrown away (${stock.displayUnit})?',
      unit: stock.displayUnit,
    );
    if (qty == null || qty <= 0) return;
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    await ref.read(inventoryRepoProvider).addMovement(
          businessId: biz,
          itemId: stock.itemId,
          type: StockMovementType.wastage,
          qtyMilli: -Quantity.toMilli(qty, stock.unit),
          note: 'Wastage',
        );
    refreshInventory(ref);
    ref.invalidate(itemMovementsProvider(stock.itemId));
  }

  Future<double?> _askQuantity(BuildContext context,
      {required String title,
      required String helper,
      required String unit}) {
    final ctl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit,
            border: const OutlineInputBorder(),
            helperText: helper,
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(ctl.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement, required this.dimension});
  final StockMovement movement;
  final QtyDimension dimension;

  @override
  Widget build(BuildContext context) {
    final into = movement.qtyMilli > 0;
    final color = into ? AppSemantics.income : AppSemantics.expense;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        into ? Icons.south_west : Icons.north_east,
        color: color,
        size: 20,
      ),
      title: Text(movement.type.label),
      subtitle: Text([
        DateFormat('d MMM').format(movement.occurredOn),
        if ((movement.reason ?? '').isNotEmpty) movement.reason,
        if ((movement.note ?? '').isNotEmpty) movement.note,
      ].join(' · ')),
      trailing: DataNumber(
        '${into ? '+' : '−'}${Quantity.format(movement.qtyMilli.abs(), dimension)}',
        size: DataSize.sm,
        color: color,
      ),
    );
  }
}
