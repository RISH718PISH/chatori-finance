import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/export/report_exporter.dart';
import '../../data/models/books.dart';
import '../../data/models/txn.dart';
import '../books/books_providers.dart';
import '../transaction/transaction_providers.dart';
import 'reports_providers.dart';

const _pieColors = [
  Color(0xFF2E7D32), Color(0xFF1565C0), Color(0xFFEF6C00), Color(0xFF6A1B9A),
  Color(0xFFC62828), Color(0xFF00838F), Color(0xFFAD1457), Color(0xFF558B2F),
  Color(0xFF4E342E), Color(0xFF37474F), Color(0xFFF9A825), Color(0xFF283593),
];

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _view = 'overview'; // overview | pl

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Share report',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showShareSheet(
              context: context,
              month: month,
              txns: txnsAsync.asData?.value ?? const [],
              salaryPaid: salaryPaid,
              advanceOutstanding: advanceOutstanding,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthSelector(
            month: month,
            onPrev: () => ref.read(selectedReportMonthProvider.notifier).prev(),
            onNext: () => ref.read(selectedReportMonthProvider.notifier).next(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'overview', label: Text('Overview')),
                ButtonSegment(value: 'pl', label: Text('P&L')),
              ],
              selected: {_view},
              onSelectionChanged: (s) => setState(() => _view = s.first),
            ),
          ),
          Expanded(
            child: txnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txns) => _view == 'pl'
                  ? _PlView(txns: txns)
                  : _Report(
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

/// Structured monthly P&L: Revenue → COGS → Gross profit → Operating → Net.
class _PlView extends ConsumerWidget {
  const _PlView({required this.txns});
  final List<Txn> txns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pl = MonthlyPl.fromTxns(txns);
    final prevAsync = ref.watch(prevMonthTxnsProvider);
    final prev = prevAsync.asData?.value == null
        ? null
        : MonthlyPl.fromTxns(prevAsync.asData!.value);

    if (txns.isEmpty) {
      return const Center(child: Text('No entries for this month.'));
    }

    final foodCostHigh = pl.foodCostPct > 40;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _plSection(context, 'Revenue', pl.revenue, AppSemantics.income),
        _plTotal(context, 'Total Revenue', pl.totalRevenue,
            color: AppSemantics.income),
        const Divider(height: 32),
        _plSection(context, 'Cost of goods sold', pl.cogs,
            AppSemantics.expense),
        _plTotal(context, 'Total COGS', pl.totalCogs,
            color: AppSemantics.expense),
        const SizedBox(height: 12),
        _plTotal(
          context,
          'Gross profit',
          pl.grossProfit,
          suffix: pl.totalRevenue > 0
              ? '  (${pl.grossMarginPct.toStringAsFixed(1)}%)'
              : null,
          color:
              pl.grossProfit >= 0 ? AppSemantics.income : AppSemantics.expense,
          emphasized: true,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text('Food cost', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text(
                '${pl.foodCostPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: foodCostHigh
                      ? AppSemantics.warning
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (foodCostHigh)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.warning_amber,
                      size: 16, color: AppSemantics.warning),
                ),
            ],
          ),
        ),
        const Divider(height: 32),
        _plSection(context, 'Operating expenses', pl.operating,
            AppSemantics.expense),
        _plTotal(context, 'Total Operating', pl.totalOperating,
            color: AppSemantics.expense),
        const Divider(height: 32),
        _plTotal(
          context,
          'NET PROFIT',
          pl.netProfit,
          suffix: pl.totalRevenue > 0
              ? '  (${pl.netMarginPct.toStringAsFixed(1)}%)'
              : null,
          color:
              pl.netProfit >= 0 ? AppSemantics.income : AppSemantics.expense,
          emphasized: true,
        ),
        if (prev != null) ...[
          const SizedBox(height: 24),
          LabelUpper('vs previous month'),
          const SizedBox(height: 8),
          _momRow(context, 'Revenue', pl.totalRevenue, prev.totalRevenue,
              upIsGood: true),
          _momRow(context, 'COGS', pl.totalCogs, prev.totalCogs,
              upIsGood: false),
          _momRow(context, 'Net', pl.netProfit, prev.netProfit,
              upIsGood: true),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _plSection(
      BuildContext context, String title, List<Bucket> rows, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelUpper(title),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child:
                Text('None', style: Theme.of(context).textTheme.bodySmall),
          )
        else
          for (final b in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(b.label)),
                  DataNumber(Money.format(b.paise, decimals: false),
                      size: DataSize.sm),
                ],
              ),
            ),
      ],
    );
  }

  Widget _plTotal(BuildContext context, String label, int paise,
      {String? suffix, Color? color, bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight:
                        emphasized ? FontWeight.w700 : FontWeight.w600)),
          ),
          DataNumber(
            '${Money.format(paise, decimals: false)}${suffix ?? ''}',
            size: emphasized ? DataSize.md : DataSize.sm,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _momRow(
      BuildContext context, String label, int current, int previous,
      {required bool upIsGood}) {
    final delta = current - previous;
    final up = delta >= 0;
    final good = up == upIsGood;
    final color = delta == 0
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : (good ? AppSemantics.income : AppSemantics.expense);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: color, size: 20),
          DataNumber(
            Money.format(delta.abs(), decimals: false),
            size: DataSize.sm,
            color: color,
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

class _Report extends ConsumerWidget {
  const _Report({
    required this.txns,
    required this.salaryPaid,
    required this.advanceOutstanding,
  });

  final List<Txn> txns;
  final int salaryPaid;
  final int advanceOutstanding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // A "Cash+UPI" split contributes to BOTH cash and digital totals — this
    // is why we now derive from cashPortionPaise / digitalPortionPaise on
    // each Txn rather than the paymentMode label. Pure-Cash / pure-UPI rows
    // behave the same as before.
    final cash = txns
        .where((t) => !t.isIncome)
        .fold<int>(0, (s, t) => s + t.cashPortionPaise);
    final digital = txns
        .where((t) => !t.isIncome)
        .fold<int>(0, (s, t) => s + t.digitalPortionPaise);

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
          _Pie(
            buckets: expenseByCat,
            total: expense,
            onSliceTap: (category) => _showCategoryDrillDown(
                context, ref, category, txns),
          ),
          const SizedBox(height: 24),
        ],
        if (incomeByCat.isNotEmpty) ...[
          _heading(context, 'Income breakdown'),
          _BarList(buckets: incomeByCat, total: income, color: AppSemantics.income),
          const SizedBox(height: 24),
        ],
        _heading(context, 'Cash vs Digital (expenses)'),
        _BarList(
          buckets: [Bucket('Cash', cash), Bucket('UPI / Bank', digital)],
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
  const _Pie({required this.buckets, required this.total, this.onSliceTap});
  final List<Bucket> buckets;
  final int total;

  /// If provided, tapping a slice or a legend row invokes this with the
  /// bucket label (typically a category name). Null → chart is display-only.
  final ValueChanged<String>? onSliceTap;

  @override
  Widget build(BuildContext context) {
    // Consistent percentages: sum to exactly 100, slice labels match legend.
    final pct = percentagesSummingTo100(buckets, total);
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                enabled: onSliceTap != null,
                touchCallback: (event, response) {
                  if (onSliceTap == null) return;
                  if (event is! FlTapUpEvent) return;
                  final idx = response?.touchedSection?.touchedSectionIndex;
                  if (idx == null || idx < 0 || idx >= buckets.length) return;
                  onSliceTap!(buckets[idx].label);
                },
              ),
              sections: [
                for (var i = 0; i < buckets.length; i++)
                  PieChartSectionData(
                    value: buckets[i].paise.toDouble(),
                    color: _pieColors[i % _pieColors.length],
                    title: total == 0 ? '' : '${pct[i]}%',
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
              InkWell(
                onTap: onSliceTap == null
                    ? null
                    : () => onSliceTap!(buckets[i].label),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          color: _pieColors[i % _pieColors.length]),
                      const SizedBox(width: 4),
                      Text(
                          '${buckets[i].label}  ${Money.format(buckets[i].paise, decimals: false)}  (${pct[i]}%)',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (onSliceTap != null) ...[
          const SizedBox(height: 6),
          Text(
            'Tap a slice or category for details',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).hintColor),
          ),
        ],
      ],
    );
  }
}

