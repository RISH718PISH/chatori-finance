import '../../core/quantity.dart';

/// A catalogue item. Quantities everywhere are integer milli-units of
/// [dimension]'s base unit — see [Quantity].
class InventoryItem {
  final String id;
  final String name;
  final QtyDimension dimension;
  final String displayUnit;
  final String? category;
  final int reorderLevelMilli;
  final bool archived;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.dimension,
    required this.displayUnit,
    this.category,
    this.reorderLevelMilli = 0,
    this.archived = false,
  });

  QtyUnit get unit =>
      Quantity.unitFromSymbol(displayUnit) ??
      Quantity.defaultUnitFor(dimension);

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        id: j['id'] as String,
        name: j['name'] as String,
        dimension: _dim(j['dimension'] as String?),
        displayUnit: j['display_unit'] as String? ?? 'pcs',
        category: j['category'] as String?,
        reorderLevelMilli: (j['reorder_level_milli'] as num?)?.toInt() ?? 0,
        archived: j['archived'] as bool? ?? false,
      );
}

/// One row of the `v_stock_on_hand` view.
class StockOnHand {
  final String itemId;
  final String name;
  final QtyDimension dimension;
  final String displayUnit;
  final String? category;
  final int reorderLevelMilli;
  final int onHandMilli;
  final int inMilli;
  final int outMilli;
  final DateTime? lastInOn;
  final DateTime? lastOutOn;

  const StockOnHand({
    required this.itemId,
    required this.name,
    required this.dimension,
    required this.displayUnit,
    required this.onHandMilli,
    this.category,
    this.reorderLevelMilli = 0,
    this.inMilli = 0,
    this.outMilli = 0,
    this.lastInOn,
    this.lastOutOn,
  });

  /// At or below the reorder level, and a level was actually set.
  bool get isLow =>
      reorderLevelMilli > 0 && onHandMilli <= reorderLevelMilli;
  bool get isOut => onHandMilli <= 0;

  QtyUnit get unit =>
      Quantity.unitFromSymbol(displayUnit) ??
      Quantity.defaultUnitFor(dimension);

  /// The on-hand quantity formatted for its dimension, e.g. "38 kg".
  String get onHandLabel => Quantity.format(onHandMilli, dimension);

  factory StockOnHand.fromJson(Map<String, dynamic> j) => StockOnHand(
        itemId: j['item_id'] as String,
        name: j['name'] as String,
        dimension: _dim(j['dimension'] as String?),
        displayUnit: j['display_unit'] as String? ?? 'pcs',
        category: j['category'] as String?,
        reorderLevelMilli: (j['reorder_level_milli'] as num?)?.toInt() ?? 0,
        onHandMilli: (j['on_hand_milli'] as num?)?.toInt() ?? 0,
        inMilli: (j['in_milli'] as num?)?.toInt() ?? 0,
        outMilli: (j['out_milli'] as num?)?.toInt() ?? 0,
        lastInOn: _date(j['last_in_on']),
        lastOutOn: _date(j['last_out_on']),
      );
}

enum StockMovementType {
  purchase,
  opening,
  consumption,
  wastage,
  adjustment,
  returned;

  /// The DB spells the return type `return` (a Dart keyword), so map it.
  String get dbValue => this == StockMovementType.returned ? 'return' : name;

  static StockMovementType fromDb(String? raw) => switch (raw) {
        'purchase' => StockMovementType.purchase,
        'opening' => StockMovementType.opening,
        'consumption' => StockMovementType.consumption,
        'wastage' => StockMovementType.wastage,
        'adjustment' => StockMovementType.adjustment,
        'return' => StockMovementType.returned,
        _ => StockMovementType.adjustment,
      };

  String get label => switch (this) {
        StockMovementType.purchase => 'Purchase',
        StockMovementType.opening => 'Opening stock',
        StockMovementType.consumption => 'Used',
        StockMovementType.wastage => 'Wastage',
        StockMovementType.adjustment => 'Adjustment',
        StockMovementType.returned => 'Returned',
      };
}

