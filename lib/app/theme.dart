import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kitchen Ledger design system, faithfully applied.
///
/// - Primary: Deep Slate (`#131b2e`) — navigation, headings, structure
/// - Secondary: Emerald Green (`#006c49`) — positive / revenue
/// - Tertiary: Warm Orange (`#d95f00`) — expenses / alerts
/// - Background: Blue-tinted gray (`#f7f9fb`)
/// - Radius: 12px cards, 8px buttons, pill for status chips
/// - Typography: Inter for UI, Geist for numeric data (via `core/design.dart`)
class AppTheme {
  AppTheme._();

  static const _bg = Color(0xFFF7F9FB);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceContainer = Color(0xFFECEEF0);
  static const _surfaceContainerHigh = Color(0xFFE6E8EA);
  static const _outline = Color(0xFF76777D);
  static const _outlineVariant = Color(0xFFC6C6CD);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF131B2E),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDAE2FD),
      onPrimaryContainer: Color(0xFF131B2E),
      secondary: Color(0xFF006C49),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF6FFBBE),
      onSecondaryContainer: Color(0xFF00251A),
      tertiary: Color(0xFFC24B00),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFFFDBCA),
      onTertiaryContainer: Color(0xFF341100),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: _bg,
      onSurface: Color(0xFF191C1E),
      surfaceContainerLowest: _surface,
      surfaceContainerLow: Color(0xFFF2F4F6),
      surfaceContainer: _surfaceContainer,
      surfaceContainerHigh: _surfaceContainerHigh,
      surfaceContainerHighest: Color(0xFFE0E3E5),
      onSurfaceVariant: Color(0xFF45464D),
      outline: _outline,
      outlineVariant: _outlineVariant,
      inverseSurface: Color(0xFF2D3133),
      onInverseSurface: Color(0xFFEFF1F3),
      inversePrimary: Color(0xFFBEC6E0),
    );
    return _themeFor(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF131B2E),
      brightness: Brightness.dark,
    );
    return _themeFor(scheme);
  }

  static ThemeData _themeFor(ColorScheme scheme) {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          height: 28 / 20,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      // Cards: soft ambient shadow, 12px radius, subtle outline
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        shadowColor: const Color(0x0D0F172A),
      ),
      // Primary filled button: Deep Slate, 8px radius, tap-friendly height
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          side: BorderSide(color: scheme.outline),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Chips: pill for status, 8px otherwise
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
      ),
      // Inputs: light gray border, thickens on focus to primary slate
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: scheme.onSurfaceVariant),
        hintStyle: GoogleFonts.inter(color: scheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      // FAB & Snackbar
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF45464D),
      ),
    );
  }
}
