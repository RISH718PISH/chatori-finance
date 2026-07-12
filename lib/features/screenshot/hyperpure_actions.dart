import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../transaction/transaction_providers.dart';
import 'hyperpure_parser.dart';

class HyperpureSaveResult {
  final int savedCount;
  final List<String> categories;
  final int totalPaise;
  const HyperpureSaveResult({
    required this.savedCount,
    required this.categories,
    required this.totalPaise,
  });
}

/// Batch-saves a parsed Hyperpure bill as N expense transactions, one per
/// auto-detected category, sharing party/date/event/attachment. Used by both
/// the auto-save button on the scan screen and the review screen's Save.
Future<HyperpureSaveResult> saveHyperpureBillAsBatch({
  required WidgetRef ref,
  required ParsedHyperpure parsed,
  String? attachmentLocalPath,
  String paymentMode = 'Bank',
  DateTime? occurredAt,
  String party = 'Hyperpure',
  String? eventId,
}) async {
  final biz = await ref.read(businessIdProvider.future);
  if (biz == null) {
    throw StateError('No business found. Please sign in again.');
  }

  final grandTotal = parsed.totalPaise ??
      parsed.items.fold<int>(0, (s, it) => s + it.amountPaise);

  var groups = groupHyperpureItemsByCategory(parsed.items);
  // Fallback: parser found no items — seed one Groceries row with the total.
  if (groups.isEmpty && grandTotal > 0) {
    groups = [
      HyperpureCategoryGroup(
        category: 'Groceries',
        items: const [],
        totalPaise: grandTotal,
      ),
    ];
  }

  String? attachmentPath;
  if (attachmentLocalPath != null) {
    attachmentPath = await ref.read(attachmentRepoProvider).store(
          businessId: biz,
          localImagePath: attachmentLocalPath,
        );
  }

  final invoiceRef = parsed.invoiceNumber == null
      ? 'Hyperpure invoice'
      : 'Hyperpure invoice ${parsed.invoiceNumber}';

  final rows = <({String category, int amountPaise, String? notes})>[
    for (final g in groups)
      (
        category: g.category,
        amountPaise: g.totalPaise,
        notes: [
          invoiceRef,
          if (g.items.isNotEmpty)
            g.items
                .take(4)
                .map((it) =>
                    '• ${it.description} — ${Money.format(it.amountPaise)}')
                .join('\n'),
          if (g.items.length > 4)
            '… +${g.items.length - 4} more in this category',
        ].join('\n'),
      ),
  ];

  await ref.read(transactionRepoProvider).addBatch(
        businessId: biz,
        rows: rows,
        type: 'expense',
        paymentMode: paymentMode,
        occurredAt: occurredAt ?? parsed.invoiceDate ?? DateTime.now(),
        partyName: party,
        source: 'screenshot',
        eventId: eventId,
        attachmentPath: attachmentPath,
      );
  refreshTransactions(ref);

  return HyperpureSaveResult(
    savedCount: rows.length,
    categories: [for (final g in groups) g.category],
    totalPaise: grandTotal,
  );
}
