import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design.dart';
import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../transaction/transaction_providers.dart';
import 'inventory_providers.dart';
import 'widgets/item_picker_sheet.dart';

/// Log discarded stock: item, quantity, reason, date, optional remarks.
/// Writes a `wastage` movement (negative), separate from consumption so
/// the two can be reported apart — waste is usually a real money leak.
class WastageScreen extends ConsumerStatefulWidget {
  const WastageScreen({super.key});

  @override
  ConsumerState<WastageScreen> createState() => _WastageScreenState();
}

class _WastageScreenState extends ConsumerState<WastageScreen> {
  InventoryItem? _item;
  final _qtyCtl = TextEditingController();
  final _remarksCtl = TextEditingController();
  String? _reason;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtl.dispose();
    _remarksCtl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _item != null &&
      _reason != null &&
      (double.tryParse(_qtyCtl.text.trim()) ?? 0) > 0 &&
      !_saving;

  Future<void> _pickItem() async {
    final result = await showItemPicker(context, ref);
    if (result != null) setState(() => _item = result.item);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final item = _item!;
    final qty = double.parse(_qtyCtl.text.trim());
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final biz = await ref.read(businessIdProvider.future);
      if (biz == null) return;
      final remarks = _remarksCtl.text.trim();
      await ref.read(inventoryRepoProvider).addMovement(
            businessId: biz,
            itemId: item.id,
            type: StockMovementType.wastage,
            qtyMilli: -Quantity.toMilli(qty, item.unit),
            occurredOn: _date,
            reason: _reason,
            note: remarks.isEmpty ? null : remarks,
          );
      refreshInventory(ref);
      ref.invalidate(itemMovementsProvider(item.id));
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppSemantics.expense,
        content: Text('Logged wastage: ${item.name} ✓',
            style: const TextStyle(color: Colors.white)),
      ));
      context.pop();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record wastage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: _pickItem,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Item *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              child: Text(_item?.name ?? 'Pick an item'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Quantity *',
              suffixText: _item?.displayUnit,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _reason,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Reason for wastage *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.report_gmailerrorred_outlined),
            ),
            items: [
              for (final r in kWastageReasons)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (v) => setState(() => _reason = v),
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
                prefixIcon: Icon(Icons.event),
              ),
              child: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksCtl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style:
                FilledButton.styleFrom(backgroundColor: AppSemantics.expense),
            onPressed: _canSave ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.delete_outline),
            label: Text(_saving ? 'Saving…' : 'Log wastage'),
          ),
        ),
      ),
    );
  }
}
