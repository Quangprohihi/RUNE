import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

/// The "you earned it!" moment.
///
/// Drops a full-screen confetti burst behind a reward card that pops in with a
/// springy bounce, then auto-dismisses. Hand-rolled with a [CustomPainter] so
/// it needs zero extra packages. Call it the instant a claim succeeds:
///
/// ```dart
/// RewardCelebration.show(context, title: 'Daily Login', tokens: 20, diamonds: 1);
/// ```
class RewardCelebration {
  const RewardCelebration._();

  static void show(
    BuildContext context, {
    required String title,
    int tokens = 0,
    int diamonds = 0,
    int exp = 0,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationView(
        title: title,
        tokens: tokens,
        diamonds: diamonds,
        exp: exp,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _CelebrationView extends StatefulWidget {
  const _CelebrationView({
    required this.title,
    required this.tokens,
    required this.diamonds,
    required this.exp,
    required this.onDismiss,
  });

  final String title;
  final int tokens;
  final int diamonds;
  final int exp;
  final VoidCallback onDismiss;

  @override
  State<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<_CelebrationView>
    with TickerProviderStateMixin {
  late final AnimationController _burst; // confetti flight
  late final AnimationController _pop; // reward card bounce-in
  late final List<_Confetto> _confetti;
  bool _visible = true;

  static const _palette = [
    Color(0xFFFFC857),
    Color(0xFFFF7B9C),
    Color(0xFF68C7BF),
    Color(0xFF3A9BBE),
    Color(0xFF8AE08A),
    Color(0xFFFFE066),
  ];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _confetti = List.generate(46, (_) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.5;
      final speed = 240 + rnd.nextDouble() * 360;
      return _Confetto(
        angle: angle,
        speed: speed,
        color: _palette[rnd.nextInt(_palette.length)],
        size: 7 + rnd.nextDouble() * 9,
        rotation: rnd.nextDouble() * math.pi * 2,
        rotationSpeed: (rnd.nextDouble() - 0.5) * 12,
        isCircle: rnd.nextBool(),
        spawnX: 0.5 + (rnd.nextDouble() - 0.5) * 0.25,
      );
    });

    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2200), _close);
  }

  void _close() {
    if (!mounted || !_visible) return;
    setState(() => _visible = false);
    Future.delayed(const Duration(milliseconds: 280), widget.onDismiss);
  }

  @override
  void dispose() {
    _burst.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        child: Material(
          color: Colors.black.withValues(alpha: 0.28),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _burst.value,
                      confetti: _confetti,
                      durationSec: 1.7,
                    ),
                  ),
                ),
              ),
              Center(child: _buildCard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final pop = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);
    return ScaleTransition(
      scale: Tween<double>(begin: 0.4, end: 1).animate(pop),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.brXl,
          boxShadow: AppShadows.reward,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BadgePop(controller: _pop),
            const SizedBox(height: 16),
            Text(
              'Reward unlocked!',
              style: AppTextStyles.title.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.muted.copyWith(
                color: AppColors.accentSky,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.tokens > 0)
                  _RewardTally(
                    icon: Icons.emoji_events,
                    color: AppColors.warning,
                    value: widget.tokens,
                  ),
                if (widget.diamonds > 0)
                  _RewardTally(
                    icon: Icons.diamond,
                    color: AppColors.accentSky,
                    value: widget.diamonds,
                  ),
                if (widget.exp > 0)
                  _RewardTally(
                    icon: Icons.auto_awesome,
                    color: AppColors.success,
                    value: widget.exp,
                    suffix: 'XP',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The gold medal that scales + spins slightly as it lands.
class _BadgePop extends StatelessWidget {
  const _BadgePop({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(controller.value);
        return Transform.rotate(angle: (1 - t) * 0.6, child: child);
      },
      child: Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE39A), Color(0xFFF6A53A)],
          ),
        ),
        child: const Icon(
          Icons.emoji_events_rounded,
          color: Colors.white,
          size: 46,
        ),
      ),
    );
  }
}

class _RewardTally extends StatelessWidget {
  const _RewardTally({
    required this.icon,
    required this.color,
    required this.value,
    this.suffix,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            '+$value${suffix != null ? ' $suffix' : ''}',
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// One piece of confetti, launched from near the top-center and pulled down by
/// gravity over the burst.
class _Confetto {
  _Confetto({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
    required this.spawnX,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final bool isCircle;
  final double spawnX; // fraction of width where it starts
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.confetti,
    required this.durationSec,
  });

  final double progress;
  final List<_Confetto> confetti;
  final double durationSec;

  static const double _gravity = 900; // px / s^2

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * durationSec;
    final originY = size.height * 0.4;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final c in confetti) {
      final dx = math.cos(c.angle) * c.speed * t;
      final dy = math.sin(c.angle) * c.speed * t + 0.5 * _gravity * t * t;
      final pos = Offset(c.spawnX * size.width + dx, originY + dy);

      // Fade out over the final third of the flight.
      final opacity = progress < 0.7
          ? 1.0
          : (1 - (progress - 0.7) / 0.3).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      paint.color = c.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(c.rotation + c.rotationSpeed * t);
      if (c.isCircle) {
        canvas.drawCircle(Offset.zero, c.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.6),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
