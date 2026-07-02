/// Result of parsing OCR text from a Hyperpure (Zomato B2B) invoice.
class ParsedHyperpure {
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final int? totalPaise;
  final String suggestedCategory;
  final String rawText;

  const ParsedHyperpure({
    this.invoiceNumber,
    this.invoiceDate,
    this.totalPaise,
    this.suggestedCategory = 'Groceries',
    required this.rawText,
  });
}

/// Best-effort, on-device, rules-based parser for Hyperpure invoices.
/// Anything it can't find stays null — the user reviews before saving.
/// Never throws.
class HyperpureParser {
  HyperpureParser._();

  /// True when the OCR text looks like a Hyperpure document.
  static bool looksLikeHyperpure(String text) =>
      text.toLowerCase().contains('hyperpure');

  static ParsedHyperpure parse(String text) {
    return ParsedHyperpure(
      invoiceNumber: _invoiceNumber(text),
      invoiceDate: _invoiceDate(text),
      totalPaise: _totalPaise(text),
      suggestedCategory: _suggestedCategory(text),
      rawText: text,
    );
  }

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
    final hp = RegExp(r'\b(HP[A-Z0-9\-]{4,20})\b').firstMatch(text);
    return hp?.group(1);
  }

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
    // dd MMM yyyy / dd Month yyyy
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
    ];
    // Prefer an amount on (or immediately after) a line naming the total.
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      final isTotalLine = totalHints.any(lower.contains);
      if (!isTotalLine) continue;
      final searchIn = i + 1 < lines.length
          ? '${lines[i]} ${lines[i + 1]}'
          : lines[i];
      final amt = _bestAmount(searchIn);
      if (amt != null) return amt;
    }
    // Fall back to the largest ₹ amount anywhere.
    return _bestAmount(text, requireCurrency: true) ?? _bestAmount(text);
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

  static String _suggestedCategory(String text) {
    final t = text.toLowerCase();
    const keywordMap = <String, List<String>>{
      'Oil': ['oil', 'sunflower', 'mustard'],
      'Packaging': ['container', 'box', 'pouch', 'packaging'],
      'Dairy': ['paneer', 'milk', 'butter', 'cream', 'cheese'],
      'Veggies': ['onion', 'tomato', 'potato', 'vegetable'],
    };
    // Count keyword hits per category; highest wins, Groceries by default.
    String bestCat = 'Groceries';
    var bestHits = 0;
    keywordMap.forEach((cat, words) {
      final hits = words.where(t.contains).length;
      if (hits > bestHits) {
        bestHits = hits;
        bestCat = cat;
      }
    });
    return bestCat;
  }
}
