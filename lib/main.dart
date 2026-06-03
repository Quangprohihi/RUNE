import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/api/api_client.dart';
import 'data/repositories/focus_repository.dart';
import 'data/repositories/pet_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'data/repositories/streak_repository.dart';
import 'data/repositories/token_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/native/app_block_channel.dart';
import 'providers/app_block_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/focus_plan_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/daily_task_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/token_provider.dart';
import 'providers/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (_) => UserProvider(UserRepository(prefs), apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => TokenProvider(TokenRepository(prefs), apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => PetProvider(PetRepository(prefs), apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => StreakProvider(StreakRepository(prefs)),
        ),
        ChangeNotifierProvider(
          create: (_) => FocusProvider(FocusRepository(prefs), apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => AppBlockProvider(prefs, AppBlockChannel()),
        ),
        ChangeNotifierProvider(create: (_) => FocusPlanProvider(apiClient)),
        ChangeNotifierProvider(
          create: (_) => ShopProvider(ShopRepository(prefs), apiClient),
        ),
        ChangeNotifierProvider(create: (_) => DailyTaskProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ActivityProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => AchievementProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider(apiClient)),
      ],
      child: const ZenZooApp(),
    ),
  );
}
