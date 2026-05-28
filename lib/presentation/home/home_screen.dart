import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/focus_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<Offset> _streakSlide;
  late Animation<double> _pillFade1;
  late Animation<double> _pillFade2;
  late Animation<double> _pillFade3;
  late Animation<Offset> _timerSlide;
  late Animation<double> _navFade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _streakSlide = Tween<Offset>(begin: const Offset(-1.4, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );

    _pillFade1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );
    _pillFade2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );
    _pillFade3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );

    _timerSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
          ),
        );

    _navFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start entrance animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      _loadBootstrap();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadBootstrap() async {
    final user = context.read<UserProvider>();
    await user.refreshBootstrap();
    if (!mounted) return;
    final wallet = user.latestWallet;
    final pet = user.latestPet;
    if (wallet != null) context.read<TokenProvider>().syncWallet(wallet);
    if (pet != null) context.read<PetProvider>().syncPet(pet);
    context.read<StreakProvider>().syncFromJson(user.latestStreak);
    await context.read<ShopProvider>().loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<TokenProvider>();
    final tokens = wallet.tokens;
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
                  // --- Streak badge (slide from left) ---
                  Positioned(
                    left: 24 * scale,
                    top: 20,
                    child: SlideTransition(
                      position: _streakSlide,
                      child: _StreakBadge(streak: streak),
                    ),
                  ),

                  // --- Mail icon ---
                  Positioned(
                    left: 28 * scale,
                    top: 116,
                    child: SlideTransition(
                      position: _streakSlide,
                      child: GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.notifications),
                        child: Transform.rotate(
                          angle: 0.18,
                          child: const Icon(
                            Icons.mark_email_unread_outlined,
                            size: 42,
                            color: AppColors.accentSky,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Resource pills (staggered fade in) ---
                  Positioned(
                    right: 23 * scale,
                    top: 28,
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _pillFade1,
                          child: _Pill(
                            icon: Icons.bolt,
                            label: '${wallet.energy}',
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _pillFade2,
                          child: _Pill(
                            icon: Icons.add_circle_outline,
                            label: '$tokens',
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _pillFade3,
                          child: _Pill(
                            icon: Icons.diamond,
                            label: '${wallet.diamonds}',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Timer card (slide from below) ---
                  Positioned(
                    left: 96 * scale,
                    right: 96 * scale,
                    top: 198,
                    child: SlideTransition(
                      position: _timerSlide,
                      child: FadeTransition(
                        opacity: _pillFade2,
                        child: _TimerCard(
                          title: 'Remaining time',
                          value: focus.isRunning
                              ? focus.formattedRemaining
                              : '00:00:00',
                          onTap: () => _openTimerFlow(context, focus),
                        ),
                      ),
                    ),
                  ),

                  // --- Habitat with animated Kiki ---
                  Positioned(
                    left: 10 * scale,
                    right: 8 * scale,
                    top: 282,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.pet),
                      child: _Habitat(
                        scale: scale,
                        ownedCompanions: context
                            .watch<ShopProvider>()
                            .ownedCompanionCodes,
                      ),
                    ),
                  ),

                  // --- Camera button ---
                  Positioned(
                    left: 28 * scale,
                    bottom: 128,
                    child: _RoundIconButton(
                      icon: Icons.camera_alt_outlined,
                      onTap: () => _showComingSoon(context, 'Camera'),
                    ),
                  ),

                  // --- Settings button ---
                  Positioned(
                    right: 26 * scale,
                    bottom: 126,
                    child: _RoundIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => _showSettingsMenu(context),
                    ),
                  ),

                  // --- Bottom nav (fade in last) ---
                  Positioned(
                    left: 21 * scale,
                    right: 21 * scale,
                    bottom: 18,
                    child: FadeTransition(
                      opacity: _navFade,
                      child: _BottomNav(
                        onFocus: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.setFocusTimer),
                        onShop: () =>
                            Navigator.of(context).pushNamed(AppRoutes.shop),
                        onTasks: () =>
                            Navigator.of(context).pushNamed(AppRoutes.tasks),
                        onPro: () =>
                            Navigator.of(context).pushNamed(AppRoutes.premium),
                      ),
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

  void _openTimerFlow(BuildContext context, FocusProvider focus) {
    final route = focus.phase == FocusPhase.idle
        ? AppRoutes.setFocusTimer
        : AppRoutes.focus;
    Navigator.of(context).pushNamed(route);
  }

  void _showSettingsMenu(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, _) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                right: 26,
                bottom: 198,
                child: Material(
                  color: Colors.transparent,
                  child: _SettingsMenuCard(
                    onSetting: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pushNamed(AppRoutes.settings);
                    },
                    onLogin: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pushNamed(AppRoutes.login);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Habitat widget – background scene + animated Kiki overlay
// ---------------------------------------------------------------------------

class _Habitat extends StatelessWidget {
  const _Habitat({required this.scale, required this.ownedCompanions});

  final double scale;
  final List<String> ownedCompanions;

  @override
  Widget build(BuildContext context) {
    final hasEagle = ownedCompanions.contains('companion_eagle');
    final hasFrog = ownedCompanions.contains('companion_frog');
    final hasGiraffe = ownedCompanions.contains('companion_giraffe');

    return SizedBox(
      height: 455,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 1 * scale,
            top: 1,
            child: Image.asset(
              'assets/images/home_habitat_figma.png',
              width: 376.205 * scale,
              height: 440.433,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 250.25 * scale,
            top: 94.37,
            child: Image.asset(
              'assets/images/fox.png',
              width: 81.852 * scale,
              height: 102.324,
              fit: BoxFit.contain,
            ),
          ),
          if (hasEagle)
            Positioned(
              left: 89.76 * scale,
              top: 24,
              child: _IslandAnimalLayer(
                assetPath: 'assets/images/companion_eagle.png',
                width: 68.373 * scale,
                height: 85.457,
              ),
            ),
          if (hasFrog)
            Positioned(
              left: 175.48 * scale,
              top: 123.77,
              child: _IslandAnimalLayer(
                assetPath: 'assets/images/companion_frog.png',
                width: 62.969 * scale,
                height: 78.711,
              ),
            ),
          if (hasGiraffe)
            Positioned(
              left: 53.25 * scale,
              top: 156.73,
              child: _IslandAnimalLayer(
                assetPath: 'assets/images/companion_giraffe.png',
                width: 116.942 * scale,
                height: 146.177,
              ),
            ),
        ],
      ),
    );
  }
}

class _IslandAnimalLayer extends StatelessWidget {
  const _IslandAnimalLayer({
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

// ---------------------------------------------------------------------------
// Streak badge
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Resource pill
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Timer card with AnimatedSwitcher for smooth digit transitions
// ---------------------------------------------------------------------------

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      shadowColor: const Color(0x665A9CAE),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accentTeal, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFBCE7EB),
                    shadows: const [
                      Shadow(
                        color: AppColors.primaryBlue,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Round icon button
// ---------------------------------------------------------------------------

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

class _SettingsMenuCard extends StatelessWidget {
  const _SettingsMenuCard({required this.onSetting, required this.onLogin});

  final VoidCallback onSetting;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SettingsMenuButton(label: 'Setting', onTap: onSetting),
          const SizedBox(height: 8),
          _SettingsMenuButton(label: 'Log in', onTap: onLogin),
          const SizedBox(height: 8),
          _SettingsMenuButton(label: 'Sign in', onTap: onLogin),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _SettingsSoundButton(icon: Icons.music_note),
              SizedBox(width: 10),
              _SettingsSoundButton(icon: Icons.volume_up),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuButton extends StatelessWidget {
  const _SettingsMenuButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF8AD8D0),
          foregroundColor: AppColors.primaryBlue,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: AppTextStyles.muted.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SettingsSoundButton extends StatelessWidget {
  const _SettingsSoundButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFF8AD8D0),
      child: Icon(icon, color: AppColors.primaryBlue, size: 16),
    );
  }
}
