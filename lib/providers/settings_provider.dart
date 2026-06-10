import 'package:flutter/foundation.dart';

import '../core/errors/friendly_error.dart';
import '../data/api/api_client.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._api);

  final ApiClient _api;
  UserSettings _settings = UserSettings.defaults();
  UserProfile? _profile;
  Subscription _subscription = Subscription.free();
  bool _isLoading = false;
  String? _error;

  UserSettings get settings => _settings;
  UserProfile? get profile => _profile;
  Subscription get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Drops the previous account's settings/profile/subscription after an
  /// account switch; the settings screen refetches on open.
  void resetForAccountSwitch() {
    _settings = UserSettings.defaults();
    _profile = null;
    _subscription = Subscription.free();
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.get('/me/settings') as Map<String, dynamic>;
      _settings = UserSettings.fromJson(
        response['settings'] as Map<String, dynamic>? ?? const {},
      );
      _profile = UserProfile.fromJson(
        response['user'] as Map<String, dynamic>? ?? const {},
      );
      _subscription = Subscription.fromJson(
        response['subscription'] as Map<String, dynamic>? ?? const {},
      );
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(UserSettings settings) async {
    _settings = settings;
    notifyListeners();
    try {
      final response =
          await _api.patch('/me/settings', body: settings.toJson())
              as Map<String, dynamic>;
      _settings = UserSettings.fromJson(response);
    } catch (error) {
      _error = friendlyError(error);
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
