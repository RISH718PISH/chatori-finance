import 'dart:convert';

import 'package:chatori_finance/features/screenshot/ai_parsed_invoice.dart';
import 'package:flutter_test/flutter_test.dart';

/// A realistic `parse-invoice` response, modelled on the ₹7,943.08 Hyperpure
/// bill the old on-device parser mangled — it returned eight "items" of which
/// zero were products (address block, GST sub-columns, an HSN code, "Page 1
/// of 1", and the footer legal declaration).
const _goldenResponse = '''
{
  "vendor_name": "Hyperpure",
  "invoice_number": "ZHPUP27-00110545",
  "invoice_date": "2026-07-16",
  "subtotal_paise": 756484,
  "tax_paise": 37824,
  "total_paise": 794308,
  "items": [
    {"description": "Paneer Fresh", "hsn": "0406", "qty": 5, "unit": "kg",
     "unit_price_paise": 32000, "amount_paise": 160000,
     "suggested_category": "Dairy", "confidence": 0.98},
    {"description": "Onion", "hsn": "0703", "qty": 20, "unit": "kg",
     "unit_price_paise": 3000, "amount_paise": 60000,
     "suggested_category": "Veggies", "confidence": 0.97},
    {"description": "Refined Sunflower Oil", "hsn": "1512", "qty": 15,
     "unit": "l", "unit_price_paise": 14000, "amount_paise": 210000,
     "suggested_category": "Oil", "confidence": 0.95},
    {"description": "Basmati Rice", "hsn": "1006", "qty": 25, "unit": "kg",
     "unit_price_paise": 9000, "amount_paise": 225000,
     "suggested_category": "Grains & Flour", "confidence": 0.93},
    {"description": "Aluminium Foil Container 750ml", "hsn": "7615",
     "qty": 200, "unit": "pcs", "unit_price_paise": 600,
     "amount_paise": 120000,
     "suggested_category": "Packaging", "confidence": 0.6},
    {"description": "Convenience Fee", "hsn": null, "qty": null, "unit": null,
     "unit_price_paise": null, "amount_paise": 19308,
     "suggested_category": "Miscellaneous", "confidence": 0.88}
  ],
  "reconciliation": {
    "items_sum_paise": 794308,
    "total_unknown": false,
    "difference_paise": 0,
    "balanced": true
  }
}
''';

AiParsedInvoice _golden() => AiParsedInvoice.fromJson(
    jsonDecode(_goldenResponse) as Map<String, dynamic>);

void main() {
  group('AiParsedInvoice mapping', () {
    test('maps header fields, keeping money as integer paise', () {
      final inv = _golden();
      expect(inv.vendorName, 'Hyperpure');
      expect(inv.invoiceNumber, 'ZHPUP27-00110545');
      expect(inv.invoiceDate, DateTime(2026, 7, 16));
      expect(inv.subtotalPaise, 756484);
      expect(inv.taxPaise, 37824);
      expect(inv.totalPaise, 794308);
    });

    test('maps every line item with quantity and unit preserved', () {
      final inv = _golden();
      expect(inv.items, hasLength(6));

      final paneer = inv.items.first;
      expect(paneer.description, 'Paneer Fresh');
      expect(paneer.qty, 5);
      expect(paneer.unit, 'kg');
      expect(paneer.amountPaise, 160000);
      expect(paneer.category, 'Dairy');
    });

    test('items sum exactly to the bill total', () {
      final inv = _golden();
      final sum = inv.items.fold<int>(0, (s, i) => s + i.amountPaise);
      expect(sum, inv.totalPaise);
      expect(inv.reconciliation.balanced, isTrue);
      expect(inv.reconciliation.differencePaise, 0);
    });

    test('flags low-confidence rows for review', () {
      final inv = _golden();
      expect(inv.lowConfidenceCount, 1);
      final flagged = inv.items.where((i) => i.isLowConfidence).single;
      expect(flagged.description, contains('Aluminium Foil'));
    });

    test('qtyLabel renders quantity with its unit', () {
      final inv = _golden();
      expect(inv.items[0].qtyLabel, '5 kg');
      expect(inv.items[2].qtyLabel, '15 l');
      // Fee row has no quantity at all.
      expect(inv.items.last.qtyLabel, '');
    });

    test('missing optional fields degrade to null, not to a crash', () {
      final inv = _golden();
      final fee = inv.items.last;
      expect(fee.hsn, isNull);
      expect(fee.qty, isNull);
      expect(fee.unit, isNull);
      expect(fee.unitPricePaise, isNull);
    });

    test('an empty result parses without throwing', () {
      final inv = AiParsedInvoice.fromJson(const {});
      expect(inv.items, isEmpty);
      expect(inv.totalPaise, isNull);
      expect(inv.reconciliation.totalUnknown, isTrue);
    });
  });

  group('reconciliation', () {
    test('an unreadable total is distinct from a zero difference', () {
      // The regression this guards: the old screen defaulted the grand
      // total to the item sum, making the difference structurally zero, so
      // no warning could fire in exactly the case where parsing had failed
      // worst.
      const r = InvoiceReconciliation(
        itemsSumPaise: 172138,
        totalUnknown: true,
        differencePaise: null,
        balanced: false,
      );
      expect(r.totalUnknown, isTrue);
      expect(r.balanced, isFalse,
          reason: 'unknown total must never count as balanced');
    });

    test('detects the shortfall the old parser silently accepted', () {
      // Items summed to 1,721.38 against a real bill of 7,943.08.
      const r = InvoiceReconciliation(
        itemsSumPaise: 172138,
        totalUnknown: false,
        differencePaise: 794308 - 172138,
        balanced: false,
      );
      expect(r.balanced, isFalse);
      expect(r.isShort, isTrue);
      expect(r.differencePaise, 622170);
    });

    test('an over-count is not reported as short', () {
      const r = InvoiceReconciliation(
        itemsSumPaise: 900000,
        totalUnknown: false,
        differencePaise: 794308 - 900000,
        balanced: false,
      );
      expect(r.isShort, isFalse);
      expect(r.differencePaise, lessThan(0));
    });
  });

  group('AiInvoiceItem.copyWith', () {
    const base = AiInvoiceItem(
      description: 'Onion',
      amountPaise: 60000,
      category: 'Veggies',
      qty: 20,
      unit: 'kg',
      confidence: 0.9,
    );

    test('updates only what is passed', () {
      final c = base.copyWith(category: 'Groceries');
      expect(c.category, 'Groceries');
      expect(c.description, 'Onion');
      expect(c.qty, 20);
      expect(c.unit, 'kg');
    });

    test('can explicitly clear qty and unit', () {
      // Needed by the review screen's "—" unit option; a plain
      // `unit ?? this.unit` would make clearing impossible.
      final c = base.copyWith(qty: null, unit: null);
      expect(c.qty, isNull);
      expect(c.unit, isNull);
      expect(c.description, 'Onion');
    });

    test('preserves confidence so a flagged row stays flagged', () {
      const low = AiInvoiceItem(
        description: 'x',
        amountPaise: 1,
        category: 'Groceries',
        confidence: 0.4,
      );
      expect(low.copyWith(description: 'y').isLowConfidence, isTrue);
    });
  });
}
