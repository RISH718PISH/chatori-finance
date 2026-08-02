import 'package:intl/intl.dart';
import 'package:syncfusion_officechart/officechart.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../../core/categories.dart';
import '../models/txn.dart';

/// Builds a rich, multi-sheet Excel workbook for one month — the "detailed
/// export with a dashboard" the owner asked for. Unlike the flat CSVs, this
/// carries real Excel charts (pie + column) so the numbers read at a glance.
///
/// Sheets: Summary (KPIs + pies), Event P&L (column chart), Day-by-day
/// (column chart), and All transactions (the full itemised ledger).
class MonthlyWorkbook {
  MonthlyWorkbook._();

  // Brand palette (wheatish).
  static const _brown = '#8A5A2B';
  static const _brownDeep = '#6E4720';
  static const _green = '#2E7D32';
  static const _red = '#C62828';
  static const _rowAlt = '#FBF6EE';
  static const _incomeFill = '#EAF3EA';
  // Indian-style thousands grouping (…,##,##,##0).
  static const _money = r'#,##,##0';
  static const _money2 = r'#,##,##0.00';

  static final _dayFmt = DateFormat('dd MMM');
  static final _isoFmt = DateFormat('yyyy-MM-dd');

  /// Returns the .xlsx file bytes. Money in, money out — everything is
  /// converted from paise to whole rupees for the spreadsheet.
  static List<int> build({
    required DateTime month,
    required List<Txn> txns,
    required Map<String, String> eventNames,
    int salaryPaidPaise = 0,
  }) {
    final monthLabel = DateFormat('MMMM yyyy').format(month);

    // ---- aggregate ----
    double r(int paise) => paise / 100.0;
    // Owner capital is neither income nor expense — keep it out of the P&L
    // aggregations and surface it separately as a running total.
    final op = txns.where((t) => !isCapitalCategory(t.category)).toList();
    final ownerFunds = ownerFundsNetPaise(txns);
    final income = op.where((t) => t.isIncome).toList();
    final expense = op.where((t) => !t.isIncome).toList();
    final totIncome = income.fold<int>(0, (s, t) => s + t.amountPaise);
    final totExpense =
        expense.fold<int>(0, (s, t) => s + t.amountPaise) + salaryPaidPaise;
    final net = totIncome - totExpense;
    final margin = totIncome == 0 ? 0.0 : net / totIncome * 100;

    List<MapEntry<String, int>> byCat(List<Txn> items) {
      final m = <String, int>{};
      for (final t in items) {
        final k = t.category.trim().isEmpty ? 'Uncategorized' : t.category;
        m.update(k, (v) => v + t.amountPaise, ifAbsent: () => t.amountPaise);
      }
      final list = m.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return list;
    }

    final incByCat = byCat(income);
    final expByCat = byCat(expense);
    if (salaryPaidPaise > 0) {
      expByCat.add(MapEntry('Salaries', salaryPaidPaise));
      expByCat.sort((a, b) => b.value.compareTo(a.value));
    }

    // event / stream grouping
    final evMap = <String, List<int>>{}; // key -> [income, expense, count]
    for (final t in op) {
      final key = t.eventId == null
          ? 'Cloud Kitchen & Daily Ops'
          : (eventNames[t.eventId] ?? 'Event');
      final e = evMap.putIfAbsent(key, () => [0, 0, 0]);
      if (t.isIncome) {
        e[0] += t.amountPaise;
      } else {
        e[1] += t.amountPaise;
      }
      e[2] += 1;
    }
    final events = evMap.entries.toList()
      ..sort((a, b) =>
          (b.value[0] - b.value[1]).compareTo(a.value[0] - a.value[1]));

    // day-by-day
    final dayMap = <String, List<int>>{}; // yyyy-MM-dd -> [income, expense]
    for (final t in op) {
      final key = _isoFmt.format(t.occurredAt);
      final d = dayMap.putIfAbsent(key, () => [0, 0]);
      if (t.isIncome) {
        d[0] += t.amountPaise;
      } else {
        d[1] += t.amountPaise;
      }
    }
    final days = dayMap.keys.toList()..sort();

    // ---- workbook ----
    final wb = Workbook();
    _buildSummary(wb.worksheets[0], monthLabel, txns.length, r, totIncome,
        totExpense, net, margin.toDouble(), ownerFunds, expByCat, incByCat);
    _buildEvents(wb.worksheets.addWithName('Event P&L'), r, events);
    _buildDaily(wb.worksheets.addWithName('Day-by-day'), r, days, dayMap);
    _buildLedger(wb.worksheets.addWithName('All transactions'), r, txns,
        eventNames);

    final bytes = wb.saveAsStream();
    wb.dispose();
    return bytes;
  }

