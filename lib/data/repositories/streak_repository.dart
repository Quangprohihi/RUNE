import 'package:shared_preferences/shared_preferences.dart';

import '../local/prefs_keys.dart';

class StreakRepository {
  StreakRepository(this._prefs);

  final SharedPreferences _prefs;

  int loadStreak() => _prefs.getInt(PrefsKeys.streak) ?? 30;

  String? loadLastFocusDate() => _prefs.getString(PrefsKeys.lastFocusDate);

  Future<void> saveStreak(int streak) =>
      _prefs.setInt(PrefsKeys.streak, streak);

  Future<void> saveLastFocusDate(String date) {
    return _prefs.setString(PrefsKeys.lastFocusDate, date);
  }
}
