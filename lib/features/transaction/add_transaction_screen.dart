import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/categories.dart';
import '../../core/category_icons.dart';
import '../../core/design.dart';
import '../../core/money.dart';
import '../../data/models/event.dart';
import '../../data/models/txn.dart';
import '../events/events_providers.dart';
import 'transaction_providers.dart';

/// Optional values to pre-fill the form (e.g. from a Paytm/Hyperpure scan).
class AddPrefill {
  final String? type;
  final int? amountPaise;
  final String? party;
  final String? notes;
  final String? category;
  final String? paymentMode;
  final DateTime? occurredAt;
  final bool fromScreenshot;

  /// Local image (e.g. the scanned bill) to attach to the entry on save.
  final String? attachmentLocalPath;

  const AddPrefill({
    this.type,
    this.amountPaise,
    this.party,
    this.notes,
    this.category,
    this.paymentMode,
    this.occurredAt,
    this.fromScreenshot = false,
    this.attachmentLocalPath,
  });
}

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.prefill,
    this.editing,
    this.initialEventId,
  });

  final String initialType; // 'income' | 'expense'
  final AddPrefill? prefill;
  final Txn? editing;

  /// Pre-selects this event (e.g. when adding from an event detail screen).
  final String? initialEventId;

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
      _eventId = e.eventId;
      _cashSplitPaise = e.cashPaise ?? 0;
      _upiSplitPaise = e.upiPaise ?? 0;
      // Pre-select the category — resolved once `kSeedCategories` is available.
      final match = kSeedCategories
          .where((c) => c.kind == e.type && c.name == e.category)
          .toList();
      if (match.isNotEmpty) _category = match.first;
      return;
    }
    _eventId = widget.initialEventId;
    final p = widget.prefill;
    if (p != null) {
      if (p.amountPaise != null) _amountPaise = p.amountPaise!;
      if (p.party != null) _partyController.text = p.party!;
      if (p.notes != null) _noteController.text = p.notes!;
      if (p.paymentMode != null) _paymentMode = p.paymentMode!;
      if (p.category != null) {
        final match = kSeedCategories
            .where((c) => c.kind == _type && c.name == p.category)
            .toList();
        if (match.isNotEmpty) _category = match.first;
      }
      if (p.occurredAt != null) _date = p.occurredAt!;
    }
  }
  SeedCategory? _category;
  String _paymentMode = 'Cash';
  String? _tag;
  String? _eventId;
  int _cashSplitPaise = 0;
  int _upiSplitPaise = 0;
  final _partyController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _showMore = false;
  bool _saving = false;

  bool get _isIncome => _type == 'income';
  bool get _isSplit => _paymentMode == kPaymentModeSplit;

  /// Split is valid when both parts are positive and sum exactly to the total.
  bool get _splitValid =>
      _cashSplitPaise > 0 &&
      _upiSplitPaise > 0 &&
      (_cashSplitPaise + _upiSplitPaise) == _amountPaise;

  bool get _canSave =>
      _amountPaise > 0 && _category != null && (!_isSplit || _splitValid);

  @override
  void dispose() {
    _partyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _press(int digit) => setState(() {
        _amountPaise = (_amountPaise * 10 + digit).clamp(0, 9999999999);
        _reconcileSplitToTotal();
      });
  void _pressDouble() => setState(() {
        _amountPaise = (_amountPaise * 100).clamp(0, 9999999999);
        _reconcileSplitToTotal();
      });
  void _backspace() => setState(() {
        _amountPaise ~/= 10;
        _reconcileSplitToTotal();
      });

  /// Keeps cash + upi in step with a changed total. Preserves whatever the
  /// user typed for UPI (their explicit intent) and adjusts Cash to close the
  /// gap. If UPI already exceeds the total, we clamp UPI down instead.
  void _reconcileSplitToTotal() {
    if (!_isSplit) return;
    if (_upiSplitPaise > _amountPaise) _upiSplitPaise = _amountPaise;
    _cashSplitPaise = _amountPaise - _upiSplitPaise;
  }

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
          eventId: _eventId,
          cashPaise: _isSplit ? _cashSplitPaise : null,
          upiPaise: _isSplit ? _upiSplitPaise : null,
        );
      } else {
        // Persist the scanned bill (if any) before inserting the entry.
        String? attachmentPath;
        final localImage = widget.prefill?.attachmentLocalPath;
        if (localImage != null) {
          attachmentPath = await ref
              .read(attachmentRepoProvider)
              .store(businessId: biz, localImagePath: localImage);
        }
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
          eventId: _eventId,
          attachmentPath: attachmentPath,
          cashPaise: _isSplit ? _cashSplitPaise : null,
          upiPaise: _isSplit ? _upiSplitPaise : null,
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
            backgroundColor: AppSemantics.income,
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
    final accent = _isIncome ? AppSemantics.income : AppSemantics.expense;

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
                  child: DataNumber(Money.format(_amountPaise),
                      size: DataSize.lg, color: accent),
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
                        onSelected: (_) => setState(() {
                          _paymentMode = mode;
                          if (!_isSplit) {
                            _cashSplitPaise = 0;
                            _upiSplitPaise = 0;
                          } else {
                            // Sensible default: give all to Cash so the user
                            // just types the UPI part and Cash auto-adjusts.
                            _cashSplitPaise = _amountPaise;
                            _upiSplitPaise = 0;
                          }
                        }),
                      ),
                  ],
                ),
                if (_isSplit) ...[
                  const SizedBox(height: 12),
                  _SplitFields(
                    total: _amountPaise,
                    cash: _cashSplitPaise,
                    upi: _upiSplitPaise,
                    onChanged: (cash, upi) => setState(() {
                      _cashSplitPaise = cash;
                      _upiSplitPaise = upi;
                    }),
                  ),
                ],
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
                const SizedBox(height: 12),
                _EventPicker(
                  selectedId: _eventId,
                  onChanged: (id) => setState(() => _eventId = id),
                ),
                if (_isEdit && widget.editing?.attachmentPath != null) ...[
                  const SizedBox(height: 12),
                  _AttachmentThumb(path: widget.editing!.attachmentPath!),
                ],
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

