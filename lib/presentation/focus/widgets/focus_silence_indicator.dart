import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class FocusSilenceIndicator extends StatelessWidget {
  const FocusSilenceIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.accentSky),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 16,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 6),
            Text(
              'Notifications silenced',
              style: AppTextStyles.muted.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
