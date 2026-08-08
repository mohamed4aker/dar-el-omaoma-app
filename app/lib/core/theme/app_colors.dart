import 'package:flutter/material.dart';

/// Brand palette for Dar El Omouma Hospital.
///
/// Values are derived from the hospital's signage and ambulance livery in the
/// client design deck. See PROMPT.md section 2.1 — these must be confirmed
/// against the official vector logo before production.
abstract final class AppColors {
  static const navy = Color(0xFF0B2E5C);
  static const navyDark = Color(0xFF071F3E);
  static const navyTint = Color(0xFFE8EEF6);

  static const pink = Color(0xFFE4327E);
  static const pinkDark = Color(0xFFB8215F);
  static const pinkTint = Color(0xFFFDE9F2);

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F7F9);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);

  static const success = Color(0xFF0E9F6E);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);

  // Dark theme surfaces.
  static const darkBackground = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkBorder = Color(0xFF2A313C);
  static const darkText = Color(0xFFE6EDF3);
  static const darkMuted = Color(0xFF9BA6B2);
}
