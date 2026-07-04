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

/// On-device, rules-based parser for Hyperpure invoices. No external calls.
class HyperpureParser {
  HyperpureParser._();

  static bool looksLikeHyperpure(String text) =>
      text.toLowerCase().contains('hyperpure');

  static ParsedHyperpure parse(String text) {
    final items = _lineItems(text);
    final tax = _amountLabeled(text, const [
      'total tax',
      'tax amount',
      'cgst + sgst',
      'gst amount',
    ]);
    final taxable = _amountLabeled(text, const [
      'taxable amount',
      'taxable value',
      'sub total',
      'subtotal',
    ]);
    return ParsedHyperpure(
      invoiceNumber: _invoiceNumber(text),
      invoiceDate: _invoiceDate(text),
      vendorName: 'Hyperpure',
      items: items,
      taxablePaise: taxable,
      taxPaise: tax,
      totalPaise: _totalPaise(text),
      suggestedCategory: _suggestedCategory(text, items),
      rawText: text,
    );
  }

  // ── Invoice number ─────────────────────────────────────────────────
  static String? _invoiceNumber(String text) {
    // "Invoice No: HP1234...", "Invoice # ABC-123", "Invoice Number XYZ".
    final labelled = RegExp(
      r'invoice\s*(?:no\.?|number|#)?\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-\/]{3,24})',
      caseSensitive: false,
    ).firstMatch(text);
    final candidate = labelled?.group(1)?.trim();
    if (candidate != null &&
        RegExp(r'\d').hasMatch(candidate) &&
        candidate.toLowerCase() != 'date') {
      return candidate;
    }
    // Standalone HP-prefixed codes anywhere in the text.
    final hp = RegExp(r'\b(HP[A-Z0-9\-\/]{4,20})\b').firstMatch(text);
    return hp?.group(1);
  }

