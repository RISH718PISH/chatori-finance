import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design.dart';
import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';
import 'widgets/item_picker_sheet.dart';

/// One-time opening count: the chef walks the store and types current
/// quantities. Writes `opening` movements. Items with no count are left
/// alone. Re-runnable, but each save adds movements — so it is framed as a
/// one-time count, not something to repeat.
class OpeningStockScreen extends ConsumerStatefulWidget {
  const OpeningStockScreen({super.key});

  @override
  ConsumerState<OpeningStockScreen> createState() =>
      _OpeningStockScreenState();
}

class _OpeningStockScreenState extends ConsumerState<OpeningStockScreen> {
  final _controllers = <String, TextEditingController>{};
  final _filled = ValueNotifier<int>(0);
  bool _saving = false;

  TextEditingController _ctl(String id) =>
      _controllers.putIfAbsent(id, () {
        final c = TextEditingController();
        c.addListener(() {
          _filled.value = _controllers.values
              .where((c) => c.text.trim().isNotEmpty)
              .length;
        });
        return c;
      });

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _filled.dispose();
    super.dispose();
  }

  Future<void> _save(List<InventoryItem> items) async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;

    final byId = {for (final i in items) i.id: i};
    final rows = <Map<String, dynamic>>[];
    for (final e in _controllers.entries) {
      final raw = e.value.text.trim();
      if (raw.isEmpty) continue;
      final qty = double.tryParse(raw);
      final item = byId[e.key];
      if (qty == null || qty <= 0 || item == null) continue;
      rows.add({
        'business_id': biz,
        'item_id': e.key,
        'movement_type': 'opening',
        'qty_milli': Quantity.toMilli(qty, item.unit),
        'note': 'Opening count',
      });
    }
    if (rows.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Enter a quantity for at least one item')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepoProvider).addMovements(rows);
      refreshInventory(ref);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppSemantics.income,
        content: Text('Opening stock set for ${rows.length} items ✓',
            style: const TextStyle(color: Colors.white)),
      ));
      context.pop();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opening stock'),
        actions: [
          IconButton(
            tooltip: 'Add an item',
            icon: const Icon(Icons.add),
            onPressed: () => showItemPicker(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppSemantics.warning.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(12),
            child: Text(
              'Count what is in your store right now. Do this once — after '
              'this, scanning bills adds stock and recording usage subtracts.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                              'No items yet. Add the things you keep in '
                              'stock, then enter how much you have.',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => showItemPicker(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Add an item'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemCount: items.length,
                  itemBuilder: (_, i) =>
                      _Row(item: items[i], controller: _ctl(items[i].id)),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<int>(
            valueListenable: _filled,
            builder: (_, n, _) => FilledButton.icon(
              onPressed: (n == 0 || _saving)
                  ? null
                  : () => _save(async.asData?.value ?? const []),
              icon: const Icon(Icons.check),
              label: Text(_saving
                  ? 'Saving…'
                  : n == 0
                      ? 'Enter your counts'
                      : 'Save $n ${n == 1 ? 'count' : 'counts'}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.controller});
  final InventoryItem item;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(item.name)),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.end,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 34, child: Text(item.displayUnit)),
        ],
      ),
    );
  }
}
