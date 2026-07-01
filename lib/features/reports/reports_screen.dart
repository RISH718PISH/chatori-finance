import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/models/books.dart';
import '../../data/models/txn.dart';
import '../books/books_providers.dart';
import 'reports_providers.dart';

const _pieColors = [
  Color(0xFF2E7D32), Color(0xFF1565C0), Color(0xFFEF6C00), Color(0xFF6A1B9A),
  Color(0xFFC62828), Color(0xFF00838F), Color(0xFFAD1457), Color(0xFF558B2F),
  Color(0xFF4E342E), Color(0xFF37474F), Color(0xFFF9A825), Color(0xFF283593),
];

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedReportMonthProvider);
    final txnsAsync = ref.watch(monthTxnsProvider);
    final salary = ref.watch(salaryProvider).asData?.value ?? const <SalaryRecord>[];
    final advances = ref.watch(advancesProvider).asData?.value ?? const <Advance>[];

    final monthKey =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final salaryPaid = salary
        .where((r) => r.month == monthKey)
        .fold<int>(0, (s, r) => s + r.amountPaidPaise);
    final advanceOutstanding = advances
        .where((a) => a.status != 'closed')
        .fold<int>(0, (s, a) => s + a.outstandingPaise);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          _MonthSelector(
            month: month,
            onPrev: () => ref.read(selectedReportMonthProvider.notifier).prev(),
            onNext: () => ref.read(selectedReportMonthProvider.notifier).next(),
          ),
          Expanded(
            child: txnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txns) => _Report(
                txns: txns,
                salaryPaid: salaryPaid,
                advanceOutstanding: advanceOutstanding,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector(
      {required this.month, required this.onPrev, required this.onNext});
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isThisMonth = () {
      final now = DateTime.now();
      return month.year == now.year && month.month == now.month;
    }();
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

class _Report extends StatelessWidget {
  const _Report({
    required this.txns,
    required this.salaryPaid,
    required this.advanceOutstanding,
  });

  final List<Txn> txns;
  final int salaryPaid;
  final int advanceOutstanding;

  @override
  Widget build(BuildContext context) {
    final income =
        txns.where((t) => t.isIncome).fold<int>(0, (s, t) => s + t.amountPaise);
    final expense =
        txns.where((t) => !t.isIncome).fold<int>(0, (s, t) => s + t.amountPaise);
    final net = income - expense;

    final expenseByCat =
        bucketize(txns, (t) => t.category, where: (t) => !t.isIncome);
    final incomeByCat =
        bucketize(txns, (t) => t.category, where: (t) => t.isIncome);
    final topParties = bucketize(
        txns, (t) => t.partyName ?? 'Unspecified',
        where: (t) => !t.isIncome && (t.partyName?.isNotEmpty ?? false));

    int modeSum(bool cash) => txns
        .where((t) => !t.isIncome && (t.paymentMode == 'Cash') == cash)
        .fold<int>(0, (s, t) => s + t.amountPaise);
    final cash = modeSum(true);
    final digital = modeSum(false);

    if (txns.isEmpty) {
      return const Center(child: Text('No entries for this month.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _card(context, 'Income', income, AppSemantics.income),
            const SizedBox(width: 12),
            _card(context, 'Expenses', expense, AppSemantics.expense),
          ],
        ),
        const SizedBox(height: 12),
        _card(context, 'Net profit / loss', net,
            net >= 0 ? AppSemantics.income : AppSemantics.expense,
            wide: true),
        const SizedBox(height: 12),
        Row(
          children: [
            _card(context, 'Salary paid', salaryPaid, Colors.blue),
            const SizedBox(width: 12),
            _card(context, 'Advance outstanding', advanceOutstanding,
                AppSemantics.warning),
          ],
        ),
        const SizedBox(height: 24),
        if (expenseByCat.isNotEmpty) ...[
          _heading(context, 'Expenses by category'),
          _Pie(buckets: expenseByCat, total: expense),
          const SizedBox(height: 24),
        ],
        if (incomeByCat.isNotEmpty) ...[
          _heading(context, 'Income breakdown'),
          _BarList(buckets: incomeByCat, total: income, color: AppSemantics.income),
          const SizedBox(height: 24),
        ],
        _heading(context, 'Cash vs Digital (expenses)'),
        _BarList(
          buckets: [Bucket('Cash', cash), Bucket('UPI / Bank / Paytm', digital)],
          total: expense,
          color: Colors.teal,
        ),
        const SizedBox(height: 24),
        if (topParties.isNotEmpty) ...[
          _heading(context, 'Top vendors'),
          for (final b in topParties.take(5))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.store_outlined),
              title: Text(b.label),
              trailing: Text(Money.format(b.paise, decimals: false),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ],
    );
  }

  Widget _heading(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _card(BuildContext context, String label, int paise, Color color,
      {bool wide = false}) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(Money.format(paise, decimals: false),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
    return wide ? card : Expanded(child: card);
  }
}

class _Pie extends StatelessWidget {
  const _Pie({required this.buckets, required this.total});
  final List<Bucket> buckets;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (var i = 0; i < buckets.length; i++)
                  PieChartSectionData(
                    value: buckets[i].paise.toDouble(),
                    color: _pieColors[i % _pieColors.length],
                    title: total == 0
                        ? ''
                        : '${(buckets[i].paise / total * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (var i = 0; i < buckets.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      color: _pieColors[i % _pieColors.length]),
                  const SizedBox(width: 4),
                  Text(
                      '${buckets[i].label}  ${Money.format(buckets[i].paise, decimals: false)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _BarList extends StatelessWidget {
  const _BarList(
      {required this.buckets, required this.total, required this.color});
  final List<Bucket> buckets;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final b in buckets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.label),
                    Text(Money.format(b.paise, decimals: false),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : b.paise / total,
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