  // ── Invoice date ───────────────────────────────────────────────────
  static DateTime? _invoiceDate(String text) {
    // dd/MM/yyyy or dd-MM-yyyy
    final numeric =
        RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})\b').firstMatch(text);
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
    final worded =
        RegExp(r'\b(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})\b').firstMatch(text);
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

  // ── Amount helpers ─────────────────────────────────────────────────
  static final _amountRe = RegExp(
    r'(?:₹|rs\.?|inr)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static int? _totalPaise(String text) {
    const totalHints = [
      'grand total',
      'total amount',
      'amount payable',
      'net payable',
      'invoice total',
      'total payable',
      'payable amount',
    ];
    final v = _amountLabeled(text, totalHints);
    if (v != null) return v;
    return _bestAmount(text, requireCurrency: true) ?? _bestAmount(text);
  }

  /// Finds an amount on a line matching any of [labels]. If the current line
  /// has no amount (OCR sometimes wraps to the next line), falls through to
  /// the next line. But if the current line ALREADY has an amount, we stop
  /// there — otherwise a "CGST + SGST 5%  218.50" line would greedily pull
  /// the "Grand Total 4,588.50" from the following line and return the total.
  static int? _amountLabeled(String text, List<String> labels) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (!labels.any(lower.contains)) continue;
      // Prefer the current line if it already contains a real amount.
      final onLine = _bestAmount(lines[i]);
      if (onLine != null) return onLine;
      // Otherwise the amount may have wrapped to the next line.
      if (i + 1 < lines.length) {
        final onNext = _bestAmount(lines[i + 1]);
        if (onNext != null) return onNext;
      }
    }
    return null;
  }

  static int? _bestAmount(String text, {bool requireCurrency = false}) {
    int? best;
    final re = requireCurrency
        ? RegExp(r'(?:₹|rs\.?|inr)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
            caseSensitive: false)
        : _amountRe;
    for (final m in re.allMatches(text)) {
      final raw = m.group(1)!.replaceAll(',', '');
      final value = double.tryParse(raw);
      if (value == null || value <= 0) continue;
      final paise = (value * 100).round();
      if (best == null || paise > best) best = paise;
    }
    return best;
  }

  // ── Line-item extraction ───────────────────────────────────────────
  /// Extracts item rows from the invoice body. Handles table layouts with
  /// varied column widths and multi-line descriptions. If no rows are found,
  /// returns an empty list — the parser then still gives you invoice-level
  /// totals from the labelled-amount helpers.
  static List<HyperpureLineItem> _lineItems(String text) {
    final lines = text.split(RegExp(r'[\r\n]+'));

    // Try to locate the header row so we skip anything before it.
    var startIdx = 0;
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      final hasDesc = l.contains('description') ||
          l.contains('item') ||
          l.contains('product') ||
          l.contains('particulars');
      final hasAmount = l.contains('amount') || l.contains('total');
      if (hasDesc && hasAmount) {
        startIdx = i + 1;
        break;
      }
    }

    // Stop at "totals" region.
    var endIdx = lines.length;
    const stopHints = [
      'sub total', 'subtotal', 'taxable', 'grand total', 'total amount',
      'amount payable', 'net payable', 'invoice total', 'sgst', 'cgst', 'igst'
    ];
    for (var i = startIdx; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      if (stopHints.any(l.contains)) {
        endIdx = i;
        break;
      }
    }

    final items = <HyperpureLineItem>[];
    // Coalesce a multi-line description into a buffer until a line ends with
    // a valid amount (typical table row structure: desc [qty] [unit] amount).
    final descBuf = <String>[];

    for (var i = startIdx; i < endIdx; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip lines that are clearly not item rows (headers/dividers).
      if (RegExp(r'^[\-=_\s]+$').hasMatch(line)) continue;

      final tokens = _numericTokens(line);
      // No numbers on this line → probably a description continuation.
      if (tokens.isEmpty) {
        descBuf.add(line);
        continue;
      }

      // Extract amount (last currency-like token), qty (first small integer/
      // decimal), unit price (if present, second-to-last number).
      final amountPaise = _paiseFromToken(tokens.last);
      if (amountPaise == null || amountPaise <= 0) {
        descBuf.add(line);
        continue;
      }

      // Strip numeric tokens and unit words from the description part.
      final descPart = _descriptionOf(line);
      final fullDesc =
          [...descBuf, descPart].where((s) => s.isNotEmpty).join(' ').trim();
      descBuf.clear();
      if (fullDesc.isEmpty) continue;
      if (_isNoiseDescription(fullDesc)) continue;

      double? qty;
      int? unitPricePaise;
      if (tokens.length >= 3) {
        qty = double.tryParse(tokens[0].replaceAll(',', ''));
        unitPricePaise = _paiseFromToken(tokens[tokens.length - 2]);
      } else if (tokens.length == 2) {
        qty = double.tryParse(tokens[0].replaceAll(',', ''));
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

  /// Numeric-looking tokens on a line ("2", "1,240.50", "15L" is skipped).
  static List<String> _numericTokens(String line) {
    return RegExp(r'[0-9][0-9,]*(?:\.[0-9]{1,2})?').allMatches(line)
        .map((m) => m.group(0)!)
        .toList();
  }

  static int? _paiseFromToken(String token) {
    final v = double.tryParse(token.replaceAll(',', ''));
    if (v == null || v <= 0) return null;
    return (v * 100).round();
  }

  static String _descriptionOf(String line) {
    // Strip currency prefixes, then remove numeric tokens.
    var s = line.replaceAll(RegExp(r'(?:₹|rs\.?|inr)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'[0-9][0-9,]*(?:\.[0-9]{1,2})?'), ' ');
    // Common unit words attached to numbers.
    s = s.replaceAll(
        RegExp(r'\b(?:kg|gm|g|ml|l|ltr|pkt|pcs|nos|no|unit|units|pc)\b',
            caseSensitive: false),
        ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Rejects description strings that look like table headers, totals, or
  /// blank rows, so we don't pollute the item list.
  static bool _isNoiseDescription(String s) {
    final l = s.toLowerCase();
    if (l.length < 2) return true;
    const noise = [
      'description', 'particulars', 'item', 'product', 'qty', 'quantity',
      'unit', 'rate', 'amount', 'total', 'gst', 'sgst', 'cgst', 'igst',
      'hsn', 'sr. no', 'sr no', 'sl no',
    ];
    // Reject if the entire description IS one of the noise words.
    if (noise.contains(l)) return true;
    return false;
  }

  // ── Suggested category ────────────────────────────────────────────
  static String _suggestedCategory(String text, List<HyperpureLineItem> items) {
    // Use both the raw text AND the item descriptions to guess.
    final haystack =
        '$text ${items.map((i) => i.description).join(' ')}'.toLowerCase();
    const keywordMap = <String, List<String>>{
      'Oil': ['oil', 'sunflower', 'mustard', 'refined'],
      'Meat & Poultry': ['chicken', 'mutton', 'fish', 'egg', 'meat'],
      'Dairy': ['paneer', 'milk', 'butter', 'cream', 'cheese', 'curd', 'ghee'],
      'Fruits': ['apple', 'banana', 'mango', 'orange', 'papaya', 'watermelon'],
      'Spices & Masalas': ['masala', 'garam', 'haldi', 'jeera', 'dhania',
          'chilli powder', 'turmeric'],
      'Grains & Flour': ['atta', 'maida', 'rice', 'basmati', 'dal', 'besan',
          'suji', 'flour', 'rava'],
      'Bakery & Sweets': ['bread', 'bun', 'pav', 'cake', 'pastry', 'mithai'],
      'Beverages': ['juice', 'cola', 'pepsi', 'sprite', 'thums up', 'soda'],
      'Water Bottles': ['bisleri', 'aquafina', 'kinley', 'water bottle'],
      'Veggies': ['onion', 'tomato', 'potato', 'vegetable', 'coriander',
          'ginger', 'garlic', 'green chilli'],
      'Packaging': ['container', 'box', 'pouch', 'packaging'],
      'Disposables & Cutlery': ['plate', 'spoon', 'fork', 'tissue', 'napkin'],
    };
    String bestCat = 'Groceries';
    var bestHits = 0;
    keywordMap.forEach((cat, words) {
      final hits = words.where(haystack.contains).length;
      if (hits > bestHits) {
        bestHits = hits;
        bestCat = cat;
      }
    });
    return bestCat;
  }
}
