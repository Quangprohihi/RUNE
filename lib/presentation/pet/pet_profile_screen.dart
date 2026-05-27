import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/pet_provider.dart';
import '../../providers/token_provider.dart';
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

  Future<void> _spendForAction(
    BuildContext context, {
    required int cost,
    required String action,
    required void Function() onParticle,
  }) async {
    try {
      final petProvider = context.read<PetProvider>();
      await petProvider.performRemoteAction(action: action, cost: cost);
      final wallet = petProvider.latestWallet;
      if (wallet != null && context.mounted) {
        context.read<TokenProvider>().syncWallet(wallet);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!context.mounted) return;
    onParticle();
    _triggerHappy();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kiki feels better! 💖')));
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>().pet;
    final tokens = context.watch<TokenProvider>().tokens;

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
                          imagePath: 'assets/images/fox.png',
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
                                onTap: () => _spendForAction(
                                  context,
                                  cost: 10,
                                  action: 'feed',
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
                                onTap: () => _spendForAction(
                                  context,
                                  cost: 10,
                                  action: 'play',
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
                                onTap: () => _spendForAction(
                                  context,
                                  cost: 5,
                                  action: 'pet',
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
                            child: _AchievementsCard(tokens: tokens),
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
            '🔋  +5 exp Gain',
            style: AppTextStyles.muted.copyWith(fontSize: 10),
          ),
          Text('🛡  +10 ⚡', style: AppTextStyles.muted.copyWith(fontSize: 10)),
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
  const _AchievementsCard({required this.tokens});

  final int tokens;

  @override
  Widget build(BuildContext context) {
    return _FigmaCard(
      borderColor: const Color(0xFFB4EAA9),
      height: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: AppTextStyles.title.copyWith(
              color: const Color(0xFF42896D),
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset(
                'assets/images/achievement_medal.png',
                width: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('⭐', style: TextStyle(fontSize: 26)),
                        Text('⭐', style: TextStyle(fontSize: 26)),
                        Text('⭐', style: TextStyle(fontSize: 26)),
                        Text('☆', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Most Productive\nPartner',
                      style: AppTextStyles.label.copyWith(
                        color: const Color(0xFFC8783C),
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text('Tokens: $tokens ⚡', style: AppTextStyles.muted),
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
