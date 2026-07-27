import 'package:chatori_finance/core/quantity.dart';
import 'package:chatori_finance/data/models/inventory.dart';
import 'package:chatori_finance/data/supabase/inventory_repository.dart';
import 'package:chatori_finance/features/inventory/item_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

InventoryItem _item(String id, String name,
        [QtyDimension d = QtyDimension.mass, String u = 'kg']) =>
    InventoryItem(id: id, name: name, dimension: d, displayUnit: u);

ItemAlias _alias(String itemId, String alias) =>
    ItemAlias(id: 'a-$alias', itemId: itemId, alias: alias);

void main() {
  group('cleanName — real Hyperpure descriptions', () {
    final cases = {
      'Amul - Butter Salted, 500 gm': 'Butter Salted',
      'Amul - Processed Cheese Block, 1 Kg': 'Processed Cheese Block',
      'ES - Cumin Powder (Jeera), 1 Kg': 'Cumin Powder',
      'MDH - Deggi Mirch, 500 gm': 'Deggi Mirch',
      'Fomex - 180 ml Bagasse Bowl, (Pack of 250)': 'Bagasse Bowl',
      'Zone - Watermelon Bar Syrup, 1 L': 'Watermelon Bar Syrup',
      'Veeba - Sweet Chilli Hot Sauce, 1 Kg': 'Sweet Chilli Hot Sauce',
      'Wooden Spoon, 140 mm (Pack of 100)': 'Wooden Spoon',
    };
    cases.forEach((input, expected) {
      test('"$input" -> "$expected"', () {
        expect(ItemMatcher.cleanName(input), expected);
      });
    });

    test('never returns empty even for a size-only description', () {
      expect(ItemMatcher.cleanName('1 L').isNotEmpty, isTrue);
    });
  });

  group('matching', () {
    test('untracked when the line has no storable unit', () {
      final m = ItemMatcher(items: const [], aliases: const []);
      final r = m.match('Paper Napkin 30x30', hasUnit: false);
      expect(r.kind, StockMatchKind.untracked);
      expect(r.tracks, isFalse);
    });

    test('exact alias hit wins immediately', () {
      final items = [_item('i1', 'Butter'), _item('i2', 'Cheese')];
      final aliases = [_alias('i1', 'Amul - Butter Salted, 500 gm')];
      final m = ItemMatcher(items: items, aliases: aliases);

      final r = m.match('Amul - Butter Salted, 500 gm', hasUnit: true);
      expect(r.kind, StockMatchKind.matched);
      expect(r.itemId, 'i1');
    });

    test('alias match ignores case and surrounding whitespace', () {
      final m = ItemMatcher(
        items: [_item('i1', 'Butter')],
        aliases: [_alias('i1', 'Amul - Butter Salted, 500 gm')],
      );
      final r = m.match('  amul - butter salted, 500 GM ', hasUnit: true);
      expect(r.itemId, 'i1');
    });

    test('fuzzy matches a new description to an existing item', () {
      // "Onion" already in the catalogue; a fresh bill lists it verbosely.
      final m = ItemMatcher(
        items: [_item('i1', 'Onion', QtyDimension.mass, 'kg')],
        aliases: const [],
      );
      final r = m.match('Fresh Red Onion, 10 kg', hasUnit: true);
      expect(r.kind, StockMatchKind.matched);
      expect(r.itemId, 'i1');
    });

    test('creates a new item when nothing matches', () {
      final m = ItemMatcher(
        items: [_item('i1', 'Onion')],
        aliases: const [],
      );
      final r = m.match('Veeba - Sweet Chilli Hot Sauce, 1 Kg', hasUnit: true);
      expect(r.kind, StockMatchKind.newItem);
      expect(r.suggestedName, 'Sweet Chilli Hot Sauce');
    });

    test('does not force a weak fuzzy match', () {
      // "Butter" must not swallow "Bagasse Bowl" just for sharing nothing.
      final m = ItemMatcher(
        items: [_item('i1', 'Butter')],
        aliases: const [],
      );
      final r = m.match('Fomex - 180 ml Bagasse Bowl, (Pack of 250)',
          hasUnit: true);
      expect(r.kind, StockMatchKind.newItem);
    });
  });

  group('lineHasStorableUnit', () {
    test('true for a real unit with a positive quantity', () {
      expect(lineHasStorableUnit('kg', 2), isTrue);
      expect(lineHasStorableUnit('Count', 5), isTrue);
    });
    test('false for pack sizes, missing units, or zero qty', () {
      expect(lineHasStorableUnit('packet', 3), isFalse);
      expect(lineHasStorableUnit(null, 3), isFalse);
      expect(lineHasStorableUnit('kg', null), isFalse);
      expect(lineHasStorableUnit('kg', 0), isFalse);
    });
  });
}
