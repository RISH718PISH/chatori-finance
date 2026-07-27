import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/categories.dart';
import '../../core/design.dart';
import '../../core/money.dart';
import '../../core/quantity.dart';
import '../../data/supabase/purchase_invoice_repository.dart';
import '../events/events_providers.dart';
import '../inventory/inventory_providers.dart';
import '../inventory/item_matcher.dart';
import '../inventory/widgets/item_picker_sheet.dart';
import '../transaction/transaction_providers.dart';
import 'ai_parsed_invoice.dart';

/// Item-level review of a scanned invoice.
///
/// Replaces the old category-only split screen, which showed three
/// aggregate rows and hid the actual products — so a bill whose items had
/// been misread looked plausible right up until it was saved.
///
/// Two deliberate behaviour changes from that screen:
///   • Saving is BLOCKED until the items reconcile to the bill total. The
///     old screen allowed a 6,000-rupee shortfall through.
///   • There is no "match total" button. Silently moving the entire
///     discrepancy onto the largest row produced confidently wrong books.
class InvoiceReviewScreen extends ConsumerStatefulWidget {
  const InvoiceReviewScreen({
    super.key,
    required this.parsed,
    this.attachmentLocalPath,
  });

  final AiParsedInvoice parsed;
  final String? attachmentLocalPath;

  @override
  ConsumerState<InvoiceReviewScreen> createState() =>
      _InvoiceReviewScreenState();
}

class _Row {
  final int id;
  AiInvoiceItem item;
  _Row(this.id, this.item);
}

class _InvoiceReviewScreenState extends ConsumerState<InvoiceReviewScreen> {
  late List<_Row> _rows;
  var _nextId = 0;

  /// Null when the bill total could not be read. Kept distinct from zero:
  /// the old screen defaulted the total to the item sum, which made the
  /// difference structurally zero and meant no warning could ever fire in
  /// exactly the case where parsing had failed worst.
  int? _billTotalPaise;

  /// User overrides for how a row maps to stock, keyed by row id. A row
  /// with no entry falls back to the automatic match computed in build().
  final Map<int, StockMatch> _stockChoice = {};

