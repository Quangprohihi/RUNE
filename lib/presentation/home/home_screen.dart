import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/focus_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<TokenProvider>().tokens;
    final streak = context.watch<StreakProvider>().streak;
    final focus = context.watch<FocusProvider>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 402;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD7F6F4), Color(0xFFE5FFD2)],
              ),
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.accentTeal),
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: 24 * scale,
                    top: 20,
                    child: _StreakBadge(streak: streak),
                  ),
                  Positioned(
                    left: 28 * scale,
                    top: 116,
                    child: Transform.rotate(
                      angle: 0.18,
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 42,
                        color: AppColors.accentSky,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 23 * scale,
                    top: 28,
                    child: Column(
                      children: [
                        const _Pill(icon: Icons.bolt, label: '5000'),
                        const SizedBox(height: 10),
                        _Pill(icon: Icons.add_circle_outline, label: '$tokens'),
                        const SizedBox(height: 10),
                        const _Pill(icon: Icons.diamond, label: '20'),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 96 * scale,
                    right: 96 * scale,
                    top: 198,
                    child: _TimerCard(
                      title: 'Remaining time',
                      value: focus.isRunning
                          ? focus.formattedRemaining
                          : '00:20:15',
                    ),
                  ),
                  Positioned(
                    left: 10 * scale,
                    right: 8 * scale,
                    top: 282,
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.pet),
                      child: _Habitat(scale: scale),
                    ),
                  ),
                  Positioned(
                    left: 28 * scale,
                    bottom: 128,
                    child: _RoundIconButton(
                      icon: Icons.camera_alt_outlined,
                      onTap: () => _showComingSoon(context, 'Camera'),
                    ),
                  ),
                  Positioned(
                    right: 26 * scale,
                    bottom: 126,
                    child: _RoundIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => _showComingSoon(context, 'Settings'),
                    ),
                  ),
                  Positioned(
                    left: 21 * scale,
                    right: 21 * scale,
                    bottom: 18,
                    child: _BottomNav(
                      onFocus: () =>
                          Navigator.of(context).pushNamed(AppRoutes.focus),
                      onShop: () =>
                          Navigator.of(context).pushNamed(AppRoutes.shop),
                      onTasks: () => _showComingSoon(context, 'Daily tasks'),
                      onPro: () => _showComingSoon(context, 'Go Pro'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('This feature is planned for the next checkpoint.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$streak',
          style: AppTextStyles.heading.copyWith(
            fontSize: 64,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFFFB0BE),
          child: Text('🔥', style: TextStyle(fontSize: 24)),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.accentSky),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.accentTeal, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x665A9CAE),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(color: AppColors.primaryBlue),
          ),
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              fontSize: 28,
              fontStyle: FontStyle.italic,
              color: const Color(0xFFBCE7EB),
              shadows: const [
                Shadow(color: AppColors.primaryBlue, offset: Offset(1, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Habitat extends StatelessWidget {
  const _Habitat({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 455,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6 * scale,
            right: 6 * scale,
            top: 0,
            child: Image.asset(
              'assets/images/home_scene.png',
              height: 430,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.onFocus,
    required this.onShop,
    required this.onTasks,
    required this.onPro,
  });

  final VoidCallback onFocus;
  final VoidCallback onShop;
  final VoidCallback onTasks;
  final VoidCallback onPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFF9CD0C8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(4, 0)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.timer_outlined,
            label: 'Set timer',
            onTap: onFocus,
          ),
          _NavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Shop',
            onTap: onShop,
          ),
          _NavItem(icon: Icons.task_alt, label: 'Tasks', onTap: onTasks),
          _NavItem(
            icon: Icons.local_offer_outlined,
            label: 'Go Pro',
            onTap: onPro,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 38),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.muted.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          width: 58,
          child: Icon(icon, size: 34, color: AppColors.accentSky),
        ),
      ),
    );
  }
}
