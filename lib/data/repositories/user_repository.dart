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
}
