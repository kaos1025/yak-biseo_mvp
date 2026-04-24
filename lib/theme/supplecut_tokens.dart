import 'package:flutter/material.dart';

/// SuppleCut Design Tokens — DS v0.5
/// ==========================================
/// Based on PetCut DS v0.4 (locked 2026-04-20).
/// Adapted for SuppleCut v1.1 under All Hands 2-week roadmap (2026-04-23).
///
/// Decision log (D-1 ~ D-14): see UX_AUDIT_20260424.md Part C.
/// Addendum spec: see DS_v0.5_addendum.md.
///
/// FORK POLICY (§11 addendum):
/// - `brand`, `brandTint`, `brandDark` → forked from PetCut for brand identity protection
/// - Primary Button bg → forked (SuppleCut uses `brand`, PetCut uses `ink`)
/// - Everything else: SHARED with PetCut (neutrals, semantic, typography, spacing, radius)
///
/// Migration note: replace `import 'package:supplecut/theme/app_theme.dart'` usage
/// across the codebase with tokens from this file. Hardcoded `Color(0x...)`,
/// `TextStyle(fontSize: ..., fontWeight: FontWeight.bold)` etc. must be replaced.

class ScColors {
  ScColors._();

  // ─── Brand (FORKED — SuppleCut identity) ────────────────────────────
  // D-1-A: Primary button uses `brand` (SuppleCut launched with green CTA)
  // D-2-A: Hex preserved from legacy AppTheme.primaryColor to protect
  //        Play Store assets and landing page brand consistency
  static const brand     = Color(0xFF2E7D32); // Deep forest green
  static const brandDark = Color(0xFF1B5E20); // Hover/pressed states
  static const brandTint = Color(0xFFE8F5E9); // Selected chip bg, subtle brand wash

  // ─── Neutrals (SHARED with PetCut) ──────────────────────────────────
  // D-12-A: `backgroundColor` #F5F5F5 (cool grey) migrated to `surface2` (warm cream)
  static const ink       = Color(0xFF1A1A1A); // Primary text, icon
  static const surface   = Color(0xFFFFFFFF); // Card bg, input bg
  static const surface2  = Color(0xFFFAF8F3); // Screen bg (warm cream)
  static const border    = Color(0xFFEDE9DF); // All borders (0.5px)
  static const textSec   = Color(0xFF6B6B63); // Secondary text, meta
  static const textTer   = Color(0xFF9A9A90); // Placeholder, disabled

  // ─── Semantic: Perfect (green) ──────────────────────────────────────
  static const okBg      = Color(0xFFEAF3DE);
  static const okAccent  = Color(0xFF639922);
  static const okText    = Color(0xFF173404);

  // ─── Semantic: Caution (amber) ──────────────────────────────────────
  static const warnBg     = Color(0xFFFAEEDA);
  static const warnAccent = Color(0xFFEF9F27);
  static const warnText   = Color(0xFF412402);

  // ─── Semantic: Warning (red) ────────────────────────────────────────
  static const dangerBg     = Color(0xFFFCEBEB);
  static const dangerAccent = Color(0xFFE24B4A);
  static const dangerText   = Color(0xFF501313);

  // ─── Semantic: Suggestion (blue, actions only) ──────────────────────
  // D-5: AI Detailed Report Paywall purple → migrated to `infoAccent`
  // D-11-B (future): Synergies 'positive' variant also uses this blue
  static const infoBg     = Color(0xFFE6F1FB);
  static const infoAccent = Color(0xFF378ADD);
  static const infoText   = Color(0xFF042C53);
}

class ScText {
  ScText._();

  // D-9-A: Only w400 (Regular) and w500 (Medium) allowed.
  // DS §3.3 forbids 600/700/800/900. Use size, not weight, for emphasis.
  // Line-height follows PetCut DS for visual rhythm consistency.

  /// 28/500, line-height 1.15. Hero copy, savings amount.
  /// Example: "You could save $6.00/mo", onboarding hero title.
  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.15,
  );

  /// 22/500, line-height 1.25. Screen title, primary heading.
  /// Example: "Ready to scan", "My Stack", "Quick Check".
  static const h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  /// 17/500, line-height 1.3. Card title, section heading.
  /// Example: "Naturealm, Sacred 7 Mushroom Extract Powder".
  static const h2 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// 16/400, line-height 1.5. Body copy, default paragraph.
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 13/400, line-height 1.5. Caption, secondary info, source.
  /// Example: "Analyzed on 2026.04.24", "$14.95/mo".
  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 11/500, letter-spacing 0.88. UPPERCASE section labels only.
  /// Example: "RECENT SCANS", "ANALYZED PRODUCTS".
  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.88,
  );
}

class ScRadius {
  ScRadius._();

  /// 8px. Chips, small controls.
  static const sm = 8.0;

  /// 12px. Default — cards, buttons, banners, progress cards.
  static const md = 12.0;

  /// 20px. Bottom sheets, hero cards, phone frames.
  static const lg = 20.0;

  /// 999px. Avatars, pill buttons.
  static const full = 999.0;
}

class ScSpace {
  ScSpace._();

  /// 4px. Icon-text spacing.
  static const xs = 4.0;

  /// 8px. Chip-to-chip, inline elements.
  static const sm = 8.0;

  /// 12px. Card internal padding (vertical).
  static const md = 12.0;

  /// 16px. Screen horizontal padding, card internal (horizontal).
  static const lg = 16.0;

  /// 24px. Section spacing.
  static const xl = 24.0;

  /// 32px. Major block separation.
  static const xxl = 32.0;
}

/// Touch target minimums (DS §1.2).
class ScTouch {
  ScTouch._();

  /// 48px. Minimum tappable area (all interactive elements).
  static const min = 48.0;

  /// 56px. Primary CTA minimum height.
  static const primaryCta = 56.0;

  /// 44px. Avatar default size (38~44 range, default 44).
  static const avatar = 44.0;
}
