/// Result of parsing OCR text from a payment screenshot.
class ParsedPayment {
  final int? amountPaise;
  final String? type; // 'income' | 'expense'
  final String? party;
  final DateTime? dateTime;
  final String rawText;

  const ParsedPayment({
    this.amountPaise,
    this.type,
    this.party,
    this.dateTime,
    required this.rawText,
  });
}

/// Best-effort, on-device parser for Paytm / UPI payment screenshots. Whatever
/// it can't find is left null for the user to fill — it never blocks.
class PaytmParser {
  static ParsedPayment parse(String text) {
    return ParsedPayment(
      amountPaise: _amount(text),
      type: _type(text),
      party: _party(text),
      dateTime: _date(text),
      rawText: text,
    );
  }

  static int? _amount(String text) {
    // Match ₹ / Rs / INR followed by a number like 1,240 or 1240.50
    final re = RegExp(
      r'(?:₹|rs\.?|inr)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    int? best;
    for (final m in re.allMatches(text)) {
      final raw = m.group(1)!.replaceAll(',', '');
      final rupees = double.tryParse(raw);
      if (rupees == null) continue;
      final paise = (rupees * 100).round();
      // Prefer the largest amount found (usually the transaction total).
      if (best == null || paise > best) best = paise;
    }
    return best;
  }

  static String? _type(String text) {
    final t = text.toLowerCase();
    const expenseHints = [
      'paid to', 'sent to', 'money sent', 'sent successfully', 'paid successfully',
      'debited', 'you paid', 'payment to'
    ];
    const incomeHints = [
      'received from', 'money received', 'received successfully', 'credited',
      'added to', 'you received', 'payment from'
    ];
    for (final h in incomeHints) {
      if (t.contains(h)) return 'income';
    }
    for (final h in expenseHints) {
      if (t.contains(h)) return 'expense';
    }
    return null;
  }

  static String? _party(String text) {
    final re = RegExp(
      r'(?:paid to|received from|to|from)\s*[:\-]?\s*([A-Z][A-Za-z0-9 .&]{2,40})',
      caseSensitive: false,
    );
    final m = re.firstMatch(text);
    final name = m?.group(1)?.trim();
    if (name == null || name.isEmpty) return null;
    // Trim trailing noise words.
    return name.split(RegExp(r'\s{2,}')).first.trim();
  }

  static DateTime? _date(String text) {
    // e.g. "12 Jun 2024" or "12 June 2024"
    final re = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})',
    );
    final m = re.firstMatch(text);
    if (m == null) return null;
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final day = int.tryParse(m.group(1)!);
    final mon = months[m.group(2)!.toLowerCase().substring(0, 3)];
    final year = int.tryParse(m.group(3)!);
    if (day == null || mon == null || year == null) return null;
    try {
      return DateTime(year, mon, day);
    } catch (_) {
      return null;
    }
  }
}
