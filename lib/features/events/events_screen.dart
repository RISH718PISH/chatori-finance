import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/models/event.dart';
import '../transaction/transaction_providers.dart';
import '../widgets/amount_field.dart';
import '../widgets/date_field.dart';
import 'events_providers.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEvent(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration_outlined,
                      size: 56, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No events yet.\nTap "Add event" to begin.',
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          final upcoming =
              events.where((e) => e.status == 'upcoming').toList();
          final done = events.where((e) => e.status == 'done').toList();
          final settled = events.where((e) => e.status == 'settled').toList();
          return RefreshIndicator(
            onRefresh: () async {
              refreshEvents(ref);
              ref.invalidate(businessTxnsProvider);
              try {
                await ref.read(eventsProvider.future);
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const _SectionHeader('Upcoming'),
                  for (final e in upcoming) _EventTile(event: e),
                ],
                if (done.isNotEmpty) ...[
                  const _SectionHeader('Done'),
                  for (final e in done) _EventTile(event: e),
                ],
                if (settled.isNotEmpty) ...[
                  const _SectionHeader('Settled'),
                  for (final e in settled) _EventTile(event: e),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addEvent(BuildContext context, WidgetRef ref) async {
    final nameCtl = TextEditingController();
    final customerCtl = TextEditingController();
    final guestsCtl = TextEditingController();
    final notesCtl = TextEditingController();
    var quotedPaise = 0;
    var date = DateTime.now();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add event', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Event name',
                  hintText: 'e.g. Sharma wedding — 15 Aug'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customerCtl,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(labelText: 'Customer (optional)'),
            ),
            const SizedBox(height: 12),
            DateField(
                label: 'Event date',
                initial: date,
                allowFuture: true,
                onChanged: (d) => date = d),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: guestsCtl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Guests (optional)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AmountField(
                      label: 'Quoted amount',
                      onChanged: (p) => quotedPaise = p),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save event'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || nameCtl.text.trim().isEmpty) return;
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    await ref.read(eventsRepoProvider).create(
          businessId: biz,
          name: nameCtl.text.trim(),
          customerName: customerCtl.text.trim().isEmpty
              ? null
              : customerCtl.text.trim(),
          eventDate: date,
          guestCount: int.tryParse(guestsCtl.text.trim()),
          quotedAmountPaise: quotedPaise,
          notes: notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim(),
        );
    refreshEvents(ref);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: LabelUpper(text),
      );
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pnl = ref.watch(eventPnlProvider(event.id));
    final netColor =
        pnl.netPaise >= 0 ? AppSemantics.income : AppSemantics.expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/events/${event.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        [
                          DateFormat('d MMM yyyy').format(event.eventDate),
                          if ((event.guestCount ?? 0) > 0)
                            '${event.guestCount} guests',
                          if (event.quotedAmountPaise > 0)
                            'quoted ${Money.format(event.quotedAmountPaise, decimals: false)}',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DataNumber(
                      Money.format(pnl.netPaise, decimals: false),
                      size: DataSize.sm,
                      color: netColor,
                    ),
                    Text('net', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
