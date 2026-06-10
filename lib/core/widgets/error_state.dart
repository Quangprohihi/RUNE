import 'package:flutter/material.dart';

import '../errors/friendly_error.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Reusable error panel shown when a data fetch fails. Renders a friendly,
/// already-mapped message (pass the raw provider error — it's cleaned here) and
/// an optional Retry action. Use this instead of dumping `provider.error!` into
/// a red Text so users never see raw exceptions.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.error,
    this.title = 'Something went wrong',
    this.icon = Icons.cloud_off_rounded,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.compact = false,
  });

  /// The raw error (Object/String/null) — mapped to friendly copy via
  /// [friendlyError].
  final Object? error;
  final String title;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  /// When true, renders a tighter inline version (for use under a list rather
  /// than as a full-screen centerpiece).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final message = friendlyError(error);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: compact ? 28 : 44, color: AppColors.accentSky),
        AppSpacing.gapSm,
        if (!compact) ...[
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
          AppSpacing.gapXs,
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.muted.copyWith(height: 1.35),
        ),
        if (onRetry != null) ...[
          AppSpacing.gapMd,
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(retryLabel),
          ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
        child: content,
      ),
    );
  }
}
