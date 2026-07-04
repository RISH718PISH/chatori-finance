/// Structured result of parsing OCR text from a Hyperpure (Zomato B2B) invoice.
/// Every field is nullable / list-may-be-empty — the parser never throws and
/// always degrades gracefully so the UI can still show whatever it found.
class ParsedHyperpure {
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final String vendorName;
  final List<HyperpureLineItem> items;
  final int? taxablePaise;
  final int? taxPaise;
  final int? totalPaise;
  final String suggestedCategory;
  final String rawText;

  const ParsedHyperpure({
    this.invoiceNumber,
    this.invoiceDate,
    this.vendorName = 'Hyperpure',
    this.items = const [],
    this.taxablePaise,
    this.taxPaise,
    this.totalPaise,
    this.suggestedCategory = 'Groceries',
    required this.rawText,
  });
}

class HyperpureLineItem {
  final String description;
  final double? quantity;
  final int? unitPricePaise;
  final int amountPaise;
  const HyperpureLineItem({
    required this.description,
    required this.amountPaise,
    this.quantity,
    this.unitPricePaise,
  });
}

/// On-device, rules-based parser for Hyperpure Tax Invoices. No external calls.
///
/// Hyperpure invoices are structured tables with columns:
///   S.No  Description  HSN  Qty  Unit Price  UoM  Taxable  Tax Rate  Tax  Total
/// The header block above the table has:
///   Invoice Number: ZHPUP27-XXXXXXXX
///   Invoice Date:   02 Jul 2026
///   Order No:       ZHPUP27-OR-XXXXXXXXXX
///   Bill From / To with addresses, GSTIN, pincode etc.
/// The footer has a "Total" summary row: `Total  5027.75  386.56  5414.31`
///   (taxable)  (tax)  (grand total)
///
/// The parser is deliberately strict: it demands **currency-formatted amounts**
/// (either with a ₹ symbol or two decimal places) so that PIN codes, HSN codes,
/// GSTINs, and order-number suffixes are never mistaken for amounts. Line
/// items are only extracted between the column header and the totals row.
class HyperpureParser {
  HyperpureParser._();

  static bool looksLikeHyperpure(String text) =>
      text.toLowerCase().contains('hyperpure');

  static ParsedHyperpure parse(String text) {
    final totals = _totalsRow(text);
    final items = _lineItems(text);
    // Labelled fallbacks only if the totals row wasn't found.
    final taxable = totals?.taxable ??
        _amountLabeled(text, const [
          'taxable amount',
          'taxable value',
          'sub total',
          'subtotal',
        ]);
    final tax = totals?.tax ??
        _amountLabeled(text, const [
          'total tax',
          'tax amount',
          'cgst + sgst',
          'gst amount',
        ]);
    final total = totals?.total ?? _totalPaise(text);
    return ParsedHyperpure(
      invoiceNumber: _invoiceNumber(text),
      invoiceDate: _invoiceDate(text),
      vendorName: 'Hyperpure',
      items: items,
      taxablePaise: taxable,
      taxPaise: tax,
      totalPaise: total,
      suggestedCategory: _suggestedCategory(text, items),
      rawText: text,
    );
  }

