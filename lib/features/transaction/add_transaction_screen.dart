import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/categories.dart';
import '../../core/category_icons.dart';
import '../../core/money.dart';
import '../../data/models/txn.dart';
import 'transaction_providers.dart';

/// Optional values to pre-fill the form (e.g. from a Paytm screenshot).
class AddPrefill {
  final String? type;
  final int? amountPaise;
  final String? party;
  final String? notes;
  final bool fromScreenshot;
  const AddPrefill({
    this.type,
    this.amountPaise,
    this.party,
    this.notes,
    this.fromScreenshot = false,
  });
}

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.prefill,
    this.editing,
  });

  final String initialType; // 'income' | 'expense'
  final AddPrefill? prefill;
  final Txn? editing;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late String _type =
      widget.editing?.type ?? widget.prefill?.type ?? widget.initialType;
  late final String _source = widget.editing?.source ??
      ((widget.prefill?.fromScreenshot ?? false) ? 'screenshot' : 'manual');
  int _amountPaise = 0;
  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _amountPaise = e.amountPaise;
      _partyController.text = e.partyName ?? '';
      _noteController.text = e.notes ?? '';
      _paymentMode = e.paymentMode;
      _tag = e.tag;
      _date = e.occurredAt;
      // Pre-select the category — resolved once `kSeedCategories` is available.
      final match = kSeedCategories
          .where((c) => c.kind == e.type && c.name == e.category)
          .toList();
      if (match.isNotEmpty) _category = match.first;
      return;
    }
    final p = widget.prefill;
    if (p != null) {
      if (p.amountPaise != null) _amountPaise = p.amountPaise!;
      if (p.party != null) _partyController.text = p.party!;
      if (p.notes != null) _noteController.text = p.notes!;
    }
  }
  SeedCategory? _category;
  String _paymentMode = 'Cash';
  String? _tag;
  final _partyController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _showMore = false;
  bool _saving = false;

  bool get _isIncome => _type == 'income';
  bool get _canSave => _amountPaise > 0 && _category != null;

  @override
  void dispose() {
    _partyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _press(int digit) => setState(
      () => _amountPaise = (_amountPaise * 10 + digit).clamp(0, 9999999999));
  void _pressDouble() =>
      setState(() => _amountPaise = (_amountPaise * 100).clamp(0, 9999999999));
  void _backspace() => setState(() => _amountPaise ~/= 10);

  void _switchType(String t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _category = null; // categories differ by type
    });
  }

  Future<void> _deleteEntry() async {
    final e = widget.editing;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
            'This will permanently delete ${Money.format(e.amountPaise)} ${e.category}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(transactionRepoProvider).delete(e.id);
    if (!mounted) return;
    refreshTransactions(ref);
    context.pop();
    messenger.showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('Entry deleted'),
    ));
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final biz = await ref.read(businessIdProvider.future);
      if (biz == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No business found. Please sign in again.')),
        );
        return;
      }
      final party = _partyController.text.trim().isEmpty
          ? null
          : _partyController.text.trim();
      final notes = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
      final repo = ref.read(transactionRepoProvider);

      // Duplicate warning: same amount + party + day (skip on edit).
      if (!_isEdit) {
        final dups = await repo.findDuplicates(
          businessId: biz,
          amountPaise: _amountPaise,
          partyName: party,
          day: _date,
        );
        if (dups.isNotEmpty && mounted) {
          final proceed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Possible duplicate'),
                  content: Text(
                      'You already have an entry of ${Money.format(_amountPaise)}${party == null ? '' : ' for $party'} on ${_friendlyDate(_date)}. Save this one anyway?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Save anyway')),
                  ],
                ),
              ) ??
              false;
          if (!proceed) {
            setState(() => _saving = false);
            return;
          }
        }
      }

      if (_isEdit) {
        await repo.update(
          id: widget.editing!.id,
          type: _type,
          category: _category!.name,
          amountPaise: _amountPaise,
          paymentMode: _paymentMode,
          occurredAt: _date,
          partyName: party,
          notes: notes,
          tag: _tag,
        );
      } else {
        await repo.add(
          businessId: biz,
          type: _type,
          category: _category!.name,
          amountPaise: _amountPaise,
          paymentMode: _paymentMode,
          occurredAt: _date,
          partyName: party,
          notes: notes,
          tag: _tag,
          source: _source,
        );
      }
      if (!mounted) return;
      refreshTransactions(ref);
      final amount = Money.format(_amountPaise);
      final label = _isIncome ? 'Income' : 'Expense';
      final verb = _isEdit ? 'updated' : 'saved';
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('$label of $amount $verb ✓',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _isIncome ? Colors.green : scheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? (_isIncome ? 'Edit Income' : 'Edit Expense')
            : (_isIncome ? 'Add Income' : 'Add Expense')),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete',
              onPressed: _saving ? null : _deleteEntry,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'income',
                      label: Text('Income'),
                      icon: Icon(Icons.add),
                    ),
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Expense'),
                      icon: Icon(Icons.remove),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => _switchType(s.first),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    Money.format(_amountPaise),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel(_isIncome ? 'Sale type' : 'Category'),
                _CategoryPicker(
                  kind: _type,
                  selectedId: _category?.id,
                  onSelected: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 16),
                _SectionLabel('Payment mode'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final mode in kPaymentModes)
                      ChoiceChip(
                        label: Text(mode),
                        selected: _paymentMode == mode,
                        onSelected: (_) => setState(() => _paymentMode = mode),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel(_isIncome ? 'Customer / party' : 'Vendor / person'),
                TextField(
                  controller: _partyController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: _isIncome ? 'Who paid (optional)' : 'Paid to (optional)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _showMore = !_showMore),
                  icon: Icon(_showMore ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showMore ? 'Less' : 'Add note / tag / date'),
                ),
                if (_showMore) _moreDetails(context),
              ],
            ),
          ),
          _Keypad(
            onDigit: _press,
            onDouble: _pressDouble,
            onBackspace: _backspace,
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: _canSave && !_saving ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        _SectionLabel('Tag (optional)'),
        Wrap(
          spacing: 8,
          children: [
            for (final tag in kTags)
              ChoiceChip(
                label: Text(tag),
                selected: _tag == tag,
                onSelected: (sel) => setState(() => _tag = sel ? tag : null),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.event, size: 20),
            const SizedBox(width: 8),
            Text(_friendlyDate(_date)),
            const Spacer(),
            TextButton(onPressed: _pickDate, child: const Text('Change')),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(
          picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  String _friendlyDate(DateTime d) {
    final today = DateTime.now();
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return 'Today';
    }
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.kind,
    required this.selectedId,
    required this.onSelected,
  });

  final String kind;
  final String? selectedId;
  final ValueChanged<SeedCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final cats = kSeedCategories.where((c) => c.kind == kind).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in cats)
          _CategoryTile(
            category: c,
            selected: c.id == selectedId,
            onTap: () => onSelected(c),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SeedCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              categoryIcon(category.icon),
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onDouble,
    required this.onBackspace,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDouble;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Center(
                child: DefaultTextStyle.merge(
                  style:
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  child: child,
                ),
              ),
            ),
          ),
        );

    Widget digit(int n) => key(Text('$n'), () => onDigit(n));

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Row(children: [digit(1), digit(2), digit(3)]),
          Row(children: [digit(4), digit(5), digit(6)]),
          Row(children: [digit(7), digit(8), digit(9)]),
          Row(children: [
            key(const Text('00'), onDouble),
            digit(0),
            key(const Icon(Icons.backspace_outlined), onBackspace),
          ]),
        ],
      ),
    );
  }
}
