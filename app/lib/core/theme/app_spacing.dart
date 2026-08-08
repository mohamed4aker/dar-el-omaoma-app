/// The 8pt spacing grid from PROMPT.md section 2.4.
///
/// Only these values may be used for padding, margins and gaps. Anything else
/// is a design bug.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

abstract final class Radii {
  static const card = 12.0;
  static const input = 8.0;
  static const pill = 999.0;
}

/// Minimum touch target, per PROMPT.md section 2.4 and WCAG 2.2 AA.
const double kMinTouchTarget = 44.0;
