import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/reward_celebration.dart';
import '../../models/achievement_progress.dart';
import '../../providers/activity_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/token_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementProvider>().load();
    });
  }

  Future<void> _claim(AchievementProgress achievement) async {
    final provider = context.read<AchievementProvider>();
    final claimed = await provider.claim(achievement.code);
    if (!mounted) return;
    if (!claimed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Could not claim achievement.'),
        ),
      );
      return;
    }

    final wallet = provider.latestWallet;
    final pet = provider.latestPet;
    if (wallet != null) context.read<TokenProvider>().syncWallet(wallet);
    if (pet != null) context.read<PetProvider>().syncPet(pet);
    await context.read<ActivityProvider>().load();
    if (!mounted) return;
    RewardCelebration.show(
      context,
      title: achievement.title,
      tokens: achievement.rewardTokens,
      exp: achievement.rewardExp,
    );
  }

  void _showDetail(AchievementProgress achievement) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AchievementDetailSheet(
        achievement: achievement,
        onClaim: () {
          Navigator.of(context).pop();
          _claim(achievement);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementProvider>();
    final achievements = provider.achievements;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AchievementsBackground()),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: context.read<AchievementProvider>().load,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageGutter,
                      AppSpacing.lg,
                      AppSpacing.pageGutter,
                      AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      // Keep the content at least as tall as the viewport so a
                      // single badge doesn't float at the top over dead space.
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - AppSpacing.lg - AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _AchievementsHeader(),
                          AppSpacing.gapLg,
                          _ProgressSummaryBand(achievements: achievements),
                          AppSpacing.gapLg,
                          ..._buildBody(context, provider, achievements),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    AchievementProvider provider,
    List<AchievementProgress> achievements,
  ) {
    if (provider.isLoading && achievements.isEmpty) {
      return const [_LoadingPanel()];
    }
    if (provider.error != null && achievements.isEmpty) {
      return [
        _StatePanel(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load achievements',
          message: provider.error!,
          actionLabel: 'Retry',
          onAction: () => context.read<AchievementProvider>().load(),
        ),
      ];
    }
    if (achievements.isEmpty) {
      return const [
        _StatePanel(
          icon: Icons.emoji_events_outlined,
          title: 'No achievements yet',
          message: 'Complete focus sessions to start earning stars.',
        ),
      ];
    }

    return [
      for (final achievement in achievements)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _AchievementCard(
            achievement: achievement,
            isClaiming: provider.isClaiming,
            onTap: () => _showDetail(achievement),
            onClaim: () => _claim(achievement),
          ),
        ),
      if (provider.error != null) ...[
        AppSpacing.gapXs,
        Text(
          provider.error!,
          style: AppTextStyles.muted.copyWith(color: Colors.redAccent),
        ),
      ],
      AppSpacing.gapSm,
      const _MoreBadgesTeaser(),
    ];
  }
}

/// Full-bleed background: the soft mint→sky gradient plus a couple of faint
/// decorative blobs so the page has depth even when it's near-empty.
class _AchievementsBackground extends StatelessWidget {
  const _AchievementsBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8FBF8), Color(0xFFD2FAFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _Blob(size: 200, color: Colors.white.withValues(alpha: 0.45)),
          ),
          Positioned(
            bottom: 40,
            left: -70,
            child: _Blob(
              size: 220,
              color: AppColors.accentTeal.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Fills the space under a short badge list with a friendly hint that more
/// badges are coming — turns "empty screen" into "anticipation".
class _MoreBadgesTeaser extends StatelessWidget {
  const _MoreBadgesTeaser();

  @override
  Widget build(BuildContext context) {
    return DottedHintCard(
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.accentSky.withValues(alpha: 0.8),
            size: 30,
          ),
          AppSpacing.gapSm,
          Text(
            'More badges on the way',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            'Keep focusing every day to unlock new tiers and rewards.',
            textAlign: TextAlign.center,
            style: AppTextStyles.muted.copyWith(color: AppColors.accentSky),
          ),
        ],
      ),
    );
  }
}

/// A soft dashed-look placeholder card (rendered with a dotted-style border via
/// a translucent surface) used for "coming soon" hints.
class DottedHintCard extends StatelessWidget {
  const DottedHintCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: AppColors.accentSky.withValues(alpha: 0.35),
          width: 1.4,
        ),
      ),
      child: child,
    );
  }
}

