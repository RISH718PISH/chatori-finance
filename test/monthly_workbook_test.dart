import 'package:chatori_finance/data/export/monthly_workbook.dart';
import 'package:chatori_finance/data/models/txn.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the monthly Excel export: the Syncfusion chart calls must not throw
/// and the result must be a real .xlsx (a zip, so it starts with "PK").
void main() {
  Txn t({
    required String type,
    required String category,
    required int rupees,
    String mode = 'UPI',
    String? eventId,
    int day = 3,
  }) =>
      Txn(
        id: '$category-$rupees-$day',
        type: type,
        category: category,
        amountPaise: rupees * 100,
        occurredAt: DateTime(2026, 7, day, 12),
        paymentMode: mode,
        eventId: eventId,
      );

  test('builds a monthly workbook with charts', () {
    final txns = <Txn>[
      t(type: 'income', category: 'Catering', rupees: 175000, eventId: 'e1'),
      t(type: 'expense', category: 'Veggies', rupees: 11500, eventId: 'e1'),
      t(type: 'expense', category: 'Event Labor', rupees: 7000, eventId: 'e1'),
      t(type: 'income', category: 'Cloud Kitchen', rupees: 5290, day: 15),
      t(type: 'expense', category: 'Rent', rupees: 31900, day: 10),
      t(type: 'expense', category: 'Dairy', rupees: 520, day: 11),
      t(
        type: 'income',
        category: 'Catering',
        rupees: 175000,
        mode: 'Cash+UPI',
        eventId: 'e1',
      ),
    ];

    final bytes = MonthlyWorkbook.build(
      month: DateTime(2026, 7),
      txns: txns,
      eventNames: const {'e1': 'Birthday Party'},
      salaryPaidPaise: 25000 * 100,
    );

    expect(bytes.length, greaterThan(2000));
    expect(bytes[0], 0x50); // P
    expect(bytes[1], 0x4B); // K
  });

  test('empty month still produces a valid file', () {
    final bytes = MonthlyWorkbook.build(
      month: DateTime(2026, 7),
      txns: const [],
      eventNames: const {},
    );
    expect(bytes[0], 0x50);
    expect(bytes[1], 0x4B);
  });
}
