import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Design tokens aligned with the Keystone HRM web platform (`hrm/src/index.css` & landing/employee modules):
/// deep pine & vibrant emerald, sunlit gold, cobalt indigo, warm rose, and soft botanical canvases
/// separated by tone & natural elevation rather than harsh hairline borders or divider lines.
abstract final class KeystoneColors {
  // Ambient canvases & elevated surfaces
  static const Color paper = Color(0xFFF3F8F5);
  static const Color paperWarm = Color(0xFFFDF8EC);
  static const Color wash = Color(0xFFEDF3EF);
  static const Color surfaceSoft = Color(0xFFF6FAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFE4EAE6);
  static const Color hairlineStrong = Color(0xFFD0D8D3);
  static const Color cardShadow = Color(0x12123D2D);

  // Typography
  static const Color ink = Color(0xFF17211C);
  static const Color muted = Color(0xFF5D6B63);
  static const Color subtle = Color(0xFF839189);

  // Brand Pine & Emerald (primary)
  static const Color pine = Color(0xFF166534);
  static const Color pineDeep = Color(0xFF123E2E);
  static const Color emerald = Color(0xFF10B981);
  static const Color pineTint = Color(0xFFE2F5EA);
  static const Color mintMist = Color(0xFFD6EFE1);
  static const Color mapCanvas = Color(0xFFDFEFE6);

  // Warm Gold & Amber (leave, rewards, highlights)
  static const Color ochre = Color(0xFFD97706);
  static const Color gold = Color(0xFFEAB308);
  static const Color ochreTint = Color(0xFFFEF3C7);
  static const Color amberMist = Color(0xFFFFF8DF);

  // Indigo & Sky (payroll, documents, field routes)
  static const Color indigo = Color(0xFF4338CA);
  static const Color indigoTint = Color(0xFFE0E7FF);
  static const Color sky = Color(0xFF0284C7);
  static const Color skyTint = Color(0xFFE0F2FE);

  // Coral / Rose / Clay (alerts, holidays, deductions)
  static const Color clay = Color(0xFFBE123C);
  static const Color coral = Color(0xFFE11D48);
  static const Color clayTint = Color(0xFFFFE4E8);

  // Violet (biometrics & security)
  static const Color violet = Color(0xFF6D28D9);
  static const Color violetTint = Color(0xFFEDE9FE);

  static const Color slateTint = Color(0xFFECF1EE);
}

abstract final class KeystoneTheme {
  static const List<String> _fontFallback = [
    '-apple-system',
    'BlinkMacSystemFont',
    'Inter',
    'Roboto',
    'sans-serif',
  ];

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: KeystoneColors.pine,
      onPrimary: Colors.white,
      secondary: KeystoneColors.emerald,
      onSecondary: Colors.white,
      error: KeystoneColors.clay,
      onError: Colors.white,
      surface: KeystoneColors.surface,
      onSurface: KeystoneColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KeystoneColors.paper,
      dividerColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        space: 0,
        thickness: 0,
      ),
      fontFamily: defaultTargetPlatform == TargetPlatform.iOS ? null : 'Roboto',
      fontFamilyFallback: _fontFallback,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: KeystoneColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: KeystoneColors.ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: KeystoneColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KeystoneColors.pine,
          foregroundColor: Colors.white,
          disabledBackgroundColor: KeystoneColors.wash,
          disabledForegroundColor: KeystoneColors.muted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            fontFamily: defaultTargetPlatform == TargetPlatform.iOS ? null : 'Roboto',
            fontFamilyFallback: _fontFallback,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KeystoneColors.pineDeep,
          backgroundColor: KeystoneColors.pineTint.withValues(alpha: 0.72),
          side: BorderSide.none,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            fontFamily: defaultTargetPlatform == TargetPlatform.iOS ? null : 'Roboto',
            fontFamilyFallback: _fontFallback,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KeystoneColors.surfaceSoft,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: const TextStyle(color: KeystoneColors.subtle, fontSize: 14),
        labelStyle: const TextStyle(color: KeystoneColors.muted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KeystoneColors.emerald, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KeystoneColors.clay, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KeystoneColors.clay, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KeystoneColors.pineDeep,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KeystoneColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KeystoneColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.55,
          color: KeystoneColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
          color: KeystoneColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          color: KeystoneColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: KeystoneColors.ink,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          color: KeystoneColors.muted,
          height: 1.35,
        ),
      ),
    );
  }

  static const TextStyle tabular = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
