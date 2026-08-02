import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';
import 'widgets/item_picker_sheet.dart';

/// Records a batch-cooking / prep step: a raw item is boiled/prepped and
/// stored, so it leaves raw stock and enters a "ready" item's stock. One save
/// writes both movements. Use this only for the few items where knowing the
/// cooked balance matters (e.g. boiled chicken); for everything else, record
/// the raw item as "Used" at prep time.
class PrepEntryScreen extends ConsumerStatefulWidget {
  const PrepEntryScreen({super.key});

  @override
  ConsumerState<PrepEntryScreen> createState() => _PrepEntryScreenState();
}

class _PrepEntryScreenState extends ConsumerState<PrepEntryScreen> {
  InventoryItem? _raw;
  InventoryItem? _made;
  final _rawQty = TextEditingController();
  final _madeQty = TextEditingController();
  final _note = TextEditingController();
  final DateTime _date = DateTime.now();
  bool _saving = false;

  double get _rawVal => double.tryParse(_rawQty.text.trim()) ?? 0;
  double get _madeVal => double.tryParse(_madeQty.text.trim()) ?? 0;

  bool get _canSave =>
      _raw != null &&
      _made != null &&
      _raw!.id != _made!.id &&
      _rawVal > 0 &&
      _madeVal > 0 &&
      !_saving;

  @override
  void dispose() {
    _rawQty.dispose();
    _madeQty.dispose();
    _note.dispose();
    super.dispose();
  }

  int _milli(InventoryItem item, double qty) {
    final unit = Quantity.unitFromSymbol(item.displayUnit) ??
        Quantity.defaultUnitFor(item.dimension);
    return Quantity.toMilli(qty, unit);
  }

  Future<void> _pickRaw() async {
    final res = await showItemPicker(context, ref);
    if (res != null) setState(() => _raw = res.item);
  }

  Future<void> _pickMade() async {
    final res = await showItemPicker(context, ref);
    if (res != null) setState(() => _made = res.item);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final biz = await ref.read(businessIdProvider.future);
      if (biz == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('No business found.')));
        return;
      }
      final note = _note.text.trim().isEmpty ? null : _note.text.trim();
      await ref.read(inventoryRepoProvider).recordPrep(
            businessId: biz,
            rawItemId: _raw!.id,
            rawQtyMilli: _milli(_raw!, _rawVal),
            producedItemId: _made!.id,
            producedQtyMilli: _milli(_made!, _madeVal),
            occurredOn: _date,
            note: note,
          );
      refreshInventory(ref);
      if (!mounted) return;
      context.pop();
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Prep saved: −$_rawQtyLabel ${_raw!.name}, '
            '+$_madeQtyLabel ${_made!.name}'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _rawQtyLabel => '${_trim(_rawVal)} ${_raw?.displayUnit ?? ''}';
  String get _madeQtyLabel => '${_trim(_madeVal)} ${_made?.displayUnit ?? ''}';
  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record prep / batch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'For items where the cooked version is counted separately — like '
            'raw chicken → boiled chicken. This deducts the raw item and adds '
            'the cooked item, so you can see how much cooked stock is left in '
            'the fridge.\n\nIf it stays the same item (dal → dal), you don\'t '
            'need prep — just record Consumption when it\'s used.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _pickerField(
            label: 'Raw item used',
            icon: Icons.outbox_outlined,
            item: _raw,
            onTap: _pickRaw,
          ),
          if (_raw != null) ...[
            const SizedBox(height: 8),
            _qtyField(_rawQty, 'Quantity used', _raw!.displayUnit),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: Icon(Icons.arrow_downward, size: 28)),
          ),
          _pickerField(
            label: 'Cooked item made',
            icon: Icons.inbox_outlined,
            item: _made,
            onTap: _pickMade,
          ),
          if (_made != null) ...[
            const SizedBox(height: 8),
            _qtyField(_madeQty, 'Quantity made', _made!.displayUnit),
          ],
          if (_raw != null && _made != null && _raw!.id == _made!.id)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Same item on both sides doesn\'t change your stock — cooking '
                'mix dal into mix dal leaves you with the same "mix dal". '
                'You don\'t need prep here: just record it under Consumption '
                'when it\'s used. Use prep only when the cooked item is counted '
                'separately (e.g. raw chicken → boiled chicken).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _canSave ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(_saving ? 'Saving…' : 'Save prep'),
          ),
        ],
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required IconData icon,
    required InventoryItem? item,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          prefixIcon: Icon(icon),
        ),
        child: Text(item?.name ?? 'Choose or create item'),
      ),
    );
  }

  Widget _qtyField(
      TextEditingController controller, String label, String unit) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
        isDense: true,
        prefixIcon: const Icon(Icons.scale_outlined),
      ),
    );
  }
}