  // ── Invoice number ─────────────────────────────────────────────────
  static String? _invoiceNumber(String text) {
    // Hyperpure-specific: "ZHPUP<digits>-<digits>" is the standard prefix.
    // Match this first so we never confuse it with an Order No.
    final zhpup = RegExp(r'\bZHPUP\d{1,3}-\d{4,10}\b').firstMatch(text);
    if (zhpup != null) {
      final v = zhpup.group(0)!;
      // Exclude the Order No form "ZHPUP27-OR-0027790830".
      if (!v.contains('-OR-')) return v;
    }
    // Label-based: check every line for an "invoice ..." token, then read
    // the value from the same line or (Hyperpure layout) the line below.
    final lines = text.split(RegExp(r'[\r\n]+'));
    final invoiceLabel = RegExp(r'invoice\b', caseSensitive: false);
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      if (l.contains('order no') || l.contains('order number')) continue;
      if (!invoiceLabel.hasMatch(l)) continue;
      // Value on the same line: after "invoice #/no/number" up to whitespace.
      final same = RegExp(
        r'invoice\s*(?:no\.?|number|#)\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-\/]{3,24})',
        caseSensitive: false,
      ).firstMatch(lines[i]);
      final candidate = same?.group(1)?.trim();
      if (candidate != null &&
          RegExp(r'\d').hasMatch(candidate) &&
          candidate.toLowerCase() != 'date') {
        return candidate;
      }
      // Otherwise value on the next line (Hyperpure header block layout).
      for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
        final next = lines[j].trim();
        final onlyCode =
            RegExp(r'^[A-Z0-9][A-Z0-9\-\/]{3,30}$').firstMatch(next);
        if (onlyCode != null && RegExp(r'\d').hasMatch(next)) {
          return next;
        }
      }
    }
    return null;
  }

  // ── Invoice date ───────────────────────────────────────────────────
  static DateTime? _invoiceDate(String text) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    // Prefer a date near an "Invoice Date" label (label may be on prior line).
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      if (!l.contains('invoice date')) continue;
      // Check this line and the next two.
      for (var j = i; j < i + 3 && j < lines.length; j++) {
        final d = _parseDate(lines[j]);
        if (d != null) return d;
      }
    }
    // Fallback: first date pattern in the text.
    return _parseDate(text);
  }

  static DateTime? _parseDate(String s) {
    // dd/MM/yyyy or dd-MM-yyyy
    final numeric =
        RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})\b').firstMatch(s);
    if (numeric != null) {
      final d = int.tryParse(numeric.group(1)!);
      final m = int.tryParse(numeric.group(2)!);
      final y = int.tryParse(numeric.group(3)!);
      if (d != null && m != null && y != null && m >= 1 && m <= 12) {
        try {
          return DateTime(y, m, d);
        } catch (_) {/* fall through */}
      }
    }
    // dd MMM yyyy — matches "02 Jul 2026", "28 June 2026", etc.
    final worded =
        RegExp(r'\b(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})\b').firstMatch(s);
    if (worded != null) {
      const months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      final d = int.tryParse(worded.group(1)!);
      final m = months[worded.group(2)!.toLowerCase().substring(0, 3)];
      final y = int.tryParse(worded.group(3)!);
      if (d != null && m != null && y != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {/* fall through */}
      }
    }
    return null;
  }

  // ── Amount recognition (strict) ─────────────────────────────────────
  /// Matches an amount that is DEFINITELY a currency amount: has 2 decimal
  /// places OR is prefixed with a currency symbol. This rules out PIN codes
  /// (`201306`), HSN codes (`19021900`), and order-number tails.
  static final _decimalAmount = RegExp(r'\d[\d,]*\.\d{2}');
  static final _currencyPrefixed = RegExp(
    r'(?:₹|rs\.?|inr)\s*(\d[\d,]*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static int? _paiseFromToken(String token) {
    final v = double.tryParse(token.replaceAll(',', ''));
    if (v == null || v <= 0) return null;
    return (v * 100).round();
  }

  /// Returns the largest strict currency amount on a line, or null.
  static int? _bestAmountOnLine(String line) {
    int? best;
    for (final m in _decimalAmount.allMatches(line)) {
      final p = _paiseFromToken(m.group(0)!);
      if (p != null && (best == null || p > best)) best = p;
    }
    for (final m in _currencyPrefixed.allMatches(line)) {
      final p = _paiseFromToken(m.group(1)!);
      if (p != null && (best == null || p > best)) best = p;
    }
    return best;
  }

  static int? _totalPaise(String text) {
    // Prefer a labelled "Grand Total"/"Total Amount"/"Amount Payable" row.
    final labelled = _amountLabeled(text, const [
      'grand total',
      'amount payable',
      'net payable',
      'invoice total',
      'total payable',
      'payable amount',
      'total amount',
    ]);
    if (labelled != null) return labelled;
    // Otherwise the largest strict amount anywhere.
    int? best;
    for (final line in text.split(RegExp(r'[\r\n]+'))) {
      final p = _bestAmountOnLine(line);
      if (p != null && (best == null || p > best)) best = p;
    }
    return best;
  }

  /// Finds a strict amount on a line matching any of [labels]. If the current
  /// line has no strict amount (OCR sometimes wraps to the next line), falls
  /// through to the next line. This never returns non-decimal digit runs.
  static int? _amountLabeled(String text, List<String> labels) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (!labels.any(lower.contains)) continue;
      final onLine = _bestAmountOnLine(lines[i]);
      if (onLine != null) return onLine;
      if (i + 1 < lines.length) {
        final onNext = _bestAmountOnLine(lines[i + 1]);
        if (onNext != null) return onNext;
      }
    }
    return null;
  }

  /// Detects the invoice's "Total" summary row: a single line containing
  /// exactly 3 decimal amounts (taxable, tax, total). This is the most
  /// reliable place to read the tax breakdown from a Hyperpure invoice.
  static ({int? taxable, int? tax, int? total})? _totalsRow(String text) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    // Search from the bottom up — the totals row is near the end.
    for (var i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final l = line.toLowerCase();
      if (!l.contains('total')) continue;
      // (No extra "Grand Total" check here — we simply require the row to
      //  have exactly 3 decimal amounts; item rows never do.)
      final amounts = _decimalAmount.allMatches(line).toList();
      if (amounts.length != 3) continue;
      final vals = amounts.map((m) => _paiseFromToken(m.group(0)!)).toList();
      // Sanity: taxable ≤ total, tax ≤ total. Rejects false matches.
      if (vals[0] == null || vals[1] == null || vals[2] == null) continue;
      if (vals[0]! > vals[2]! || vals[1]! > vals[2]!) continue;
      return (taxable: vals[0], tax: vals[1], total: vals[2]);
    }
    return null;
  }

  // ── Line-item extraction ───────────────────────────────────────────
  /// Extracts item rows from the invoice body. Only accepts rows that end in
  /// a strict currency-formatted amount AND look like part of the items table
  /// (not header/address/totals metadata).
  ///
  /// If a clean "Description ... Amount" header row is found in the OCR, we
  /// anchor the item section right after it (this rejects the invoice's own
  /// header block). If no such header row is found (photo OCR often skips it
  /// or breaks it up), we fall through and walk the WHOLE document — the
  /// per-line metadata blacklist plus the strict amount rule are enough to
  /// reject bill-from / bill-to / address / GSTIN blocks.
  static List<HyperpureLineItem> _lineItems(String text) {
    final lines = text.split(RegExp(r'[\r\n]+'));

    // Find the item section's start via the column header if present.
    var startIdx = 0;
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      final hasDesc = l.contains('description');
      final hasCol = l.contains('hsn') ||
          l.contains('unit price') ||
          l.contains('taxable') ||
          (l.contains('qty') && l.contains('amount'));
      if (hasDesc && hasCol) {
        startIdx = i + 1;
        break;
      }
    }

    // End: at the first line that looks like the totals summary row (3
    // decimal amounts + "total") or a totals-block phrase anywhere on the
    // line. We match by `contains` (not `startsWith`) because photo OCR
    // sometimes prefixes/suffixes stray characters onto totals lines.
    var endIdx = lines.length;
    for (var i = startIdx; i < lines.length; i++) {
      final l = lines[i].toLowerCase().trim();
      if (l == 'other charges') {
        endIdx = i;
        break;
      }
      if (l.contains('grand total') ||
          l.contains('total payable') ||
          l.contains('amount payable') ||
          l.contains('net payable') ||
          l.contains('total amount')) {
        endIdx = i;
        break;
      }
      // The main "Total ... 5027.75 386.56 5414.31" summary row.
      final amounts = _decimalAmount.allMatches(lines[i]).length;
      if (l.startsWith('total') && amounts >= 3) {
        endIdx = i;
        break;
      }
    }

    final items = <HyperpureLineItem>[];
    final descBuf = <String>[];

    for (var i = startIdx; i < endIdx; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || RegExp(r'^[\-=_\s]+$').hasMatch(line)) continue;
      if (_isMetadataLine(line)) continue;

      // Item rows END with a strict decimal amount (Hyperpure's "Total" col).
      final endMatch =
          RegExp(r'(\d[\d,]*\.\d{2})\s*$').firstMatch(line);
      if (endMatch == null) {
        // No trailing decimal amount → could be a wrapped description
        // (e.g. "John - Cheese (Diced Mozzarella and" then "Cheddar), 1 Kg ..."
        //  first line has no ending amount). Buffer it and try the next row.
        if (line.length > 3 && !_isNoiseDescription(line)) descBuf.add(line);
        continue;
      }

      final amountPaise = _paiseFromToken(endMatch.group(1)!);
      if (amountPaise == null || amountPaise <= 0) continue;

      // Description = everything BEFORE the trailing amount, minus numeric
      // columns and UoM words. Combine with any buffered wrap lines.
      final beforeAmount = line.substring(0, endMatch.start).trim();
      final descPart = _descriptionOf(beforeAmount);
      final fullDesc = [...descBuf, descPart]
          .where((s) => s.isNotEmpty)
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      descBuf.clear();
      if (fullDesc.length < 3) continue;
      if (_isNoiseDescription(fullDesc)) continue;

      // Qty & unit price live in the numeric columns between HSN and UoM.
      // A typical row parses to tokens like:
      //   ["1"(SNo) "19021900"(HSN) "1"(Qty) "342"(UnitPrice) "342"(Taxable)
      //    "8.55"(Tax)]
      // We can't tell reliably which is which without column positions, so
      // we use heuristics: the qty is a small integer (1..999), the unit
      // price sits just after a long numeric HSN or just before a UoM word.
      double? qty;
      int? unitPricePaise;
      final tokens = _numericTokens(beforeAmount);
      if (tokens.isNotEmpty) {
        // Skip a leading S.No (short int at the very start).
        var start = 0;
        if (tokens.first.length <= 3 &&
            beforeAmount.trimLeft().startsWith(tokens.first)) {
          start = 1;
        }
        // Skip an HSN (6-10 digits, no decimal).
        while (start < tokens.length &&
            RegExp(r'^\d{6,10}$').hasMatch(tokens[start])) {
          start++;
        }
        // Now tokens[start] should be Qty.
        if (start < tokens.length) {
          final qStr = tokens[start].replaceAll(',', '');
          qty = double.tryParse(qStr);
          if (qty != null && (qty < 0.01 || qty > 9999)) qty = null;
        }
        // Unit price is usually the next token.
        if (start + 1 < tokens.length) {
          unitPricePaise = _paiseFromToken(tokens[start + 1]);
        }
      }

      items.add(HyperpureLineItem(
        description: fullDesc,
        quantity: qty,
        unitPricePaise: unitPricePaise,
        amountPaise: amountPaise,
      ));
    }
    return items;
  }

  static List<String> _numericTokens(String line) {
    return RegExp(r'[0-9][0-9,]*(?:\.[0-9]{1,2})?')
        .allMatches(line)
        .map((m) => m.group(0)!)
        .toList();
  }

  static String _descriptionOf(String line) {
    var s =
        line.replaceAll(RegExp(r'(?:₹|rs\.?|inr)', caseSensitive: false), '');
    // Strip strict currency amounts and any bare number runs (HSN, qty, etc.)
    s = s.replaceAll(_decimalAmount, ' ');
    s = s.replaceAll(RegExp(r'\b\d{4,}\b'), ' '); // HSN codes, order tails
    s = s.replaceAll(RegExp(r'\b\d+\+\d+\+?\d*\b'), ' '); // tax rates "2.5+2.5+0"
    // Common unit words.
    s = s.replaceAll(
        RegExp(r'\b(?:kg|gm|g|ml|l|ltr|pkt|pcs|nos|no|unit|units|pc|count|pack)\b',
            caseSensitive: false),
        ' ');
    // Drop stray S.No integers at the very start.
    s = s.replaceAllMapped(
        RegExp(r'^\s*\d{1,3}\s+'), (_) => '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Lines that carry invoice metadata (addresses, PINs, GSTIN, etc.) — must
  /// NEVER be confused with an item row.
  static bool _isMetadataLine(String line) {
    final l = line.toLowerCase();
    const meta = [
      'invoice number',
      'invoice no',
      'invoice date',
      'reference po',
      'order no',
      'order number',
      'bill from',
      'bill to',
      'shipped from',
      'ship to',
      'address :',
      'address:',
      'gstin',
      'fssai',
      'pincode',
      'pin code',
      'outlet',
      'place of supply',
      'zomato hyperpure',
      'plot no',
      'sector',
      'noida',
      'uttar pradesh',
      'greater n', // "Greater Noida" — a common address token
      'ecotech',
      'udyog kendra',
    ];
    if (meta.any(l.contains)) return true;
    // Standalone 6-digit PIN codes (no decimal, no letters).
    if (RegExp(r'^\s*\d{6}\s*$').hasMatch(line)) return true;
    // GSTIN pattern (2 digits + 10 alphanumeric + 3 alphanumeric).
    if (RegExp(r'\d{2}[A-Z]{5}\d{4}[A-Z]\d[A-Z]\d[A-Z0-9]').hasMatch(line)) {
      return true;
    }
    return false;
  }

  /// Rejects descriptions that clearly aren't real items (headers, totals).
  static bool _isNoiseDescription(String s) {
    final l = s.toLowerCase().trim();
    if (l.length < 2) return true;
    const noise = [
      'description', 'particulars', 'item', 'product', 'qty', 'quantity',
      'unit', 'rate', 'amount', 'total', 'gst', 'sgst', 'cgst', 'igst',
      'hsn', 'sr. no', 'sr no', 'sl no', 's no', 'uom', 'other charges',
      'convenience_fee', 'convenience fee',
    ];
    if (noise.contains(l)) return true;
    // Descriptions containing any obvious totals phrase — filters lines like
    // "Hyperpure garbled scan xx xx xx Grand Total" if the totals-anchor at
    // endIdx didn't catch them for any reason.
    if (l.contains('grand total') ||
        l.contains('sub total') ||
        l.contains('subtotal') ||
        l.contains('total payable') ||
        l.contains('amount payable')) {
      return true;
    }
    return false;
  }

  // ── Category classification ─────────────────────────────────────
  /// Keyword map used to categorize BOTH the whole-bill fallback AND each
  /// individual line item. Extended for Hyperpure vocabulary: pulses,
  /// convenience-fee, etc.
  static const Map<String, List<String>> _categoryKeywords = {
    'Oil':
        ['oil', 'sunflower', 'mustard', 'refined', 'sesame', 'til', 'palm'],
    'Meat & Poultry': ['chicken', 'mutton', 'fish', 'egg', 'meat', 'lamb'],
    'Dairy': [
      'paneer', 'milk', 'butter', 'cream', 'cheese', 'curd', 'ghee',
      'mozzarella', 'cheddar', 'fat spread', 'nutralite', 'khoya', 'malai',
    ],
    'Fruits': [
      'apple', 'banana', 'mango', 'orange', 'papaya', 'watermelon',
      'strawberry', 'grape', 'pomegranate', 'kiwi',
    ],
    'Spices & Masalas': [
      'masala', 'garam', 'haldi', 'jeera', 'dhania', 'chilli powder',
      'turmeric', 'cardamom', 'elaichi', 'mirch', 'clove', 'cinnamon',
      'pepper', 'coriander seed', 'mustard seed', 'saunf', 'ajwain', 'mdh',
      'everest', 'hing', 'kasuri methi', 'bay leaf',
    ],
    'Grains & Flour': [
      'atta', 'maida', 'rice', 'basmati', 'dal', 'besan', 'suji', 'flour',
      'rava', 'penne', 'pasta', 'sugar', 'poha', 'noodle', 'macaroni',
      'chana', 'moong', 'toor', 'urad', 'masoor', 'rajma', 'kabuli',
      'lentil', 'pulse',
    ],
    'Bakery & Sweets': [
      'bread', 'bun', 'pav', 'cake', 'pastry', 'mithai', 'biscuit',
      'cookie', 'muffin', 'croissant',
    ],
    'Beverages': [
      'juice', 'cola', 'pepsi', 'sprite', 'thums up', 'soda', 'tea',
      'coffee', 'nescafe', 'red bull',
    ],
    'Water Bottles': ['bisleri', 'aquafina', 'kinley', 'water bottle'],
    'Veggies': [
      'onion', 'tomato', 'potato', 'vegetable', 'coriander', 'ginger',
      'garlic', 'green chilli', 'mushroom', 'cabbage', 'cauliflower',
      'brinjal', 'capsicum', 'lauki', 'karela', 'bhindi', 'palak',
      'spinach', 'lettuce', 'cucumber', 'lemon', 'nimbu', 'magaz tumba',
    ],
    'Packaging': [
      'container', 'box', 'pouch', 'packaging', 'cling film',
      'aluminium foil', 'foil', 'wrap', 'homefoil',
    ],
    'Disposables & Cutlery': [
      'plate', 'spoon', 'fork', 'tissue', 'napkin', 'cup', 'straw',
    ],
    'Miscellaneous': [
      'convenience', 'delivery fee', 'service charge', 'round off',
    ],
  };

  /// Maps a single line item to its category using keyword hits. Falls back
  /// to 'Groceries' when nothing distinctive matches.
  static String categoryOfItem(HyperpureLineItem item) =>
      _bestCategory(item.description.toLowerCase());

  static String _bestCategory(String haystack) {
    String bestCat = 'Groceries';
    var bestHits = 0;
    _categoryKeywords.forEach((cat, words) {
      final hits = words.where(haystack.contains).length;
      if (hits > bestHits) {
        bestHits = hits;
        bestCat = cat;
      }
    });
    return bestCat;
  }

  static String _suggestedCategory(String text, List<HyperpureLineItem> items) {
    return _bestCategory(
        '$text ${items.map((i) => i.description).join(' ')}'.toLowerCase());
  }
}

/// One category slice of a Hyperpure bill after auto-splitting.
class HyperpureCategoryGroup {
  final String category;
  final List<HyperpureLineItem> items;
  final int totalPaise;
  const HyperpureCategoryGroup({
    required this.category,
    required this.items,
    required this.totalPaise,
  });
}

/// Groups line items by their auto-detected category. Result is sorted by
/// total desc (biggest bucket first) so the user sees the important ones
/// on top of the review screen.
List<HyperpureCategoryGroup> groupHyperpureItemsByCategory(
    List<HyperpureLineItem> items) {
  final map = <String, List<HyperpureLineItem>>{};
  for (final it in items) {
    final cat = HyperpureParser.categoryOfItem(it);
    map.putIfAbsent(cat, () => []).add(it);
  }
  final groups = map.entries
      .map((e) => HyperpureCategoryGroup(
            category: e.key,
            items: e.value,
            totalPaise: e.value.fold<int>(0, (s, it) => s + it.amountPaise),
          ))
      .toList();
  groups.sort((a, b) => b.totalPaise.compareTo(a.totalPaise));
  return groups;
}
