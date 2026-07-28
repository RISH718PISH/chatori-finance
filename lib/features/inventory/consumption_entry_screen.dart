import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../events/events_providers.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';
import 'widgets/category_bar.dart';

/// The daily driver: a chef records what the kitchen used today.
///
/// Speed decisions that matter at 150 items:
///  • one flat list, one number per row, unit fixed as text (no per-row
///    dropdown), one batched save;
///  • rows sorted by most-recently-used so the ~12 daily items stay on top;
///  • `ListView.builder` + lazily created controllers + a `ValueNotifier`
///    for the button label, so a keystroke doesn't rebuild the list.
class ConsumptionEntryScreen extends ConsumerStatefulWidget {
  const ConsumptionEntryScreen({super.key});

  @override
  ConsumerState<ConsumptionEntryScreen> createState() =>
      _ConsumptionEntryScreenState();
}

class _ConsumptionEntryScreenState
    extends ConsumerState<ConsumptionEntryScreen> {
  final _controllers = <String, TextEditingController>{};
  final _filled = ValueNotifier<int>(0);
  DateTime _date = DateTime.now();
  String? _eventId;
  String? _reason; // mandatory before saving
  String? _category; // null = all
  final _search = TextEditingController();
  bool _saving = false;

  TextEditingController _ctl(String itemId) =>
      _controllers.putIfAbsent(itemId, () {
        final c = TextEditingController();
        c.addListener(_recount);
        return c;
      });

  void _recount() {
    _filled.value =
        _controllers.values.where((c) => c.text.trim().isNotEmpty).length;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _filled.dispose();
    _search.dispose();
    super.dispose();
  }

  bool _matches(StockOnHand s) {
    if (_category != null && s.category != _category) return false;
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty || s.name.toLowerCase().contains(q);
  }

  /// Most-recently-used first, so the daily items float to the top; the
  /// long tail is reached by scrolling or searching.
  List<StockOnHand> _ordered(List<StockOnHand> items) {
    final sorted = [for (final s in items) if (_matches(s)) s];
    sorted.sort((a, b) {
      final ad = a.lastOutOn, bd = b.lastOutOn;
      if (ad != null && bd != null) return bd.compareTo(ad);
      if (ad != null) return -1;
      if (bd != null) return 1;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  Future<void> _save(List<StockOnHand> items) async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;

    final byId = {for (final s in items) s.itemId: s};
    final rows = <Map<String, dynamic>>[];
    for (final entry in _controllers.entries) {
      final raw = entry.value.text.trim();
      if (raw.isEmpty) continue;
      final qty = double.tryParse(raw);
      final stock = byId[entry.key];
      if (qty == null || qty <= 0 || stock == null) continue;
      final milli = Quantity.toMilli(qty, stock.unit);
      rows.add({
        'business_id': biz,
        'item_id': entry.key,
        'movement_type': 'consumption',
        'qty_milli': -milli, // out of stock → negative
        'occurred_on': _date.toIso8601String().substring(0, 10),
        'event_id': _eventId,
        'reason': _reason,
      });
    }

    if (rows.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Nothing to save — enter a quantity first')));
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
        content: Text(
            'Recorded ${rows.length} for ${DateFormat('EEE, d MMM').format(_date)} ✓',
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
    final events = ref.watch(eventsProvider).asData?.value ?? const [];
    final selectableEvents = events.where((e) => !e.isSettled).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Consumption')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          if (all.isEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                  'No items yet. Count opening stock or scan a bill first.',
                  textAlign: TextAlign.center),
            ));
          }
          final categories = <String>{
            for (final s in all)
              if ((s.category ?? '').isNotEmpty) s.category!,
          }.toList()
            ..sort();
          final items = _ordered(all);
          return Column(
            children: [
              _header(context, selectableEvents),
              CategoryBar(
                categories: categories,
                selected: _category,
                search: _search,
                onCategory: (c) => setState(() => _category = c),
                onSearch: () => setState(() {}),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No matching items.')))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _Row(
                          stock: items[i],
                          controller: _ctl(items[i].itemId),
                        ),
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
              onPressed: (n == 0 || _reason == null || _saving)
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
                      ? 'Enter what was used'
                      : _reason == null
                          ? 'Pick a reason first'
                          : 'Save $n ${n == 1 ? 'entry' : 'entries'}'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, List events) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          // Reason is mandatory — it drives the channel reporting the owner
          // cares about (Zomato vs Swiggy vs Catering …).
          DropdownButtonFormField<String>(
            initialValue: _reason,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Reason for consumption *',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.label_outline),
            ),
            items: [
              for (final r in kConsumptionReasons)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (v) => setState(() => _reason = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(DateFormat('EEE, d MMM').format(_date)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    initialDate: _date,
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(width: 8),
              if (events.isNotEmpty)
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _eventId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Event (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.celebration_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('No event')),
                      for (final e in events)
                        DropdownMenuItem(
                            value: e.id as String, child: Text(e.name)),
                    ],
                    onChanged: (v) => setState(() => _eventId = v),
                  ),
                ),
            ],
          ),
        ],
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
                Text('${stock.onHandLabel} left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: stock.isOut
                              ? AppSemantics.expense
                              : Theme.of(context).hintColor,
                        )),
              ],
            ),
          ),
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
          SizedBox(
            width: 34,
            child: Text(stock.displayUnit,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
