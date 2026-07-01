import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kitchen Ledger design tokens — semantic aliases used across the app.
///
/// The base palette is defined in [AppTheme]; this file exposes the small set
/// of *semantic* colors and typography helpers screens should use so we can
/// tweak the design system in one place.
class AppSemantics {
  AppSemantics._();

  // Positive = income, capacity, growth. Emerald.
  static const income = Color(0xFF006C49);
  // Expense / alert. Warm orange.
  static const expense = Color(0xFFC24B00);
  // Warning highlight (pending, outstanding advance).
  static const warning = Color(0xFFB35C00);
  // Card border.
  static const cardBorder = Color(0xFFE2E8F0);
}

/// Typography tokens (Kitchen Ledger design):
/// - Inter for UI / body
/// - Geist for numeric data ("hard facts")
class AppText {
  AppText._();

  static TextStyle labelUpper(BuildContext context) => GoogleFonts.geist(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ).copyWith(height: 16 / 12);

  static TextStyle dataLg(BuildContext context, {Color? color}) =>
      GoogleFonts.geist(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.24,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ).copyWith(height: 32 / 24);

  static TextStyle dataMd(BuildContext context, {Color? color}) =>
      GoogleFonts.geist(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ).copyWith(height: 24 / 18);

  static TextStyle dataSm(BuildContext context, {Color? color}) =>
      GoogleFonts.geist(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ).copyWith(height: 20 / 14);
}

/// A label rendered in the uppercase Geist "label-uppercase" style — used on
/// data cards above the numeric value.
class LabelUpper extends StatelessWidget {
  const LabelUpper(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.labelUpper(context).copyWith(color: color),
    );
  }
}

/// A numeric value styled with Geist. Kitchen Ledger's "data-lg" by default.
class DataNumber extends StatelessWidget {
  const DataNumber(
    this.text, {
    super.key,
    this.size = DataSize.lg,
    this.color,
  });

  final String text;
  final DataSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = switch (size) {
      DataSize.sm => AppText.dataSm(context, color: color),
      DataSize.md => AppText.dataMd(context, color: color),
      DataSize.lg => AppText.dataLg(context, color: color),
    };
    return Text(text, style: style);
  }
}

enum DataSize { sm, md, lg }
