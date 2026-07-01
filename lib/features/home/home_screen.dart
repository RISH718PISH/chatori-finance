import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/models/txn.dart';
import '../transaction/transaction_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todayTotalsProvider);
    final recent = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatori Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(businessTxnsProvider),
        child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // --- Today summary ---
          Row(
            children: [
              _SummaryCard(
                label: 'Income',
                value: Money.format(totals.incomePaise, decimals: false),
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'Expenses',
                value: Money.format(totals.expensePaise, decimals: false),
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            label: 'Net (today)',
            value: Money.format(totals.netPaise, decimals: false),
            color: totals.netPaise >= 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            wide: true,
          ),
          const SizedBox(height: 20),

          // --- Quick add ---
          Text('Quick add', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => context.push('/add?type=income'),
                  icon: const Icon(Icons.add),
                  label: const Text('Income'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => context.push('/add?type=expense'),
                  icon: const Icon(Icons.remove),
                  label: const Text('Expense'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Sections ---
          Text('Sections', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: const [
              _NavTile('Salaries', Icons.badge_outlined, '/salary'),
              _NavTile('Advances', Icons.account_balance_wallet_outlined, '/advances'),
              _NavTile('Import Paytm', Icons.image_outlined, '/import'),
              _NavTile('Reports', Icons.bar_chart_outlined, '/reports'),
            ],
          ),
          const SizedBox(height: 20),

          // --- Recent entries ---
          Text('Recent', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          recent.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text('Error: $e'),
            data: (txns) => txns.isEmpty
                ? const _EmptyRecent()
                : Column(
                    children: [for (final t in txns) _TxnTile(t)],
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
    return wide ? card : Expanded(child: card);
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile(this.txn);
  final Txn txn;

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final subtitle = [
      txn.paymentMode,
      if (txn.partyName != null && txn.partyName!.isNotEmpty) txn.partyName,
      DateFormat('d MMM, h:mm a').format(txn.occurredAt),
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(isIncome ? Icons.south_west : Icons.north_east, color: color),
      ),
      title: Text(txn.category),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '${isIncome ? '+' : '−'}${Money.format(txn.amountPaise)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No entries yet — tap Income or Expense to add one.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
