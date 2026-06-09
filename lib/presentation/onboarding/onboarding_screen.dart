import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/local/prefs_keys.dart';

/// First-run welcome carousel.
///
/// Shown exactly once (the seen-flag is written the moment it appears, so any
/// exit — finish, skip, or back — counts). It turns the "all zeros" first Home
/// into a warm, guided start: meet Kiki, learn the loop, then jump into the
/// first focus session. Pushed over Home by [HomeScreen] so it can never
/// interfere with the Login/Home root routing.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_OnbPageData>[
    _OnbPageData(
      image: 'assets/images/fox.png',
      accent: Color(0xFFF6A53A),
      title: 'Meet Kiki 🦊',
      body:
          'Your focus buddy lives on a little floating island. '
          'The more you focus, the happier and stronger Kiki grows.',
    ),
    _OnbPageData(
      image: 'assets/images/home_habitat_figma.png',
      accent: Color(0xFF42A779),
      title: 'Focus to grow your world',
      body:
          'Every focus session earns tokens and EXP — unlock new friends '
          'and bring your island to life, one session at a time.',
    ),
    _OnbPageData(
      image: 'assets/images/achievement_medal.png',
      accent: Color(0xFF3A9BBE),
      title: 'Build streaks, earn rewards',
      body:
          'Study a little every day to keep your streak 🔥 alive, claim daily '
          'tasks and collect badges as you go.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Mark as seen immediately so it shows exactly once, regardless of how the
    // user leaves (Get started, Skip, or the system back button).
    _markSeen();
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.onboardingSeen, true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pages.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDF7F4), Color(0xFFEAFFD9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.sm,
                    top: AppSpacing.sm,
                  ),
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryBlue.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _OnbPage(data: _pages[i]),
                ),
              ),
              _Dots(count: _pages.length, active: _page),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageGutter,
                  0,
                  AppSpacing.pageGutter,
                  AppSpacing.lg,
                ),
                child: _PrimaryButton(
                  label: _isLast ? 'Get started' : 'Next',
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnbPageData {
  const _OnbPageData({
    required this.image,
    required this.accent,
    required this.title,
    required this.body,
  });

  final String image;
  final Color accent;
  final String title;
  final String body;
}

class _OnbPage extends StatelessWidget {
  const _OnbPage({required this.data});

  final _OnbPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.55),
              boxShadow: [
                BoxShadow(
                  color: data.accent.withValues(alpha: 0.22),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Image.asset(data.image, fit: BoxFit.contain),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primaryBlue.withValues(alpha: 0.7),
              height: 1.45,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accentTeal
                : AppColors.primaryBlue.withValues(alpha: 0.18),
            borderRadius: AppRadius.brPill,
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brXl,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF68C7BF), Color(0xFF3A9BBE)],
            ),
            borderRadius: AppRadius.brXl,
            boxShadow: AppShadows.raised,
          ),
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
