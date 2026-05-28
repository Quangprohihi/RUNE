import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/analytics_summary.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final summary = provider.summary;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8FBF8), Color(0xFFD0F2FF)],
          ),
        ),
        child: SafeArea(
          child: provider.isLoading && summary.totalFocusMinutes == 0
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.chevron_left,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'FOCUS STATS',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heading.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          _StatCard(
                            label: 'Total Focus',
                            value: '${summary.totalFocusMinutes}m',
                          ),
                          _StatCard(
                            label: 'Today',
                            value: '${summary.sessionsToday} sessions',
                          ),
                          _StatCard(
                            label: 'Pomodoros Today',
                            value: '${summary.pomodorosToday}',
                          ),
                          _StatCard(
                            label: 'Best Streak',
                            value: '${summary.bestStreak} days',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SevenDayCard(days: summary.focusByDay),
                      const SizedBox(height: 16),
                      _CategoryCard(categories: summary.categoryBreakdown),
                      if (provider.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          provider.error!,
                          style: AppTextStyles.muted.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.muted),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SevenDayCard extends StatelessWidget {
  const _SevenDayCard({required this.days});

  final List<FocusDayStat> days;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = days.fold<int>(
      1,
      (max, day) => day.minutes > max ? day.minutes : max,
    );
    return _Panel(
      title: 'Last 7 days',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final height = 24 + (day.minutes / maxMinutes * 80);
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: height,
                  width: 22,
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${day.date.day}', style: AppTextStyles.muted),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.categories});

  final List<CategoryFocusStat> categories;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Focus by category',
      child: categories.isEmpty
          ? Text(
              'Complete a focus session to see categories.',
              style: AppTextStyles.muted,
            )
          : Column(
              children: categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.category,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      Text('${category.minutes}m', style: AppTextStyles.muted),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
