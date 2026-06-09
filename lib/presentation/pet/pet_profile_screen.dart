import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/achievement_progress.dart';
import '../../models/pet.dart';
import '../../models/pet_evolution.dart';
import '../../models/shop_item.dart';
import '../../providers/activity_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/token_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/floating_particles.dart';
import '../widgets/pet_animated_widget.dart';

part 'widgets/pet_profile_widgets.dart';

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen>
    with SingleTickerProviderStateMixin {
  // Entrance animation controller
  late AnimationController _entranceController;
  late Animation<Offset> _skillSlide;
  late Animation<Offset> _statusSlide;
  late Animation<Offset> _achSlide;
  late Animation<double> _cardFade;

  // Pet state
  PetAnimationState _petState = PetAnimationState.idle;

  // Particle bursts per action button
  int _feedParticles = 0;
  int _playParticles = 0;
  int _petParticles = 0;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _skillSlide = Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
          ),
        );

    _statusSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
          ),
        );

    _achSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
          ),
        );

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );

    // Determine initial pet state
    final pet = context.read<PetProvider>().pet;
    _petState = _stateFromMood(pet.mood);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      context.read<AchievementProvider>().load();
      context.read<ShopProvider>().loadCatalog();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  PetAnimationState _stateFromMood(int mood) {
    if (mood < 30) return PetAnimationState.sad;
    if (mood >= 70) return PetAnimationState.idle;
    return PetAnimationState.idle;
  }

  void _triggerHappy() {
    setState(() => _petState = PetAnimationState.happy);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _petState = _stateFromMood(context.read<PetProvider>().pet.mood);
        });
      }
    });
  }

  void _showCareSheet(
    BuildContext context, {
    required String title,
    required Set<PetEffectType> effects,
    required void Function() onParticle,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _CareItemSheet(
          title: title,
          effects: effects,
          onUse: (item) =>
              _useCareItem(context, item: item, onParticle: onParticle),
        );
      },
    );
  }

  Future<void> _useCareItem(
    BuildContext context, {
    required ShopItem item,
    required void Function() onParticle,
  }) async {
    final pet = context.read<PetProvider>().pet;
    if (_statValueFor(pet, item.effectType) >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_effectLabel(item.effectType)} is already full.'),
        ),
      );
      return;
    }

    try {
      await context.read<ShopProvider>().useItem(
        item: item,
        pet: context.read<PetProvider>(),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    onParticle();
    _triggerHappy();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} used. Kiki feels better!')),
    );
  }

  void _showEvolutionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EvolutionPathSheet(onSelect: _selectEvolutionSkin),
    );
  }

  Future<void> _selectEvolutionSkin(
    BuildContext context,
    PetEvolution evolution,
  ) async {
    final petProvider = context.read<PetProvider>();
    if (!evolution.isUnlocked(petProvider.pet.level)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reach Lv ${evolution.unlockLevel} to unlock ${evolution.title}.',
          ),
        ),
      );
      return;
    }
    try {
      await petProvider.selectEvolutionSkin(evolution.code);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${evolution.title} selected.')));
  }

  void _showAchievementSheet(
    BuildContext context,
    AchievementProgress achievement,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _AchievementBottomSheet(achievement: achievement);
      },
    );
  }

  Future<void> _claimAchievement(BuildContext context) async {
    final achievementProvider = context.read<AchievementProvider>();
    final claimed = await achievementProvider.claimProductivePartner();
    if (!context.mounted) return;
    if (!claimed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            achievementProvider.error ?? 'Could not claim achievement yet.',
          ),
        ),
      );
      return;
    }

    final wallet = achievementProvider.latestWallet;
    final pet = achievementProvider.latestPet;
    if (wallet != null) context.read<TokenProvider>().syncWallet(wallet);
    if (pet != null) context.read<PetProvider>().syncPet(pet);
    await context.read<ActivityProvider>().load();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Achievement claimed! +100 tokens and +100 EXP.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>().pet;
    final achievementState = context.watch<AchievementProvider>();
    final achievement = achievementState.productivePartner;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 402;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFD2FAFF)],
              ),
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.accentTeal),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: 980,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // --- Back button ---
                      Positioned(
                        left: 28 * scale,
                        top: 22,
                        child: _CircleBackButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),

                      // --- Forest background ---
                      Positioned(
                        left: -26 * scale,
                        top: 194,
                        child: Opacity(
                          opacity: 0.72,
                          child: Image.asset(
                            'assets/images/profile_forest.png',
                            width: 238 * scale,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // --- Kiki fox: match Figma coordinates, fixed to the right side ---
                      Positioned(
                        left: 201 * scale,
                        top: 166,
                        child: Container(
                          width: 222 * scale,
                          height: 205,
                          decoration: const BoxDecoration(
                            color: Color(0x5E77BBD4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 186 * scale,
                        top: 92,
                        child: PetAnimatedWidget(
                          imagePath: pet.skinAssetPath,
                          width: 301 * scale,
                          state: _petState,
                          enableMotion: false,
                          onTap: _triggerHappy,
                        ),
                      ),
                      Positioned(
                        left: 236 * scale,
                        top: 170,
                        child: SizedBox(
                          width: 180 * scale,
                          height: 180,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              FloatingParticlesWidget(
                                trigger: _feedParticles,
                                emojis: const ['🍖', '🍎', '🐾'],
                                count: 8,
                                spread: 80,
                              ),
                              FloatingParticlesWidget(
                                trigger: _playParticles,
                                emojis: const ['⚽', '🎾', '✨'],
                                count: 8,
                                spread: 80,
                              ),
                              FloatingParticlesWidget(
                                trigger: _petParticles,
                                emojis: const ['❤️', '💖', '💕'],
                                count: 8,
                                spread: 80,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // --- Pet name, species, level, EXP bar ---
                      Positioned(
                        left: 30 * scale,
                        top: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pet.name,
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 40,
                                    color: const Color(0xFF61A628),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.accentSky,
                                  size: 30,
                                ),
                              ],
                            ),
                            Text(
                              pet.species,
                              style: AppTextStyles.label.copyWith(
                                color: const Color(0xFF289CA0),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'LV ${pet.level}',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 140 * scale,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: pet.expProgress),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOut,
                                builder: (context, value, _) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 9,
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFF77BBD4),
                                    backgroundColor: const Color(0xFFD9D9D9),
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              width: 140 * scale,
                              child: Text(
                                '${pet.exp}/${pet.expToNext} exp',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.muted.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _showEvolutionSheet(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.accentTeal,
                                  ),
                                ),
                                child: Text(
                                  'Evolution',
                                  style: AppTextStyles.muted.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- Skill card (slide from left) ---
                      Positioned(
                        left: 34 * scale,
                        top: 332,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _skillSlide,
                            child: _SkillCard(scale: scale),
                          ),
                        ),
                      ),

                      // --- Feed/Play/Pet action buttons ---
                      Positioned(
                        left: 30 * scale,
                        right: 30 * scale,
                        top: 410,
                        child: Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.local_dining,
                                label: 'Feed',
                                onTap: () => _showCareSheet(
                                  context,
                                  title: 'Feed Kiki',
                                  effects: {PetEffectType.hunger},
                                  onParticle: () =>
                                      setState(() => _feedParticles++),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.sports_soccer,
                                label: 'Play',
                                onTap: () => _showCareSheet(
                                  context,
                                  title: 'Play / Rest with Kiki',
                                  effects: {
                                    PetEffectType.mood,
                                    PetEffectType.energy,
                                  },
                                  onParticle: () =>
                                      setState(() => _playParticles++),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.pets,
                                label: 'Pet',
                                onTap: () => _showCareSheet(
                                  context,
                                  title: 'Care for Kiki',
                                  effects: {PetEffectType.love},
                                  onParticle: () =>
                                      setState(() => _petParticles++),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- Status card (animated bars, slide from below) ---
                      Positioned(
                        left: 32 * scale,
                        right: 32 * scale,
                        top: 490,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _statusSlide,
                            child: _StatusCard(
                              energy: pet.energy,
                              mood: pet.mood,
                              hunger: pet.hunger,
                              love: pet.love,
                            ),
                          ),
                        ),
                      ),

                      // --- Achievements card (slide from below) ---
                      Positioned(
                        left: 32 * scale,
                        right: 32 * scale,
                        top: 720,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _achSlide,
                            child: _AchievementsCard(
                              achievement: achievement,
                              isLoading: achievementState.isLoading,
                              isClaiming: achievementState.isClaiming,
                              onTap: () =>
                                  _showAchievementSheet(context, achievement),
                              onClaim: () => _claimAchievement(context),
                              onViewAll: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.achievements),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Back button
// ---------------------------------------------------------------------------
