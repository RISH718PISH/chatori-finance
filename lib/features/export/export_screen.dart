import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/export/report_exporter.dart';
import '../../data/models/books.dart';
import '../../data/models/inventory.dart';
import '../../data/models/txn.dart';
import '../books/books_providers.dart' show salaryProvider;
import '../inventory/inventory_providers.dart';
import '../reports/reports_providers.dart';
import '../transaction/transaction_providers.dart';

/// One place to pull everything out as CSV — for Excel, the CA, or a
/// backup. Owner-only (reached from the Home dashboard tile).
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
              'Download your data as a spreadsheet (CSV). Opens the share '
              'sheet — save to files, email it, or send to your accountant.',
            ),
          ),
          _tile(
            icon: Icons.receipt_long_outlined,
            title: 'All transactions',
            subtitle: 'Every income and expense entry',
            onTap: () => _share(
              context,
              'chatori-transactions-$stamp.csv',
              () async {
                final t = ref.read(businessTxnsProvider).asData?.value ??
                    const <Txn>[];
                return ReportExporter.buildTransactionsCsv(t);
              },
            ),
          ),
          const Divider(height: 1),
          _tile(
            icon: Icons.inventory_2_outlined,
            title: 'Stock on hand',
            subtitle: 'Snapshot: item, quantity, value, avg cost',
            onTap: () => _share(
              context,
              'chatori-stock-$stamp.csv',
              () async {
                final items =
                    ref.read(stockOnHandProvider).asData?.value ?? const [];
                final values =
                    ref.read(stockValueProvider).asData?.value ?? const [];
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
            onTap: () => _share(
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
          const Divider(height: 1),
          _MonthHeader(label: monthLabel, ref: ref),
          _tile(
            icon: Icons.assessment_outlined,
            title: 'Monthly P&L — $monthLabel',
            subtitle: 'Revenue, COGS, operating, net',
            onTap: () => _share(
              context,
              'chatori-pl-${_key(month)}.csv',
              () async {
                final pl = _plFor(ref, month);
                return ReportExporter.buildPlCsv(
                  revenue: pl.revenue,
                  cogs: pl.cogs,
                  operating: pl.operating,
                );
              },
            ),
          ),
          _tile(
            icon: Icons.restaurant_menu,
            title: 'Consumption — $monthLabel',
            subtitle: 'What was used and wasted, per item',
            onTap: () => _share(
              context,
              'chatori-consumption-${_key(month)}.csv',
              () async {
                final rows =
                    ref.read(consumptionForMonthProvider(_key(month))).asData?.value ??
                        const <ConsumptionRow>[];
                return ReportExporter.buildConsumptionCsv(rows);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _key(DateTime m) =>
      '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';

  /// Builds the month's P&L the same way the Reports screen does (salary
  /// folded in), so the export matches what the owner sees on screen.
  MonthlyPl _plFor(WidgetRef ref, DateTime month) {
    final txns = ref.read(monthTxnsProvider).asData?.value ?? const <Txn>[];
    final salary =
        ref.read(salaryProvider).asData?.value ?? const <SalaryRecord>[];
    final salaryPaid = salary
        .where((r) => r.month == _key(month))
        .fold<int>(0, (s, r) => s + r.amountPaidPaise + r.advanceAdjustedPaise);
    return MonthlyPl.fromTxns(txns, salaryForMonthPaise: salaryPaid);
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

  Future<void> _share(BuildContext context, String filename,
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
        ShareParams(files: [XFile(path, mimeType: 'text/csv')], subject: filename),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not export: $e')));
    }
  }
}

/// A month stepper so the P&L / consumption exports can target any month —
/// reuses the shared selectedReportMonthProvider.
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
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
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
