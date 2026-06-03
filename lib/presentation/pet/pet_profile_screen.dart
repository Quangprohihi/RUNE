import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
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

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentTeal,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          height: 34,
          width: 34,
          child: Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skill card
// ---------------------------------------------------------------------------

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135 * scale,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primaryBlue,
              fontSize: 12,
            ),
          ),
          Text(
            'Fast Learner',
            style: AppTextStyles.muted.copyWith(fontSize: 10),
          ),
          Text(
            '+5% EXP from focus',
            style: AppTextStyles.muted.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button with press scale feedback
// ---------------------------------------------------------------------------

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (context, child) =>
            Transform.scale(scale: _pressScale.value, child: child),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF289EA0), AppColors.primaryBlue],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _statValueFor(Pet pet, PetEffectType effectType) {
  return switch (effectType) {
    PetEffectType.energy => pet.energy,
    PetEffectType.mood => pet.mood,
    PetEffectType.hunger => pet.hunger,
    PetEffectType.love => pet.love,
  };
}

String _effectLabel(PetEffectType effectType) {
  return switch (effectType) {
    PetEffectType.energy => 'Energy',
    PetEffectType.mood => 'Mood',
    PetEffectType.hunger => 'Hunger',
    PetEffectType.love => 'Love',
  };
}

class _CareItemSheet extends StatelessWidget {
  const _CareItemSheet({
    required this.title,
    required this.effects,
    required this.onUse,
  });

