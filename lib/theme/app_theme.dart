import 'package:flutter/material.dart';
import 'supplecut_tokens.dart';

/// SuppleCut App Theme — v1.1 refactor
/// ==========================================
/// MIGRATION FROM: lib/theme/app_theme.dart (legacy, pre-2026-04-24)
/// MIGRATION TO:   DS v0.5 (based on PetCut DS v0.4)
///
/// Changes from legacy theme (D-1 ~ D-14):
/// - Font family: none (Roboto fallback) → Pretendard (D-13-A)
/// - Scaffold bg: #F5F5F5 → ScColors.surface2 (#FAF8F3, warm cream, D-12-A)
/// - AppBar bg: Colors.white → ScColors.surface2 (matches scaffold)
/// - AppBar centerTitle: false → true (matches actual UI)
/// - AppBar foreground: Colors.black → ScColors.ink
/// - ElevatedButton elevation: 3 → 0 (flat, DS §1.3, D-14-A)
/// - ElevatedButton fontSize: 18 bold → 15 medium (D-9-A)
/// - ElevatedButton padding: 16v/24h → 16v/20h (DS §7.1)
/// - ElevatedButton minHeight: none → 56 (DS §1.2, D-14 exception spec)
/// - ElevatedButton disabled: none → surface2 bg + textTer fg (D-14 exception spec)
/// - OutlinedButton border: 1.5 primaryColor → 0.5 border token (DS §7.2, D-14-A)
/// - OutlinedButton fontSize: 16 bold → 15 medium
/// - CardTheme: commented out → active flat + border 0.5 (D-14-A)
/// - TextTheme: ad-hoc 4 styles → full ScText scale (6 tiers)
/// - Text colors: Colors.black87/54 → ScColors.ink/textSec (warm shift, D-12-A)
/// - ColorScheme primary: primaryColor (#2E7D32) → ScColors.brand (same hex, token-based)
/// - ColorScheme secondary: accent #FFC107 → ScColors.warnAccent #EF9F27 (DS semantic)
///
/// Rollback: revert this file to legacy version (git history). Theme is
/// self-contained — no DB migration or asset cleanup required for rollback.

class AppTheme {
  AppTheme._();

  // ─── Legacy constants retained for backwards compatibility ──────────
  // Callers that reference AppTheme.primaryColor etc. keep working.
  // New code should use ScColors.brand directly.
  @Deprecated('Use ScColors.brand instead.')
  static const Color primaryColor = ScColors.brand;

  @Deprecated('Use ScColors.warnAccent instead (DS semantic).')
  static const Color accentColor = ScColors.warnAccent;

  @Deprecated('Use ScColors.surface2 instead (warm cream, DS unified).')
  static const Color backgroundColor = ScColors.surface2;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // D-13-A: Pretendard unified with PetCut
      fontFamily: 'Pretendard',

      // D-12-A: warm cream background (was #F5F5F5 cool grey)
      scaffoldBackgroundColor: ScColors.surface2,

      colorScheme: const ColorScheme.light(
        primary: ScColors.brand,             // D-1-A: green primary (fork)
        onPrimary: ScColors.surface,
        secondary: ScColors.warnAccent,      // DS semantic amber
        onSecondary: ScColors.warnText,
        surface: ScColors.surface,
        onSurface: ScColors.ink,
        error: ScColors.dangerAccent,
        onError: ScColors.surface,
      ),

      // AppBar: matches actual UI (centered titles, flat, surface2 bg)
      appBarTheme: const AppBarTheme(
        backgroundColor: ScColors.surface2,
        foregroundColor: ScColors.ink,
        elevation: 0,
        centerTitle: true, // D-4 exception: AppBar Title Case allowed
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: ScColors.ink,
          height: 1.25,
        ),
        iconTheme: IconThemeData(color: ScColors.ink, size: 24),
      ),

      // D-9-A: Full DS typography scale (6 tiers)
      textTheme: const TextTheme(
        displayLarge: ScText.display,
        displayMedium: ScText.display,
        headlineLarge: ScText.h1,
        headlineMedium: ScText.h1,
        titleLarge: ScText.h1,
        titleMedium: ScText.h2,
        titleSmall: ScText.h2,
        bodyLarge: ScText.body,
        bodyMedium: ScText.body,
        bodySmall: ScText.caption,
        labelLarge: ScText.body,
        labelMedium: ScText.caption,
        labelSmall: ScText.label,
      ),

      // D-1-A, D-14-A, D-9-A: Primary CTA
      // - brand green bg (fork from DS ink primary)
      // - elevation 0 (flat)
      // - 15/w500 (was 18/bold)
      // - disabled state explicit
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return ScColors.surface2; // Disabled bg (DS §7.1 exception spec)
            }
            return ScColors.brand;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return ScColors.textTer;
            }
            return ScColors.surface;
          }),
          textStyle: WidgetStateProperty.all(const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          )),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ScRadius.md),
            ),
          ),
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(
            const Size.fromHeight(ScTouch.primaryCta),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return ScColors.brandDark.withValues(alpha: 0.2);
            }
            return null;
          }),
        ),
      ),

      // D-14-A: Secondary / Outlined
      // - border 0.5 (was 1.5)
      // - border color: ScColors.border (was primaryColor)
      // - fg ink (was primaryColor)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ScColors.ink,
          backgroundColor: ScColors.surface,
          side: const BorderSide(color: ScColors.border, width: 0.5),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScRadius.md),
          ),
          minimumSize: const Size.fromHeight(ScTouch.primaryCta),
        ),
      ),

      // TextButton for Ghost Button §7.17 base (further customized inline)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ScColors.ink,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScRadius.full),
          ),
        ),
      ),

      // D-14-A: CardTheme active, flat, border 0.5
      // Every Card widget inherits this unless explicitly overridden.
      // Legacy card shadow across the app is removed in a single stroke.
      cardTheme: CardThemeData(
        color: ScColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScRadius.md),
          side: const BorderSide(color: ScColors.border, width: 0.5),
        ),
        margin: const EdgeInsets.only(bottom: ScSpace.md),
        clipBehavior: Clip.antiAlias,
      ),

      // Divider (used in §7.21 Summary Stats Card)
      dividerTheme: const DividerThemeData(
        color: ScColors.border,
        thickness: 0.5,
        space: 0,
      ),

      // D-14 (misc): Input / TextField → DS §7.23 Text Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ScColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        hintStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ScColors.textTer,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScRadius.md),
          borderSide: const BorderSide(color: ScColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScRadius.md),
          borderSide: const BorderSide(color: ScColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScRadius.md),
          borderSide: const BorderSide(color: ScColors.ink, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScRadius.md),
          borderSide: const BorderSide(color: ScColors.dangerAccent, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScRadius.md),
          borderSide: const BorderSide(color: ScColors.dangerAccent, width: 1.0),
        ),
      ),

      // Snackbar (used by §7.9 Save Scan button — PetCut pattern)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ScColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ScColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator (used by §7.14 Full-screen Loading)
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ScColors.brand,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: ScColors.ink,
        size: 24,
      ),
    );
  }
}
