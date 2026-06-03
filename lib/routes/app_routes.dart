import 'package:flutter/material.dart';

import '../presentation/analytics/analytics_screen.dart';
import '../presentation/blocking/app_blocking_screen.dart';
import '../presentation/focus/focus_screen.dart';
import '../presentation/focus/focus_summary_screen.dart';
import '../presentation/history/history_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/notifications/notifications_screen.dart';
import '../presentation/pet/pet_profile_screen.dart';
import '../presentation/premium/premium_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/shop/shop_screen.dart';
import '../presentation/tasks/daily_tasks_screen.dart';
import '../presentation/timer/set_focus_timer_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String focus = '/focus';
  static const String pet = '/pet';
  static const String shop = '/shop';
  static const String history = '/history';
  static const String notifications = '/notifications';
  static const String setFocusTimer = '/set-focus-timer';
  static const String tasks = '/tasks';
  static const String focusSummary = '/focus-summary';
  static const String settings = '/settings';
  static const String analytics = '/analytics';
  static const String premium = '/premium';
  static const String appBlocking = '/app-blocking';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    home: (_) => const HomeScreen(),
    focus: (_) => const FocusScreen(),
    pet: (_) => const PetProfileScreen(),
    shop: (_) => const ShopScreen(),
    history: (_) => const HistoryScreen(),
    notifications: (_) => const NotificationsScreen(),
    setFocusTimer: (_) => const SetFocusTimerScreen(),
    tasks: (_) => const DailyTasksScreen(),
    focusSummary: (_) => const FocusSummaryScreen(),
    settings: (_) => const SettingsScreen(),
    analytics: (_) => const AnalyticsScreen(),
    premium: (_) => const PremiumScreen(),
    appBlocking: (_) => const AppBlockingScreen(),
  };
}