  // -------------------------------------------------------------------------
  static void _title(Worksheet s, String monthLabel) {
    s.getRangeByName('A1').setText('Chatori Kitchen');
    final t = s.getRangeByName('A1');
    t.cellStyle
      ..bold = true
      ..fontSize = 18
      ..fontColor = _brown;
    s.getRangeByName('A2').setText('Monthly report  •  $monthLabel');
    s.getRangeByName('A2').cellStyle
      ..fontSize = 11
      ..fontColor = '#7A6A55';
  }

  static void _tableHeader(Range hdr) {
    hdr.cellStyle
      ..bold = true
      ..fontColor = '#FFFFFF'
      ..backColor = _brown
      ..hAlign = HAlignType.center;
  }

  static void _buildSummary(
    Worksheet s,
    String monthLabel,
    int entryCount,
    double Function(int) r,
    int totIncome,
    int totExpense,
    int net,
    double margin,
    int ownerFunds,
    List<MapEntry<String, int>> expByCat,
    List<MapEntry<String, int>> incByCat,
  ) {
    s.showGridlines = false;
    _title(s, monthLabel);

    // KPI block
    final kpis = <List<Object>>[
      ['Total income', r(totIncome), _green],
      ['Total expenses', r(totExpense), _red],
      ['Net profit', r(net), net >= 0 ? _green : _red],
    ];
    var row = 4;
    for (final k in kpis) {
      s.getRangeByIndex(row, 1).setText(k[0] as String);
      s.getRangeByIndex(row, 1).cellStyle
        ..bold = true
        ..fontColor = '#7A6A55';
      final v = s.getRangeByIndex(row, 2)..setNumber(k[1] as double);
      v.numberFormat = _money;
      v.cellStyle
        ..bold = true
        ..fontSize = 13
        ..fontColor = k[2] as String;
      row++;
    }
    s.getRangeByIndex(row, 1).setText('Profit margin');
    s.getRangeByIndex(row, 1).cellStyle
      ..bold = true
      ..fontColor = '#7A6A55';
    final mv = s.getRangeByIndex(row, 2)..setNumber(margin / 100);
    mv.numberFormat = '0.0%';
    mv.cellStyle
      ..bold = true
      ..fontSize = 13
      ..fontColor = _brown;
    s.getRangeByIndex(4, 3).setText('$entryCount entries this month');
    s.getRangeByIndex(4, 3).cellStyle.fontColor = '#9A8A73';
    if (ownerFunds != 0) {
      s.getRangeByIndex(6, 3).setText("Owner's funds added (not in profit)");
      s.getRangeByIndex(6, 3).cellStyle.fontColor = '#9A8A73';
      final of = s.getRangeByIndex(6, 4)..setNumber(ownerFunds / 100.0);
      of.numberFormat = _money;
      of.cellStyle
        ..bold = true
        ..fontColor = _brown;
    }

    // Expenses by category table (A/B), starting row 10
    final expStart = 10;
    s.getRangeByIndex(expStart - 1, 1).setText('Where the money went');
    s.getRangeByIndex(expStart - 1, 1).cellStyle
      ..bold = true
      ..fontColor = _brownDeep;
    s.getRangeByIndex(expStart, 1).setText('Category');
    s.getRangeByIndex(expStart, 2).setText('Amount');
    _tableHeader(s.getRangeByIndex(expStart, 1, expStart, 2));
    var er = expStart;
    for (final e in expByCat) {
      er++;
      s.getRangeByIndex(er, 1).setText(e.key);
      final c = s.getRangeByIndex(er, 2)..setNumber(r(e.value));
      c.numberFormat = _money;
      if ((er - expStart).isOdd) {
        s.getRangeByIndex(er, 1, er, 2).cellStyle.backColor = _rowAlt;
      }
    }
    er++;
    s.getRangeByIndex(er, 1).setText('Total');
    s.getRangeByIndex(er, 1).cellStyle.bold = true;
    final expTot = s.getRangeByIndex(er, 2)
      ..setNumber(r(expByCat.fold<int>(0, (a, e) => a + e.value)));
    expTot.numberFormat = _money;
    expTot.cellStyle.bold = true;
    final expEnd = er;

    // Income by source table below it
    final incStart = expEnd + 3;
    s.getRangeByIndex(incStart - 1, 1).setText('Where income came from');
    s.getRangeByIndex(incStart - 1, 1).cellStyle
      ..bold = true
      ..fontColor = _brownDeep;
    s.getRangeByIndex(incStart, 1).setText('Source');
    s.getRangeByIndex(incStart, 2).setText('Amount');
    _tableHeader(s.getRangeByIndex(incStart, 1, incStart, 2));
    var ir = incStart;
    for (final e in incByCat) {
      ir++;
      s.getRangeByIndex(ir, 1).setText(e.key);
      final c = s.getRangeByIndex(ir, 2)..setNumber(r(e.value));
      c.numberFormat = _money;
      if ((ir - incStart).isOdd) {
        s.getRangeByIndex(ir, 1, ir, 2).cellStyle.backColor = _rowAlt;
      }
    }
    ir++;
    s.getRangeByIndex(ir, 1).setText('Total');
    s.getRangeByIndex(ir, 1).cellStyle.bold = true;
    final incTot = s.getRangeByIndex(ir, 2)
      ..setNumber(r(incByCat.fold<int>(0, (a, e) => a + e.value)));
    incTot.numberFormat = _money;
    incTot.cellStyle.bold = true;
    final incEnd = ir;

    s.getRangeByIndex(1, 1).columnWidth = 26;
    s.getRangeByIndex(1, 2).columnWidth = 16;
    s.getRangeByIndex(1, 3).columnWidth = 22;

    // Charts (to the right, cols D..L)
    final charts = ChartCollection(s);
    if (expByCat.isNotEmpty) {
      final pie = charts.add();
      pie.chartType = ExcelChartType.pie;
      pie.dataRange = s.getRangeByIndex(expStart + 1, 1, expEnd - 1, 2);
      pie.isSeriesInRows = false;
      pie.chartTitle = 'Expenses by category';
      pie.hasTitle = true;
      pie.hasLegend = true;
      pie.topRow = expStart;
      pie.bottomRow = expStart + 15;
      pie.leftColumn = 4;
      pie.rightColumn = 12;
      pie.series[0].dataLabels
        ..isValue = true
        ..textArea.size = 8;
    }
    if (incByCat.isNotEmpty) {
      final pie2 = charts.add();
      pie2.chartType = ExcelChartType.pie;
      pie2.dataRange = s.getRangeByIndex(incStart + 1, 1, incEnd - 1, 2);
      pie2.isSeriesInRows = false;
      pie2.chartTitle = 'Income by source';
      pie2.hasTitle = true;
      pie2.hasLegend = true;
      pie2.topRow = incStart;
      pie2.bottomRow = incStart + 15;
      pie2.leftColumn = 4;
      pie2.rightColumn = 12;
      pie2.series[0].dataLabels
        ..isValue = true
        ..textArea.size = 8;
    }
    s.charts = charts;
  }

