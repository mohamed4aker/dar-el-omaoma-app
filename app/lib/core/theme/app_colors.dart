import 'package:flutter/material.dart';

/// Brand palette for Dar El Omouma Hospital, taken from the hospital's logo:
/// the pink of the mark and the teal of the name beneath it.
///
/// The exact logo colours ([brandPink], [brandTeal]) are used where colour is
/// decoration. Text and buttons use slightly deeper shades of the same hues,
/// so that white text on them stays readable (WCAG AA, 4.5:1).
abstract final class AppColors {
  /// Logo pink, exactly as sampled from the logo file.
  static const brandPink = Color(0xFFEE6591);

  /// Logo teal, exactly as sampled from the hospital name in the logo.
  static const brandTeal = Color(0xFF4CB0B0);

  // Primary: the logo pink, deepened for contrast.
  static const primary = Color(0xFFC93A72);
  static const primaryDark = Color(0xFF9E2656);
  static const primaryTint = Color(0xFFFCE8F0);

  // Accent: the logo teal, deepened for contrast.
  static const accent = Color(0xFF237A7A);
  static const accentDark = Color(0xFF175A5A);
  static const accentTint = Color(0xFFE3F3F3);

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAF7F8);
  static const text = Color(0xFF1F1A1C);
  static const muted = Color(0xFF6E6468);
  static const border = Color(0xFFEDE4E8);

  static const success = Color(0xFF0E9F6E);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);

  // Dark theme surfaces.
  static const darkBackground = Color(0xFF141012);
  static const darkSurface = Color(0xFF1E181B);
  static const darkBorder = Color(0xFF362C31);
  static const darkText = Color(0xFFF0E8EB);
  static const darkMuted = Color(0xFFB3A6AB);
  static const darkPrimary = Color(0xFFF28AB0);
}