class StockMovement {
  final String id;
  final String itemId;
  final StockMovementType type;

  /// Signed: positive into stock, negative out.
  final int qtyMilli;
  final DateTime occurredOn;
  final String? note;
  final String? eventId;
  final String? invoiceItemId;

  /// Total cost in paise for this movement's quantity. Null when unpriced.
  final int? costPaise;

  /// Structured reason — the consumption channel (Zomato, Catering …) or
  /// the wastage cause (Spoiled …). Free-text detail is in [note].
  final String? reason;

  const StockMovement({
    required this.id,
    required this.itemId,
    required this.type,
    required this.qtyMilli,
    required this.occurredOn,
    this.note,
    this.eventId,
    this.invoiceItemId,
    this.costPaise,
    this.reason,
  });

  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
        id: j['id'] as String,
        itemId: j['item_id'] as String,
        type: StockMovementType.fromDb(j['movement_type'] as String?),
        qtyMilli: (j['qty_milli'] as num).toInt(),
        occurredOn: DateTime.parse(j['occurred_on'] as String),
        note: j['note'] as String?,
        eventId: j['event_id'] as String?,
        invoiceItemId: j['invoice_item_id'] as String?,
        costPaise: (j['cost_paise'] as num?)?.toInt(),
        reason: j['reason'] as String?,
      );
}

/// One row of `v_stock_value` (owner only — the view returns nothing to a
/// chef, so this list is simply empty for them).
class StockValue {
  final String itemId;
  final String name;
  final QtyDimension dimension;
  final int onHandMilli;
  final int valuePaise;
  final double paisePerMilli;

  const StockValue({
    required this.itemId,
    required this.name,
    required this.dimension,
    required this.onHandMilli,
    required this.valuePaise,
    required this.paisePerMilli,
  });

  /// Average cost per display unit, in paise, for a label like "₹42/kg".
  int avgCostPerUnitPaise(QtyUnit unit) =>
      (paisePerMilli * unit.milliPerUnit).round();

  factory StockValue.fromJson(Map<String, dynamic> j) => StockValue(
        itemId: j['item_id'] as String,
        name: j['name'] as String,
        dimension: _dim(j['dimension'] as String?),
        onHandMilli: (j['on_hand_milli'] as num?)?.toInt() ?? 0,
        valuePaise: (j['value_paise'] as num?)?.toInt() ?? 0,
        paisePerMilli: (j['paise_per_milli'] as num?)?.toDouble() ?? 0,
      );
}

/// One row of `v_consumption_by_month`.
class ConsumptionRow {
  final String itemId;
  final String name;
  final QtyDimension dimension;
  final int consumedMilli;
  final int wastedMilli;

  const ConsumptionRow({
    required this.itemId,
    required this.name,
    required this.dimension,
    required this.consumedMilli,
    required this.wastedMilli,
  });

  factory ConsumptionRow.fromJson(Map<String, dynamic> j) => ConsumptionRow(
        itemId: j['item_id'] as String,
        name: j['name'] as String,
        dimension: _dim(j['dimension'] as String?),
        consumedMilli: (j['consumed_milli'] as num?)?.toInt() ?? 0,
        wastedMilli: (j['wasted_milli'] as num?)?.toInt() ?? 0,
      );
}

/// Why stock was consumed — the channel it went out through. Mandatory on
/// the consumption screen.
const List<String> kConsumptionReasons = [
  'Zomato Order',
  'Swiggy Order',
  'Direct Order',
  'Catering',
  'Consumed By Owner',
  'Trial / Recipe Testing',
  'Other',
];

/// Why stock was wasted.
const List<String> kWastageReasons = [
  'Spoiled / Expired',
  'Spillage',
  'Over-preparation',
  'Burnt / Cooking error',
  'Pest / Contamination',
  'Returned by customer',
  'Other',
];

QtyDimension _dim(String? raw) => switch (raw) {
      'mass' => QtyDimension.mass,
      'volume' => QtyDimension.volume,
      _ => QtyDimension.count,
    };

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.tryParse(v as String);
