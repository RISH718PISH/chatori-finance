import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/models/event.dart';
import '../../data/models/txn.dart';
import '../transaction/transaction_providers.dart';
import 'events_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final txns = ref.watch(eventTxnsProvider(eventId));
    final pnl = ref.watch(eventPnlProvider(eventId));

    return eventsAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (events) {
        final matches = events.where((e) => e.id == eventId).toList();
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Event not found.')),
          );
        }
        final event = matches.first;
        return _EventDetail(event: event, txns: txns, pnl: pnl);
      },
    );
  }
}

class _EventDetail extends ConsumerWidget {
  const _EventDetail(
      {required this.event, required this.txns, required this.pnl});

  final Event event;
  final List<Txn> txns;
  final EventPnl pnl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toCollect = (event.quotedAmountPaise - pnl.incomePaise)
        .clamp(0, event.quotedAmountPaise);
    final guests = event.guestCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Delete event',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/add?type=expense&event=${event.id}'),
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshEvents(ref);
          ref.invalidate(businessTxnsProvider);
          try {
            await ref.read(businessTxnsProvider.future);
          } catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      DateFormat('EEE, d MMM yyyy').format(event.eventDate),
                      if (guests > 0) '$guests guests',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                ActionChip(
                  label: Text(event.status.toUpperCase()),
                  labelStyle: AppText.labelUpper(context),
                  onPressed: () async {
                    await ref
                        .read(eventsRepoProvider)
                        .updateStatus(event.id, nextEventStatus(event.status));
                    refreshEvents(ref);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // P&L block
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LabelUpper('Event P&L'),
                    const SizedBox(height: 12),
                    _row(context, 'Revenue received',
                        Money.format(pnl.incomePaise),
                        color: AppSemantics.income),
                    if (event.quotedAmountPaise > 0)
                      _row(context, 'Quoted',
                          Money.format(event.quotedAmountPaise)),
                    const Divider(height: 20),
                    _row(context, 'Total expenses',
                        Money.format(pnl.expensePaise),
                        color: AppSemantics.expense),
                    for (final e in (pnl.expenseByCategory.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value))))
                      _row(context, '   ${e.key}', Money.format(e.value),
                          small: true),
                    const Divider(height: 20),
                    _row(
                      context,
                      'Net profit',
                      '${Money.format(pnl.netPaise)}'
                          '${pnl.incomePaise > 0 ? '  (${pnl.marginPct.toStringAsFixed(1)}%)' : ''}',
                      color: pnl.netPaise >= 0
                          ? AppSemantics.income
                          : AppSemantics.expense,
                      bold: true,
                    ),
                    if (guests > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _perPlate(context, 'Revenue / plate',
                                pnl.incomePaise ~/ guests),
                          ),
                          Expanded(
                            child: _perPlate(context, 'Cost / plate',
                                pnl.expensePaise ~/ guests),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Money to collect
            if (!event.isSettled && toCollect > 0) ...[
              const SizedBox(height: 12),
              Card(
                color: AppSemantics.warning.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: AppSemantics.warning.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_bottom,
                          color: AppSemantics.warning),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Money to collect')),
                      DataNumber(Money.format(toCollect),
                          size: DataSize.md, color: AppSemantics.warning),
                    ],
                  ),
                ),
              ),
            ],

            // Linked transactions
            const SizedBox(height: 20),
            LabelUpper('Linked entries (${txns.length})'),
            const SizedBox(height: 8),
            if (txns.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text(
                        'No entries linked yet.\nUse "Add entry" or pick this event when adding a transaction.',
                        textAlign: TextAlign.center)),
              )
            else
              for (final t in txns) _TxnRow(txn: t),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {Color? color, bool bold = false, bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: small
                  ? Theme.of(context).textTheme.bodySmall
                  : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          DataNumber(value,
              size: small ? DataSize.sm : (bold ? DataSize.md : DataSize.sm),
              color: color),
        ],
      ),
    );
  }

  Widget _perPlate(BuildContext context, String label, int paise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelUpper(label),
        const SizedBox(height: 4),
        DataNumber(Money.format(paise), size: DataSize.md),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${event.name}"?'),
        content: const Text(
            'Linked transactions stay in your books; only the event record is removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(eventsRepoProvider).delete(event.id);
    refreshEvents(ref);
    ref.invalidate(businessTxnsProvider);
    if (context.mounted) context.pop();
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});
  final Txn txn;

  @override
  Widget build(BuildContext context) {
    final color = txn.isIncome ? AppSemantics.income : AppSemantics.expense;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/add', extra: txn),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(txn.isIncome ? Icons.south_west : Icons.north_east,
            color: color),
      ),
      title: Text(txn.category),
      subtitle: Text(
        [
          txn.paymentMode,
          if ((txn.partyName ?? '').isNotEmpty) txn.partyName,
          DateFormat('d MMM').format(txn.occurredAt),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: DataNumber(
        '${txn.isIncome ? '+' : '−'}${Money.format(txn.amountPaise)}',
        size: DataSize.sm,
        color: color,
      ),
    );
  }
}
