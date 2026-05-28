import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
          Image.asset('assets/images/fox.png', height: 110),
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
