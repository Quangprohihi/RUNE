import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/pet_animated_widget.dart';

class FocusPartnerPanel extends StatelessWidget {
  const FocusPartnerPanel({
    super.key,
    required this.petName,
    required this.imagePath,
    required this.phrase,
    required this.petState,
  });

  final String petName;
  final String imagePath;
  final String phrase;
  final PetAnimationState petState;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 32,
            right: 0,
            top: 14,
            child: Container(
              height: 60,
              padding: const EdgeInsets.only(left: 60, right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.accentSky),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Partner',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 20,
                      color: AppColors.accentSky,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      phrase,
                      key: ValueKey(phrase),
                      style: AppTextStyles.muted.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: PetAnimatedWidget(
                imagePath: imagePath,
                width: 72,
                state: petState,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