  static void _buildEvents(
    Worksheet s,
    double Function(int) r,
    List<MapEntry<String, List<int>>> events,
  ) {
    s.showGridlines = false;
    s.getRangeByName('A1').setText('Profit & loss by event / stream');
    s.getRangeByName('A1').cellStyle
      ..bold = true
      ..fontSize = 14
      ..fontColor = _brown;
    // Columns ordered so Event|Income|Expense are contiguous for the chart.
    const hdrRow = 3;
    final headers = ['Event / stream', 'Income', 'Expenses', 'Net', 'Entries'];
    for (var c = 0; c < headers.length; c++) {
      s.getRangeByIndex(hdrRow, c + 1).setText(headers[c]);
    }
    _tableHeader(s.getRangeByIndex(hdrRow, 1, hdrRow, headers.length));
    var row = hdrRow;
    var ti = 0, te = 0, tn = 0, tc = 0;
    for (final e in events) {
      row++;
      final inc = e.value[0], exp = e.value[1], n = e.value[2];
      final net = inc - exp;
      ti += inc;
      te += exp;
      tn += net;
      tc += n;
      s.getRangeByIndex(row, 1).setText(e.key);
      (s.getRangeByIndex(row, 2)..setNumber(r(inc))).numberFormat = _money;
      (s.getRangeByIndex(row, 3)..setNumber(r(exp))).numberFormat = _money;
      final nv = s.getRangeByIndex(row, 4)..setNumber(r(net));
      nv.numberFormat = _money;
      nv.cellStyle
        ..bold = true
        ..fontColor = net >= 0 ? _green : _red;
      s.getRangeByIndex(row, 5).setNumber(n.toDouble());
      if ((row - hdrRow).isOdd) {
        s.getRangeByIndex(row, 1, row, 5).cellStyle.backColor = _rowAlt;
      }
    }
    final lastData = row;
    row++;
    s.getRangeByIndex(row, 1).setText('TOTAL');
    s.getRangeByIndex(row, 1).cellStyle.bold = true;
    (s.getRangeByIndex(row, 2)..setNumber(r(ti))).numberFormat = _money;
    (s.getRangeByIndex(row, 3)..setNumber(r(te))).numberFormat = _money;
    (s.getRangeByIndex(row, 4)..setNumber(r(tn))).numberFormat = _money;
    s.getRangeByIndex(row, 5).setNumber(tc.toDouble());
    s.getRangeByIndex(row, 1, row, 5).cellStyle.bold = true;

    s.getRangeByIndex(1, 1).columnWidth = 30;
    for (var c = 2; c <= 5; c++) {
      s.getRangeByIndex(1, c).columnWidth = 13;
    }

    if (events.isNotEmpty) {
      final charts = ChartCollection(s);
      final chart = charts.add();
      chart.chartType = ExcelChartType.column;
      chart.dataRange = s.getRangeByIndex(hdrRow, 1, lastData, 3);
      chart.isSeriesInRows = false;
      chart.chartTitle = 'Income vs expenses by event';
      chart.hasTitle = true;
      chart.hasLegend = true;
      chart.topRow = row + 2;
      chart.bottomRow = row + 20;
      chart.leftColumn = 1;
      chart.rightColumn = 8;
      s.charts = charts;
    }
  }

