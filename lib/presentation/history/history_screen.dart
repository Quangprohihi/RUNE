import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/activity_event.dart';
import '../../models/analytics_summary.dart';
import '../../providers/activity_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/streak_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      context.read<ActivityProvider>().load();
      context.read<AnalyticsProvider>().load();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakProvider>().streak;
    final activity = context.watch<ActivityProvider>();
    final analytics = context.watch<AnalyticsProvider>();
    final summary = analytics.summary;
    final isInitialLoading =
        analytics.isLoading &&
        activity.isLoading &&
        summary.focusByDay.isEmpty &&
        activity.events.isEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFD8F6FF), Color(0xFFE6FFE8)],
          ),
        ),
        child: SafeArea(
          child: isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      context.read<ActivityProvider>().load(),
                      context.read<AnalyticsProvider>().load(),
                    ]);
                  },
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                      children: [
                        _HistoryHeader(streak: streak),
                        const SizedBox(height: 18),
                        _ChartCard(days: summary.focusByDay),
                        const SizedBox(height: 18),
                        _OverviewCard(summary: summary),
                        const SizedBox(height: 18),
                        _DistributionCard(
                          categories: summary.categoryBreakdown,
                          totalMinutes: summary.weeklyFocusMinutes,
                        ),
                        const SizedBox(height: 18),
                        _RecentActivitySection(
                          activity: activity,
                          analyticsError: analytics.error,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Material(
              color: AppColors.accentTeal,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  height: 36,
                  width: 36,
                  child: Icon(Icons.chevron_left, color: Colors.white),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$streak',
              style: AppTextStyles.heading.copyWith(
                fontSize: 72,
                color: const Color(0xFF4DC7BD),
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 3),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 58,
              height: 58,
              margin: const EdgeInsets.only(bottom: 13),
              decoration: const BoxDecoration(
                color: Color(0xFFFFB0BE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 34,
              ),
            ),
          ],
        ),
        Text(
          'ACTIVITY HISTORY',
          style: AppTextStyles.heading.copyWith(
            fontSize: 22,
            color: const Color(0xFF238CA3),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.days});

  final List<FocusDayStat> days;

  @override
  Widget build(BuildContext context) {
    return _HistoryPanel(
      title: 'Total Focus Time (min) per Day',
      child: days.isEmpty
          ? const _EmptyInline(
              message: 'Complete a focus session to draw your chart.',
            )
          : SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _FocusLineChartPainter(days),
                child: const SizedBox.expand(),
              ),
            ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final averageHours = summary.averageMinutesPerDay / 60;
    final mostActive = summary.mostActiveDay;
    final mostActiveLabel = mostActive == null
        ? 'No focus yet'
        : '${_weekdayName(mostActive.date.weekday)} (${_formatHours(mostActive.minutes)})';
    final weeklyHours = _formatHours(summary.weeklyFocusMinutes);

    return _HistoryPanel(
      title: 'Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Week (${summary.weekRangeLabel})',
            style: AppTextStyles.label.copyWith(
              color: const Color(0xFF238CA3),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _RichMetricLine(
            label: 'Average:',
            value: averageHours.toStringAsFixed(1),
            suffix: ' hours per day',
          ),
          const SizedBox(height: 10),
          Text(
            'Most Active Day: $mostActiveLabel',
            style: AppTextStyles.label.copyWith(
              color: const Color(0xFF238CA3),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentTeal, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/fox.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary.weeklyFocusMinutes == 0
                      ? 'Kiki is ready for your first focus session this week.'
                      : 'Kiki has focused with you for $weeklyHours this week.',
                  style: AppTextStyles.muted.copyWith(
                    color: const Color(0xFF238CA3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHours(int minutes) {
    final hours = minutes / 60;
    if (hours == 0) return '0h';
    if (hours < 1) return '${minutes}m';
    return '${hours.toStringAsFixed(hours >= 10 ? 0 : 1)}h';
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }
}

class _RichMetricLine extends StatelessWidget {
  const _RichMetricLine({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.label.copyWith(
          color: const Color(0xFF238CA3),
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: AppTextStyles.title.copyWith(
              color: const Color(0xFF4FD7AC),
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: suffix),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.categories,
    required this.totalMinutes,
  });

  final List<CategoryFocusStat> categories;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories
        .where((category) => category.minutes > 0)
        .toList(growable: false);

    return _HistoryPanel(
      title: 'Time distribution',
      child: visibleCategories.isEmpty
          ? const _EmptyInline(message: 'Focus categories will appear here.')
          : Column(
              children: visibleCategories.map((category) {
                final ratio = totalMinutes == 0
                    ? 0.0
                    : (category.minutes / totalMinutes).clamp(0, 1).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DistributionBar(category: category, ratio: ratio),
                );
              }).toList(),
            ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.category, required this.ratio});

  final CategoryFocusStat category;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.category,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${category.minutes}m',
              style: AppTextStyles.muted.copyWith(
                color: const Color(0xFF238CA3),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: const Color(0xFFEAF7FF),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.accentTeal,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.activity,
    required this.analyticsError,
  });

  final ActivityProvider activity;
  final String? analyticsError;

  @override
  Widget build(BuildContext context) {
    final events = activity.events.take(5).toList(growable: false);
    final error = activity.error ?? analyticsError;

    return _HistoryPanel(
      title: 'Recent activity',
      child: activity.isLoading && events.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          : error != null && events.isEmpty
          ? _EmptyInline(message: error)
          : events.isEmpty
          ? const _EmptyInline(
              message: 'No activity yet. Start focusing with Kiki.',
            )
          : Column(
              children: [
                for (var index = 0; index < events.length; index++) ...[
                  _ActivityCard(item: events[index]),
                  if (index != events.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: const Color(0xFF8DDEE0)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143A9BBE),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              color: const Color(0xFF238CA3),
              fontSize: 18,
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

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: AppTextStyles.muted.copyWith(color: AppColors.primaryBlue),
      ),
    );
  }
}

class _FocusLineChartPainter extends CustomPainter {
  const _FocusLineChartPainter(this.days);

  final List<FocusDayStat> days;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    const leftPadding = 34.0;
    const rightPadding = 12.0;
    const topPadding = 16.0;
    const bottomPadding = 28.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final maxMinutes = days.fold<int>(
      1,
      (max, day) => day.minutes > max ? day.minutes : max,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFE5EEF2)
      ..strokeWidth = 1;
    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var i = 0; i <= 4; i++) {
      final y = topPadding + chartHeight * i / 4;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      final label = (maxMinutes * (4 - i) / 4).round().toString();
      labelPainter.text = TextSpan(
        text: label,
        style: AppTextStyles.muted.copyWith(fontSize: 10),
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(0, y - 7));
    }

    final points = <Offset>[];
    for (var i = 0; i < days.length; i++) {
      final x =
          leftPadding +
          (days.length == 1 ? 0 : chartWidth * i / (days.length - 1));
      final y =
          topPadding +
          chartHeight -
          (days[i].minutes / maxMinutes) * chartHeight;
      points.add(Offset(x, y));
    }

    final areaPath = Path()..moveTo(points.first.dx, topPadding + chartHeight);
    for (final point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath
      ..lineTo(points.last.dx, topPadding + chartHeight)
      ..close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x5547A8E5), Color(0x0047A8E5)],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF47A8E5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF47A8E5);
    final last = points.last;
    canvas.drawCircle(last, 5, dotPaint);
    canvas.drawCircle(last, 12, Paint()..color = const Color(0x2247A8E5));

    for (var i = 0; i < days.length; i++) {
      labelPainter.text = TextSpan(
        text: i == 0 ? _monthDay(days[i].date) : '${days[i].date.day}',
        style: AppTextStyles.muted.copyWith(fontSize: 10),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          points[i].dx - labelPainter.width / 2,
          topPadding + chartHeight + 8,
        ),
      );
    }
  }

  String _monthDay(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[date.month - 1]} ${date.day}';
  }

  @override
  bool shouldRepaint(covariant _FocusLineChartPainter oldDelegate) {
    return oldDelegate.days != days;
  }
}

// ---------------------------------------------------------------------------
// Activity card
// ---------------------------------------------------------------------------

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final ActivityEvent item;

  @override
  Widget build(BuildContext context) {
    final chips = _focusChips(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _eventColor(item.eventType),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: AppTextStyles.muted),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: chips),
                ],
              ],
            ),
          ),
          Text(
            _formatTime(item.createdAt),
            style: AppTextStyles.muted.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  List<Widget> _focusChips(ActivityEvent item) {
    if (item.eventType != 'focus_completed') return const [];
    final metadata = item.metadata;
    final category = metadata['category'] as String?;
    final pomodoroCount = metadata['pomodoroCount'];
    final rewardTokens = metadata['rewardTokens'];
    final rewardExp = metadata['rewardExp'];
    final skillName = metadata['skillName'] as String?;
    final bonusTokens = metadata['bonusTokens'];
    final bonusExp = metadata['bonusExp'];
    final energySaved = metadata['energySaved'];
    final bonusParts = [
      if (bonusTokens is int && bonusTokens > 0) '+$bonusTokens tokens',
      if (bonusExp is int && bonusExp > 0) '+$bonusExp EXP',
      if (energySaved is int && energySaved > 0) '$energySaved energy saved',
    ];
    return [
      if (category != null && category.isNotEmpty)
        _MiniMetaChip(label: category, color: const Color(0xFFEFF6FF)),
      if (pomodoroCount is int)
        _MiniMetaChip(
          label: pomodoroCount <= 1 ? '1 Pomodoro' : '$pomodoroCount Pomodoros',
          color: const Color(0xFFE3F8E8),
        ),
      if (rewardTokens is int)
        _MiniMetaChip(
          label: '+$rewardTokens tokens',
          color: const Color(0xFFFEF3C7),
        ),
      if (rewardExp is int)
        _MiniMetaChip(label: '+$rewardExp EXP', color: const Color(0xFFE0E7FF)),
      if (skillName != null && skillName.isNotEmpty && bonusParts.isNotEmpty)
        _MiniMetaChip(
          label: '$skillName ${bonusParts.join(', ')}',
          color: const Color(0xFFEAF7FF),
        ),
    ];
  }

  Color _eventColor(String type) {
    return switch (type) {
      'focus_completed' => const Color(0xFFE3F8E8),
      'pet_feed' => const Color(0xFFFFF3E0),
      'pet_play' => const Color(0xFFE8F4FF),
      'pet_pet' => const Color(0xFFFFE8EF),
      'shop_purchase' => const Color(0xFFF3E8FF),
      'daily_task_claimed' => const Color(0xFFFFEDCC),
      _ => const Color(0xFFE8F4FF),
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      final hour = time.hour > 12 ? time.hour - 12 : time.hour;
      final suffix = time.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $suffix';
    }
    final diff = now.difference(time).inDays;
    if (diff <= 1) return 'Yesterday';
    return '$diff days ago';
  }
}

class _MiniMetaChip extends StatelessWidget {
  const _MiniMetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.muted.copyWith(
          fontSize: 10,
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
