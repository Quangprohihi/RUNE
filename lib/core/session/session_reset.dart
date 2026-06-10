import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/native/focus_silence_service.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/app_block_provider.dart';
import '../../providers/daily_task_provider.dart';
import '../../providers/focus_plan_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/token_provider.dart';

/// Resets every account-scoped provider after a different user signs in.
///
/// [UserProvider] wipes the previous account's local storage when it detects
/// the switch; this drops the stale in-memory copies the providers loaded at
/// app start. Run it right after login succeeds and before syncing the new
/// user's server data, so the new session starts from a clean slate.
class SessionReset {
  const SessionReset._();

  static void resetAll(BuildContext context) {
    context.read<TokenProvider>().resetForAccountSwitch();
    context.read<PetProvider>().resetForAccountSwitch();
    context.read<StreakProvider>().resetForAccountSwitch();
    context.read<FocusProvider>().resetForAccountSwitch();
    context.read<ShopProvider>().resetForAccountSwitch();
    context.read<DailyTaskProvider>().resetForAccountSwitch();
    context.read<NotificationProvider>().resetForAccountSwitch();
    context.read<SettingsProvider>().resetForAccountSwitch();
    context.read<ActivityProvider>().resetForAccountSwitch();
    context.read<AchievementProvider>().resetForAccountSwitch();
    context.read<AnalyticsProvider>().resetForAccountSwitch();
    context.read<SubscriptionProvider>().resetForAccountSwitch();
    context.read<PaymentProvider>().resetForAccountSwitch();
    context.read<FocusPlanProvider>().clear();
    unawaited(context.read<AppBlockProvider>().resetForAccountSwitch());
    // Lift any leftover Do-Not-Disturb from the previous user's focus
    // session: the native silence state survives logout and process death.
    unawaited(_disableFocusSilence());
  }

  static Future<void> _disableFocusSilence() async {
    try {
      await const FocusSilenceService().disableFocusSilence();
    } catch (_) {
      // Best-effort: without notification-policy access there is nothing
      // to restore anyway.
    }
  }
}
