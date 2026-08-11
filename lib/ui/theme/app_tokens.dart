import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Raw design tokens for the (deliberately divergent) clone design language.
///
/// These values come straight from `app_spec.json` -> `design_tokens`. They are
/// NOT the colors/fonts seen in the source screenshots — they are a new palette
/// on purpose. Every widget and screen must read from here (or the [ThemeData]
/// built in `app_theme.dart`) rather than hardcoding colors/radii.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFDC0C5B);
  static const Color primaryGradientStart = Color(0xFFB80E74);
  static const Color primaryGradientEnd = Color(0xFFE54629);
  static const Color proGradientStart = Color(0xFFE9D53A);
  static const Color proGradientEnd = Color(0xFF63C53B);

  // ── Brightness-aware semantic surfaces ──────────────────────────────────────
  // [background]/[surface]/[textPrimary]/[textSecondary] are the tokens every
  // widget reads. They resolve against [brightness], which the root MaterialApp
  // keeps in sync with the active [ThemeData] (see `main.dart`). This makes the
  // whole design system theme-aware without each widget reaching for
  // `Theme.of(context)` — a Light selection instantly repaints every screen.
  static Brightness brightness = Brightness.dark;
  static bool get _isLight => brightness == Brightness.light;

  // Raw dark surfaces.
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1E1D1C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF93918E);

  // Raw light surfaces (Theme screen offers System/Dark/Light).
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF6B6B70);

  // The onboarding/splash hero: a deep plum in dark, a soft light surface in
  // light — brightness-aware so first-run screens stay readable in both themes.
  static const Color darkBackgroundOnboarding = Color(0xFF150A12);
  static const Color lightBackgroundOnboarding = Color(0xFFEDEBF0);
  static Color get backgroundOnboarding =>
      _isLight ? lightBackgroundOnboarding : darkBackgroundOnboarding;

  static Color get background => _isLight ? lightBackground : darkBackground;
  static Color get surface => _isLight ? lightSurface : darkSurface;
  static Color get textPrimary => _isLight ? lightTextPrimary : darkTextPrimary;
  static Color get textSecondary =>
      _isLight ? lightTextSecondary : darkTextSecondary;

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color ctaLight = Color(0xFFFFFFFF);

  static const Color accentBadge = Color(0xFFF4182A);
  static const Color warningBg = Color(0xFFD7F0FC);
  static const Color warningText = Color(0xFF1B6A7D);
  static const Color ratingStar = Color(0xFF3DD4FF);
  static const Color success = Color(0xFFA830CB);
  static const Color danger = Color(0xFF30FFA7);
}

/// Corner radii from `design_tokens.dimension`.
class AppRadii {
  AppRadii._();

  static const double sm = 12;
  static const double md = 24;
  static const double lg = 30;
  static const double pill = 42;

  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rPill => BorderRadius.circular(pill);
}

/// Spacing / sizing tokens from `design_tokens.dimension`.
class AppDimens {
  AppDimens._();

  static const double gutter = 15;
  static const double buttonHeight = 54;
}

/// Design decisions from `design_tokens`.
class AppStyleTokens {
  AppStyleTokens._();

  /// `design_tokens.button_style` — filled | tonal | outlined.
  static const String buttonStyle = 'outlined';

  /// `design_tokens.elevation_style` — flat | soft | raised.
  static const String elevationStyle = 'soft';
}

/// Reusable [LinearGradient]s exposed from `design_tokens.gradient.*` plus the
/// button/badge gradients derived from the paired gradient color tokens.
class AppGradients {
  AppGradients._();

  /// Maps a CSS-style gradient angle (degrees, 0 = pointing up, clockwise) to
  /// Flutter begin/end [Alignment]s.
  static (Alignment, Alignment) _fromAngle(double angleDeg) {
    // Convert to radians where 0deg points up, angle increases clockwise.
    final double rad = (angleDeg - 90) * math.pi / 180.0;
    final double dx = math.cos(rad);
    final double dy = math.sin(rad);
    return (Alignment(-dx, -dy), Alignment(dx, dy));
  }

  static LinearGradient _build(double angle, List<Color> colors,
      [List<double>? stops]) {
    final (begin, end) = _fromAngle(angle);
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    );
  }

  /// `design_tokens.gradient.primary` (angle 135, flat primary).
  static LinearGradient get primary => _build(
        135,
        const [AppColors.primary, AppColors.primary],
        const [0.0, 1.0],
      );

  /// Primary action-button pill gradient (start -> end color tokens).
  static LinearGradient get cta => _build(
        135,
        const [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
        const [0.0, 1.0],
      );

  /// GET PRO / Go Premium badge gradient.
  static LinearGradient get pro => _build(
        135,
        const [AppColors.proGradientStart, AppColors.proGradientEnd],
        const [0.0, 1.0],
      );
}
