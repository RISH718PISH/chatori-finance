import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';
import 'widgets/category_bar.dart';

/// Periodic stock count — the practical way to capture spices, oil and
/// other bits you can't weigh per dish.
///
/// You enter what is LEFT in each tin. The app compares to the expected
/// on-hand and:
///   • counted < expected  → the difference is recorded AS consumption, so
///     it flows into food cost (not a silent adjustment);
///   • counted > expected  → recorded as a positive adjustment (you found
///     more than expected — a missed purchase, say).
///
/// No per-dish weighing: cook all week, count the tin on Sunday, done.
class StockCountScreen extends ConsumerStatefulWidget {
  const StockCountScreen({super.key});

  @override
  ConsumerState<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends ConsumerState<StockCountScreen> {
  final _controllers = <String, TextEditingController>{};
  final _filled = ValueNotifier<int>(0);
  final _search = TextEditingController();
  String? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;

  TextEditingController _ctl(String id) => _controllers.putIfAbsent(id, () {
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
    _search.dispose();
    _filled.dispose();
    super.dispose();
  }

  bool _matches(StockOnHand s) {
    if (_category != null && s.category != _category) return false;
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty || s.name.toLowerCase().contains(q);
  }

  Future<void> _save(List<StockOnHand> all) async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;

    final byId = {for (final s in all) s.itemId: s};
    final rows = <Map<String, dynamic>>[];
    for (final e in _controllers.entries) {
      final raw = e.value.text.trim();
      if (raw.isEmpty) continue;
      final counted = double.tryParse(raw);
      final stock = byId[e.key];
      if (counted == null || counted < 0 || stock == null) continue;
      final countedMilli = Quantity.toMilli(counted, stock.unit);
      final delta = countedMilli - stock.onHandMilli;
      if (delta == 0) continue;
      final on = e.key;
      if (delta < 0) {
        // Used since the last count → consumption (feeds food cost).
        rows.add({
          'business_id': biz,
          'item_id': on,
          'movement_type': 'consumption',
          'qty_milli': delta, // negative
          'occurred_on': _date.toIso8601String().substring(0, 10),
          'reason': 'Stock count',
        });
      } else {
        // Found more than expected → correction up.
        rows.add({
          'business_id': biz,
          'item_id': on,
          'movement_type': 'adjustment',
          'qty_milli': delta, // positive
          'occurred_on': _date.toIso8601String().substring(0, 10),
          'note': 'Stock count — found extra',
        });
      }
    }

    if (rows.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('No changes — counts match the expected stock')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepoProvider).addMovements(rows);
      refreshInventory(ref);
      if (!mounted) return;
      final used = rows.where((r) => r['movement_type'] == 'consumption').length;
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppSemantics.income,
        content: Text(
            'Counted ${rows.length} items · $used recorded as used ✓',
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
    final async = ref.watch(stockOnHandProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock count')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No items yet.', textAlign: TextAlign.center),
              ),
            );
          }
          final categories = <String>{
            for (final s in all)
              if ((s.category ?? '').isNotEmpty) s.category!,
          }.toList()
            ..sort();
          final shown = [for (final s in all) if (_matches(s)) s]
            ..sort((a, b) => a.name.compareTo(b.name));

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: AppSemantics.warning.withValues(alpha: 0.08),
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Enter what is LEFT in each tin. Any drop since the last '
                  'count is recorded as used. Great for spices, oil and '
                  'condiments you cannot weigh per dish.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.event, size: 18),
                    label: Text(DateFormat('EEE, d MMM').format(_date)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 1)),
                        initialDate: _date,
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                ),
              ),
              CategoryBar(
                categories: categories,
                selected: _category,
                search: _search,
                onCategory: (c) => setState(() => _category = c),
                onSearch: () => setState(() {}),
              ),
              const Divider(height: 1),
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No matching items.')))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                        itemCount: shown.length,
                        itemBuilder: (_, i) =>
                            _Row(stock: shown[i], controller: _ctl(shown[i].itemId)),
                      ),
              ),
            ],
          );
        },
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
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
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
  const _Row({required this.stock, required this.controller});
  final StockOnHand stock;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${stock.onHandLabel} expected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor)),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.end,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Left',
                hintText: '0',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 34, child: Text(stock.displayUnit)),
        ],
      ),
    );
  }
}
