import 'package:shared_preferences/shared_preferences.dart';

import '../local/prefs_keys.dart';

class StreakRepository {
  StreakRepository(this._prefs);

  final SharedPreferences _prefs;

  // Default to 0: a fresh account has no streak yet. The server value
  // arrives right after login via StreakProvider.syncFromJson.
  int loadStreak() => _prefs.getInt(PrefsKeys.streak) ?? 0;

  String? loadLastFocusDate() => _prefs.getString(PrefsKeys.lastFocusDate);

  Future<void> saveStreak(int streak) =>
      _prefs.setInt(PrefsKeys.streak, streak);

  Future<void> saveLastFocusDate(String date) {
    return _prefs.setString(PrefsKeys.lastFocusDate, date);
  }
}