/// Optional event link. Shows non-settled events; searchable when there are
/// many. Falls back to nothing when the business has no events.
class _EventPicker extends ConsumerWidget {
  const _EventPicker({required this.selectedId, required this.onChanged});

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).asData?.value ?? const <Event>[];
    // Selectable: non-settled events, plus the currently linked one (so an
    // edit of an old entry still shows its event even if settled).
    final selectable = [
      for (final e in events)
        if (!e.isSettled || e.id == selectedId) e,
    ];
    if (selectable.isEmpty) return const SizedBox.shrink();

    final selected =
        selectable.where((e) => e.id == selectedId).toList();
    final label = selected.isEmpty ? null : selected.first.name;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _pick(context, selectable),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Event (optional)',
          prefixIcon: const Icon(Icons.celebration_outlined),
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: label == null
              ? const Icon(Icons.arrow_drop_down)
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(label ?? 'None'),
      ),
    );
  }

  Future<void> _pick(BuildContext context, List<Event> events) async {
    final chosen = await showModalBottomSheet<Event>(
      context: context,
      showDragHandle: true,
      isScrollControlled: events.length > 8,
      builder: (ctx) => _EventPickList(events: events),
    );
    if (chosen != null) onChanged(chosen.id);
  }
}

class _EventPickList extends StatefulWidget {
  const _EventPickList({required this.events});
  final List<Event> events;

  @override
  State<_EventPickList> createState() => _EventPickListState();
}

