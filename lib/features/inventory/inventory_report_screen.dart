import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../reports/reports_providers.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';

/// Owner-only monthly view. The headline is "Purchases vs consumption" —
/// the line that shows how much cash went into stock that is still sitting
/// in the store. The P&L is untouched; this is explicitly a separate lens.
class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedReportMonthProvider);
    final monthKey =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final consumption = ref.watch(consumptionForMonthProvider(monthKey));
    final values = ref.watch(stockValueProvider).asData?.value ?? const [];
    final wac = {for (final v in values) v.itemId: v.paisePerMilli};
    final stockValueTotal = ref.watch(stockValueTotalProvider);

    // Purchases this month (COGS-ish): the scanned-expense transactions.
    final monthTxns = ref.watch(monthTxnsProvider).asData?.value ?? const [];
    final purchasedPaise = monthTxns
        .where((t) => !t.isIncome && t.source == 'screenshot')
        .fold<int>(0, (s, t) => s + t.amountPaise);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock report')),
      body: Column(
        children: [
          _MonthBar(
            month: month,
            onPrev: () =>
                ref.read(selectedReportMonthProvider.notifier).prev(),
            onNext: () =>
                ref.read(selectedReportMonthProvider.notifier).next(),
          ),
          const Divider(height: 1),
          Expanded(
            child: consumption.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rows) {
                final consumedValue = rows.fold<int>(0, (s, r) {
                  final rate = wac[r.itemId] ?? 0;
                  return s + (r.consumedMilli * rate).round();
                });
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        _card(context, 'Stock value now',
                            stockValueTotal == null
                                ? '—'
                                : Money.format(stockValueTotal,
                                    decimals: false),
                            color: AppSemantics.income),
                        const SizedBox(width: 12),
                        _card(context, 'Consumed value',
                            Money.format(consumedValue, decimals: false),
                            color: AppSemantics.expense),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PurchaseVsConsumption(
                      purchasedPaise: purchasedPaise,
                      consumedPaise: consumedValue,
                    ),
                    const SizedBox(height: 20),
                    const LabelUpper('Consumed this month'),
                    const SizedBox(height: 8),
                    if (rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No usage recorded this month.'),
                      )
                    else
                      for (final r in (rows.toList()
                        ..sort((a, b) {
                          final av = (a.consumedMilli * (wac[a.itemId] ?? 0));
                          final bv = (b.consumedMilli * (wac[b.itemId] ?? 0));
                          return bv.compareTo(av);
                        })))
                        _ConsumedRow(row: r, ratePaisePerMilli: wac[r.itemId]),
                    const SizedBox(height: 20),
                    const _RecentActivity(),
                    const SizedBox(height: 20),
                    Text(
                      'Your P&L is unchanged — it still counts purchases as '
                      'cost. This page is a separate view of what you have '
                      'actually used versus what is still in the store.',
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _card(BuildContext context, String label, String value,
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
              DataNumber(value, size: DataSize.md, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseVsConsumption extends StatelessWidget {
  const _PurchaseVsConsumption({
    required this.purchasedPaise,
    required this.consumedPaise,
  });
  final int purchasedPaise;
  final int consumedPaise;

  @override
  Widget build(BuildContext context) {
    final buildup = purchasedPaise - consumedPaise;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, 'Food purchased (scanned bills)', purchasedPaise),
            _row(context, 'Food consumed (qty × avg cost)', consumedPaise),
            const Divider(height: 20),
            _row(
              context,
              buildup >= 0 ? 'Stock build-up' : 'Drew down stock',
              buildup.abs(),
              bold: true,
              color: buildup >= 0 ? AppSemantics.warning : AppSemantics.income,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, int paise,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          ),
          DataNumber(Money.format(paise, decimals: false),
              size: bold ? DataSize.md : DataSize.sm, color: color),
        ],
      ),
    );
  }
}

class _ConsumedRow extends StatelessWidget {
  const _ConsumedRow({required this.row, this.ratePaisePerMilli});
  final ConsumptionRow row;
  final double? ratePaisePerMilli;

  @override
  Widget build(BuildContext context) {
    final value = ratePaisePerMilli == null
        ? null
        : (row.consumedMilli * ratePaisePerMilli!).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(row.name)),
          Text(Quantity.format(row.consumedMilli, row.dimension),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 16),
          SizedBox(
            width: 84,
            child: Text(
              value == null ? '—' : Money.format(value, decimals: false),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "when did stock change, and who" feed — newest first, across items.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(recentActivityProvider);
    final members = ref.watch(businessMembersProvider).asData?.value ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LabelUpper('Recent activity'),
        const SizedBox(height: 8),
        activity.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (list) {
            if (list.isEmpty) {
              return Text('No stock changes yet.',
                  style: Theme.of(context).textTheme.bodySmall);
            }
            return Column(
              children: [
                for (final a in list.take(20))
                  _ActivityRow(activity: a, members: members),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.members});
  final StockActivity activity;
  final Map<String, String> members;

  @override
  Widget build(BuildContext context) {
    final into = activity.qtyMilli > 0;
    final color = into ? AppSemantics.income : AppSemantics.expense;
    final who = attributionFor(members, activity.createdBy);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(into ? Icons.south_west : Icons.north_east,
          color: color, size: 20),
      title: Text('${activity.itemName} · ${activity.type.label}'),
      subtitle: Text([
        DateFormat('d MMM, h:mm a').format(activity.createdAt),
        if ((activity.reason ?? '').isNotEmpty) activity.reason,
        ?who,
      ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: DataNumber(
        '${into ? '+' : '−'}${Quantity.format(activity.qtyMilli.abs(), activity.dimension)}',
        size: DataSize.sm,
        color: color,
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar(
      {required this.month, required this.onPrev, required this.onNext});
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isThisMonth = month.year == now.year && month.month == now.month;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(DateFormat('MMMM yyyy').format(month),
              style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            onPressed: isThisMonth ? null : onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
