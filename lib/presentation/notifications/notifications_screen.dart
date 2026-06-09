import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late List<Animation<double>> _itemFades;
  late List<Animation<Offset>> _itemSlides;
  late Animation<double> _headerFade;

  static const int _itemCount = 5;

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
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _itemFades = List.generate(_itemCount, (i) {
      final start = 0.1 + i * 0.1;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _itemSlides = List.generate(_itemCount, (i) {
      final start = 0.1 + i * 0.1;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
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
      context.read<NotificationProvider>().load();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5FBFF), Color(0xFFE8F4FF)],
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
                        'Notifications',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 22,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: provider.markAllRead,
                        child: Text(
                          'Mark all read',
                          style: AppTextStyles.muted.copyWith(
                            color: AppColors.accentSky,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Notification list ---
              Expanded(
                child: provider.isLoading && notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null && notifications.isEmpty
                    ? _EmptyState(message: provider.error!)
                    : notifications.isEmpty
                    ? const _EmptyState(message: 'No notifications yet.')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final fade = index < _itemFades.length
                              ? _itemFades[index]
                              : _itemFades.last;
                          final slide = index < _itemSlides.length
                              ? _itemSlides[index]
                              : _itemSlides.last;
                          final notif = notifications[index];
                          return FadeTransition(
                            opacity: fade,
                            child: SlideTransition(
                              position: slide,
                              child: _NotificationCard(notif: notif),
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
// Notification card
// ---------------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notif});

  final AppNotification notif;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: notif.isRead ? Colors.white : const Color(0xFFF0FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.isRead
              ? const Color(0xFFE0E0E0)
              : AppColors.accentTeal.withValues(alpha: 0.5),
          width: notif.isRead ? 1 : 1.5,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _avatarColor(notif.notificationType),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(notif.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Message + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.message,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: notif.isRead
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(notif.createdAt),
                  style: AppTextStyles.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          // Unread indicator dot
          if (!notif.isRead)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentSky,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _avatarColor(String type) {
    return switch (type) {
      'focus_completed' => const Color(0xFFB4EAA9),
      'daily_task_claimed' => const Color(0xFFD4F0D4),
      'shop_purchase' => const Color(0xFFFFE0E0),
      'welcome' => const Color(0xFFFFE4B5),
      _ => const Color(0xFFE8E0FF),
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