class _AchievementsHeader extends StatelessWidget {
  const _AchievementsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryBlue),
        ),
        Expanded(
          child: Text(
            'ACHIEVEMENTS',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ProgressSummaryBand extends StatelessWidget {
  const _ProgressSummaryBand({required this.achievements});

  final List<AchievementProgress> achievements;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements
        .where((achievement) => achievement.isClaimed)
        .length;
    final claimable = achievements
        .where((achievement) => achievement.canClaim)
        .length;
    final totalTokens = achievements
        .where((achievement) => achievement.isClaimed)
        .fold<int>(0, (sum, achievement) => sum + achievement.rewardTokens);

    final hasClaimable = claimable > 0;
    return AppCard(
      borderColor: hasClaimable
          ? const Color(0xFFFFD166)
          : const Color(0xFFB4EAA9),
      shadows: hasClaimable ? AppShadows.reward : null,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFFFF4CE),
            child: Icon(Icons.emoji_events, color: Color(0xFFF6A53A)),
          ),
          AppSpacing.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked/${achievements.length} unlocked',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  claimable > 0
                      ? '$claimable reward ready to claim'
                      : '$totalTokens tokens earned from badges',
                  style: AppTextStyles.muted.copyWith(
                    color: AppColors.accentSky,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.isClaiming,
    required this.onTap,
    required this.onClaim,
  });

  final AchievementProgress achievement;
  final bool isClaiming;
  final VoidCallback onTap;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final borderColor = achievement.isClaimed
        ? AppColors.borderSubtle
        : achievement.isComplete
        ? const Color(0xFFFFD166)
        : const Color(0xFFB4EAA9);

    return AppCard(
      onTap: onTap,
      borderColor: borderColor,
      borderWidth: 1.6,
      radius: AppRadius.brXl,
      elevated: achievement.canClaim,
      shadows: achievement.canClaim ? AppShadows.reward : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MedalVisual(achievement: achievement),
          AppSpacing.wGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  achievement.title,
                  style: AppTextStyles.label.copyWith(
                    color: const Color(0xFFC8783C),
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                AppSpacing.gapSm,
                _StarRow(
                  stars: achievement.stars,
                  maxStars: achievement.maxStars,
                ),
                AppSpacing.gapSm,
                ClipRRect(
                  borderRadius: AppRadius.brPill,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: achievement.progress),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEAF7FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentTeal,
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  _statusText(achievement),
                  style: AppTextStyles.muted.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppSpacing.gapSm,
                _AchievementAction(
                  achievement: achievement,
                  isClaiming: isClaiming,
                  onClaim: onClaim,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(AchievementProgress achievement) {
    if (achievement.isClaimed) return 'Claimed forever';
    if (achievement.canClaim) {
      return 'Ready: +${achievement.rewardTokens} tokens and +${achievement.rewardExp} EXP';
    }
    return '${achievement.stars}/${achievement.maxStars} stars earned';
  }
}

class _MedalVisual extends StatelessWidget {
  const _MedalVisual({required this.achievement});

  final AchievementProgress achievement;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Opacity(
          opacity: achievement.stars == 0 ? 0.55 : 1,
          child: Image.asset(
            'assets/images/achievement_medal.png',
            width: 82,
            fit: BoxFit.contain,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0B8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFFFC857)),
          ),
          child: Text(
            'Tier ${achievement.tier}',
            style: AppTextStyles.muted.copyWith(
              color: const Color(0xFFC8783C),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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
      children: List.generate(maxStars, (index) {
        final earned = index < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_border_rounded,
          color: earned ? const Color(0xFFFFC857) : Colors.grey.shade400,
          size: 23,
        );
      }),
    );
  }
}

class _AchievementAction extends StatelessWidget {
  const _AchievementAction({
    required this.achievement,
    required this.isClaiming,
    required this.onClaim,
  });

  final AchievementProgress achievement;
  final bool isClaiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    if (achievement.isClaimed) {
      return _StatusPill(
        text: 'Claimed',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        backgroundColor: const Color(0xFFE8FFF1),
      );
    }
    if (!achievement.canClaim) {
      return _StatusPill(
        text: 'View missions',
        icon: Icons.list_alt_rounded,
        color: AppColors.accentSky,
        backgroundColor: const Color(0xFFEAF7FF),
      );
    }
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: isClaiming ? null : onClaim,
        child: Text(isClaiming ? 'Claiming...' : 'Claim reward'),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String text;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.muted.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  const _AchievementDetailSheet({
    required this.achievement,
    required this.onClaim,
  });

  final AchievementProgress achievement;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
            _RewardInfo(achievement: achievement),
            if (achievement.canClaim) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onClaim,
                  child: const Text('Claim reward'),
                ),
              ),
            ],
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

class _RewardInfo extends StatelessWidget {
  const _RewardInfo({required this.achievement});

  final AchievementProgress achievement;

  @override
  Widget build(BuildContext context) {
    final message = achievement.isClaimed
        ? 'Reward claimed. This badge stays unlocked forever.'
        : achievement.canClaim
        ? 'All stars complete. Claim your badge reward now.'
        : 'Complete every mission to unlock +${achievement.rewardTokens} tokens and +${achievement.rewardExp} EXP.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: AppTextStyles.muted.copyWith(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      radius: AppRadius.brXl,
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.accentSky),
          AppSpacing.gapMd,
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.primaryBlue),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
