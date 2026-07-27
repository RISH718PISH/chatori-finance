import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/categories.dart';
import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/models/books.dart';
import '../../data/models/inventory.dart';
import '../books/books_providers.dart' show salaryProvider;
import '../inventory/inventory_providers.dart';
import 'health.dart';
import 'reports_providers.dart';

/// Owner-only "where is the business heading" view: P&L + stock ratios,
/// each with a status and a plain line, plus a channel mix and a
/// what-to-fix-first summary. Reads earned revenue (Customer Advance
/// excluded) so a month isn't flattered by deposits.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedReportMonthProvider);
    final monthKey =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

    final txns = ref.watch(monthTxnsProvider).asData?.value ?? const [];
    final salary =
        ref.watch(salaryProvider).asData?.value ?? const <SalaryRecord>[];
    final stockValue = ref.watch(stockValueTotalProvider) ?? 0;
    final byReason =
        ref.watch(consumptionByReasonProvider(monthKey)).asData?.value ??
            const <ReasonValue>[];
    final wastage =
        ref.watch(wastageByReasonProvider(monthKey)).asData?.value ??
            const <ReasonValue>[];

    // Earned revenue excludes Customer Advance (unearned).
    final revenue = txns
        .where((t) => t.isIncome && t.category != 'Customer Advance')
        .fold<int>(0, (s, t) => s + t.amountPaise);
    final cogs = txns
        .where((t) =>
            !t.isIncome &&
            plSectionFor(t.category, isIncome: false) == PlSection.cogs)
        .fold<int>(0, (s, t) => s + t.amountPaise);
    final operating = txns
        .where((t) =>
            !t.isIncome &&
            plSectionFor(t.category, isIncome: false) == PlSection.operating)
        .fold<int>(0, (s, t) => s + t.amountPaise);
    // Full salary for the month (cash + advance adjusted) — not a txn.
    final salaryPaid = salary
        .where((r) => r.month == monthKey)
        .fold<int>(0, (s, r) => s + r.amountPaidPaise + r.advanceAdjustedPaise);

    final consumptionValue =
        byReason.fold<int>(0, (s, r) => s + r.valuePaise);
    final wastageValue = wastage.fold<int>(0, (s, r) => s + r.valuePaise);

    final report = computeHealth(
      revenuePaise: revenue,
      cogsPaise: cogs,
      salaryPaise: salaryPaid,
      otherOperatingPaise: operating,
      netProfitPaise: revenue - cogs - operating - salaryPaid,
      stockValuePaise: stockValue,
      monthlyConsumptionValuePaise: consumptionValue,
      wastageValuePaise: wastageValue,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Business health')),
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // What to fix first.
                Card(
                  color: AppSemantics.warning.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LabelUpper('What to improve'),
                        const SizedBox(height: 8),
                        for (final line in report.summary)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                Expanded(child: Text(line)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const LabelUpper('Key ratios'),
                const SizedBox(height: 8),
                for (final m in report.metrics) _MetricTile(metric: m),
                if (byReason.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const LabelUpper('Consumption by channel'),
                  const SizedBox(height: 8),
                  for (final r in (byReason.toList()
                    ..sort((a, b) => b.valuePaise.compareTo(a.valuePaise))))
                    _ChannelRow(row: r, total: consumptionValue),
                ],
                const SizedBox(height: 20),
                Text(
                  'Revenue here is what you EARNED — customer advances for '
                  'future parties are excluded. Food cost uses purchases; the '
                  '“used” figure uses consumption and is the truer number.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});
  final HealthMetric metric;

  Color _color() => switch (metric.status) {
        HealthStatus.good => AppSemantics.income,
        HealthStatus.watch => AppSemantics.warning,
        HealthStatus.act => AppSemantics.expense,
        HealthStatus.none => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(metric.note,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DataNumber(metric.valueText, size: DataSize.md, color: color),
          ],
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.row, required this.total});
  final ReasonValue row;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0 : (row.valuePaise / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(row.reason)),
          Text('$pct%',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(Money.format(row.valuePaise, decimals: false),
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
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
