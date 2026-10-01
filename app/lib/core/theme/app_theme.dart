import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Light and dark themes.
///
/// The dark theme re-maps the palette rather than inverting it
/// (PROMPT.md section 2.1).
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final onSurface = isDark ? AppColors.darkText : AppColors.text;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? AppColors.primaryDark : Colors.white,
      secondary: isDark ? AppColors.brandTeal : AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark ? AppColors.darkSurface : AppColors.primaryTint,
      outline: border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Cairo',
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, onSurface, muted),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kMinTouchTarget + 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(kMinTouchTarget + 4),
          side: BorderSide(color: border),
          foregroundColor: onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: TextStyle(color: muted),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.primaryTint,
        side: BorderSide(color: border),
        // Cairo's tall ascenders are clipped by the chip's fixed height at
        // the default line height.
        labelStyle: TextStyle(color: onSurface, fontSize: 13, height: 1.15),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: isDark ? AppColors.primaryDark : AppColors.primaryTint,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        subtitleTextStyle: TextStyle(fontSize: 13, color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.input),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color onSurface, Color muted) {
    return base.copyWith(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.35,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.4,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: onSurface, height: 1.55),
      bodyMedium: TextStyle(fontSize: 14, color: onSurface, height: 1.55),
      bodySmall: TextStyle(fontSize: 13, color: muted, height: 1.5),
      labelSmall: TextStyle(fontSize: 11, color: muted, height: 1.4),
    );
  }
}