  static void _buildDaily(
    Worksheet s,
    double Function(int) r,
    List<String> days,
    Map<String, List<int>> dayMap,
  ) {
    s.showGridlines = false;
    s.getRangeByName('A1').setText('Day-by-day cash flow');
    s.getRangeByName('A1').cellStyle
      ..bold = true
      ..fontSize = 14
      ..fontColor = _brown;
    const hdrRow = 3;
    final headers = ['Date', 'Income', 'Expenses', 'Net'];
    for (var c = 0; c < headers.length; c++) {
      s.getRangeByIndex(hdrRow, c + 1).setText(headers[c]);
    }
    _tableHeader(s.getRangeByIndex(hdrRow, 1, hdrRow, headers.length));
    var row = hdrRow;
    for (final key in days) {
      row++;
      final inc = dayMap[key]![0], exp = dayMap[key]![1];
      s.getRangeByIndex(row, 1).setText(_dayFmt.format(DateTime.parse(key)));
      (s.getRangeByIndex(row, 2)..setNumber(r(inc))).numberFormat = _money;
      (s.getRangeByIndex(row, 3)..setNumber(r(exp))).numberFormat = _money;
      final nv = s.getRangeByIndex(row, 4)..setNumber(r(inc - exp));
      nv.numberFormat = _money;
      nv.cellStyle.fontColor = (inc - exp) >= 0 ? _green : _red;
      if ((row - hdrRow).isOdd) {
        s.getRangeByIndex(row, 1, row, 4).cellStyle.backColor = _rowAlt;
      }
    }
    final lastData = row;
    s.getRangeByIndex(1, 1).columnWidth = 12;
    for (var c = 2; c <= 4; c++) {
      s.getRangeByIndex(1, c).columnWidth = 13;
    }

    if (days.isNotEmpty) {
      final charts = ChartCollection(s);
      final chart = charts.add();
      chart.chartType = ExcelChartType.column;
      chart.dataRange = s.getRangeByIndex(hdrRow, 1, lastData, 3);
      chart.isSeriesInRows = false;
      chart.chartTitle = 'Income vs expenses by day';
      chart.hasTitle = true;
      chart.hasLegend = true;
      chart.topRow = 3;
      chart.bottomRow = 22;
      chart.leftColumn = 6;
      chart.rightColumn = 16;
      s.charts = charts;
    }
  }

