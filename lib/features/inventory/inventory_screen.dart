import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';
import 'widgets/item_picker_sheet.dart';

/// Inventory home — the chef's landing screen and an owner section.
///
/// Item tiles show quantities only, so the row is identical for both roles;
/// the only role-dependent element is the stock-value card, which a chef
/// receives data for only because the owner opted them in.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _search = TextEditingController();
  String? _category; // null = all

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(StockOnHand s) {
    if (_category != null && s.category != _category) return false;
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty || s.name.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stockOnHandProvider);
    final low = ref.watch(lowStockProvider);
    final canViewValue =
        ref.watch(myRoleProvider).can(Permission.viewInventoryValue);
    final canScan = ref.watch(myRoleProvider).can(Permission.scanInvoice);
    final isOwner = ref.watch(isOwnerProvider);
    final valueTotal = ref.watch(stockValueTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo_wordmark.png', height: 36),
        toolbarHeight: 62,
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
              'wastage' => context.push('/inventory/wastage'),
              'scan' => context.push('/import'),
              _ => null,
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'add', child: Text('Add an item')),
              const PopupMenuItem(
                  value: 'opening', child: Text('Count opening stock')),
              const PopupMenuItem(
                  value: 'wastage', child: Text('Record wastage')),
              if (canScan)
                const PopupMenuItem(value: 'scan', child: Text('Scan a bill')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/consumption'),
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Consumption'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) return _empty(context, ref);

          final categories = <String>{
            for (final s in items)
              if ((s.category ?? '').isNotEmpty) s.category!,
          }.toList()
            ..sort();
          final filtered = items.where(_matches).toList();

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
                // ── Summary cards ──
                Row(
                  children: [
                    _statCard(context, 'Items', '${items.length}'),
                    const SizedBox(width: 12),
                    if (canViewValue)
                      _statCard(
                        context,
                        'Stock value',
                        valueTotal == null
                            ? '—'
                            : Money.format(valueTotal, decimals: false),
                        color: AppSemantics.income,
                      )
                    else
                      _statCard(context, 'Low / out', '${low.length}',
                          color: low.isEmpty
                              ? null
                              : AppSemantics.warning),
                  ],
                ),

                // ── Quick actions ──
                const SizedBox(height: 20),
                const LabelUpper('Quick actions'),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: [
                    _ActionTile(
                      icon: Icons.restaurant_menu,
                      label: 'Consumption',
                      color: AppSemantics.expense,
                      onTap: () => context.push('/inventory/consumption'),
                    ),
                    _ActionTile(
                      icon: Icons.delete_outline,
                      label: 'Wastage',
                      color: AppSemantics.warning,
                      onTap: () => context.push('/inventory/wastage'),
                    ),
                    if (canScan)
                      _ActionTile(
                        icon: Icons.document_scanner_outlined,
                        label: 'Scan a bill',
                        color: AppSemantics.income,
                        onTap: () => context.push('/import'),
                      ),
                    _ActionTile(
                      icon: Icons.fact_check_outlined,
                      label: 'Stock count',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => context.push('/inventory/count'),
                    ),
                  ],
                ),

                // ── Running low (capped) ──
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
                  for (final s in low.take(6)) _ItemTile(stock: s),
                  if (low.length > 6)
                    TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _category = null;
                      }),
                      child: Text('+ ${low.length - 6} more low'),
                    ),
                ],

                // ── All items: search + category filter ──
                const SizedBox(height: 20),
                const LabelUpper('All items'),
                const SizedBox(height: 8),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search items',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _search.clear()),
                          ),
                  ),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _catChip('All', _category == null,
                            () => setState(() => _category = null)),
                        for (final c in categories)
                          _catChip(c, _category == c,
                              () => setState(() => _category = c)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No matching items.')),
                  )
                else
                  for (final s in filtered) _ItemTile(stock: s),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _catChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),

        selected: selected,
        onSelected: (_) => onTap(),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
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
          if (stock.lastMovedAt != null)
            'updated ${DateFormat('d MMM').format(stock.lastMovedAt!)}',
        ].join(' · ')),
        trailing: DataNumber(stock.onHandLabel,
            size: DataSize.sm, color: color),
      ),
    );
  }
}
