import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/categories.dart';
import '../../core/design.dart';
import '../../core/money.dart';
import '../events/events_providers.dart';
import '../transaction/transaction_providers.dart';
import 'hyperpure_parser.dart';

/// Auto-split review for a Hyperpure invoice. Groups line items by category,
/// shows one editable row per category, and saves the whole bill as N
/// transactions (one per category) sharing party/date/event/attachment.
class HyperpureSplitScreen extends ConsumerStatefulWidget {
  const HyperpureSplitScreen({
    super.key,
    required this.parsed,
    this.attachmentLocalPath,
  });

  final ParsedHyperpure parsed;
  final String? attachmentLocalPath;

  @override
  ConsumerState<HyperpureSplitScreen> createState() =>
      _HyperpureSplitScreenState();
}

class _SplitRow {
  String category;
  int amountPaise;
  List<HyperpureLineItem> items;
  _SplitRow(
      {required this.category, required this.amountPaise, required this.items});
}

class _HyperpureSplitScreenState extends ConsumerState<HyperpureSplitScreen> {
  late final List<_SplitRow> _rows;
  late final int _grandTotal;
  String _paymentMode = 'Bank';
  DateTime _date = DateTime.now();
  String _party = 'Hyperpure';
  String? _eventId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _grandTotal = widget.parsed.totalPaise ??
        widget.parsed.items
            .fold<int>(0, (s, it) => s + it.amountPaise);
    _date = widget.parsed.invoiceDate ?? DateTime.now();
    _rows = groupHyperpureItemsByCategory(widget.parsed.items)
        .map((g) => _SplitRow(
              category: g.category,
              amountPaise: g.totalPaise,
              items: g.items,
            ))
        .toList();
    // If parser found NO items, seed one Groceries row with the whole total
    // so the user still gets a working split screen.
    if (_rows.isEmpty && _grandTotal > 0) {
      _rows.add(_SplitRow(
          category: 'Groceries', amountPaise: _grandTotal, items: const []));
    }
  }

  int get _splitTotal =>
      _rows.fold<int>(0, (s, r) => s + r.amountPaise);
  int get _diffPaise => _grandTotal - _splitTotal;
  bool get _canSave => _rows.isNotEmpty &&
      _rows.every((r) => r.amountPaise > 0 && r.category.isNotEmpty) &&
      !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final biz = await ref.read(businessIdProvider.future);
      if (biz == null) {
        _snack('No business found. Please sign in again.');
        return;
      }
      String? attachmentPath;
      if (widget.attachmentLocalPath != null) {
        attachmentPath = await ref.read(attachmentRepoProvider).store(
              businessId: biz,
              localImagePath: widget.attachmentLocalPath!,
            );
      }
      final invoiceRef = widget.parsed.invoiceNumber == null
          ? 'Hyperpure invoice'
          : 'Hyperpure invoice ${widget.parsed.invoiceNumber}';
      final rows = <({String category, int amountPaise, String? notes})>[
        for (final r in _rows)
          (
            category: r.category,
            amountPaise: r.amountPaise,
            notes: [
              invoiceRef,
              if (r.items.isNotEmpty)
                r.items
                    .take(4)
                    .map((it) => '• ${it.description} — '
                        '${Money.format(it.amountPaise)}')
                    .join('\n'),
              if (r.items.length > 4)
                '… +${r.items.length - 4} more in this category',
            ].join('\n'),
          ),
      ];
      await ref.read(transactionRepoProvider).addBatch(
            businessId: biz,
            rows: rows,
            type: 'expense',
            paymentMode: _paymentMode,
            occurredAt: _date,
            partyName: _party,
            source: 'screenshot',
            eventId: _eventId,
            attachmentPath: attachmentPath,
          );
      if (!mounted) return;
      refreshTransactions(ref);
      _snack('Saved ${_rows.length} entries ✓', good: true);
      // Pop back to Home (past the scan screen too).
      context.go('/');
    } catch (e) {
      _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool good = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: good ? AppSemantics.income : null,
        content: Text(msg,
            style: good ? const TextStyle(color: Colors.white) : null),
      ));
  }

  void _distributeDiff() {
    if (_diffPaise == 0 || _rows.isEmpty) return;
    setState(() {
      // Put the whole difference on the biggest row so grand total ties out.
      final biggest = _rows
          .reduce((a, b) => a.amountPaise >= b.amountPaise ? a : b);
      final adjusted = biggest.amountPaise + _diffPaise;
      biggest.amountPaise = adjusted < 0 ? 0 : adjusted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ok = _diffPaise == 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Hyperpure bill'),
        actions: [
          if (_grandTotal > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  Money.format(_grandTotal, decimals: false),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          // Invoice header snapshot
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.parsed.invoiceNumber == null
                              ? 'Hyperpure invoice'
                              : widget.parsed.invoiceNumber!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(DateFormat('d MMM yyyy').format(_date),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.parsed.items.length} items · '
                    'Taxable ${widget.parsed.taxablePaise != null ? Money.format(widget.parsed.taxablePaise!, decimals: false) : '—'} · '
                    'Tax ${widget.parsed.taxPaise != null ? Money.format(widget.parsed.taxPaise!, decimals: false) : '—'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Split into ${_rows.length} categories',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _rows.length; i++)
            _SplitRowCard(
              key: ValueKey('$i-${_rows[i].category}'),
              row: _rows[i],
              onChangedCategory: (cat) =>
                  setState(() => _rows[i].category = cat),
              onChangedAmount: (p) =>
                  setState(() => _rows[i].amountPaise = p),
              onRemove: () => setState(() => _rows.removeAt(i)),
              canRemove: _rows.length > 1,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: () => setState(() {
                _rows.add(_SplitRow(
                    category: 'Miscellaneous',
                    amountPaise: 0,
                    items: const []));
              }),
              icon: const Icon(Icons.add),
              label: const Text('Add another category'),
            ),
          ),
          const Divider(),
          // Split summary + diff banner
          _SummaryRow(
              label: 'Bill total', paise: _grandTotal, emphasize: true),
          _SummaryRow(label: 'Split total', paise: _splitTotal),
          if (!ok)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 18, color: AppSemantics.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _diffPaise > 0
                          ? 'Split is short by ${Money.format(_diffPaise)}'
                          : 'Split is over by ${Money.format(_diffPaise.abs())}',
                      style: TextStyle(color: AppSemantics.warning),
                    ),
                  ),
                  TextButton(
                    onPressed: _distributeDiff,
                    child: const Text('Match total'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text('Shared details',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final mode in kPaymentModes.where((m) => m != kPaymentModeSplit))
                ChoiceChip(
                  label: Text(mode),
                  selected: _paymentMode == mode,
                  onSelected: (_) => setState(() => _paymentMode = mode),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _EventDropdown(
            selectedId: _eventId,
            onChanged: (id) => setState(() => _eventId = id),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _party,
            decoration: const InputDecoration(
              labelText: 'Party',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => _party = v,
          ),
          if (widget.attachmentLocalPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(widget.attachmentLocalPath!),
                  height: 120, fit: BoxFit.contain),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _canSave ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(_saving ? 'Saving…' : 'Save ${_rows.length} entries'),
          ),
        ),
      ),
    );
  }
}