  static void _buildLedger(
    Worksheet s,
    double Function(int) r,
    List<Txn> txns,
    Map<String, String> eventNames,
  ) {
    final headers = [
      'Date',
      'Type',
      'Category',
      'Amount',
      'Payment',
      'Cash',
      'UPI',
      'Party',
      'Event',
      'Notes',
      'Tag',
      'Source',
    ];
    for (var c = 0; c < headers.length; c++) {
      s.getRangeByIndex(1, c + 1).setText(headers[c]);
    }
    _tableHeader(s.getRangeByIndex(1, 1, 1, headers.length));
    final sorted = [...txns]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    var row = 1;
    for (final t in sorted) {
      row++;
      s.getRangeByIndex(row, 1).setText(_isoFmt.format(t.occurredAt));
      s.getRangeByIndex(row, 2)
          .setText(t.isIncome ? 'Income' : 'Expense');
      s.getRangeByIndex(row, 3).setText(t.category);
      (s.getRangeByIndex(row, 4)..setNumber(r(t.amountPaise))).numberFormat =
          _money2;
      s.getRangeByIndex(row, 5).setText(t.paymentMode);
      if (t.cashPaise != null && t.cashPaise! > 0) {
        (s.getRangeByIndex(row, 6)..setNumber(r(t.cashPaise!))).numberFormat =
            _money2;
      }
      if (t.upiPaise != null && t.upiPaise! > 0) {
        (s.getRangeByIndex(row, 7)..setNumber(r(t.upiPaise!))).numberFormat =
            _money2;
      }
      s.getRangeByIndex(row, 8).setText(t.partyName ?? '');
      s.getRangeByIndex(row, 9)
          .setText(t.eventId == null ? '' : (eventNames[t.eventId] ?? ''));
      s.getRangeByIndex(row, 10).setText(t.notes ?? '');
      s.getRangeByIndex(row, 11).setText(t.tag ?? '');
      s.getRangeByIndex(row, 12).setText(t.source);
      if (t.isIncome) {
        s.getRangeByIndex(row, 1, row, headers.length).cellStyle.backColor =
            _incomeFill;
      }
    }
    // Freeze the header row.
    s.getRangeByName('A2').freezePanes();
    final widths = [12, 9, 16, 12, 10, 10, 10, 18, 22, 34, 14, 10];
    for (var c = 0; c < widths.length; c++) {
      s.getRangeByIndex(1, c + 1).columnWidth = widths[c].toDouble();
    }
  }
}
