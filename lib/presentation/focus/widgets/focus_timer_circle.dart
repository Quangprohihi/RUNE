import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

class FocusTimerCircle extends StatelessWidget {
  const FocusTimerCircle({
    super.key,
    required this.progress,
    required this.text,
    required this.subtitle,
    required this.ringColorAnim,
  });

  final double progress;
  final String text;
  final String subtitle;
  final Animation<Color?> ringColorAnim;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: AnimatedBuilder(
              animation: ringColorAnim,
              builder: (context, _) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: progress <= 0 ? 0.78 : progress.clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 16,
                      backgroundColor: Colors.white,
                      color: ringColorAnim.value ?? const Color(0xFF41B8D5),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            height: 152,
            width: 152,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 64,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: FittedBox(
                      key: ValueKey(text),
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextStyles.heading.copyWith(
                          fontSize: text.contains(':') ? 42 : 54,
                          height: 1,
                          color: const Color(0xFF6CE5E8),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFF41B8D5),
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
