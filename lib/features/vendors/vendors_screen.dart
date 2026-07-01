import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/models/txn.dart';
import '../transaction/transaction_providers.dart';

class VendorSummary {
  final String name;
  final int paidPaise;
  final DateTime lastAt;
  final int count;
  const VendorSummary(this.name, this.paidPaise, this.lastAt, this.count);
}

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<VendorSummary> _summarize(List<Txn> all) {
    final byName = <String, List<Txn>>{};
    for (final t in all) {
      if (t.isIncome) continue;
      final name = (t.partyName ?? '').trim();
      if (name.isEmpty) continue;
      byName.putIfAbsent(name, () => []).add(t);
    }
    final list = <VendorSummary>[];
    byName.forEach((name, txns) {
      var paid = 0;
      DateTime last = txns.first.occurredAt;
      for (final t in txns) {
        paid += t.amountPaise;
        if (t.occurredAt.isAfter(last)) last = t.occurredAt;
      }
      list.add(VendorSummary(name, paid, last, txns.length));
    });
    list.sort((a, b) => b.paidPaise.compareTo(a.paidPaise));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(businessTxnsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search vendor',
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
                    .where((v) => _search.text.trim().isEmpty ||
                        v.name.toLowerCase().contains(_search.text.trim().toLowerCase()))
                    .toList();
                if (list.isEmpty) {
                  return const Center(
                      child: Text('No vendors yet.\n'
                          'Add an expense entry with a vendor name.',
                          textAlign: TextAlign.center));
                }
                final total = list.fold<int>(0, (s, v) => s + v.paidPaise);
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total paid to vendors',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(Money.format(total, decimals: false),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
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
                          itemBuilder: (_, i) {
                            final v = list[i];
                            return ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                                  child: Text(v.name.isNotEmpty
                                      ? v.name[0].toUpperCase()
                                      : '?')),
                              title: Text(v.name),
                              subtitle: Text(
                                  '${v.count} bills · last ${DateFormat('d MMM').format(v.lastAt)}'),
                              trailing: Text(Money.format(v.paidPaise, decimals: false),
                                  style: const TextStyle(
                                      color: Colors.red, fontWeight: FontWeight.bold)),
                              onTap: () => context.push('/transactions'),
                            );
                          },
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
}