class _EventPickListState extends State<_EventPickList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final searchable = widget.events.length > 8;
    final list = _query.isEmpty
        ? widget.events
        : widget.events
            .where((e) =>
                e.name.toLowerCase().contains(_query.toLowerCase()) ||
                (e.customerName ?? '')
                    .toLowerCase()
                    .contains(_query.toLowerCase()))
            .toList();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search events',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final e in list)
                  ListTile(
                    leading: const Icon(Icons.celebration_outlined),
                    title: Text(e.name),
                    subtitle: Text(DateFormat('d MMM yyyy').format(e.eventDate)),
                    onTap: () => Navigator.pop(context, e),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thumbnail of an attached bill photo; tap for full screen. Handles both
/// Supabase Storage paths (signed URL) and `local:` fallback paths.
class _AttachmentThumb extends ConsumerWidget {
  const _AttachmentThumb({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(attachmentRepoProvider);

    Widget thumb(ImageProvider provider) => InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.all(12),
              child: InteractiveViewer(
                child: Image(image: provider, fit: BoxFit.contain),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(
              image: provider,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 48,
                child: Center(child: Text('Attachment unavailable')),
              ),
            ),
          ),
        );

    if (repo.isLocal(path)) {
      final file = File(repo.localFilePath(path));
      if (!file.existsSync()) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Attached bill (this device only)'),
          thumb(FileImage(file)),
        ],
      );
    }

    return FutureBuilder<String?>(
      future: ref.read(attachmentRepoProvider).signedUrl(path),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Attached bill'),
            thumb(NetworkImage(snap.data!)),
          ],
        );
      },
    );
  }
}

/// Cash + UPI split entry. The user types the UPI amount; Cash auto-fills the
/// remainder so the row's sum always equals the transaction total. Save is
/// blocked (in the parent) if either part is zero or the sum drifts.
class _SplitFields extends StatefulWidget {
  const _SplitFields({
    required this.total,
    required this.cash,
    required this.upi,
    required this.onChanged,
  });
  final int total;
  final int cash;
  final int upi;
  final void Function(int cash, int upi) onChanged;

  @override
  State<_SplitFields> createState() => _SplitFieldsState();
}

class _SplitFieldsState extends State<_SplitFields> {
  late final TextEditingController _upiCtl = TextEditingController(
      text: widget.upi > 0 ? (widget.upi / 100).toStringAsFixed(2) : '');

  @override
  void didUpdateWidget(_SplitFields old) {
    super.didUpdateWidget(old);
    // If a keypad change auto-adjusted the split, keep the UPI field in sync
    // (but avoid re-rendering while the user is typing).
    final expected = widget.upi > 0
        ? (widget.upi / 100).toStringAsFixed(2)
        : '';
    if (expected != _upiCtl.text &&
        (double.tryParse(_upiCtl.text) ?? 0) * 100 != widget.upi) {
      _upiCtl.text = expected;
    }
  }

  @override
  void dispose() {
    _upiCtl.dispose();
    super.dispose();
  }

  void _onUpiChanged(String s) {
    final rupees = double.tryParse(s.trim()) ?? 0;
    var upiPaise = (rupees * 100).round();
    if (upiPaise < 0) upiPaise = 0;
    if (upiPaise > widget.total) upiPaise = widget.total;
    widget.onChanged(widget.total - upiPaise, upiPaise);
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.total - widget.cash - widget.upi;
    final ok = widget.cash > 0 && widget.upi > 0 && diff == 0;
    final color = ok
        ? AppSemantics.income
        : (widget.total == 0 ? Colors.grey : AppSemantics.warning);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _upiCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'UPI amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: _onUpiChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Cash (auto)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(
                    widget.total == 0
                        ? '0.00'
                        : (widget.cash / 100).toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.total == 0
                ? 'Enter the total first, then set UPI amount.'
                : ok
                    ? 'Split matches total ✓'
                    : diff > 0
                        ? 'Split short by ${Money.format(diff)}'
                        : 'Split over by ${Money.format(diff.abs())}',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
