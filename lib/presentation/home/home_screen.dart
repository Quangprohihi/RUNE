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

part 'widgets/home_widgets.dart';

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
    try {
      await context.read<ShopProvider>().loadCatalog();
    } catch (_) {
      // Keep Home usable when the backend database is not available.
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<TokenProvider>();
    final tokens = wallet.tokens;
    final streak = context.watch<StreakProvider>().streak;
    final focus = context.watch<FocusProvider>();
    final pet = context.watch<PetProvider>().pet;

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
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.history),
                        child: _StreakBadge(streak: streak),
                      ),
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
                    top: 184,
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

                  Positioned(
                    left: 42 * scale,
                    right: 42 * scale,
                    top: 272,
                    child: FadeTransition(
                      opacity: _pillFade3,
                      child: _DailyGoalCard(focus: focus),
                    ),
                  ),

                  // --- Habitat with animated Kiki ---
                  Positioned(
                    left: 10 * scale,
                    right: 8 * scale,
                    top: 336,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.pet),
                      child: _Habitat(
                        scale: scale,
                        kikiAssetPath: pet.skinAssetPath,
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
