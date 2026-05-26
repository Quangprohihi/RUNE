import 'package:shared_preferences/shared_preferences.dart';

import '../local/prefs_keys.dart';

class TokenRepository {
  TokenRepository(this._prefs);

  final SharedPreferences _prefs;

  int load() => _prefs.getInt(PrefsKeys.tokens) ?? 1234;

  Future<void> save(int tokens) => _prefs.setInt(PrefsKeys.tokens, tokens);
}