  String _paymentMode = 'Bank';
  late DateTime _date;
  late final TextEditingController _partyCtl;
  String? _eventId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rows = [
      for (final it in widget.parsed.items) _Row(_nextId++, it),
    ];
    _billTotalPaise = widget.parsed.totalPaise;
    _date = widget.parsed.invoiceDate ?? DateTime.now();
    _partyCtl =
        TextEditingController(text: widget.parsed.vendorName ?? 'Hyperpure');
  }

  @override
  void dispose() {
    _partyCtl.dispose();
    super.dispose();
  }

  int get _itemsSum =>
      _rows.fold<int>(0, (s, r) => s + r.item.amountPaise);
  int? get _diff =>
      _billTotalPaise == null ? null : _billTotalPaise! - _itemsSum;
  bool get _balanced => _diff == 0;
  int get _lowConfidence =>
      _rows.where((r) => r.item.isLowConfidence).length;

  bool get _canSave =>
      _rows.isNotEmpty &&
      _billTotalPaise != null &&
      _balanced &&
      _rows.every((r) => r.item.amountPaise > 0) &&
      !_saving;

  List<SeedCategory> get _categories =>
      kSeedCategories.where((c) => c.kind == 'expense').toList();

  Map<String, int> get _rollup {
    final m = <String, int>{};
    for (final r in _rows) {
      m.update(r.item.category, (v) => v + r.item.amountPaise,
          ifAbsent: () => r.item.amountPaise);
    }
    return m;
  }

  // ── Actions ────────────────────────────────────────────────

  void _addRemainderAsRow() {
    final d = _diff;
    if (d == null || d == 0) return;
    setState(() {
      _rows.add(_Row(
        _nextId++,
        AiInvoiceItem(
          description: d > 0 ? 'Unlisted / rounding' : 'Correction',
          amountPaise: d,
          category: 'Miscellaneous',
          confidence: 0.0,
        ),
      ));
    });
  }

  Future<void> _editBillTotal() async {
    final ctl = TextEditingController(
      text: _billTotalPaise == null
          ? ''
          : (_billTotalPaise! / 100).toStringAsFixed(2),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bill total'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '₹ ',
            border: OutlineInputBorder(),
            helperText: 'Type the final payable amount from the bill',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set')),
        ],
      ),
    );
    if (ok != true) return;
    final rupees = double.tryParse(ctl.text.trim());
    if (rupees == null) return;
    setState(() => _billTotalPaise = (rupees * 100).round());
  }

  void _viewImage() {
    final path = widget.attachmentLocalPath;
    if (path == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          maxScale: 6,
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }

  /// The stock decision for a row: the user's override if set, else the
  /// automatic match from [matcher].
  StockMatch _matchFor(_Row r, ItemMatcher matcher) {
    final override = _stockChoice[r.id];
    if (override != null) return override;
    return matcher.match(
      r.item.description,
      hasUnit: lineHasStorableUnit(r.item.unit, r.item.qty),
    );
  }

  StockTarget _targetFor(StockMatch m) => switch (m.kind) {
        StockMatchKind.matched => StockTarget.matched(m.itemId!),
        StockMatchKind.newItem => StockTarget.create(m.suggestedName!),
        StockMatchKind.untracked => const StockTarget.untracked(),
      };

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final biz = await ref.read(businessIdProvider.future);
      if (biz == null) {
        messenger.showSnackBar(const SnackBar(
            content: Text('No business found. Please sign in again.')));
        return;
      }

      String? attachmentPath;
      if (widget.attachmentLocalPath != null) {
        attachmentPath = await ref.read(attachmentRepoProvider).store(
              businessId: biz,
              localImagePath: widget.attachmentLocalPath!,
            );
      }

      final matcher = ItemMatcher(
        items: ref.read(inventoryItemsProvider).asData?.value ?? const [],
        aliases: ref.read(itemAliasesProvider).asData?.value ?? const [],
      );
      final matches = [for (final r in _rows) _matchFor(r, matcher)];
      final targets = [for (final m in matches) _targetFor(m)];
      final tracked = matches.where((m) => m.tracks).length;
      final skipped = _rows.length - tracked;

      final party = _partyCtl.text.trim();
      await ref.read(purchaseInvoiceRepoProvider).save(
            businessId: biz,
            invoice: widget.parsed,
            items: [for (final r in _rows) r.item],
            paymentMode: _paymentMode,
            occurredAt: _date,
            partyName: party.isEmpty ? null : party,
            eventId: _eventId,
            attachmentPath: attachmentPath,
            stockTargets: targets,
          );

      refreshTransactions(ref);
      refreshInventory(ref);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppSemantics.income,
        content: Text(
          'Saved ${_rows.length} items · ${Money.format(_itemsSum)} — '
          '$tracked added to stock${skipped > 0 ? ', $skipped not tracked' : ''}',
          style: const TextStyle(color: Colors.white),
        ),
      ));
      context.go('/');
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Rebuilt each frame from the catalogue providers. While they load it is
  /// simply an empty matcher (everything reads as a new item), which
  /// self-corrects once the data arrives.
  ItemMatcher get _matcher => ItemMatcher(
        items: ref.watch(inventoryItemsProvider).asData?.value ?? const [],
        aliases: ref.watch(itemAliasesProvider).asData?.value ?? const [],
      );

  Future<void> _editStock(_Row r) async {
    final result = await showItemPicker(
      context,
      ref,
      seedName: ItemMatcher.cleanName(r.item.description),
      seedDimension: parseQuantity(r.item.qty, r.item.unit)?.dimension,
      seedUnit: r.item.unit,
      seedCategory: r.item.category,
    );
    if (result == null) return;
    setState(() {
      _stockChoice[r.id] =
          StockMatch.matched(result.item.id, result.item.name);
    });
  }

  void _toggleTrack(_Row r) {
    setState(() {
      final current = _matchFor(r, _matcher);
      _stockChoice[r.id] = current.kind == StockMatchKind.untracked
          // Re-enable: fall back to the automatic match by clearing the
          // override, unless there's no unit, in which case it stays off.
          ? _matcher.match(r.item.description, hasUnit: true)
          : const StockMatch.untracked();
    });
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = widget.parsed;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review invoice'),
        actions: [
          if (widget.attachmentLocalPath != null)
            IconButton(
              tooltip: 'View bill photo',
              icon: const Icon(Icons.image_outlined),
              onPressed: _viewImage,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        children: [
          if (p.isFallback) _banner(
            icon: Icons.cloud_off,
            color: AppSemantics.warning,
            title: 'Read offline — check every row',
            body:
                'The invoice reader could not be reached, so this used the '
                'older on-device parser. It is much less accurate.',
          ),
          if (_lowConfidence > 0) _banner(
            icon: Icons.help_outline,
            color: AppSemantics.warning,
            title: '$_lowConfidence '
                '${_lowConfidence == 1 ? 'row needs' : 'rows need'} a check',
            body: 'Marked rows are ones the reader was unsure about.',
          ),

          // Invoice header
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
                          p.invoiceNumber ?? p.vendorName ?? 'Invoice',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(DateFormat('d MMM yyyy').format(_date),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_rows.length} items'
                    '${p.subtotalPaise != null ? ' · Taxable ${Money.format(p.subtotalPaise!, decimals: false)}' : ''}'
                    '${p.taxPaise != null ? ' · Tax ${Money.format(p.taxPaise!, decimals: false)}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items
          Text('Items', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _rows.length; i++)
            _ItemCard(
              key: ValueKey(_rows[i].id),
              index: i,
              item: _rows[i].item,
              categories: _categories,
              stockMatch: _matchFor(_rows[i], _matcher),
              onChanged: (it) => setState(() => _rows[i].item = it),
              onRemove: () => setState(() => _rows.removeAt(i)),
              onEditStock: () => _editStock(_rows[i]),
              onToggleTrack: () => _toggleTrack(_rows[i]),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextButton.icon(
              onPressed: () => setState(() => _rows.add(_Row(
                    _nextId++,
                    const AiInvoiceItem(
                      description: '',
                      amountPaise: 0,
                      category: 'Groceries',
                      confidence: 0,
                    ),
                  ))),
              icon: const Icon(Icons.add),
              label: const Text('Add an item'),
            ),
          ),

          const Divider(height: 24),
          _reconciliation(context),
          const SizedBox(height: 16),

          // Category rollup
          Card(
            child: ExpansionTile(
              title: Text('Category summary (${_rollup.length})',
                  style: Theme.of(context).textTheme.titleSmall),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                for (final e in (_rollup.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value))))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key)),
                        DataNumber(Money.format(e.value, decimals: false),
                            size: DataSize.sm),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shared details
          const LabelUpper('Shared details'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m
                  in kPaymentModes.where((m) => m != kPaymentModeSplit))
                ChoiceChip(
                  label: Text(m),
                  selected: _paymentMode == m,
                  onSelected: (_) => setState(() => _paymentMode = m),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDate: _date,
              );
              if (picked != null) setState(() => _date = picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.event),
              ),
              child: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _partyCtl,
            decoration: const InputDecoration(
              labelText: 'Vendor',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _EventDropdown(
            selectedId: _eventId,
            onChanged: (id) => setState(() => _eventId = id),
          ),
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(_saveLabel()),
          ),
        ),
      ),
    );
  }

  String _saveLabel() {
    if (_saving) return 'Saving…';
    if (_rows.isEmpty) return 'Add at least one item';
    if (_billTotalPaise == null) return 'Enter the bill total first';
    if (!_balanced) return 'Fix the difference to save';
    return 'Save ${_rows.length} items';
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reconciliation(BuildContext context) {
    final unknown = _billTotalPaise == null;
    final d = _diff;
    final good = _balanced;
    final color = unknown
        ? AppSemantics.warning
        : (good ? AppSemantics.income : AppSemantics.expense);

    return Card(
      color: color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Items total')),
                DataNumber(Money.format(_itemsSum), size: DataSize.sm),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(child: Text('Bill total')),
                if (unknown)
                  TextButton(
                    onPressed: _editBillTotal,
                    child: const Text('Enter total'),
                  )
                else ...[
                  DataNumber(Money.format(_billTotalPaise!),
                      size: DataSize.sm),
                  IconButton(
                    tooltip: 'Edit bill total',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: _editBillTotal,
                  ),
                ],
              ],
            ),
            const Divider(height: 18),
            if (unknown)
              Text(
                'The bill total could not be read. Enter it so the items can '
                'be checked against it.',
                style: TextStyle(color: color),
              )
            else if (good)
              Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text('Items match the bill total',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600)),
                ],
              )
            else ...[
              Row(
                children: [
                  Icon(Icons.warning_amber, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      d! > 0
                          ? 'Short by ${Money.format(d)} — an item is missing '
                              'or an amount is too low'
                          : 'Over by ${Money.format(d.abs())} — an amount is '
                              'too high or a row is duplicated',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addRemainderAsRow,
                  icon: const Icon(Icons.playlist_add, size: 18),
                  label: Text(
                      'Add ${Money.format(d.abs())} as a separate item'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Only do this if you cannot find the mistake — it books the '
                  'difference to Miscellaneous.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Item row ─────────────────────────────────────────────────

class _ItemCard extends StatefulWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.categories,
    required this.stockMatch,
    required this.onChanged,
    required this.onRemove,
    required this.onEditStock,
    required this.onToggleTrack,
  });

  final int index;
  final AiInvoiceItem item;
  final List<SeedCategory> categories;
  final StockMatch stockMatch;
  final ValueChanged<AiInvoiceItem> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onEditStock;
  final VoidCallback onToggleTrack;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _desc =
      TextEditingController(text: widget.item.description);
  late final TextEditingController _amount = TextEditingController(
      text: widget.item.amountPaise == 0
          ? ''
          : (widget.item.amountPaise / 100).toStringAsFixed(2));
  late final TextEditingController _qty = TextEditingController(
      text: widget.item.qty == null
          ? ''
          : (widget.item.qty! % 1 == 0
              ? widget.item.qty!.toInt().toString()
              : widget.item.qty!.toString()));

  @override
  void dispose() {
    _desc.dispose();
    _amount.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final low = widget.item.isLowConfidence;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: low
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: AppSemantics.warning.withValues(alpha: 0.6)),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (low) ...[
                    const Icon(Icons.help_outline,
                        size: 16, color: AppSemantics.warning),
                    const SizedBox(width: 4),
                  ],
                  Text('#${widget.index + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).hintColor)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Remove item',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              TextField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Item',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) =>
                    widget.onChanged(widget.item.copyWith(description: v)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.item.category,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final c in widget.categories)
                          DropdownMenuItem(
                              value: c.name, child: Text(c.name)),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          widget.onChanged(widget.item.copyWith(category: v));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final r = double.tryParse(v) ?? 0;
                        widget.onChanged(widget.item
                            .copyWith(amountPaise: (r * 100).round()));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _qty,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => widget.onChanged(
                          widget.item.copyWith(qty: double.tryParse(v))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue:
                          Quantity.unitFromSymbol(widget.item.unit)?.symbol,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('—')),
                        for (final u in Quantity.all)
                          DropdownMenuItem(
                              value: u.symbol, child: Text(u.symbol)),
                      ],
                      onChanged: (v) =>
                          widget.onChanged(widget.item.copyWith(unit: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _stockLine(context),
            ],
          ),
        ),
      ),
    );
  }

  /// The "→ Stock" line: shows how this row will affect inventory and lets
  /// the user change the target or opt the line out.
  Widget _stockLine(BuildContext context) {
    final m = widget.stockMatch;
    final (IconData icon, String label, Color color) = switch (m.kind) {
      StockMatchKind.matched => (
          Icons.link,
          'Stock: ${m.itemName}',
          AppSemantics.income,
        ),
      StockMatchKind.newItem => (
          Icons.add_circle_outline,
          'Stock: new "${m.suggestedName}"',
          Theme.of(context).colorScheme.primary,
        ),
      StockMatchKind.untracked => (
          Icons.block,
          'Not added to stock',
          Theme.of(context).hintColor,
        ),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color)),
        ),
        if (m.kind != StockMatchKind.untracked)
          TextButton(
            onPressed: widget.onEditStock,
            style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Change'),
          ),
        IconButton(
          tooltip: m.kind == StockMatchKind.untracked
              ? 'Add to stock'
              : "Don't add to stock",
          visualDensity: VisualDensity.compact,
          icon: Icon(
            m.kind == StockMatchKind.untracked
                ? Icons.add_box_outlined
                : Icons.not_interested,
            size: 18,
          ),
          onPressed: widget.onToggleTrack,
        ),
      ],
    );
  }
}

/// Compact event picker — same UX as the other add screens.
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
        const DropdownMenuItem<String?>(value: null, child: Text('No event')),
        for (final e in selectable)
          DropdownMenuItem(value: e.id, child: Text(e.name)),
      ],
      onChanged: onChanged,
    );
  }
}
