import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/local/prefs_keys.dart';
import '../../models/pet.dart';
import '../../providers/focus_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../onboarding/onboarding_screen.dart';

part 'widgets/home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _revealHeader;
  late Animation<double> _revealResources;
  late Animation<double> _revealHero;
  late Animation<double> _revealCta;
  late Animation<double> _revealNav;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    Animation<double> stage(double start, double end) {
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    }

    _revealHeader = stage(0.0, 0.45);
    _revealResources = stage(0.12, 0.55);
    _revealHero = stage(0.28, 0.72);
    _revealCta = stage(0.45, 0.9);
    _revealNav = stage(0.6, 1.0);

    // Start entrance animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      _loadBootstrap();
      _maybeShowOnboarding();
    });
  }

  /// On the very first run, greet the user with the onboarding carousel. Pushed
  /// over Home (not part of root routing) so it can never disrupt Login/Home.
  Future<void> _maybeShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PrefsKeys.onboardingSeen) ?? false) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
    );
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

  /// Reveal helper: fades [child] in and floats it up a touch, driven by [t].
  Widget _reveal(Animation<double> t, Widget child) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, inner) => Opacity(
        opacity: t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t.value) * 18),
          child: inner,
        ),
      ),
      child: child,
    );
  }

  /// Slide-only reveal (no `Opacity`). The habitat hero wraps a large image and
  /// several `Transform` layers; pushing it through an `Opacity` saveLayer
  /// triggers a red compositing artifact under the Impeller engine, so we
  /// animate position only and let it fade via the slide.
  Widget _slideReveal(Animation<double> t, Widget child) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, inner) => Transform.translate(
        offset: Offset(0, (1 - t.value.clamp(0.0, 1.0)) * 24),
        child: inner,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final wallet = context.watch<TokenProvider>();
    final streak = context.watch<StreakProvider>().streak;
    final focus = context.watch<FocusProvider>();
    final pet = context.watch<PetProvider>().pet;
    final owned = context.watch<ShopProvider>().ownedCompanionCodes;

    final firstName = _firstName(user.profile.displayName);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDF7F4), Color(0xFFEAFFD9)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Cap the habitat hero to a fraction of the viewport so the
              // "Today's Goal" card stays visible above the bottom nav instead
              // of being pushed off-screen by a fixed-height island.
              final heroHeight = (constraints.maxHeight * 0.42).clamp(
                300.0,
                430.0,
              );

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          _reveal(
                            _revealHeader,
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.pageGutter,
                              ),
                              child: _GreetingHeader(
                                greeting: _timeGreeting(),
                                name: firstName,
                                streak: streak,
                                onStreak: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.history),
                                onMail: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.notifications),
                                onSettings: () => _showSettingsMenu(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _reveal(
                            _revealResources,
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.pageGutter,
                              ),
                              child: _ResourceBar(
                                energy: wallet.energy,
                                coins: wallet.tokens,
                                diamonds: wallet.diamonds,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _slideReveal(
                            _revealHero,
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  Navigator.of(context).pushNamed(AppRoutes.pet),
                              child: SizedBox(
                                height: heroHeight,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: 402,
                                    height: 455,
                                    child: _HabitatHero(
                                      scale: 1,
                                      kikiAssetPath: pet.skinAssetPath,
                                      ownedCompanions: owned,
                                      message: _kikiMessage(pet, streak, focus),
                                      petName: pet.name,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _reveal(
                            _revealCta,
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.pageGutter,
                              ),
                              child: _PrimaryFocusButton(
                                focus: focus,
                                onTap: () => _openTimerFlow(context, focus),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _reveal(
                            _revealCta,
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.pageGutter,
                              ),
                              child: _DailyGoalCard(focus: focus),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _reveal(
                    _revealNav,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageGutter,
                        AppSpacing.sm,
                        AppSpacing.pageGutter,
                        AppSpacing.md,
                      ),
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
              );
            },
          ),
        ),
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
                right: 20,
                top: 70,
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
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting / personalization helpers
// ---------------------------------------------------------------------------

String _firstName(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return 'Friend';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _timeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

/// What Kiki says in the speech bubble — personalised by streak, pet care
/// state and whether a session is already running. This is the emotional hook
/// the moment Home opens.
String _kikiMessage(Pet pet, int streak, FocusProvider focus) {
  if (focus.isRunning) return "We're focusing — keep going! ✨";
  if (streak >= 2) return "$streak-day streak! Don't break it 🔥";
  if (pet.hunger < 35) return "I'm getting a little hungry… 🥺";
  if (pet.mood < 35) return "Let's do something fun today!";
  if (pet.love < 35) return 'I missed you! 💛';
  return 'Ready to focus with me? 🦊';
}
