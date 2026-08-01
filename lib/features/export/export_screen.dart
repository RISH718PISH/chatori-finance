import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/export/monthly_workbook.dart';
import '../../data/export/report_exporter.dart';
import '../../data/models/event.dart';
import '../books/books_providers.dart' show salaryProvider;
import '../events/events_providers.dart';
import '../inventory/inventory_providers.dart';
import '../reports/reports_providers.dart';
import '../transaction/transaction_providers.dart';

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// One place to pull everything out — a full Excel workbook for the month
/// (detail sheets + charts) plus the raw CSV feeds. Owner-only (reached from
/// the Home dashboard tile).
class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedReportMonthProvider);
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Export data')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'The monthly Excel report gives you the full picture — a summary '
              'with charts, profit per event, day-by-day cash flow, and every '
              'entry itemised. Opens the share sheet: save to files, email it, '
              'or send to your accountant.',
            ),
          ),
          _MonthHeader(label: monthLabel, ref: ref),
          _FeatureTile(
            icon: Icons.table_chart,
            title: 'Monthly Excel report — $monthLabel',
            subtitle:
                'Summary + charts, event P&L, daily cash flow, all entries',
            onTap: () => _shareMonthlyExcel(context, ref, month),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text('Raw CSV feeds',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          _tile(
            icon: Icons.receipt_long_outlined,
            title: 'All transactions',
            subtitle: 'Every income and expense entry, all time',
            onTap: () => _shareCsv(
              context,
              'chatori-transactions-$stamp.csv',
              () async {
                final t = await ref.read(businessTxnsProvider.future);
                return ReportExporter.buildTransactionsCsv(t);
              },
            ),
          ),
          _tile(
            icon: Icons.restaurant_menu,
            title: 'Consumption — $monthLabel',
            subtitle: 'What was used and wasted, per item',
            onTap: () => _shareCsv(
              context,
              'chatori-consumption-${_key(month)}.csv',
              () async {
                final rows = await ref
                    .read(consumptionForMonthProvider(_key(month)).future);
                return ReportExporter.buildConsumptionCsv(rows);
              },
            ),
          ),
          const Divider(height: 1),
          _tile(
            icon: Icons.inventory_2_outlined,
            title: 'Stock on hand',
            subtitle: 'Snapshot: item, quantity, value, avg cost',
            onTap: () => _shareCsv(
              context,
              'chatori-stock-$stamp.csv',
              () async {
                final items = await ref.read(stockOnHandProvider.future);
                final values = await ref.read(stockValueProvider.future);
                return ReportExporter.buildStockOnHandCsv(
                  items,
                  valueByItem: {for (final v in values) v.itemId: v},
                );
              },
            ),
          ),
          _tile(
            icon: Icons.swap_vert,
            title: 'Stock movements',
            subtitle: 'Full ledger: purchases, usage, wastage, corrections',
            onTap: () => _shareCsv(
              context,
              'chatori-stock-movements-$stamp.csv',
              () async {
                final biz = await ref.read(businessIdProvider.future);
                if (biz == null) return '';
                final activity = await ref
                    .read(inventoryRepoProvider)
                    .fetchRecentActivity(biz, limit: 5000);
                return ReportExporter.buildStockMovementsCsv(activity);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _key(DateTime m) =>
      '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';

  /// Builds and shares the full monthly workbook. Fetches fresh data (awaits
  /// the futures) so it is never empty just because Reports wasn't opened
  /// first — that was the old "exports zeros" bug.
  Future<void> _shareMonthlyExcel(
      BuildContext context, WidgetRef ref, DateTime month) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        duration: Duration(seconds: 1), content: Text('Building report…')));
    try {
      final txns = await ref.read(monthTxnsProvider.future);
      if (txns.isEmpty) {
        messenger.showSnackBar(
            const SnackBar(content: Text('No entries in this month')));
        return;
      }
      final events = await ref.read(eventsProvider.future);
      final salary = await ref.read(salaryProvider.future);
      final salaryPaid = salary
          .where((r) => r.month == _key(month))
          .fold<int>(
              0, (s, r) => s + r.amountPaidPaise + r.advanceAdjustedPaise);

      final bytes = MonthlyWorkbook.build(
        month: month,
        txns: txns,
        eventNames: {for (final Event e in events) e.id: e.name},
        salaryPaidPaise: salaryPaid,
      );
      final filename = 'Chatori-${DateFormat('MMM-yyyy').format(month)}.xlsx';
      final path = await ReportExporter.writeBytesToCache(filename, bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: _xlsxMime)],
          subject: filename,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not export: $e')));
    }
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.ios_share, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _shareCsv(BuildContext context, String filename,
      Future<String> Function() build) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = await build();
      // Header row only → nothing to export.
      if (csv.trim().isEmpty || !csv.contains('\n')) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Nothing to export yet')));
        return;
      }
      final path = await ReportExporter.writeCsvToCache(filename, csv);
      await SharePlus.instance.share(
        ShareParams(
            files: [XFile(path, mimeType: 'text/csv')], subject: filename),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not export: $e')));
    }
  }
}

/// The headline export tile — visually heavier than the CSV rows.
class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 32, color: scheme.onPrimaryContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: scheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                              color: scheme.onPrimaryContainer
                                  .withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Icon(Icons.ios_share, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A month stepper so the export can target any month — reuses the shared
/// selectedReportMonthProvider.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label, required this.ref});
  final String label;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = ref.watch(selectedReportMonthProvider);
    final isThisMonth = month.year == now.year && month.month == now.month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text('MONTH: $label',
                style: Theme.of(context).textTheme.labelMedium),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                ref.read(selectedReportMonthProvider.notifier).prev(),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: isThisMonth
                ? null
                : () => ref.read(selectedReportMonthProvider.notifier).next(),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
