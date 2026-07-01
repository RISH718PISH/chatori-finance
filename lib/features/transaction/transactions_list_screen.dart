import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/models/txn.dart';
import 'transaction_providers.dart';

/// Full searchable / filterable list of all transactions.
class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  final _search = TextEditingController();
  String _typeFilter = 'all'; // all | income | expense
  String? _modeFilter; // Cash | UPI | Paytm | Bank | Other | null
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Txn t) {
    if (_typeFilter != 'all' && t.type != _typeFilter) return false;
    if (_modeFilter != null && t.paymentMode != _modeFilter) return false;
    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end.add(const Duration(days: 1));
      if (t.occurredAt.isBefore(start) || !t.occurredAt.isBefore(end)) {
        return false;
      }
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return t.category.toLowerCase().contains(q) ||
        (t.partyName ?? '').toLowerCase().contains(q) ||
        (t.notes ?? '').toLowerCase().contains(q) ||
        (t.tag ?? '').toLowerCase().contains(q);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(businessTxnsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('All transactions'),
        actions: [
          if (_dateRange != null || _typeFilter != 'all' || _modeFilter != null)
            IconButton(
              tooltip: 'Clear filters',
              onPressed: () => setState(() {
                _typeFilter = 'all';
                _modeFilter = null;
                _dateRange = null;
              }),
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search category, party, notes…',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All', _typeFilter == 'all',
                    () => setState(() => _typeFilter = 'all')),
                _chip('Income', _typeFilter == 'income',
                    () => setState(() => _typeFilter = 'income'),
                    color: AppSemantics.income),
                _chip('Expense', _typeFilter == 'expense',
                    () => setState(() => _typeFilter = 'expense'),
                    color: AppSemantics.expense),
                const SizedBox(width: 8),
                _chip(
                    _dateRange == null
                        ? 'Date range'
                        : '${DateFormat('d MMM').format(_dateRange!.start)} – ${DateFormat('d MMM').format(_dateRange!.end)}',
                    _dateRange != null,
                    _pickRange),
                const SizedBox(width: 8),
                for (final m in ['Cash', 'UPI', 'Paytm', 'Bank', 'Other'])
                  _chip(m, _modeFilter == m,
                      () => setState(() => _modeFilter = _modeFilter == m ? null : m)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final list = all.where(_matches).toList();
                if (list.isEmpty) {
                  return const Center(child: Text('No matching entries.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(businessTxnsProvider);
                    try {
                      await ref.read(businessTxnsProvider.future);
                    } catch (_) {}
                  },
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (_, i) => _Tile(txn: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: (color ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha: 0.2),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.txn});
  final Txn txn;

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.isIncome;
    final color = isIncome ? AppSemantics.income : AppSemantics.expense;
    final subtitle = [
      txn.paymentMode,
      if ((txn.partyName ?? '').isNotEmpty) txn.partyName,
      DateFormat('d MMM, h:mm a').format(txn.occurredAt),
    ].where((e) => e != null).join(' · ');
    return ListTile(
      onTap: () => context.push('/add', extra: txn),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(isIncome ? Icons.south_west : Icons.north_east, color: color),
      ),
      title: Text(txn.category),
      subtitle: Text(subtitle,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '${isIncome ? '+' : '−'}${Money.format(txn.amountPaise)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
