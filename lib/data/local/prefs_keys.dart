class PrefsKeys {
  const PrefsKeys._();

  static const String userProfile = 'user_profile';
  static const String currentUserId = 'current_user_id';
  static const String pet = 'pet';
  static const String petRoster = 'pet_roster';
  static const String tokens = 'tokens';
  static const String streak = 'streak';
  static const String lastFocusDate = 'last_focus_date';
  static const String sessionsToday = 'sessions_today';
  static const String todayFocusMinutes = 'today_focus_minutes';
  static const String totalFocusMinutes = 'total_focus_minutes';
  static const String ownedItems = 'owned_items';
  static const String inventoryQuantities = 'inventory_quantities';
  static const String appBlockingEnabled = 'app_blocking_enabled';
  static const String blockedAppPackages = 'blocked_app_packages';

  /// Legacy device-wide onboarding flag. Superseded by [onboardingSeenFor];
  /// kept only to migrate existing installs and as a guest fallback.
  static const String onboardingSeen = 'onboarding_seen';

  /// Per-account onboarding flag, so every new account gets the welcome
  /// carousel exactly once while returning accounts never see it again.
  static String onboardingSeenFor(String userId) => 'onboarding_seen_$userId';

  /// Every key that stores one account's progress. Wiped when a different
  /// user signs in on this device so a new account never inherits the
  /// previous user's island, wallet, streak, or inventory.
  /// (Onboarding flags are intentionally excluded: they are per-user keys.)
  static const List<String> accountScoped = [
    pet,
    petRoster,
    tokens,
    streak,
    lastFocusDate,
    sessionsToday,
    todayFocusMinutes,
    totalFocusMinutes,
    ownedItems,
    inventoryQuantities,
    appBlockingEnabled,
    blockedAppPackages,
  ];
}
