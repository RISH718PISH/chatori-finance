/// Business-health ratios for a catering + cloud kitchen.
///
/// Pure Dart, no Flutter, so the thresholds and "what to improve" logic are
/// unit-testable. All money is integer paise; ratios are percentages.
///
/// Accounting notes honoured here (from the chatori-accountant skill):
///  • Revenue is EARNED revenue — Customer Advance is excluded upstream, so
///    a month isn't flattered by deposits for future parties.
///  • COGS is purchase-based, so food cost % is lumpy; we surface the
///    consumption-based figure alongside it as the smoother truth.
library;

enum HealthStatus { good, watch, act, none }

class HealthMetric {
  final String label;
  final String valueText;
  final HealthStatus status;

  /// One plain line: what it means / what to do.
  final String note;

  const HealthMetric({
    required this.label,
    required this.valueText,
    required this.status,
    required this.note,
  });
}

class HealthReport {
  final List<HealthMetric> metrics;

  /// 1–3 plain sentences: the most important things to fix, worst first.
  final List<String> summary;

  const HealthReport({required this.metrics, required this.summary});
}

double _pct(int part, int whole) => whole <= 0 ? 0 : part / whole * 100;
String _p(double v) => '${v.toStringAsFixed(0)}%';

/// [status] where a LOWER percentage is better (costs). Thresholds are the
/// upper bound of each band.
HealthStatus _lowerBetter(double v, double good, double watch) =>
    v <= good ? HealthStatus.good : (v <= watch ? HealthStatus.watch : HealthStatus.act);

HealthReport computeHealth({
  required int revenuePaise,
  required int cogsPaise,
  required int salaryPaise,
  required int otherOperatingPaise,
  required int netProfitPaise,
  required int stockValuePaise,
  required int monthlyConsumptionValuePaise,
  required int wastageValuePaise,
}) {
  final metrics = <HealthMetric>[];

  if (revenuePaise <= 0) {
    return const HealthReport(
      metrics: [],
      summary: [
        'No earned revenue recorded this month yet, so ratios can’t be '
            'computed. Add your income entries and check back.',
      ],
    );
  }

  // ── Food cost % (purchase-based) ──
  final foodCost = _pct(cogsPaise, revenuePaise);
  final foodStatus = _lowerBetter(foodCost, 35, 40);
  metrics.add(HealthMetric(
    label: 'Food cost',
    valueText: _p(foodCost),
    status: foodStatus,
    note: foodStatus == HealthStatus.act
        ? 'Above 40% — but this counts what you BOUGHT. Check the '
            'consumption figure below before acting; a stock-up month reads high.'
        : 'COGS as a share of sales. Healthy catering runs 30–35%.',
  ));

  // ── Consumption-based food cost (the smoother truth) ──
  if (monthlyConsumptionValuePaise > 0) {
    final consFood = _pct(monthlyConsumptionValuePaise, revenuePaise);
    final consStatus = _lowerBetter(consFood, 35, 40);
    metrics.add(HealthMetric(
      label: 'Food cost (used)',
      valueText: _p(consFood),
      status: consStatus,
      note: 'What you actually CONSUMED vs sales — the truer food cost. '
          'If this is healthy but the one above is high, you just bought ahead.',
    ));
  }

  // ── Labour % ──
  final labour = _pct(salaryPaise, revenuePaise);
  final labourStatus = _lowerBetter(labour, 25, 35);
  metrics.add(HealthMetric(
    label: 'Labour cost',
    valueText: _p(labour),
    status: labourStatus,
    note: labourStatus == HealthStatus.act
        ? 'Wages are eating over a third of sales — trim shifts or push volume.'
        : 'Salaries as a share of sales. Aim under 25%.',
  ));

  // ── Prime cost % (COGS + labour) — the headline kitchen metric ──
  final prime = _pct(cogsPaise + salaryPaise, revenuePaise);
  final primeStatus = _lowerBetter(prime, 60, 65);
  metrics.add(HealthMetric(
    label: 'Prime cost',
    valueText: _p(prime),
    status: primeStatus,
    note: 'Food + labour together — the number most kitchens live or die by. '
        'Keep it under 60%.',
  ));

  // ── Overheads % ──
  final overheads = _pct(otherOperatingPaise, revenuePaise);
  final overStatus = _lowerBetter(overheads, 20, 30);
  metrics.add(HealthMetric(
    label: 'Overheads',
    valueText: _p(overheads),
    status: overStatus,
    note: 'Rent, power, transport, ads, misc as a share of sales. Aim under 20%.',
  ));

  // ── Net margin % (higher better) ──
  final margin = netProfitPaise / revenuePaise * 100;
  final marginStatus = margin >= 12
      ? HealthStatus.good
      : (margin >= 5 ? HealthStatus.watch : HealthStatus.act);
  metrics.add(HealthMetric(
    label: 'Net margin',
    valueText: _p(margin),
    status: marginStatus,
    note: marginStatus == HealthStatus.act
        ? (margin < 0
            ? 'You lost money this month. Prime cost and overheads are where to look.'
            : 'Thin — under 5% leaves no cushion. Lift prices or cut the worst ratio above.')
        : 'What you keep from every ₹100 of sales. Above 12% is healthy.',
  ));

  // ── Wastage % ──
  if (monthlyConsumptionValuePaise > 0) {
    final wastage = _pct(wastageValuePaise, monthlyConsumptionValuePaise);
    final wasteStatus = _lowerBetter(wastage, 3, 5);
    metrics.add(HealthMetric(
      label: 'Wastage',
      valueText: _p(wastage),
      status: wasteStatus,
      note: wasteStatus == HealthStatus.act
          ? 'Over 5% of what you use is being thrown away — check the wastage '
              'reasons and prep/ordering.'
          : 'Waste as a share of consumption. Under 3% is tight.',
    ));
  }

  // ── Days of stock on hand ──
  if (monthlyConsumptionValuePaise > 0 && stockValuePaise > 0) {
    final days = stockValuePaise / (monthlyConsumptionValuePaise / 30);
    final daysStatus = (days < 3 || days > 20)
        ? HealthStatus.act
        : (days > 12 ? HealthStatus.watch : HealthStatus.good);
    metrics.add(HealthMetric(
      label: 'Days of stock',
      valueText: '${days.toStringAsFixed(0)} days',
      status: daysStatus,
      note: days > 20
          ? 'You’re holding a lot of stock — cash tied up and more spoilage risk.'
          : (days < 3
              ? 'Very little buffer — you risk running out mid-service.'
              : 'How long current stock lasts at this month’s usage. 5–12 days is comfortable.'),
    ));
  }

  // ── Summary: worst offenders first, a loss always headlining ──
  final summary = <String>[];
  final acts = metrics.where((m) => m.status == HealthStatus.act).toList();
  // A net loss is the single most important thing — float it to the top.
  acts.sort((a, b) {
    final an = a.label == 'Net margin' ? 0 : 1;
    final bn = b.label == 'Net margin' ? 0 : 1;
    return an.compareTo(bn);
  });
  for (final m in acts.take(3)) {
    summary.add('${m.label} (${m.valueText}): ${m.note}');
  }
  if (summary.isEmpty) {
    final watches = metrics.where((m) => m.status == HealthStatus.watch);
    if (watches.isEmpty) {
      summary.add('Solid month — every ratio is in a healthy band. Keep going.');
    } else {
      summary.add('Broadly healthy. Keep an eye on: '
          '${watches.map((m) => m.label.toLowerCase()).join(', ')}.');
    }
  }

  return HealthReport(metrics: metrics, summary: summary);
}
