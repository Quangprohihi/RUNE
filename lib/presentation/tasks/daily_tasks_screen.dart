import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/daily_task.dart';
import '../../providers/daily_task_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';
import '../../routes/app_routes.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyTaskProvider>().loadToday();
    });
  }

  Future<void> _claimTask(DailyTask task) async {
    if (!task.canClaim) return;
    final provider = context.read<DailyTaskProvider>();
    await provider.claim(task.id);
    final wallet = provider.latestWallet;
    if (wallet != null && mounted) {
      context.read<TokenProvider>().syncWallet(wallet);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${task.template.title} claimed!')));
  }

  Future<void> _claimMilestone(DailyMilestone milestone) async {
    if (!milestone.canClaim(context.read<DailyTaskProvider>().totalPoints)) {
      return;
    }
    final provider = context.read<DailyTaskProvider>();
    await provider.claimMilestone(milestone.id);
    final wallet = provider.latestWallet;
    if (wallet != null && mounted) {
      context.read<TokenProvider>().syncWallet(wallet);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${milestone.pointsRequired} pts reward claimed!'),
      ),
    );
  }

  void _goToFocusTimer() {
    Navigator.of(context).pushNamed(AppRoutes.setFocusTimer);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<DailyTaskProvider>();
    final streak = context.watch<StreakProvider>().streak;
    final dailyLogin = _findTask(tasks.tasks, 'daily_login');
    final sunshine = _findTask(tasks.tasks, 'sunshine_collector');
    final deepFocus = _findTask(tasks.tasks, 'deep_focus');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0FFF4), Color(0xFFE9FFF2)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: 38,
                child: _GlowBlob(
                  size: 128,
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                left: -38,
                top: 126,
                child: _GlowBlob(
                  size: 96,
                  color: AppColors.success.withValues(alpha: 0.08),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.accentSky,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _HeaderCard(),
                    const SizedBox(height: 22),
                    if (tasks.isLoading && tasks.tasks.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (tasks.error != null && tasks.tasks.isEmpty)
                      _StateMessage(message: tasks.error!)
                    else ...[
                      _MilestoneRewardsCard(
                        totalPoints: tasks.totalPoints,
                        milestones: tasks.milestones,
                        onClaim: _claimMilestone,
                      ),
                      const SizedBox(height: 16),
                      if (dailyLogin != null)
                        _TaskCard.fromTask(
                          task: dailyLogin,
                          icon: Icons.calendar_today_outlined,
                          onAction: () => _claimTask(dailyLogin),
                        ),
                      const SizedBox(height: 16),
                      if (sunshine != null)
                        _TaskCard.fromTask(
                          task: sunshine,
                          icon: Icons.wb_sunny_outlined,
                          onAction: sunshine.canClaim
                              ? () => _claimTask(sunshine)
                              : _goToFocusTimer,
                          softAction: !sunshine.canClaim,
                        ),
                      const SizedBox(height: 16),
                      if (deepFocus != null)
                        _TaskCard.fromTask(
                          task: deepFocus,
                          icon: Icons.self_improvement,
                          onAction: deepFocus.canClaim
                              ? () => _claimTask(deepFocus)
                              : _goToFocusTimer,
                          softAction: !deepFocus.canClaim,
                        ),
                      const SizedBox(height: 18),
                      _StreakPanel(streak: streak),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DailyTask? _findTask(List<DailyTask> tasks, String code) {
    for (final task in tasks) {
      if (task.template.code == code) return task;
    }
    return null;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final remaining = nextDay.difference(now);
    final countdown =
        '${remaining.inHours}h\n${remaining.inMinutes.remainder(60)}m';
    return Container(
      height: 124,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF76D88D), Color(0xFF323E83)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Daily Tasks',
                  style: AppTextStyles.heading.copyWith(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete daily\nfor rewards!',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 118,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    countdown,
                    style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
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
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _TaskSurface(
      height: 120,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.primaryBlue),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _MilestoneRewardsCard extends StatelessWidget {
  const _MilestoneRewardsCard({
    required this.totalPoints,
    required this.milestones,
    required this.onClaim,
  });

  final int totalPoints;
  final List<DailyMilestone> milestones;
  final ValueChanged<DailyMilestone> onClaim;

  @override
  Widget build(BuildContext context) {
    final maxPoints = milestones.isEmpty ? 1 : milestones.last.pointsRequired;
    final progress = (totalPoints / maxPoints).clamp(0.0, 1.0);
    return _TaskSurface(
      height: 138,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Milestone Rewards',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                _SmallBadge(
                  text: '$totalPoints / $maxPoints pts',
                  color: AppColors.accentSky,
                  backgroundColor: const Color(0xFFF1FBFF),
                ),
              ],
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 10,
                      margin: const EdgeInsets.only(left: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22BDEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: milestones.isEmpty
                      ? const [_MilestoneIcon()]
                      : milestones.map((milestone) {
                          return _MilestoneIcon(
                            isClaimed: milestone.isClaimed,
                            canClaim: milestone.canClaim(totalPoints),
                            isUnlocked: totalPoints >= milestone.pointsRequired,
                            onTap: () => onClaim(milestone),
                          );
                        }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progressText,
    required this.tokenReward,
    required this.diamondReward,
    required this.actionLabel,
    required this.actionEnabled,
    required this.onAction,
    this.softAction = false,
  });

  factory _TaskCard.fromTask({
    required DailyTask task,
    required IconData icon,
    required VoidCallback onAction,
    bool softAction = false,
  }) {
    return _TaskCard(
      icon: icon,
      title: task.template.title,
      subtitle: task.template.description,
      progressText: '${task.progressValue}/${task.targetValue}',
      tokenReward: task.template.rewardTokens,
      diamondReward: task.template.rewardDiamonds,
      actionLabel: task.isClaimed
          ? 'Claimed'
          : task.canClaim
          ? 'Claim'
          : 'Go',
      actionEnabled: !task.isClaimed,
      onAction: onAction,
      softAction: softAction,
    );
  }

  final IconData icon;
  final String title;
  final String subtitle;
  final String progressText;
  final int tokenReward;
  final int diamondReward;
  final String actionLabel;
  final bool actionEnabled;
  final VoidCallback onAction;
  final bool softAction;

  @override
  Widget build(BuildContext context) {
    return _TaskSurface(
      height: 142,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE9FFF2),
              child: Icon(icon, color: const Color(0xFF36C27B), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    style: AppTextStyles.label.copyWith(
                      color: const Color(0xFF1D293D),
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF607094),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SmallBadge(
                    text: progressText,
                    color: const Color(0xFF46B97E),
                    backgroundColor: const Color(0xFFDDFBE8),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    _RewardChip(text: '$tokenReward', icon: Icons.emoji_events),
                    const SizedBox(width: 6),
                    _RewardChip(
                      text: '$diamondReward',
                      icon: Icons.diamond,
                      color: AppColors.accentSky,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 96,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: actionEnabled ? onAction : null,
                    style: ElevatedButton.styleFrom(
                      elevation: softAction ? 0 : 4,
                      backgroundColor: softAction
                          ? const Color(0xFFF4F7FB)
                          : const Color(0xFF20CF83),
                      foregroundColor: softAction
                          ? const Color(0xFF90A1B9)
                          : Colors.white,
                      disabledBackgroundColor: const Color(0xFFE8EDF2),
                      disabledForegroundColor: const Color(0xFF90A1B9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        actionLabel,
                        maxLines: 1,
                        style: AppTextStyles.label.copyWith(
                          color: !actionEnabled || softAction
                              ? const Color(0xFF90A1B9)
                              : Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
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

class _StreakPanel extends StatelessWidget {
  const _StreakPanel({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '7-DAY STREAK',
                style: AppTextStyles.muted.copyWith(
                  color: const Color(0xFF90A1B9),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _SmallBadge(
                text: '+50% Bonus',
                color: AppColors.warning,
                backgroundColor: const Color(0xFFFFF5D7),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 6 ? 0 : 5),
                  child: _StreakDay(day: index + 1, streak: streak),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StreakDay extends StatelessWidget {
  const _StreakDay({required this.day, required this.streak});

  final int day;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final checked = day <= streak;
    final active = day == streak + 1;
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF48C77E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: checked || active
              ? const Color(0xFFB9F4D2)
              : const Color(0xFFE5EDF4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Day $day',
            style: AppTextStyles.muted.copyWith(
              color: active ? Colors.white : const Color(0xFF7F91B2),
              fontWeight: FontWeight.w900,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 12,
            backgroundColor: checked || active
                ? Colors.white
                : const Color(0xFFF6F8FB),
            child: Icon(
              checked ? Icons.check_circle_outline : Icons.lock_outline,
              color: checked || active
                  ? const Color(0xFF48C77E)
                  : const Color(0xFFBBC6D8),
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSurface extends StatelessWidget {
  const _TaskSurface({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MilestoneIcon extends StatelessWidget {
  const _MilestoneIcon({
    this.isClaimed = false,
    this.canClaim = false,
    this.isUnlocked = false,
    this.onTap,
  });

  final bool isClaimed;
  final bool canClaim;
  final bool isUnlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isClaimed
        ? const Color(0xFF48C77E)
        : isUnlocked
        ? const Color(0xFF00B9EF)
        : const Color(0xFFDCE5EF);
    final icon = isClaimed
        ? Icons.check_rounded
        : isUnlocked
        ? Icons.diamond
        : Icons.lock_outline;

    return GestureDetector(
      onTap: canClaim ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: canClaim ? const Color(0xFFE9FBFF) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: isUnlocked ? 2 : 3),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.text,
    required this.icon,
    this.color = AppColors.warning,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.muted.copyWith(
              color: const Color(0xFF1D293D),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  final String text;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: AppTextStyles.muted.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

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
