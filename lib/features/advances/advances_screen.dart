import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/models/books.dart';
import '../books/books_providers.dart';
import '../transaction/transaction_providers.dart';
import '../widgets/amount_field.dart';

const _personTypes = ['staff', 'vendor', 'helper', 'other'];

class AdvancesScreen extends ConsumerWidget {
  const AdvancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(advancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Advances')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAdvance(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add advance'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (advances) {
          if (advances.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 56, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No advances yet.\nTap "Add advance" to begin.',
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          final outstanding = advances.fold<int>(
              0, (sum, a) => sum + (a.status == 'closed' ? 0 : a.outstandingPaise));
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total outstanding'),
                    Text(Money.format(outstanding),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: AppSemantics.warning)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  children: [
                    for (final a in advances)
                      _AdvanceCard(
                        advance: a,
                        onRecover: () => _recover(context, ref, a),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addAdvance(BuildContext context, WidgetRef ref) async {
    final nameCtl = TextEditingController();
    final reasonCtl = TextEditingController();
    var type = 'staff';
    var amountPaise = 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add advance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Person name'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in _personTypes)
                      ChoiceChip(
                        label: Text(t[0].toUpperCase() + t.substring(1)),
                        selected: type == t,
                        onSelected: (_) => setState(() => type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AmountField(
                    label: 'Advance amount', onChanged: (p) => amountPaise = p),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtl,
                  decoration:
                      const InputDecoration(labelText: 'Reason (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || nameCtl.text.trim().isEmpty || amountPaise <= 0) return;
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    await ref.read(booksRepoProvider).addAdvance(
          businessId: biz,
          personName: nameCtl.text.trim(),
          personType: type,
          amountPaise: amountPaise,
          reason: reasonCtl.text.trim().isEmpty ? null : reasonCtl.text.trim(),
        );
    ref.invalidate(advancesProvider);
  }

  Future<void> _recover(BuildContext context, WidgetRef ref, Advance a) async {
    var recoverPaise = a.outstandingPaise;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Recover from ${a.personName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Outstanding: ${Money.format(a.outstandingPaise)}'),
            const SizedBox(height: 12),
            AmountField(
              label: 'Amount recovered now',
              initialPaise: a.outstandingPaise,
              onChanged: (p) => recoverPaise = p,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || recoverPaise <= 0) return;
    await ref.read(booksRepoProvider).recoverAdvance(
          id: a.id,
          totalAmountPaise: a.amountPaise,
          newRecoveredPaise: a.recoveredPaise + recoverPaise,
        );
    ref.invalidate(advancesProvider);
  }
}

class _AdvanceCard extends StatelessWidget {
  const _AdvanceCard({required this.advance, required this.onRecover});

  final Advance advance;
  final VoidCallback onRecover;

  @override
  Widget build(BuildContext context) {
    final closed = advance.status == 'closed';
    final statusColor = closed
        ? AppSemantics.income
        : (advance.status == 'partial' ? AppSemantics.warning : AppSemantics.expense);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(advance.personName,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Chip(
                  label: Text(advance.status,
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  side: BorderSide(color: statusColor),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            Text('${advance.personType}${advance.reason != null ? ' · ${advance.reason}' : ''}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                _stat('Advance', Money.format(advance.amountPaise, decimals: false)),
                _stat('Recovered',
                    Money.format(advance.recoveredPaise, decimals: false)),
                _stat('Outstanding',
                    Money.format(advance.outstandingPaise, decimals: false)),
              ],
            ),
            if (!closed) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onRecover,
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Record recovery'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
