import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/categories.dart';
import '../../core/design.dart';
import '../../core/money.dart';
import '../events/events_providers.dart';
import 'transaction_providers.dart';

/// Initial row shown when opening bulk-add from the single Add screen —
/// carries whatever the user had typed so far so nothing is lost.
class BulkSeedRow {
  final String? category;
  final int amountPaise;
  final String? notes;
  const BulkSeedRow({this.category, this.amountPaise = 0, this.notes});
}

class BulkAddScreen extends ConsumerStatefulWidget {
  const BulkAddScreen({
    super.key,
    this.type = 'expense',
    this.seed,
    this.initialPaymentMode,
    this.initialParty,
    this.initialEventId,
  });

  final String type; // 'income' | 'expense'
  final BulkSeedRow? seed;
  final String? initialPaymentMode;
  final String? initialParty;
  final String? initialEventId;

  @override
  ConsumerState<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkRow {
  String? category;
  int amountPaise;
  String notes;
  _BulkRow({this.category, this.amountPaise = 0, this.notes = ''});
}

class _BulkAddScreenState extends ConsumerState<BulkAddScreen> {
  late final List<_BulkRow> _rows;
  late String _paymentMode = widget.initialPaymentMode ?? 'Cash';
  DateTime _date = DateTime.now();
  late final TextEditingController _partyCtl =
      TextEditingController(text: widget.initialParty ?? '');
  String? _eventId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _eventId = widget.initialEventId;
    final seed = widget.seed;
    _rows = [
      if (seed != null)
        _BulkRow(
          category: seed.category,
          amountPaise: seed.amountPaise,
          notes: seed.notes ?? '',
        ),
      _BulkRow(),
    ];
  }

  @override
  void dispose() {
    _partyCtl.dispose();
    super.dispose();
  }

  bool get _isExpense => widget.type == 'expense';
  int get _total => _rows.fold<int>(0, (s, r) => s + r.amountPaise);
  List<_BulkRow> get _validRows =>
      _rows.where((r) => r.amountPaise > 0 && (r.category ?? '').isNotEmpty)
          .toList();
  bool get _canSave => _validRows.isNotEmpty && !_saving;

  List<SeedCategory> get _availableCategories =>
      kSeedCategories.where((c) => c.kind == widget.type).toList();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final biz = await ref.read(businessIdProvider.future);
      if (biz == null) {
        _snack('No business found. Please sign in again.');
        return;
      }
      final rows = <({String category, int amountPaise, String? notes})>[
        for (final r in _validRows)
          (
            category: r.category!,
            amountPaise: r.amountPaise,
            notes: r.notes.trim().isEmpty ? null : r.notes.trim(),
          ),
      ];
      final party = _partyCtl.text.trim();
      await ref.read(transactionRepoProvider).addBatch(
            businessId: biz,
            rows: rows,
            type: widget.type,
            paymentMode: _paymentMode,
            occurredAt: _date,
            partyName: party.isEmpty ? null : party,
            eventId: _eventId,
          );
      refreshTransactions(ref);
      if (!mounted) return;
      _snack('Saved ${rows.length} '
          '${rows.length == 1 ? 'entry' : 'entries'} · ${Money.format(_total)}',
          good: true);
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

  @override
  Widget build(BuildContext context) {
    final validCount = _validRows.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isExpense
            ? 'Add multiple expenses'
            : 'Add multiple incomes'),
        actions: [
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  Money.format(_total, decimals: false),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          // ── Shared details ─────────────────────────────
          const LabelUpper('Shared details'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final mode in kPaymentModes
                  .where((m) => m != kPaymentModeSplit))
                ChoiceChip(
                  label: Text(mode),
                  selected: _paymentMode == mode,
                  onSelected: (_) => setState(() => _paymentMode = mode),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
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
            decoration: InputDecoration(
              labelText: _isExpense ? 'Party (vendor)' : 'Party (customer)',
              hintText: 'e.g. Local market, Cash pickup',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _EventDropdown(
            selectedId: _eventId,
            onChanged: (id) => setState(() => _eventId = id),
          ),
          const SizedBox(height: 24),

          // ── Rows ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text('Entries (${_rows.length})',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text('Total ${Money.format(_total, decimals: false)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _isExpense
                          ? AppSemantics.expense
                          : AppSemantics.income)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _rows.length; i++)
            _RowCard(
              key: ValueKey('bulkrow-$i'),
              index: i,
              row: _rows[i],
              categories: _availableCategories,
              canRemove: _rows.length > 1,
              onCategory: (c) => setState(() => _rows[i].category = c),
              onAmount: (p) => setState(() => _rows[i].amountPaise = p),
              onNotes: (t) => setState(() => _rows[i].notes = t),
              onRemove: () => setState(() => _rows.removeAt(i)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _rows.add(_BulkRow())),
              icon: const Icon(Icons.add),
              label: const Text('Add another entry'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor:
                    _isExpense ? AppSemantics.expense : AppSemantics.income),
            onPressed: _canSave ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(_saving
                ? 'Saving…'
                : validCount == 0
                    ? 'Fill at least one row'
                    : 'Save $validCount '
                        '${validCount == 1 ? 'entry' : 'entries'}'),
          ),
        ),
      ),
    );
  }
}

class _RowCard extends StatefulWidget {
  const _RowCard({
    super.key,
    required this.index,
    required this.row,
    required this.categories,
    required this.canRemove,
    required this.onCategory,
    required this.onAmount,
    required this.onNotes,
    required this.onRemove,
  });

  final int index;
  final _BulkRow row;
  final List<SeedCategory> categories;
  final bool canRemove;
  final ValueChanged<String> onCategory;
  final ValueChanged<int> onAmount;
  final ValueChanged<String> onNotes;
  final VoidCallback onRemove;

  @override
  State<_RowCard> createState() => _RowCardState();
}

class _RowCardState extends State<_RowCard> {
  late final TextEditingController _amountCtl = TextEditingController(
      text: widget.row.amountPaise == 0
          ? ''
          : (widget.row.amountPaise / 100).toStringAsFixed(2));
  late final TextEditingController _notesCtl =
      TextEditingController(text: widget.row.notes);

  @override
  void dispose() {
    _amountCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${widget.index + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).hintColor)),
                  const Spacer(),
                  if (widget.canRemove)
                    IconButton(
                      tooltip: 'Remove row',
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        for (final c in widget.categories)
                          DropdownMenuItem(
                              value: c.name, child: Text(c.name)),
                      ],
                      onChanged: (v) {
                        if (v != null) widget.onCategory(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: _amountCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final rupees = double.tryParse(v) ?? 0;
                        widget.onAmount((rupees * 100).round());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: widget.onNotes,
              ),
            ],
          ),
        ),
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
