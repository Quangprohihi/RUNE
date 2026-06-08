part of '../pet_profile_screen.dart';

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
