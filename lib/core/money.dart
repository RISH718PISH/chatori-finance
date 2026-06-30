import 'package:intl/intl.dart';

/// Currency helpers. App stores money as integer **paise**; this is the only
/// place rupees/₹ formatting happens. Uses the Indian numbering system
/// (lakh/crore grouping) via the en_IN locale.
class Money {
  Money._();

  static final NumberFormat _withDecimals =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final NumberFormat _noDecimals =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  /// paise -> "₹1,23,456.00" (or without decimals when [decimals] is false).
  static String format(int paise, {bool decimals = true}) {
    final rupees = paise / 100.0;
    return (decimals ? _withDecimals : _noDecimals).format(rupees);
  }

  /// rupees (e.g. user input 1234.5) -> paise (123450).
  static int toPaise(num rupees) => (rupees * 100).round();

  /// paise -> rupees as a double.
  static double toRupees(int paise) => paise / 100.0;
}