class _SplitRowCard extends StatefulWidget {
  const _SplitRowCard({
    super.key,
    required this.row,
    required this.onChangedCategory,
    required this.onChangedAmount,
    required this.onRemove,
    required this.canRemove,
  });
  final _SplitRow row;
  final ValueChanged<String> onChangedCategory;
  final ValueChanged<int> onChangedAmount;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<_SplitRowCard> createState() => _SplitRowCardState();
}

class _SplitRowCardState extends State<_SplitRowCard> {
  late final TextEditingController _amountCtl = TextEditingController(
      text: (widget.row.amountPaise / 100).toStringAsFixed(2));

  @override
  void didUpdateWidget(_SplitRowCard old) {
    super.didUpdateWidget(old);
    // Refresh the amount field only when the parent explicitly reassigned
    // (e.g. "Match total" pressed).
    final expected = (widget.row.amountPaise / 100).toStringAsFixed(2);
    final typed = double.tryParse(_amountCtl.text) ?? 0;
    if ((typed * 100).round() != widget.row.amountPaise) {
      _amountCtl.text = expected;
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.row.category,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final c
                            in kSeedCategories.where((c) => c.kind == 'expense'))
                          DropdownMenuItem(
                              value: c.name, child: Text(c.name)),
                      ],
                      onChanged: (v) {
                        if (v != null) widget.onChangedCategory(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _amountCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final rupees = double.tryParse(v) ?? 0;
                        widget.onChangedAmount((rupees * 100).round());
                      },
                    ),
                  ),
                  if (widget.canRemove)
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                ],
              ),
              if (widget.row.items.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${widget.row.items.length} items · ${widget.row.items.take(2).map((i) => i.description).join(', ')}${widget.row.items.length > 2 ? '…' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label, required this.paise, this.emphasize = false});
  final String label;
  final int paise;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: emphasize
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null),
          Text(Money.format(paise),
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

/// Compact event picker — same UX as the one in add_transaction_screen.
class _EventDropdown extends ConsumerWidget {
  const _EventDropdown({required this.selectedId, required this.onChanged});
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).asData?.value ?? const [];
    final selectable = [
      for (final e in events)
        if (!e.isSettled || e.id == selectedId) e,
    ];
    if (selectable.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String?>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: 'Event (optional)',
        border: OutlineInputBorder(),
        isDense: true,
        prefixIcon: Icon(Icons.celebration_outlined),
      ),
      items: [
        const DropdownMenuItem<String?>(
            value: null, child: Text('No event')),
        for (final e in selectable)
          DropdownMenuItem(value: e.id, child: Text(e.name)),
      ],
      onChanged: onChanged,
    );
  }
}
