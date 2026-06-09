import 'package:flutter/widgets.dart';

/// Spacing scale for the whole app.
///
/// Use these instead of hard-coded `SizedBox`/`EdgeInsets` numbers so every
/// screen breathes with the same rhythm. The scale is a soft 4pt grid:
/// 4 · 8 · 12 · 16 · 24 · 32 · 40.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Default horizontal screen gutter (left/right page padding).
  static const double pageGutter = 20;

  // --- Vertical gap helpers (drop straight into a Column/Row) ---
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  // --- Horizontal gap helpers ---
  static const SizedBox wGapXs = SizedBox(width: xs);
  static const SizedBox wGapSm = SizedBox(width: sm);
  static const SizedBox wGapMd = SizedBox(width: md);
  static const SizedBox wGapLg = SizedBox(width: lg);
}
