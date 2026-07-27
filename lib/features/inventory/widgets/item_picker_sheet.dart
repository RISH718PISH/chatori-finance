import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/categories.dart';
import '../../../core/quantity.dart';
import '../../../data/models/inventory.dart';
import '../../transaction/transaction_providers.dart';
import '../inventory_providers.dart';

/// Result of picking in the sheet.
class ItemPickerResult {
  /// An existing catalogue item was chosen.
  final InventoryItem? existing;

  /// A new item was created (already persisted); this is it.
  final InventoryItem? created;

  const ItemPickerResult({this.existing, this.created});

  InventoryItem get item => (existing ?? created)!;
}

/// Searchable item picker with "create new" and (optionally) "don't track".
/// Shared by the invoice-review stock line, consumption entry, and opening
/// count. Returns null if dismissed.
Future<ItemPickerResult?> showItemPicker(
  BuildContext context,
  WidgetRef ref, {
  String? seedName,
  QtyDimension? seedDimension,
  String? seedUnit,
  String? seedCategory,
}) {
  return showModalBottomSheet<ItemPickerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PickerSheet(
      seedName: seedName,
      seedDimension: seedDimension,
      seedUnit: seedUnit,
      seedCategory: seedCategory,
    ),
  );
}

class _PickerSheet extends ConsumerStatefulWidget {
  const _PickerSheet({
    this.seedName,
    this.seedDimension,
    this.seedUnit,
    this.seedCategory,
  });
  final String? seedName;
  final QtyDimension? seedDimension;
  final String? seedUnit;
  final String? seedCategory;

  @override
  ConsumerState<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends ConsumerState<_PickerSheet> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.seedName != null) _search.text = widget.seedName!;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryItemsProvider).asData?.value ?? const [];
    final q = _search.text.trim().toLowerCase();
    final matches = q.isEmpty
        ? items
        : items.where((i) => i.name.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _search,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search or type a new item name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (q.isNotEmpty &&
                    !items.any((i) => i.name.toLowerCase() == q))
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text('Create "${_search.text.trim()}"'),
                    onTap: _createAndReturn,
                  ),
                for (final it in matches)
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(it.name),
                    subtitle: Text(
                        '${it.category ?? 'Uncategorised'} · ${it.displayUnit}'),
                    onTap: () => Navigator.pop(
                        context, ItemPickerResult(existing: it)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAndReturn() async {
    final name = _search.text.trim();
    if (name.isEmpty) return;

    // Confirm dimension/unit/category — seeded from the invoice line when
    // the picker was opened from the review screen.
    final spec = await showDialog<_NewItemSpec>(
      context: context,
      builder: (_) => _NewItemDialog(
        name: name,
        seedDimension: widget.seedDimension,
        seedUnit: widget.seedUnit,
        seedCategory: widget.seedCategory,
      ),
    );
    if (spec == null || !mounted) return;

    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    final id = await ref.read(inventoryRepoProvider).createItem(
          businessId: biz,
          name: name,
          dimension: spec.dimension,
          displayUnit: spec.unit.symbol,
          category: spec.category,
        );
    refreshInventory(ref);
    if (!mounted) return;
    Navigator.pop(
      context,
      ItemPickerResult(
        created: InventoryItem(
          id: id,
          name: name,
          dimension: spec.dimension,
          displayUnit: spec.unit.symbol,
          category: spec.category,
        ),
      ),
    );
  }
}

class _NewItemSpec {
  final QtyDimension dimension;
  final QtyUnit unit;
  final String? category;
  const _NewItemSpec(this.dimension, this.unit, this.category);
}

class _NewItemDialog extends StatefulWidget {
  const _NewItemDialog({
    required this.name,
    this.seedDimension,
    this.seedUnit,
    this.seedCategory,
  });
  final String name;
  final QtyDimension? seedDimension;
  final String? seedUnit;
  final String? seedCategory;

  @override
  State<_NewItemDialog> createState() => _NewItemDialogState();
}

class _NewItemDialogState extends State<_NewItemDialog> {
  late QtyUnit _unit = Quantity.unitFromSymbol(widget.seedUnit) ??
      Quantity.defaultUnitFor(widget.seedDimension ?? QtyDimension.mass);
  late String? _category = widget.seedCategory;

  @override
  Widget build(BuildContext context) {
    final expenseCats =
        kSeedCategories.where((c) => c.kind == 'expense').toList();
    return AlertDialog(
      title: Text('New item: ${widget.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Measured in'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final u in Quantity.all)
                ChoiceChip(
                  label: Text(u.symbol),
                  selected: _unit.symbol == u.symbol,
                  onSelected: (_) => setState(() => _unit = u),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final c in expenseCats)
                DropdownMenuItem(value: c.name, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(
              context, _NewItemSpec(_unit.dimension, _unit, _category)),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
