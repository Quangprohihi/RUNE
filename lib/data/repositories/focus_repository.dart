import 'package:shared_preferences/shared_preferences.dart';

import '../local/prefs_keys.dart';

class FocusRepository {
  FocusRepository(this._prefs);

  final SharedPreferences _prefs;

  int loadSessionsToday() => _prefs.getInt(PrefsKeys.sessionsToday) ?? 0;

  int loadTotalFocusMinutes() {
    return _prefs.getInt(PrefsKeys.totalFocusMinutes) ?? 0;
  }

  Future<void> saveSessionsToday(int value) {
    return _prefs.setInt(PrefsKeys.sessionsToday, value);
  }

  Future<void> saveTotalFocusMinutes(int value) {
    return _prefs.setInt(PrefsKeys.totalFocusMinutes, value);
  }
}
