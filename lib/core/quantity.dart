/// Quantity helpers — the sibling of [Money].
///
/// Quantities are stored as **integer milli-units**, exactly as money is
/// stored as integer paise, and for the same reason: repeatedly adding and
/// subtracting binary floats (0.1 kg + 0.2 kg) accumulates error, and an
/// inventory balance that silently drifts is worse than one that is
/// obviously wrong.
///
/// The base is defined per *dimension*, not per item, so an item bought in
/// kg and consumed in g reconciles without any per-item conversion:
///
///   mass    base gram   -> qtyMilli is milligrams   (1 kg = 1,000,000)
///   volume  base ml     -> qtyMilli is microlitres  (1 L  = 1,000,000)
///   count   base piece  -> qtyMilli is milli-pieces (1 dozen = 12,000)
///
/// Note there is deliberately no `packet` unit. A packet is a *pack size*,
/// not a unit of measure — allowing it would produce items whose stock
/// reads "3 packets" while consumption wants grams, with no way to
/// reconcile the two. Model packs at the purchase line instead
/// ("2 packets x 500 g" -> 1,000,000 mg).
library;

enum QtyDimension { mass, volume, count }

class QtyUnit {
  final String symbol;
  final QtyDimension dimension;

  /// How many milli-units one of this unit represents.
  final int milliPerUnit;

  const QtyUnit(this.symbol, this.dimension, this.milliPerUnit);
}

class Quantity {
  Quantity._();

  static const kg = QtyUnit('kg', QtyDimension.mass, 1000000);
  static const g = QtyUnit('g', QtyDimension.mass, 1000);
  static const l = QtyUnit('l', QtyDimension.volume, 1000000);
  static const ml = QtyUnit('ml', QtyDimension.volume, 1000);
  static const pcs = QtyUnit('pcs', QtyDimension.count, 1000);
  static const dozen = QtyUnit('dozen', QtyDimension.count, 12000);

  static const List<QtyUnit> all = [kg, g, l, ml, pcs, dozen];

  /// Units offered when the user picks a display unit for an item.
  static List<QtyUnit> unitsFor(QtyDimension d) =>
      all.where((u) => u.dimension == d).toList();

  /// The unit a dimension defaults to when nothing better is known.
  static QtyUnit defaultUnitFor(QtyDimension d) => switch (d) {
        QtyDimension.mass => kg,
        QtyDimension.volume => l,
        QtyDimension.count => pcs,
      };

  /// Looks up a unit by symbol, tolerating the spellings that turn up on
  /// real invoices ("Kg", "KG", "gm", "ltr", "nos", "pc"). Returns null
  /// when the text is not a recognisable unit — callers should treat that
  /// as "quantity unknown" rather than guessing.
  static QtyUnit? unitFromSymbol(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toLowerCase().replaceAll('.', '');
    return switch (s) {
      'kg' || 'kgs' || 'kilogram' || 'kilograms' => kg,
      'g' || 'gm' || 'gms' || 'gram' || 'grams' => g,
      'l' || 'ltr' || 'ltrs' || 'litre' || 'litres' || 'liter' => l,
      'ml' || 'mls' || 'millilitre' || 'milliliter' => ml,
      'pcs' || 'pc' || 'piece' || 'pieces' || 'nos' || 'no' || 'unit' ||
      'units' =>
        pcs,
      'dozen' || 'dz' || 'doz' => dozen,
      _ => null,
    };
  }

  /// A quantity in [unit] -> integer milli-units. Rounds half-up.
  static int toMilli(num qty, QtyUnit unit) =>
      (qty * unit.milliPerUnit).round();

  /// Integer milli-units -> a quantity expressed in [unit].
  static double fromMilli(int milli, QtyUnit unit) =>
      milli / unit.milliPerUnit;

  /// Formats milli-units for display, auto-scaling to the unit a human
  /// would actually say: 850 g rather than 0.85 kg, 1.25 kg rather than
  /// 1250 g. Negative values (stock-out movements) keep their sign.
  static String format(int milli, QtyDimension dimension) {
    final neg = milli < 0;
    final abs = milli.abs();
    final (value, symbol) = switch (dimension) {
      QtyDimension.mass =>
        abs >= kg.milliPerUnit ? (abs / kg.milliPerUnit, 'kg') : (abs / g.milliPerUnit, 'g'),
      QtyDimension.volume =>
        abs >= l.milliPerUnit ? (abs / l.milliPerUnit, 'L') : (abs / ml.milliPerUnit, 'ml'),
      QtyDimension.count => (abs / pcs.milliPerUnit, 'pcs'),
    };
    return '${neg ? '-' : ''}${_trim(value)} $symbol';
  }

  /// Formats in a specific unit rather than auto-scaling.
  static String formatAs(int milli, QtyUnit unit) =>
      '${_trim(fromMilli(milli, unit))} ${unit.symbol}';

  /// Drops a trailing ".0" and caps at 3 decimals so 0.001 kg (= 1 g) is
  /// still representable without showing float noise.
  static String _trim(double v) {
    final s = v.toStringAsFixed(3);
    var out = s.contains('.')
        ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : s;
    if (out.isEmpty || out == '-') out = '0';
    return out;
  }
}

/// Storage triple for a parsed/entered quantity.
typedef ParsedQty = ({int milli, QtyDimension dimension, String displayUnit});

/// Converts a raw (qty, unit-text) pair — e.g. straight off an invoice —
/// into the stored representation. Returns null when the unit is not
/// recognised, so the caller can prompt rather than silently mis-store.
ParsedQty? parseQuantity(num? qty, String? unitText) {
  if (qty == null) return null;
  final unit = Quantity.unitFromSymbol(unitText);
  if (unit == null) return null;
  return (
    milli: Quantity.toMilli(qty, unit),
    dimension: unit.dimension,
    displayUnit: unit.symbol,
  );
}
