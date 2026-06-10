import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_profile.dart';
import '../local/prefs_keys.dart';

class UserRepository {
  UserRepository(this._prefs);

  final SharedPreferences _prefs;

  UserProfile load() {
    final raw = _prefs.getString(PrefsKeys.userProfile);
    if (raw == null) return UserProfile.guest();
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(UserProfile profile) {
    return _prefs.setString(
      PrefsKeys.userProfile,
      jsonEncode(profile.toJson()),
    );
  }

  Future<void> clear() {
    return _prefs.remove(PrefsKeys.userProfile);
  }

  /// The id of the account whose data currently lives in local storage.
  /// Survives logout on purpose: it lets the next login detect whether it is
  /// the same person returning (keep local data) or a different account
  /// (wipe it first).
  String? loadCurrentUserId() => _prefs.getString(PrefsKeys.currentUserId);

  Future<void> saveCurrentUserId(String userId) {
    return _prefs.setString(PrefsKeys.currentUserId, userId);
  }

  /// Removes every account-scoped key so a newly signed-in account starts
  /// from a clean slate instead of inheriting the previous user's progress.
  Future<void> clearAccountScopedData() async {
    for (final key in PrefsKeys.accountScoped) {
      await _prefs.remove(key);
    }
  }

  /// One-time migration: older builds stored a single device-wide
  /// "onboarding seen" flag. Attribute it to [userId] (the account already
  /// using this device) so they don't see onboarding again, then drop the
  /// global flag so future new accounts still get it.
  Future<void> migrateLegacyOnboardingFlag(String userId) async {
    if (_prefs.getBool(PrefsKeys.onboardingSeen) ?? false) {
      await _prefs.setBool(PrefsKeys.onboardingSeenFor(userId), true);
      await _prefs.remove(PrefsKeys.onboardingSeen);
    }
  }
}
