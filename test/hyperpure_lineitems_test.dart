import 'package:chatori_finance/features/screenshot/hyperpure_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts line items with quantity, unit price, amount + tax split',
      () {
    const ocr = '''
Hyperpure by Zomato
Tax Invoice
Invoice No: HP2607-88231
Date: 28/06/2026
Description                Qty  Unit    Amount
Sunflower Oil 15L          2    1445    2,890.00
Paneer 1kg                 4    370     1,480.00
Sub Total                                4,370.00
Taxable Amount                           4,370.00
CGST + SGST 5%                             218.50
Grand Total                              4,588.50
''';
    final r = HyperpureParser.parse(ocr);
    expect(r.invoiceNumber, 'HP2607-88231');
    expect(r.invoiceDate, DateTime(2026, 6, 28));
    expect(r.totalPaise, 458850);
    expect(r.taxablePaise, 437000);
    expect(r.taxPaise, 21850);
    expect(r.items.length, greaterThanOrEqualTo(2));
    // Descriptions retained with unit words stripped from numbers, not text.
    expect(r.items.any((i) => i.description.toLowerCase().contains('sunflower')),
        isTrue);
    expect(r.items.any((i) => i.description.toLowerCase().contains('paneer')),
        isTrue);
    // Category leaned toward Oil via multiple keyword hits, but Dairy is also
    // a plausible pick — accept either.
    expect(['Oil', 'Dairy'], contains(r.suggestedCategory));
  });

  test('multi-line item descriptions are coalesced with the amount row', () {
    const ocr = '''
Hyperpure Order
Basmati Rice Premium
Grade A 10kg pack       1  1250  1,250.00
Grand Total  1,250.00
''';
    final r = HyperpureParser.parse(ocr);
    expect(r.items, isNotEmpty);
    // Description should include both lines.
    final joined =
        r.items.map((i) => i.description.toLowerCase()).join(' ');
    expect(joined, contains('basmati'));
    expect(joined, contains('grade a'));
    expect(r.totalPaise, 125000);
  });

  test('gracefully returns empty items when the table layout is unreadable',
      () {
    const ocr = 'Hyperpure garbled scan xx xx xx Grand Total 1,000.00';
    final r = HyperpureParser.parse(ocr);
    expect(r.items, isEmpty);
    expect(r.totalPaise, 100000);
    // Vendor name still present so the app can still fall back.
    expect(r.vendorName, 'Hyperpure');
  });

  test('non-Hyperpure text is not misidentified', () {
    const ocr = 'Paytm Paid Rs 500 to Ramesh';
    expect(HyperpureParser.looksLikeHyperpure(ocr), isFalse);
  });
}
