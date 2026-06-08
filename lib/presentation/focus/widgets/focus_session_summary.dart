import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/focus_provider.dart';

class FocusSessionSummary extends StatelessWidget {
  const FocusSessionSummary({super.key, required this.focus});

  final FocusProvider focus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              focus.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: const Color(0xFF1D293D),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            focus.pomodoroLabel,
            style: AppTextStyles.muted.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
