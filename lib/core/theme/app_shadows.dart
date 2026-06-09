import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Elevation tokens. Cards in a study app should feel like they gently float
/// above the soft background — so we use a slightly blue-tinted, two-layer
/// shadow (a tight contact shadow + a soft ambient one) instead of flat black.
/// This reads far more premium than a single hard `Colors.black` drop.
class AppShadows {
  const AppShadows._();

  static Color get _tint => AppColors.primaryBlue;

  /// Resting card elevation — most cards on a page.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: _tint.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  /// Raised elements — sheets, highlighted/claimable cards, FABs.
  static List<BoxShadow> get raised => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: _tint.withValues(alpha: 0.12),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
  ];

  /// A warm glow for reward / celebration states (gold-tinted).
  static List<BoxShadow> get reward => [
    BoxShadow(
      color: const Color(0xFFF6A53A).withValues(alpha: 0.28),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
