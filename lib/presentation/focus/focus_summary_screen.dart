import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api/api_client.dart';
import '../../models/focus_summary.dart';
import '../../routes/app_routes.dart';

class FocusSummaryScreen extends StatelessWidget {
  const FocusSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = ModalRoute.of(context)?.settings.arguments as FocusSummary?;
    if (summary == null) {
      return const Scaffold(body: Center(child: Text('No focus summary yet.')));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9FFF4), Color(0xFFDDF7FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'FOCUS COMPLETE',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 24,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _HeroCard(summary: summary),
                const SizedBox(height: 16),
                _KikiRecapCard(summary: summary),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Tokens',
                        value: '+${summary.rewardTokens}',
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'EXP',
                        value: '+${summary.rewardExp}',
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Streak',
                        value: '${summary.currentStreak} days',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Kiki Level',
                        value: '${summary.pet.level}',
                        color: AppColors.accentSky,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CompanionBonusCard(summary: summary),
                const SizedBox(height: 16),
                _DailyProgressCard(summary: summary),
                const SizedBox(height: 16),
                _PetProgressCard(summary: summary),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                  child: const Text('Back Home'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.analytics),
                  child: const Text('View Analytics'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final FocusSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A42A779),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(summary.pet.skinAssetPath, height: 110),
          const SizedBox(height: 10),
          Text(
            summary.label,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(
              color: const Color(0xFF1D293D),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.plannedMinutes} minutes · ${summary.category} · ${summary.pomodoroCount} Pomodoro',
            textAlign: TextAlign.center,
            style: AppTextStyles.muted.copyWith(color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.muted),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionBonusCard extends StatelessWidget {
  const _CompanionBonusCard({required this.summary});

  final FocusSummary summary;

  @override
  Widget build(BuildContext context) {
    final bonuses = [
      if (summary.bonusTokens > 0) '+${summary.bonusTokens} tokens',
      if (summary.bonusExp > 0) '+${summary.bonusExp} EXP',
      if (summary.energySaved > 0) '${summary.energySaved} energy saved',
    ];
    final detail = bonuses.isEmpty
        ? summary.skillDescription
        : '${summary.skillDescription} · ${bonuses.join(' · ')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFB4EAA9), width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFEAF7FF),
            child: Icon(Icons.pets, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.companionName}: ${summary.skillName}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(detail, style: AppTextStyles.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({required this.summary});

  final FocusSummary summary;

  @override
  Widget build(BuildContext context) {
    final percent = (summary.dailyGoalProgress * 100).round();
    final subtitle = summary.dailyGoalCompleted
        ? 'Daily goal complete. Great focus today!'
        : '${summary.dailyGoalRemainingMinutes} min left for today.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Progress",
                  style: AppTextStyles.title.copyWith(
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
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: summary.dailyGoalProgress,
            minHeight: 8,
            backgroundColor: const Color(0xFFEAF7FF),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.accentTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.todayFocusMinutes} / ${summary.dailyGoalMinutes} min focused · $subtitle',
            style: AppTextStyles.muted,
          ),
        ],
      ),
    );
  }
}

/// "Kiki says" — an AI-generated recap (praise + next-session suggestion)
/// fetched from the backend after a session. Falls back to a friendly static
/// message if the request fails, so the card always feels alive and never
/// shows a raw error.
class _KikiRecapCard extends StatefulWidget {
  const _KikiRecapCard({required this.summary});

  final FocusSummary summary;

  @override
  State<_KikiRecapCard> createState() => _KikiRecapCardState();
}

class _KikiRecapCardState extends State<_KikiRecapCard> {
  bool _loading = true;
  String _praise = '';
  String _suggestion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecap());
  }

  Future<void> _loadRecap() async {
    final s = widget.summary;
    try {
      final response =
          await context.read<ApiClient>().post(
                '/focus-plans/recap',
                body: {
                  'label': s.label,
                  'minutes': s.plannedMinutes,
                  'currentStreak': s.currentStreak,
                  'todayFocusMinutes': s.todayFocusMinutes,
                  'dailyGoalMinutes': s.dailyGoalMinutes,
                  'dailyGoalCompleted': s.dailyGoalCompleted,
                },
              )
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _praise = (response['praise'] as String?)?.trim() ?? '';
        _suggestion = (response['suggestion'] as String?)?.trim() ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _praise = 'Great focus session! Kiki is proud of you. 🎉';
        _suggestion =
            'Next time, pick one clear topic before the timer starts.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7FF), Color(0xFFF3FBFF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFB9E2F2)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage(widget.summary.pet.skinAssetPath),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Kiki says',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.auto_awesome,
                      size: 15,
                      color: AppColors.accentSky,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loading)
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Kiki is thinking…',
                        style: AppTextStyles.muted.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    _praise,
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF1D293D),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_suggestion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          size: 15,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _suggestion,
                            style: AppTextStyles.muted.copyWith(height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetProgressCard extends StatelessWidget {
  const _PetProgressCard({required this.summary});

  final FocusSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kiki after focus',
            style: AppTextStyles.title.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: summary.pet.expProgress),
          const SizedBox(height: 8),
          Text(
            'EXP ${summary.pet.exp}/${summary.pet.expToNext} · Mood ${summary.pet.mood} · Energy ${summary.pet.energy}',
            style: AppTextStyles.muted,
          ),
        ],
      ),
    );
  }
}