  final String title;
  final Set<PetEffectType> effects;
  final ValueChanged<ShopItem> onUse;

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final pet = context.watch<PetProvider>().pet;
    final items = shop.ownedItemsForEffect(effects);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.title.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use items bought from ZenZoo Shop.',
              style: AppTextStyles.muted.copyWith(color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              _EmptyCareInventory(effects: effects)
            else
              ...items.map((item) {
                final statValue = _statValueFor(pet, item.effectType);
                final isFull = statValue >= 100;
                return _CareItemTile(
                  item: item,
                  quantity: shop.quantityFor(item.id),
                  isFull: isFull,
                  onUse: () {
                    if (isFull) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_effectLabel(item.effectType)} is already full.',
                          ),
                        ),
                      );
                      return;
                    }
                    onUse(item);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EmptyCareInventory extends StatelessWidget {
  const _EmptyCareInventory({required this.effects});

  final Set<PetEffectType> effects;

  @override
  Widget build(BuildContext context) {
    final labels = effects.map(_effectLabel).join(' / ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'No $labels item in inventory yet.',
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.shop);
              },
              child: const Text('Go to Shop'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareItemTile extends StatelessWidget {
  const _CareItemTile({
    required this.item,
    required this.quantity,
    required this.isFull,
    required this.onUse,
  });

  final ShopItem item;
  final int quantity;
  final bool isFull;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2F1EE)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.label),
                const SizedBox(height: 3),
                Text(
                  '+${item.effectValue} ${_effectLabel(item.effectType)} · x$quantity',
                  style: AppTextStyles.muted.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 82,
            height: 38,
            child: ElevatedButton(
              onPressed: onUse,
              child: Text(isFull ? 'Full' : 'Use'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionPathSheet extends StatefulWidget {
  const _EvolutionPathSheet({required this.onSelect});

  final Future<void> Function(BuildContext context, PetEvolution evolution)
  onSelect;

  @override
  State<_EvolutionPathSheet> createState() => _EvolutionPathSheetState();
}

class _EvolutionPathSheetState extends State<_EvolutionPathSheet> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final pet = context.read<PetProvider>().pet;
    final selectedIndex = petEvolutions.indexWhere(
      (evolution) => evolution.code == pet.selectedSkinCode,
    );
    _index = selectedIndex < 0 ? 0 : selectedIndex;
    _controller = PageController(initialPage: _index, viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= petEvolutions.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>().pet;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
        child: SizedBox(
          height: 440,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: petEvolutions.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  final evolution = petEvolutions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _EvolutionCard(
                      evolution: evolution,
                      pet: pet,
                      onSelect: () => widget.onSelect(context, evolution),
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                child: _EvolutionChevron(
                  icon: Icons.chevron_left,
                  enabled: _index > 0,
                  onTap: () => _goTo(_index - 1),
                ),
              ),
              Positioned(
                right: 0,
                child: _EvolutionChevron(
                  icon: Icons.chevron_right,
                  enabled: _index < petEvolutions.length - 1,
                  onTap: () => _goTo(_index + 1),
                ),
              ),
              Positioned(
                top: 8,
                right: 26,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF289CA0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({
    required this.evolution,
    required this.pet,
    required this.onSelect,
  });

  final PetEvolution evolution;
  final Pet pet;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final unlocked = evolution.isUnlocked(pet.level);
    final selected = pet.selectedSkinCode == evolution.code;
    final status = selected
        ? 'Selected'
        : unlocked
        ? 'Unlocked'
        : 'Reach Lv ${evolution.unlockLevel}';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFD1EBC1)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 34, 18, 18),
              child: Column(
                children: [
                  Text(
                    'EVOLUTION PATH',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    evolution.levelRange,
                    style: AppTextStyles.label.copyWith(
                      color: const Color(0xFF289CA0),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Opacity(
                      opacity: unlocked ? 1 : 0.72,
                      child: Image.asset(
                        evolution.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evolution.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title.copyWith(
                      color: const Color(0xFF287B7F),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unlocked ? evolution.flavor : status,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.muted.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: selected ? null : onSelect,
                      child: Text(status),
                    ),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 50,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionChevron extends StatelessWidget {
  const _EvolutionChevron({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: enabled ? onTap : null,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        disabledBackgroundColor: Colors.white54,
      ),
      icon: Icon(icon, color: AppColors.accentTeal, size: 30),
    );
  }
}

// ---------------------------------------------------------------------------
// Status card with animated bars
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.energy,
    required this.mood,
    required this.hunger,
    required this.love,
  });

  final int energy;
  final int mood;
  final int hunger;
  final int love;

  @override
  Widget build(BuildContext context) {
    return _FigmaCard(
      borderColor: AppColors.accentTeal,
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: AppTextStyles.title.copyWith(
              color: AppColors.primaryBlue,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _AnimatedStatBar(label: 'Energy', value: energy),
                    const SizedBox(height: 14),
                    _AnimatedStatBar(label: 'Hunger', value: hunger),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _AnimatedStatBar(label: 'Mood', value: mood),
                    const SizedBox(height: 14),
                    _AnimatedStatBar(label: 'Love', value: love),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated stat bar (TweenAnimationBuilder)
// ---------------------------------------------------------------------------

class _AnimatedStatBar extends StatelessWidget {
  const _AnimatedStatBar({required this.label, required this.value});

  final String label;
  final int value;

  Color _barColor() {
    if (value >= 70) return const Color(0xFF42A779);
    if (value >= 40) return const Color(0xFF77BBD4);
    return const Color(0xFFF6A53A);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(color: AppColors.primaryBlue),
            ),
            Text('$value%', style: AppTextStyles.muted.copyWith(fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value / 100),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (context, animValue, _) {
            return LinearProgressIndicator(
              value: animValue,
              minHeight: 9,
              borderRadius: BorderRadius.circular(8),
              color: _barColor(),
              backgroundColor: const Color(0xFFD9D9D9),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Achievements card
// ---------------------------------------------------------------------------

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard({
    required this.achievement,
    required this.isLoading,
    required this.isClaiming,
    required this.onTap,
    required this.onClaim,
  });

  final AchievementProgress achievement;
  final bool isLoading;
  final bool isClaiming;
  final VoidCallback onTap;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final subtitle = achievement.isClaimed
        ? 'Reward claimed'
        : achievement.canClaim
        ? 'Claim +${achievement.rewardTokens} tokens · +${achievement.rewardExp} EXP'
        : 'Tap to see how to earn stars';

    return GestureDetector(
      onTap: onTap,
      child: _FigmaCard(
        borderColor: achievement.isComplete
            ? const Color(0xFFFFD166)
            : const Color(0xFFB4EAA9),
        height: 230,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Achievements',
                    style: AppTextStyles.title.copyWith(
                      color: const Color(0xFF42896D),
                      fontSize: 20,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Opacity(
                      opacity: achievement.stars == 0 ? 0.55 : 1,
                      child: Image.asset(
                        'assets/images/achievement_medal.png',
                        width: 88,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0B8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFFC857)),
                      ),
                      child: Text(
                        'Tier I',
                        style: AppTextStyles.muted.copyWith(
                          color: const Color(0xFFC8783C),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _StarRow(
                        stars: achievement.stars,
                        maxStars: achievement.maxStars,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement.title,
                        style: AppTextStyles.label.copyWith(
                          color: const Color(0xFFC8783C),
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: achievement.progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFEAF7FF),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${achievement.stars}/${achievement.maxStars} stars · $subtitle',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.muted.copyWith(
                          color: AppColors.primaryBlue,
                          fontSize: 10,
                        ),
                      ),
                      if (achievement.canClaim) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: ElevatedButton(
                            onPressed: isClaiming ? null : onClaim,
                            child: Text(
                              isClaiming ? 'Claiming...' : 'Claim reward',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars, required this.maxStars});

  final int stars;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxStars, (index) {
        final earned = index < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_border_rounded,
          color: earned ? const Color(0xFFFFC857) : Colors.grey.shade400,
          size: 24,
        );
      }),
    );
  }
}

class _AchievementBottomSheet extends StatelessWidget {
  const _AchievementBottomSheet({required this.achievement});

  final AchievementProgress achievement;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to earn stars',
              style: AppTextStyles.title.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${achievement.title} · ${achievement.stars}/${achievement.maxStars} stars',
              style: AppTextStyles.muted.copyWith(color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 16),
            ...achievement.tasks.map(_AchievementTaskTile.new),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                achievement.isClaimed
                    ? 'Reward claimed. This badge stays unlocked forever.'
                    : achievement.canClaim
                    ? 'All stars complete. Claim your badge reward from the card.'
                    : 'Complete every mission to unlock +${achievement.rewardTokens} tokens and +${achievement.rewardExp} EXP.',
                style: AppTextStyles.muted.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTaskTile extends StatelessWidget {
  const _AchievementTaskTile(this.task);

  final AchievementTask task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            task.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: task.completed ? AppColors.success : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: AppTextStyles.label.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: task.completed ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${task.current}/${task.target}',
            style: AppTextStyles.muted.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Base card container
// ---------------------------------------------------------------------------

class _FigmaCard extends StatelessWidget {
  const _FigmaCard({
    required this.borderColor,
    required this.height,
    required this.child,
  });

  final Color borderColor;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 7, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
