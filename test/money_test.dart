import 'package:chatori_finance/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('paise -> rupees conversion is exact', () {
      expect(Money.toPaise(1234.5), 123450);
      expect(Money.toRupees(123450), 1234.5);
    });

    test('rounds to nearest paise', () {
      expect(Money.toPaise(10.005), 1001);
      expect(Money.toPaise(10.004), 1000);
    });

    test('formats with the ₹ symbol', () {
      expect(Money.format(123450), contains('₹'));
      expect(Money.format(0, decimals: false), '₹0');
    });

    test('uses Indian grouping (lakh)', () {
      // 1,00,000.00 not 100,000.00
      expect(Money.format(10000000), '₹1,00,000.00');
    });
  });
}
