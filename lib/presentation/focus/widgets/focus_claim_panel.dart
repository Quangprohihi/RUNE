import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class FocusClaimPanel extends StatelessWidget {
  const FocusClaimPanel({
    super.key,
    required this.canClaim,
    required this.rewardTokens,
    required this.rewardExp,
    required this.onClaim,
  });

  final bool canClaim;
  final int rewardTokens;
  final int rewardExp;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(16, 8),
          child: Text(
            'Claim',
            style: AppTextStyles.heading.copyWith(
              fontSize: 24,
              color: AppColors.accentSky,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: canClaim ? AppColors.success : AppColors.primaryBlue,
              width: canClaim ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: canClaim
                ? const [
                    BoxShadow(
                      color: Color(0x3342A779),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.warning,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+$rewardTokens',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.success,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$rewardExp EXP',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'after finish',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryBlue,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedScale(
                scale: canClaim ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: canClaim ? onClaim : null,
                  child: Text(
                    canClaim ? 'Claim reward' : 'Finish focus to claim',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
