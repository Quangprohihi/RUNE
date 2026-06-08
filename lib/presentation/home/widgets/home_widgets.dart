part of '../home_screen.dart';

class _Habitat extends StatelessWidget {
  const _Habitat({
    required this.scale,
    required this.kikiAssetPath,
    required this.ownedCompanions,
  });

  final double scale;
  final String kikiAssetPath;
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
              kikiAssetPath,
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
// Daily goal progress
// ---------------------------------------------------------------------------

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.focus});

  final FocusProvider focus;

  @override
  Widget build(BuildContext context) {
    final percent = (focus.dailyGoalProgress * 100).round();
    final message = focus.dailyGoalCompleted
        ? 'Goal complete! Kiki is proud of you.'
        : '${focus.dailyGoalRemainingMinutes} min left to complete today.';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: const Color(0xFFB7EFE7), width: 1.2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x225A9CAE),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Goal",
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: focus.dailyGoalProgress,
              backgroundColor: const Color(0xFFEAF7FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentTeal,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${focus.todayFocusMinutes} / ${focus.dailyGoalMinutes} min focused · $message',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.muted.copyWith(
              color: const Color(0xFF4367A3),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
