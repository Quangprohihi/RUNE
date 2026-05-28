import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/activity_event.dart';
import '../../providers/activity_provider.dart';
import '../../providers/streak_provider.dart';
import '../../routes/app_routes.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late List<Animation<Offset>> _itemSlides;
  late Animation<double> _headerFade;

  static const int _itemCount = 7;

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

    _itemSlides = List.generate(_itemCount, (i) {
      final start = 0.1 + i * 0.08;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.4, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      context.read<ActivityProvider>().load();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              FadeTransition(
                opacity: _headerFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
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
                            child: Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Activity History',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 22,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Streak + stats summary ---
              FadeTransition(
                opacity: _headerFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _StatChip(
                        emoji: '🔥',
                        label: '$streak day streak',
                        color: const Color(0xFFFFB0BE),
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        emoji: '⚡',
                        label: '${activity.totalFocusMinutes} min total',
                        color: const Color(0xFFB4EAA9),
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        emoji: '📅',
                        label: '${activity.sessionsToday} sessions today',
                        color: const Color(0xFFBDE8FF),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.analytics),
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('View stats'),
                ),
              ),
              const SizedBox(height: 12),

              // --- Activity list ---
              Expanded(
                child: activity.isLoading && activity.events.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : activity.error != null && activity.events.isEmpty
                    ? _EmptyState(message: activity.error!)
                    : activity.events.isEmpty
                    ? const _EmptyState(message: 'No activity yet.')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: activity.events.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final slide = index < _itemSlides.length
                              ? _itemSlides[index]
                              : _itemSlides.last;
                          final item = activity.events[index];
                          return SlideTransition(
                            position: slide,
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: _ActivityCard(item: item),
                            ),
                          );
                        },
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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: AppTextStyles.body.copyWith(color: AppColors.primaryBlue),
          textAlign: TextAlign.center,
        ),
      ),
    );
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

// ---------------------------------------------------------------------------
// Stat chip
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.emoji,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.muted.copyWith(
                  fontSize: 11,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
