import 'package:chatori_finance/core/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unit parsing', () {
    test('recognises the spellings that appear on real invoices', () {
      expect(Quantity.unitFromSymbol('Kg'), Quantity.kg);
      expect(Quantity.unitFromSymbol('KGS'), Quantity.kg);
      expect(Quantity.unitFromSymbol('gm'), Quantity.g);
      expect(Quantity.unitFromSymbol('Ltr'), Quantity.l);
      expect(Quantity.unitFromSymbol('ML'), Quantity.ml);
      expect(Quantity.unitFromSymbol('Nos'), Quantity.pcs);
      expect(Quantity.unitFromSymbol('pc'), Quantity.pcs);
      expect(Quantity.unitFromSymbol('Doz'), Quantity.dozen);
    });

    test('returns null for unknown units rather than guessing', () {
      // "packet" is deliberately NOT a unit — it is a pack size.
      expect(Quantity.unitFromSymbol('packet'), isNull);
      expect(Quantity.unitFromSymbol('box'), isNull);
      expect(Quantity.unitFromSymbol(''), isNull);
      expect(Quantity.unitFromSymbol(null), isNull);
    });
  });

  group('conversion', () {
    test('kg and g share the same base so they reconcile exactly', () {
      expect(Quantity.toMilli(1, Quantity.kg), 1000000);
      expect(Quantity.toMilli(1000, Quantity.g), 1000000);
      expect(Quantity.toMilli(1, Quantity.kg),
          Quantity.toMilli(1000, Quantity.g));
    });

    test('litres and ml share the same base', () {
      expect(Quantity.toMilli(1, Quantity.l), 1000000);
      expect(Quantity.toMilli(1000, Quantity.ml), 1000000);
    });

    test('a dozen is twelve pieces', () {
      expect(Quantity.toMilli(1, Quantity.dozen),
          Quantity.toMilli(12, Quantity.pcs));
    });

    test('buy in kg, consume in g, no drift over many movements', () {
      // 2 kg in, then 200 g out ten times -> exactly zero.
      var balance = Quantity.toMilli(2, Quantity.kg);
      for (var i = 0; i < 10; i++) {
        balance -= Quantity.toMilli(200, Quantity.g);
      }
      expect(balance, 0);
    });

    test('fractional quantities round half-up to whole milli-units', () {
      expect(Quantity.toMilli(0.5, Quantity.kg), 500000);
      expect(Quantity.toMilli(1.255, Quantity.kg), 1255000);
      // 1 mg is the smallest representable mass.
      expect(Quantity.toMilli(0.001, Quantity.g), 1);
    });
  });

  group('formatting', () {
    test('auto-scales to the unit a human would say', () {
      expect(Quantity.format(850000, QtyDimension.mass), '850 g');
      expect(Quantity.format(1250000, QtyDimension.mass), '1.25 kg');
      expect(Quantity.format(500000, QtyDimension.volume), '500 ml');
      expect(Quantity.format(2000000, QtyDimension.volume), '2 L');
      expect(Quantity.format(3000, QtyDimension.count), '3 pcs');
    });

    test('keeps the sign on negative (stock-out) balances', () {
      expect(Quantity.format(-1250000, QtyDimension.mass), '-1.25 kg');
    });

    test('zero renders cleanly', () {
      expect(Quantity.format(0, QtyDimension.mass), '0 g');
    });

    test('formatAs pins the unit instead of auto-scaling', () {
      expect(Quantity.formatAs(1250000, Quantity.g), '1250 g');
      expect(Quantity.formatAs(1250000, Quantity.kg), '1.25 kg');
    });
  });

  group('parseQuantity', () {
    test('converts an invoice (qty, unit) pair to storage form', () {
      final p = parseQuantity(2.5, 'Kg');
      expect(p, isNotNull);
      expect(p!.milli, 2500000);
      expect(p.dimension, QtyDimension.mass);
      expect(p.displayUnit, 'kg');
    });

    test('returns null when the unit is unrecognised, so callers prompt', () {
      expect(parseQuantity(3, 'packet'), isNull);
      expect(parseQuantity(3, null), isNull);
    });

    test('returns null when quantity is missing', () {
      expect(parseQuantity(null, 'kg'), isNull);
    });
  });
}
