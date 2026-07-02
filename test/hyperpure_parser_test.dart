import 'package:chatori_finance/features/screenshot/hyperpure_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('full invoice with grand total, invoice number and date', () {
    const ocr = '''
Hyperpure by Zomato
Tax Invoice
Invoice No: HP2607-88231
Date: 28/06/2026
Sunflower Oil 15L          2  ₹2,890.00
Paneer 1kg                 4  ₹1,480.00
Sub Total                     ₹4,370.00
GST 5%                       ₹218.50
Grand Total                  ₹4,588.50
''';
    expect(HyperpureParser.looksLikeHyperpure(ocr), isTrue);
    final r = HyperpureParser.parse(ocr);
    expect(r.invoiceNumber, 'HP2607-88231');
    expect(r.invoiceDate, DateTime(2026, 6, 28));
    expect(r.totalPaise, 458850);
    // "oil" + "sunflower" beat "paneer" alone.
    expect(r.suggestedCategory, 'Oil');
  });

  test('comma amounts and "Amount Payable" label', () {
    const ocr = '''
HYPERPURE
Invoice # ZH-99120
12 Jun 2026
Fresh Onion 25kg    ₹1,050.00
Tomato 20kg         ₹980.00
Potato 30kg         ₹760.00
Amount Payable      ₹12,480.50
''';
    final r = HyperpureParser.parse(ocr);
    expect(r.invoiceNumber, 'ZH-99120');
    expect(r.invoiceDate, DateTime(2026, 6, 12));
    expect(r.totalPaise, 1248050);
    expect(r.suggestedCategory, 'Veggies');
  });

  test('only a bare total is findable — falls back to largest amount', () {
    const ocr = '''
hyperpure order summary
milk butter cream
910.00
1,240.00
total 3,150.00
''';
    final r = HyperpureParser.parse(ocr);
    expect(r.invoiceNumber, isNull);
    expect(r.totalPaise, 315000);
    expect(r.suggestedCategory, 'Dairy');
  });

  test('a Paytm screenshot is NOT detected as Hyperpure', () {
    const ocr = '''
Paytm
Paid Successfully
₹1,240
Paid to Ramesh Vegetables
UPI Ref No: 415223344556
12 Jun 2026, 10:42 AM
''';
    expect(HyperpureParser.looksLikeHyperpure(ocr), isFalse);
  });

  test('parser never throws on garbage input', () {
    final r = HyperpureParser.parse('%%%@@ \n\n 🍽️');
    expect(r.totalPaise, isNull);
    expect(r.invoiceNumber, isNull);
    expect(r.invoiceDate, isNull);
    expect(r.suggestedCategory, 'Groceries');
  });
}
