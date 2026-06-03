import 'package:shared_preferences/shared_preferences.dart';

import '../local/prefs_keys.dart';

class FocusRepository {
  FocusRepository(this._prefs);

  final SharedPreferences _prefs;

  int loadSessionsToday() => _prefs.getInt(PrefsKeys.sessionsToday) ?? 0;

  int loadTodayFocusMinutes() {
    return _prefs.getInt(PrefsKeys.todayFocusMinutes) ?? 0;
  }

  int loadTotalFocusMinutes() {
    return _prefs.getInt(PrefsKeys.totalFocusMinutes) ?? 0;
  }

  String? loadLastFocusDate() {
    return _prefs.getString(PrefsKeys.lastFocusDate);
  }

  Future<void> saveSessionsToday(int value) {
    return _prefs.setInt(PrefsKeys.sessionsToday, value);
  }

  Future<void> saveTodayFocusMinutes(int value) {
    return _prefs.setInt(PrefsKeys.todayFocusMinutes, value);
  }

  Future<void> saveTotalFocusMinutes(int value) {
    return _prefs.setInt(PrefsKeys.totalFocusMinutes, value);
  }

  Future<void> saveLastFocusDate(String value) {
    return _prefs.setString(PrefsKeys.lastFocusDate, value);
  }
}
