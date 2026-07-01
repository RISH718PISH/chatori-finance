import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/categories.dart';
import '../../core/category_icons.dart';
import '../../core/money.dart';
import 'transaction_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  final String initialType; // 'income' | 'expense'

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late String _type = widget.initialType;
  int _amountPaise = 0;
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
      await ref.read(transactionRepoProvider).add(
            businessId: biz,
            type: _type,
            category: _category!.name,
            amountPaise: _amountPaise,
            paymentMode: _paymentMode,
            occurredAt: _date,
            partyName: _partyController.text.trim().isEmpty
                ? null
                : _partyController.text.trim(),
            notes: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            tag: _tag,
          );
      if (!mounted) return;
      final amount = Money.format(_amountPaise);
      final label = _isIncome ? 'Income' : 'Expense';
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
                  child: Text('$label of $amount saved ✓',
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
      appBar: AppBar(title: Text(_isIncome ? 'Add Income' : 'Add Expense')),
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
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _showMore = !_showMore),
                  icon: Icon(_showMore ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showMore ? 'Less' : 'Add vendor / note / date'),
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
          controller: _partyController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Vendor / person (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
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
