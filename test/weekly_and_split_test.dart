import 'package:chatori_finance/data/models/event.dart';
import 'package:chatori_finance/data/models/txn.dart';
import 'package:chatori_finance/features/reports/reports_providers.dart';
import 'package:flutter_test/flutter_test.dart';

Txn _t({
  String type = 'expense',
  String category = 'Groceries',
  int paise = 100,
  DateTime? at,
  String mode = 'Cash',
  int? cash,
  int? upi,
}) =>
    Txn(
      id: '$paise-${at?.millisecondsSinceEpoch ?? 0}',
      type: type,
      category: category,
      amountPaise: paise,
      occurredAt: at ?? DateTime.now(),
      paymentMode: mode,
      cashPaise: cash,
      upiPaise: upi,
    );

void main() {
  group('bucketize', () {
    test('sums per category, sorts descending, folds empty labels', () {
      final txns = [
        _t(category: 'Groceries', paise: 500),
        _t(category: 'Veggies', paise: 300),
        _t(category: 'Groceries', paise: 200),
        _t(category: '', paise: 100), // empty → Uncategorized
        _t(category: '   ', paise: 50), // whitespace → Uncategorized
      ];
      final buckets = bucketize(txns, (t) => t.category);
      expect(buckets.first.label, 'Groceries');
      expect(buckets.first.paise, 700);
      expect(buckets[1].label, 'Veggies');
      expect(buckets[1].paise, 300);
      // The two empty-ish labels folded into one Uncategorized bucket.
      final uncat = buckets.firstWhere((b) => b.label == 'Uncategorized');
      expect(uncat.paise, 150);
    });

    test('applies where filter without leaking into totals', () {
      final txns = [
        _t(type: 'income', paise: 1000),
        _t(type: 'expense', category: 'Rent', paise: 200),
      ];
      final buckets = bucketize(txns, (t) => t.category,
          where: (t) => !t.isIncome);
      expect(buckets.length, 1);
      expect(buckets.first.label, 'Rent');
      expect(buckets.first.paise, 200);
    });
  });

  group('percentagesSummingTo100', () {
    test('sums to exactly 100 even after rounding', () {
      final result = percentagesSummingTo100(
        const [Bucket('A', 33), Bucket('B', 33), Bucket('C', 34)],
        100,
      );
      expect(result.reduce((a, b) => a + b), 100);
    });

    test('handles zero total without dividing by zero', () {
      final result = percentagesSummingTo100(const [Bucket('A', 0)], 0);
      expect(result, [0]);
    });

    test('empty buckets return empty list', () {
      expect(percentagesSummingTo100(const [], 100), isEmpty);
    });
  });

  group('Txn split payments', () {
    test('pure-Cash contributes only to cash portion', () {
      final t = _t(mode: 'Cash', paise: 500);
      expect(t.cashPortionPaise, 500);
      expect(t.digitalPortionPaise, 0);
    });

    test('pure-UPI contributes only to digital portion', () {
      final t = _t(mode: 'UPI', paise: 500);
      expect(t.cashPortionPaise, 0);
      expect(t.digitalPortionPaise, 500);
    });

    test('Cash+UPI split contributes both, summing to total', () {
      final t = _t(mode: 'Cash+UPI', paise: 500, cash: 200, upi: 300);
      expect(t.cashPortionPaise, 200);
      expect(t.digitalPortionPaise, 300);
      expect(t.cashPortionPaise + t.digitalPortionPaise, t.amountPaise);
    });

    test('Cash+UPI with missing split falls back to zero cash portion', () {
      // Malformed: server row missing columns (older data). Should not throw.
      final t = _t(mode: 'Cash+UPI', paise: 500);
      expect(t.cashPortionPaise, 0);
      expect(t.digitalPortionPaise, 500);
    });
  });

  group('eventSectionOf', () {
    Event mk({required DateTime date, String status = 'upcoming'}) => Event(
          id: date.toIso8601String(),
          name: 'evt',
          eventDate: date,
          status: status,
        );

    final today = DateTime(2026, 7, 4);

    test('upcoming with future date → Upcoming', () {
      final s = eventSectionOf(mk(date: DateTime(2026, 7, 10)), now: today);
      expect(s, EventSection.upcoming);
    });

    test('upcoming with today\'s date → Due today', () {
      final s = eventSectionOf(mk(date: DateTime(2026, 7, 4)), now: today);
      expect(s, EventSection.dueToday);
    });

    test('upcoming with past date → Past (regression fix)', () {
      // The original bug: an event dated 3rd July stayed in Upcoming after
      // that date passed. Must move to Past on its own.
      final s = eventSectionOf(mk(date: DateTime(2026, 7, 3)), now: today);
      expect(s, EventSection.past);
    });

    test('done → always Past regardless of date', () {
      final future = mk(date: DateTime(2026, 8, 1), status: 'done');
      expect(eventSectionOf(future, now: today), EventSection.past);
    });

    test('settled → always Past', () {
      final future = mk(date: DateTime(2026, 8, 1), status: 'settled');
      expect(eventSectionOf(future, now: today), EventSection.past);
    });
  });
}
