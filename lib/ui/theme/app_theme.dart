import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

export 'app_tokens.dart';

/// Builds the app's [ThemeData] from the divergent `design_tokens`.
///
/// Typography uses the DIVERGENT family named in `design_tokens.font.*`
/// (Poppins) applied via [GoogleFonts] so every screen inherits it. The source
/// app's real fonts are intentionally NOT bundled.
class AppTheme {
  AppTheme._();

  static const String fontFamilyName = 'Poppins';

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color bg =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primaryGradientEnd,
      onSecondary: AppColors.onPrimary,
      error: AppColors.accentBadge,
      onError: AppColors.onPrimary,
      surface: surface,
      onSurface: textPrimary,
    );

    final TextTheme baseText = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final TextTheme textTheme = GoogleFonts.poppinsTextTheme(baseText).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    // Elevation from `elevation_style: soft`.
    const double softElevation = 2;

    final OutlinedBorder pillShape =
        RoundedRectangleBorder(borderRadius: AppRadii.rPill);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: fontFamilyName,
      textTheme: textTheme,
      primaryColor: AppColors.primary,
      dividerColor: textSecondary.withValues(alpha: 0.2),
      iconTheme: IconThemeData(color: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: AppStyleTokens.elevationStyle == 'flat' ? 0 : softElevation,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.rMd),
        margin: EdgeInsets.zero,
      ),
      // Default button look honors `button_style: outlined`.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
          foregroundColor: textPrimary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: pillShape,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
          backgroundColor: AppColors.ctaLight,
          foregroundColor: AppColors.background,
          elevation: AppStyleTokens.elevationStyle == 'flat' ? 0 : softElevation,
          shape: pillShape,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.gutter,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.rPill,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rPill,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.rPill,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.primary,
        labelStyle: textTheme.labelLarge?.copyWith(color: textPrimary),
        secondaryLabelStyle:
            textTheme.labelLarge?.copyWith(color: AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.rPill),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textPrimary,
        textColor: textPrimary,
      ),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
      ),
    );
  }
}
