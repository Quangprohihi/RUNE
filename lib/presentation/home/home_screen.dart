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
import '../pet/pet_profile_screen.dart';

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

  /// Greets each account's first visit with the onboarding carousel. The
  /// seen-flag is keyed per user id so a brand-new account on a shared device
  /// still gets it, while returning accounts never see it twice. Pushed over
  /// Home (not part of root routing) so it can never disrupt Login/Home.
  Future<void> _maybeShowOnboarding() async {
    // Capture the id before any await: a concurrently failing bootstrap can
    // clear the session, and a guest id must never key the seen-flag.
    final userId = context.read<UserProvider>().profile.id;
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PrefsKeys.onboardingSeenFor(userId)) ?? false) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(userId: userId),
      ),
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

  /// Slide-only reveal (no `Opacity`). The island hero wraps large images and
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

  void _openPet(BuildContext context, String petId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PetProfileScreen(petId: petId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final wallet = context.watch<TokenProvider>();
    final streak = context.watch<StreakProvider>().streak;
    final focus = context.watch<FocusProvider>();
    final petProvider = context.watch<PetProvider>();
    final shop = context.watch<ShopProvider>();
    final activePet = petProvider.pet;
    // Only pets the user actually owns live on the island: Kiki (active) is
    // always here; companions appear once they're unlocked/bought in the shop.
    final pets = petProvider.pets
        .where(
          (p) =>
              p.id == activePet.id ||
              shop.isCompanionUnlocked(_companionCodeForPet(p)),
        )
        .toList();

    final firstName = _firstName(user.profile.displayName);

    return Scaffold(
      body: Stack(
        children: [
          // Sky + drifting clouds fill the whole screen behind everything.
          const Positioned.fill(child: _CloudBackground()),
          SafeArea(
            child: Column(
              children: [
                // --- Top HUD: greeting + resource pills ---
                _reveal(
                  _revealHeader,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageGutter,
                      AppSpacing.sm,
                      AppSpacing.pageGutter,
                      0,
                    ),
                    child: _GreetingHeader(
                      greeting: _timeGreeting(),
                      name: firstName,
                      streak: streak,
                      onStreak: () =>
                          Navigator.of(context).pushNamed(AppRoutes.history),
                      onMail: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.notifications),
                      onSettings: () => _showSettingsMenu(context),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
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

                // --- Island map: 4 pet slots + floating shop island ---
                Expanded(
                  child: _slideReveal(
                    _revealHero,
                    _IslandScene(
                      pets: pets,
                      activePetId: activePet.id,
                      message: _kikiMessage(activePet, streak, focus),
                      onPetTap: (id) => _openPet(context, id),
                      onShopTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.shop),
                    ),
                  ),
                ),

                // --- Bottom HUD: focus CTA + daily goal + nav ---
                _reveal(
                  _revealCta,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageGutter,
                      0,
                      AppSpacing.pageGutter,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PrimaryFocusButton(
                          focus: focus,
                          onTap: () => _openTimerFlow(context, focus),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DailyGoalStrip(focus: focus),
                      ],
                    ),
                  ),
                ),
                _reveal(
                  _revealNav,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageGutter,
                      0,
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
            ),
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

/// Maps a roster pet to its shop companion code via its sprite asset
/// (assets/images/companion_eagle.png → companion_eagle). Returns '' for the
/// fox/active pet, which has no companion code and is always on the island.
String _companionCodeForPet(Pet pet) {
  final asset = pet.assetPath;
  if (asset == null) return '';
  return asset.split('/').last.replaceAll('.png', '');
}

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
