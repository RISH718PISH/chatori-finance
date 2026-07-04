import 'package:chatori_finance/features/screenshot/hyperpure_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a real Hyperpure tax invoice (12 items + totals)', () {
    // Modelled on a real Zomato Hyperpure PVT LTD Noida tax invoice. Column
    // order matches the on-screen table:
    //   S.No  Description  HSN  Qty  Unit Price  UoM  Taxable  Tax Rate  Tax  Total
    const ocr = '''
hyperpure
BY ZOMATO
TAX INVOICE                                Invoice Count: 2
Invoice Number            Order No.                    Invoice Date        Reference PO
ZHPUP27-00095672          ZHPUP27-OR-0027790830        02 Jul 2026         -
Bill From / Shipped From:  ZOMATO HYPERPURE PVT LTD - NOIDA
Address :                  Plot No: 24, 25A, Udyog kendra, Ecotech - III, Greater Noida, UP - 201306
GSTIN :                    09AAACZ8867B1ZY
FSSAI :                    12723055000583
Bill To / Ship To :        ANKITA SHARMA
Outlet:                    Chatori Kitchen For Indian
Address :                  Ha - 76, RWA Sector-144, Noida-201306, Noida
Pincode :                  201306
Place of Supply :          Uttar Pradesh (09)
GSTIN :                    09DYOPS2756E1ZU
S No.  Description of Goods and Services       HSN        Qty  Unit Price  UoM     Taxable Amount  Tax Rate (CGST+SGST+IGST)%  Tax Amount (CGST+SGST+IGST)  Total
1      Ultimate - Penne Pasta, 5 Kg            19021900   1    342         Count   342             2.5+2.5+0                   8.55+8.55+0                  359.10
2      Cling Film Roll, 1.4 Kg (Width 12 Inch) 39239090   2    257         Count   514             9+9+0                       46.26+46.26+0                606.52
3      John - Cheese (Diced Mozzarella and
       Cheddar), 1 Kg                          04062000   1    478         Pack    478             2.5+2.5+0                   11.95+11.95+0                501.90
4      Nutralite - Professional Fat Spread, 500 gm  04052000  4    89          Pack    356             2.5+2.5+0                   8.9+8.9+0                    373.80
5      Fludor - Cashew BB (Baby Bits), 1 Kg    08011100   1    624         Pack    624             2.5+2.5+0                   15.6+15.6+0                  655.20
6      Pansari - Kacchi Ghani Mustard Oil, 1 L Bottle  15149120  1    181         Count   181             2.5+2.5+0                   4.53+4.53+0                  190.05
7      Eastmade - Cardamom (Elaichi Green), 100 gm  09083120  1    319         Count   319             2.5+2.5+0                   7.98+7.98+0                  334.95
8      Eastmade - Sesame White (Till), 1 Kg    12074090   1    180         Count   180             2.5+2.5+0                   4.5+4.5+0                    189.00
9      ES - Magaz Tumba, 1 Kg                  12077090   1    476         Count   476             2.5+2.5+0                   11.9+11.9+0                  499.80
10     MDH - Deggi Mirch, 500 gm               09042211   1    490         Count   490             2.5+2.5+0                   12.25+12.25+0                514.50
11     Sugar, 10 Kg                            17011490   1    542         Count   542             2.5+2.5+0                   13.55+13.55+0                569.10
12     HOMEFOIL - Aluminium Foil, 75 Meters (12 Micron)  76071991  1    425         Pack    425             9+9+0                       38.25+38.25+0                501.50
Other Charges
1      CONVENIENCE_FEE                         998599     1    100.75      Count   100.75          9+9+0                       9.07+9.07+0                  118.89
Total                                                                                            5027.75                                                     386.56                       5414.31
''';

    expect(HyperpureParser.looksLikeHyperpure(ocr), isTrue);
    final r = HyperpureParser.parse(ocr);

    // Invoice header
    expect(r.invoiceNumber, 'ZHPUP27-00095672');
    expect(r.invoiceDate, DateTime(2026, 7, 2));
    expect(r.vendorName, 'Hyperpure');

    // Totals summary row (5027.75, 386.56, 5414.31)
    expect(r.taxablePaise, 502775);
    expect(r.taxPaise, 38656);
    expect(r.totalPaise, 541431);

    // Line items — should be ~12–13, not 28. Never zero, never 3× that.
    expect(r.items.length, greaterThanOrEqualTo(10));
    expect(r.items.length, lessThanOrEqualTo(15));

    // Should NEVER capture PIN codes or order-number tails as amounts.
    // 2,01,306 (from PIN 201306) or 27,79,08,30 (from order 0027790830)
    // must NOT show up as an item amount.
    for (final it in r.items) {
      expect(it.amountPaise, isNot(equals(20130600)),
          reason: 'PIN 201306 leaked into item amount: ${it.description}');
      expect(it.amountPaise, isNot(equals(27790830 * 100)),
          reason: 'Order-number tail leaked into item amount: ${it.description}');
    }

    // Address/metadata lines should NOT appear as items.
    for (final it in r.items) {
      final d = it.description.toLowerCase();
      expect(d, isNot(contains('zomato hyperpure')));
      expect(d, isNot(contains('ankita sharma')));
      expect(d, isNot(contains('udyog kendra')));
      expect(d, isNot(contains('greater noida')));
      expect(d, isNot(contains('gstin')));
    }

    // A few known items should be recognisable.
    final joined = r.items.map((i) => i.description.toLowerCase()).join(' | ');
    expect(joined, contains('penne pasta'));
    expect(joined, contains('sugar'));

    // Category inference from mixed COGS items should land on a food bucket.
    expect(r.suggestedCategory, isIn(<String>{
      'Groceries', 'Dairy', 'Spices & Masalas', 'Grains & Flour', 'Oil',
      'Packaging'
    }));
  });

  test('multi-line item description gets coalesced', () {
    const ocr = '''
Description of Goods and Services  HSN       Qty  Unit Price  UoM    Taxable  Tax Rate  Tax  Total
1  John - Cheese (Diced Mozzarella and
   Cheddar), 1 Kg                  04062000  1    478         Pack   478      2.5+2.5+0  23.9  501.90
Total  478.00  23.90  501.90
''';
    final r = HyperpureParser.parse(ocr);
    expect(r.items.length, 1);
    final desc = r.items.first.description.toLowerCase();
    expect(desc, contains('mozzarella'));
    expect(desc, contains('cheddar'));
    expect(r.items.first.amountPaise, 50190);
    expect(r.totalPaise, 50190);
  });

  test('gracefully returns empty items when the table layout is unreadable',
      () {
    const ocr = 'Hyperpure garbled scan xx xx xx Grand Total 1,000.00';
    final r = HyperpureParser.parse(ocr);
    expect(r.items, isEmpty);
    expect(r.totalPaise, 100000);
    expect(r.vendorName, 'Hyperpure');
  });

  test('non-Hyperpure text is not misidentified', () {
    const ocr = 'Paytm Paid Rs 500 to Ramesh';
    expect(HyperpureParser.looksLikeHyperpure(ocr), isFalse);
  });

  test(
      'strict amount rule: PIN codes and HSN codes are never captured '
      'as amounts', () {
    const ocr = '''
hyperpure
Ship To: Address, Sector-144, Noida-201306
GSTIN 09DYOPS2756E1ZU
Description of Goods and Services  HSN       Qty  Unit Price  UoM  Taxable  Tax Rate  Tax  Total
Total  0.00  0.00  0.00
''';
    final r = HyperpureParser.parse(ocr);
    // No items, no bogus amount extracted from the PIN or GSTIN.
    expect(r.items, isEmpty);
    // Total is null (zero row is treated as "no total" — safer than 0).
    expect(r.totalPaise, isNull);
  });
}
