import 'package:chatori_finance/features/reports/health.dart';
import 'package:flutter_test/flutter_test.dart';

// Money helpers in paise.
int r(int rupees) => rupees * 100;

HealthMetric _metric(HealthReport rep, String label) =>
    rep.metrics.firstWhere((m) => m.label == label);

void main() {
  group('computeHealth', () {
    test('no revenue → no ratios, a clear message', () {
      final rep = computeHealth(
        revenuePaise: 0,
        cogsPaise: r(1000),
        salaryPaise: 0,
        otherOperatingPaise: 0,
        netProfitPaise: -r(1000),
        stockValuePaise: 0,
        monthlyConsumptionValuePaise: 0,
        wastageValuePaise: 0,
      );
      expect(rep.metrics, isEmpty);
      expect(rep.summary.single, contains('No earned revenue'));
    });

    test('a healthy month reads green across the board', () {
      // Revenue 1,00,000 · COGS 32,000 (32%) · salary 20,000 (20%) ·
      // overheads 15,000 (15%) · net 33,000 (33%).
      final rep = computeHealth(
        revenuePaise: r(100000),
        cogsPaise: r(32000),
        salaryPaise: r(20000),
        otherOperatingPaise: r(15000),
        netProfitPaise: r(33000),
        stockValuePaise: r(10000), // 10 days at 30k/mo → good
        monthlyConsumptionValuePaise: r(30000),
        wastageValuePaise: r(600), // 2% of consumption
      );
      expect(_metric(rep, 'Food cost').status, HealthStatus.good);
      expect(_metric(rep, 'Labour cost').status, HealthStatus.good);
      expect(_metric(rep, 'Prime cost').status, HealthStatus.good);
      expect(_metric(rep, 'Net margin').status, HealthStatus.good);
      expect(_metric(rep, 'Wastage').status, HealthStatus.good);
      expect(rep.summary.single, contains('Solid month'));
    });

    test('high food cost is flagged to act', () {
      final rep = computeHealth(
        revenuePaise: r(100000),
        cogsPaise: r(45000), // 45%
        salaryPaise: r(20000),
        otherOperatingPaise: r(15000),
        netProfitPaise: r(20000),
        stockValuePaise: r(10000),
        monthlyConsumptionValuePaise: r(30000),
        wastageValuePaise: r(300),
      );
      expect(_metric(rep, 'Food cost').status, HealthStatus.act);
    });

    test('prime cost combines food and labour', () {
      // 40% food + 30% labour = 70% prime → act.
      final rep = computeHealth(
        revenuePaise: r(100000),
        cogsPaise: r(40000),
        salaryPaise: r(30000),
        otherOperatingPaise: r(10000),
        netProfitPaise: r(20000),
        stockValuePaise: r(10000),
        monthlyConsumptionValuePaise: r(38000),
        wastageValuePaise: r(300),
      );
      expect(_metric(rep, 'Prime cost').valueText, '70%');
      expect(_metric(rep, 'Prime cost').status, HealthStatus.act);
    });

    test('a loss is called out plainly in the summary', () {
      final rep = computeHealth(
        revenuePaise: r(100000),
        cogsPaise: r(50000),
        salaryPaise: r(35000),
        otherOperatingPaise: r(25000),
        netProfitPaise: -r(10000), // loss
        stockValuePaise: r(10000),
        monthlyConsumptionValuePaise: r(45000),
        wastageValuePaise: r(3000),
      );
      expect(_metric(rep, 'Net margin').status, HealthStatus.act);
      expect(rep.summary.any((s) => s.toLowerCase().contains('lost money')),
          isTrue);
    });

    test('purchase-based vs consumption-based food cost shown separately', () {
      // Bought a lot (48%) but only used 33% — the "just stocked up" case.
      final rep = computeHealth(
        revenuePaise: r(100000),
        cogsPaise: r(48000),
        salaryPaise: r(20000),
        otherOperatingPaise: r(15000),
        netProfitPaise: -r(3000),
        stockValuePaise: r(40000),
        monthlyConsumptionValuePaise: r(33000),
        wastageValuePaise: r(500),
      );
      expect(_metric(rep, 'Food cost').valueText, '48%');
      expect(_metric(rep, 'Food cost (used)').valueText, '33%');
      expect(_metric(rep, 'Food cost (used)').status, HealthStatus.good);
    });

    test('days of stock flags both too-much and too-little', () {
      // Stock 60,000 at 30,000/mo consumption = 60 days → act (too much).
      final tooMuch = computeHealth(
        revenuePaise: r(100000),
        cogsPaise: r(30000),
        salaryPaise: r(20000),
        otherOperatingPaise: r(15000),
        netProfitPaise: r(35000),
        stockValuePaise: r(60000),
        monthlyConsumptionValuePaise: r(30000),
        wastageValuePaise: r(300),
      );
      expect(_metric(tooMuch, 'Days of stock').status, HealthStatus.act);
    });
  });
}