Future<void> _showCategoryDrillDown(
  BuildContext context,
  WidgetRef ref,
  String category,
  List<Txn> monthTxns,
) {
  final rows = monthTxns
      .where((t) => !t.isIncome && t.category == category)
      .toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final total = rows.fold<int>(0, (s, t) => s + t.amountPaise);
  final members = ref.read(businessMembersProvider).asData?.value;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category,
                          style: Theme.of(ctx).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${rows.length} '
                        '${rows.length == 1 ? 'entry' : 'entries'}',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  Money.format(total, decimals: false),
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      color: AppSemantics.expense,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: rows.isEmpty
                ? const Center(child: Text('No entries in this category.'))
                : ListView.separated(
                    controller: scroll,
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _DrillTile(txn: rows[i], members: members),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _DrillTile extends StatelessWidget {
  const _DrillTile({required this.txn, this.members});
  final Txn txn;
  final Map<String, String>? members;

  @override
  Widget build(BuildContext context) {
    final byWhom = attributionFor(members, txn.createdBy);
    final subtitle = [
      txn.paymentMode,
      if ((txn.partyName ?? '').isNotEmpty) txn.partyName,
      DateFormat('d MMM, h:mm a').format(txn.occurredAt),
      ?byWhom,
    ].join(' · ');
    return ListTile(
      onTap: () {
        Navigator.of(context).pop();
        context.push('/add', extra: txn);
      },
      leading: const CircleAvatar(
        backgroundColor: Color(0x22B71C1C),
        child: Icon(Icons.north_east, color: AppSemantics.expense),
      ),
      title: Text(txn.category),
      subtitle: Text(subtitle,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '−${Money.format(txn.amountPaise)}',
        style: const TextStyle(
            color: AppSemantics.expense, fontWeight: FontWeight.bold),
      ),
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

void _showShareSheet({
  required BuildContext context,
  required DateTime month,
  required List<Txn> txns,
  required int salaryPaid,
  required int advanceOutstanding,
}) {
  final monthLabel = DateFormat('MMMM yyyy').format(month);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Share summary text'),
            subtitle: const Text('Paste into WhatsApp, email, or notes'),
            onTap: () async {
              Navigator.pop(ctx);
              final text = ReportExporter.buildMonthlySummaryText(
                month: month,
                txns: txns,
                salaryPaidPaise: salaryPaid,
                advanceOutstandingPaise: advanceOutstanding,
              );
              await SharePlus.instance.share(
                ShareParams(text: text, subject: 'Chatori Finance — $monthLabel'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Share P&L statement'),
            subtitle: const Text('Revenue → COGS → Net, as plain text'),
            enabled: txns.isNotEmpty,
            onTap: () async {
              Navigator.pop(ctx);
              final pl = MonthlyPl.fromTxns(txns);
              final text = ReportExporter.buildPlText(
                month: month,
                revenue: pl.revenue,
                cogs: pl.cogs,
                operating: pl.operating,
              );
              await SharePlus.instance.share(
                ShareParams(text: text, subject: 'P&L — $monthLabel'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export CSV'),
            subtitle: Text(
                '${txns.length} entries · opens in Excel / Google Sheets'),
            enabled: txns.isNotEmpty,
            onTap: () async {
              Navigator.pop(ctx);
              final csv = ReportExporter.buildTransactionsCsv(txns);
              final path = await ReportExporter.writeCsvToCache(
                'chatori-${DateFormat('yyyy-MM').format(month)}.csv',
                csv,
              );
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(path, mimeType: 'text/csv')],
                  subject: 'Chatori Finance CSV — $monthLabel',
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

