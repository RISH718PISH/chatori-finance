import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/models/txn.dart';
import '../transaction/transaction_providers.dart';

/// Aggregated view per customer: total advance paid, other income received,
/// last activity date. A lightweight receivables ledger.
class CustomerSummary {
  final String name;
  final int advancePaise;   // sum of "Customer Advance" income
  final int otherIncomePaise; // sum of other income from this customer
  final DateTime lastAt;
  final int count;

  const CustomerSummary({
    required this.name,
    required this.advancePaise,
    required this.otherIncomePaise,
    required this.lastAt,
    required this.count,
  });

  int get totalReceivedPaise => advancePaise + otherIncomePaise;
}

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CustomerSummary> _summarize(List<Txn> all) {
    final byName = <String, List<Txn>>{};
    for (final t in all) {
      if (!t.isIncome) continue;
      final name = (t.partyName ?? '').trim();
      if (name.isEmpty) continue;
      byName.putIfAbsent(name, () => []).add(t);
    }
    final list = <CustomerSummary>[];
    byName.forEach((name, txns) {
      var adv = 0;
      var other = 0;
      DateTime last = txns.first.occurredAt;
      for (final t in txns) {
        if (t.category == 'Customer Advance') {
          adv += t.amountPaise;
        } else {
          other += t.amountPaise;
        }
        if (t.occurredAt.isAfter(last)) last = t.occurredAt;
      }
      list.add(CustomerSummary(
        name: name,
        advancePaise: adv,
        otherIncomePaise: other,
        lastAt: last,
        count: txns.length,
      ));
    });
    list.sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(businessTxnsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search customer',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final list = _summarize(all)
                    .where((c) => _search.text.trim().isEmpty ||
                        c.name.toLowerCase().contains(_search.text.trim().toLowerCase()))
                    .toList();
                if (list.isEmpty) {
                  return const Center(
                      child: Text('No customers yet.\n'
                          'Add an income entry with a customer name.',
                          textAlign: TextAlign.center));
                }
                final totalAdv = list.fold<int>(0, (s, c) => s + c.advancePaise);
                final totalAll = list.fold<int>(0, (s, c) => s + c.totalReceivedPaise);
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          Expanded(child: _kv(context, 'Total advances',
                              Money.format(totalAdv, decimals: false))),
                          Expanded(child: _kv(context, 'All income',
                              Money.format(totalAll, decimals: false))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(businessTxnsProvider);
                          try {
                            await ref.read(businessTxnsProvider.future);
                          } catch (_) {}
                        },
                        child: ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) => _CustomerTile(summary: list[i]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: Theme.of(context).textTheme.bodySmall),
          Text(v,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      );
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.summary});
  final CustomerSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
          child: Text(summary.name.isNotEmpty ? summary.name[0].toUpperCase() : '?')),
      title: Text(summary.name),
      subtitle: Text(
          '${summary.count} entries · last ${DateFormat('d MMM').format(summary.lastAt)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Money.format(summary.advancePaise, decimals: false),
              style: const TextStyle(
                  color: AppSemantics.income, fontWeight: FontWeight.bold)),
          const Text('advance', style: TextStyle(fontSize: 11)),
        ],
      ),
      onTap: () => context.push('/transactions'),
    );
  }
}
