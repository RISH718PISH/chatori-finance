import '../../core/quantity.dart';
import '../../data/models/inventory.dart';
import '../../data/supabase/inventory_repository.dart';

/// How an invoice line resolved against the item catalogue.
enum StockMatchKind {
  /// An existing catalogue item — either an exact alias hit or a confident
  /// fuzzy-name match.
  matched,

  /// No match; a new item will be created from the cleaned description.
  newItem,

  /// The line cannot enter stock (no readable unit). The expense still
  /// books; stock is skipped.
  untracked,
}

/// The resolution for one invoice line. The review screen shows this, the
/// user can override it, and the save RPC acts on the final value.
class StockMatch {
  final StockMatchKind kind;

  /// Set when [kind] is matched.
  final String? itemId;
  final String? itemName;

  /// The name a new item would be created with (kind == newItem).
  final String? suggestedName;

  const StockMatch._(this.kind,
      {this.itemId, this.itemName, this.suggestedName});

  factory StockMatch.matched(String id, String name) =>
      StockMatch._(StockMatchKind.matched, itemId: id, itemName: name);
  factory StockMatch.newItem(String name) =>
      StockMatch._(StockMatchKind.newItem, suggestedName: name);
  const StockMatch.untracked() : this._(StockMatchKind.untracked);

  bool get tracks => kind != StockMatchKind.untracked;
}

/// Resolves invoice lines to catalogue items. Pure Dart — no Flutter, no
/// Supabase — so the whole thing is unit-testable against real invoice
/// strings, which is where the value is.
class ItemMatcher {
  ItemMatcher({
    required List<InventoryItem> items,
    required List<ItemAlias> aliases,
  })  : _items = items,
        _aliasByText = {
          for (final a in aliases) _norm(a.alias): a.itemId,
        },
        _itemById = {for (final i in items) i.id: i};

  final List<InventoryItem> _items;
  final Map<String, String> _aliasByText; // normalised alias -> itemId
  final Map<String, InventoryItem> _itemById;

  /// Resolve one line. [hasUnit] is whether the parsed quantity produced a
  /// storable unit — a line without one can only be untracked.
  StockMatch match(String description, {required bool hasUnit}) {
    if (!hasUnit) return const StockMatch.untracked();

    final normDesc = _norm(description);

    // 1. Exact alias hit — the common steady-state path.
    final aliasItemId = _aliasByText[normDesc];
    if (aliasItemId != null && _itemById.containsKey(aliasItemId)) {
      final it = _itemById[aliasItemId]!;
      return StockMatch.matched(it.id, it.name);
    }

    // 2. Fuzzy name against the catalogue.
    final cleaned = cleanName(description);
    final best = _bestFuzzy(cleaned);
    if (best != null) return StockMatch.matched(best.id, best.name);

    // 3. New item from the cleaned description.
    return StockMatch.newItem(cleaned);
  }

  /// The catalogue item whose name best matches [cleanedDescription], or
  /// null if none clears the bar. Accepts when the item's name tokens are a
  /// subset of the description's, or the Dice coefficient is >= 0.6.
  InventoryItem? _bestFuzzy(String cleanedDescription) {
    final descTokens = _tokens(cleanedDescription);
    if (descTokens.isEmpty) return null;

    InventoryItem? best;
    var bestScore = 0.0;
    for (final it in _items) {
      final itemTokens = _tokens(it.name);
      if (itemTokens.isEmpty) continue;

      final subset = itemTokens.every(descTokens.contains);
      final dice = _dice(descTokens, itemTokens);
      final score = subset ? 1.0 : dice;
      if (score > bestScore) {
        bestScore = score;
        best = it;
      }
    }
    return bestScore >= 0.6 ? best : null;
  }

  // ── Name cleaning ────────────────────────────────────────────

  /// Turns a vendor description into a human item name:
  ///   "Amul - Butter Salted, 500 gm"  -> "Butter Salted"
  ///   "Fomex - 180 ml Bagasse Bowl, (Pack of 250)" -> "Bagasse Bowl"
  /// Drops the brand prefix before " - ", strips trailing pack sizes and
  /// quantities, collapses punctuation, and title-cases the result.
  static String cleanName(String raw) {
    var s = raw.trim();

    // Drop a leading "Brand - " prefix (first segment before " - ").
    final dash = s.indexOf(' - ');
    if (dash > 0 && dash < s.length - 3) {
      s = s.substring(dash + 3);
    }

    // Everything from the first comma is usually size/pack detail.
    final comma = s.indexOf(',');
    if (comma > 0) s = s.substring(0, comma);

    // Strip parenthetical pack notes: "(Pack of 250)", "(50 each)".
    s = s.replaceAll(RegExp(r'\([^)]*\)'), ' ');

    // Strip standalone quantities+units: "500 gm", "1 Kg", "180 ml", "1 L".
    s = s.replaceAll(
        RegExp(
            r'\b\d+(\.\d+)?\s*(kg|kgs|g|gm|gms|ml|l|ltr|ltrs|pcs?|nos?|dozen|mm|cm|ply|gsm)\b',
            caseSensitive: false),
        ' ');

    // Leftover bare numbers and punctuation.
    s = s.replaceAll(RegExp(r'[^A-Za-z& ]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (s.isEmpty) {
      // Nothing survived cleaning (e.g. "1 L" only). Fall back to the raw
      // description so the item at least has a name.
      s = raw.trim();
    }
    return _titleCase(s);
  }

  static String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  // ── Similarity primitives ────────────────────────────────────

  static final _stop = {
    'the', 'and', 'of', 'a', 'with', 'for', 'in', 'fresh', 'premium',
  };

  static Set<String> _tokens(String s) => _norm(s)
      .split(' ')
      .where((t) => t.length > 1 && !_stop.contains(t))
      .toSet();

  /// Sørensen–Dice over token sets.
  static double _dice(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final overlap = a.where(b.contains).length;
    return 2 * overlap / (a.length + b.length);
  }

  static String _norm(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Whether a parsed invoice unit is storable as stock. Mirrors the server:
/// a null / unrecognised unit (e.g. a pack size) means the line can't post.
bool lineHasStorableUnit(String? unit, double? qty) =>
    qty != null && qty > 0 && Quantity.unitFromSymbol(unit) != null;
