import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/pet_provider.dart';
import '../../providers/token_provider.dart';

class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({super.key});

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
                  height: 960,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 28 * scale,
                        top: 22,
                        child: _CircleBackButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
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
                      Positioned(
                        right: -90 * scale,
                        top: 90,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 222 * scale,
                              height: 205,
                              decoration: const BoxDecoration(
                                color: Color(0x5E77BBD4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Image.asset(
                              'assets/images/fox.png',
                              width: 305 * scale,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
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
                              child: LinearProgressIndicator(
                                value: pet.expProgress,
                                minHeight: 9,
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF77BBD4),
                                backgroundColor: const Color(0xFFD9D9D9),
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
                      Positioned(
                        left: 34 * scale,
                        top: 332,
                        child: _SkillCard(scale: scale),
                      ),
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
                                  action: context.read<PetProvider>().feed,
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
                                  action: context.read<PetProvider>().play,
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
                                  action: context.read<PetProvider>().petKiki,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 32 * scale,
                        right: 32 * scale,
                        top: 490,
                        child: _StatusCard(
                          energy: pet.energy,
                          mood: pet.mood,
                          hunger: pet.hunger,
                          love: pet.love,
                        ),
                      ),
                      Positioned(
                        left: 32 * scale,
                        right: 32 * scale,
                        top: 710,
                        child: _AchievementsCard(tokens: tokens),
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

  Future<void> _spendForAction(
    BuildContext context, {
    required int cost,
    required Future<void> Function() action,
  }) async {
    final paid = await context.read<TokenProvider>().spend(cost);
    if (!context.mounted) return;
    if (!paid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough focus tokens yet.')),
      );
      return;
    }
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kiki feels better!')));
  }
}

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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
      borderRadius: BorderRadius.circular(10),
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
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.label.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

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
      height: 180,
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
                    _StatBar(label: 'Energy', value: energy),
                    const SizedBox(height: 14),
                    _StatBar(label: 'Hunger', value: hunger),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _StatBar(label: 'Mood', value: mood),
                    const SizedBox(height: 14),
                    _StatBar(label: 'Love', value: love),
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

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value / 100,
          minHeight: 9,
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF77BBD4),
          backgroundColor: const Color(0xFFD9D9D9),
        ),
      ],
    );
  }
}

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
