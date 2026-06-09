import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/prefs_keys.dart';
import '../data/native/app_block_channel.dart';

class AppBlockProvider extends ChangeNotifier {
  AppBlockProvider(this._prefs, this._channel) {
    _load();
  }

  final SharedPreferences _prefs;
  final AppBlockChannel _channel;

  static const Set<String> _strictFocusPackages = {
    'com.android.chrome',
    'com.google.android.youtube',
    'com.zhiliaoapp.musically',
    'com.instagram.android',
    'com.facebook.katana',
    'com.android.vending',
  };

  final Set<String> _blockedPackages = <String>{};
  bool _blockingEnabled = false;
  bool _hasUsageAccess = false;
  bool _hasNotificationPermission = true;
  bool _hasAccessibilityPermission = false;
  bool _isBlockingActive = false;
  bool _isLoading = false;
  int _blockedAttempts = 0;
  String? _error;

  Set<String> get blockedPackages => Set.unmodifiable(_blockedPackages);
  bool get blockingEnabled => _blockingEnabled;
  bool get hasUsageAccess => _hasUsageAccess;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get hasAccessibilityPermission => _hasAccessibilityPermission;
  bool get hasRequiredPermissions =>
      _hasUsageAccess &&
      _hasNotificationPermission &&
      _hasAccessibilityPermission;
  bool get canStartBlocking => _blockingEnabled && hasRequiredPermissions;
  bool get isBlockingActive => _isBlockingActive;
  bool get isLoading => _isLoading;
  int get blockedAttempts => _blockedAttempts;
  String? get error => _error;

  bool isBlocked(String packageName) => _blockedPackages.contains(packageName);

  Future<void> _load() async {
    _blockingEnabled = _prefs.getBool(PrefsKeys.appBlockingEnabled) ?? false;
    _blockedPackages
      ..clear()
      ..addAll(_prefs.getStringList(PrefsKeys.blockedAppPackages) ?? const []);
    await refreshPermissions();
  }

  Future<void> refreshPermissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final usageAccess = await _channel.hasUsageAccess();
      final notificationPermission = await _channel.hasNotificationPermission();
      final accessibilityPermission = await _channel
          .hasAccessibilityPermission();
      _hasUsageAccess = usageAccess;
      _hasNotificationPermission = notificationPermission;
      _hasAccessibilityPermission = accessibilityPermission;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openUsageAccessSettings() {
    return _channel.openUsageAccessSettings();
  }

  Future<void> openAccessibilitySettings() {
    return _channel.openAccessibilitySettings();
  }

  Future<void> requestNotificationPermission() async {
    try {
      _hasNotificationPermission = await _channel
          .requestNotificationPermission();
    } catch (error) {
      _error = error.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> setBlockingEnabled(bool enabled) async {
    _blockingEnabled = enabled;
    await _prefs.setBool(PrefsKeys.appBlockingEnabled, enabled);
    notifyListeners();
    if (!enabled) {
      await stopBlocking();
    }
  }

  Future<void> toggleApp(String packageName, bool blocked) async {
    if (blocked) {
      _blockedPackages.add(packageName);
    } else {
      _blockedPackages.remove(packageName);
    }
    await _prefs.setStringList(
      PrefsKeys.blockedAppPackages,
      _blockedPackages.toList(growable: false),
    );
    notifyListeners();
  }

  Future<bool> startBlocking() async {
    await refreshPermissions();
    if (!canStartBlocking) return false;
    try {
      final packages = _blockedPackages.isEmpty
          ? _strictFocusPackages
          : _blockedPackages;
      await _channel.startBlocking(packages);
      _isBlockingActive = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      _isBlockingActive = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stopBlocking() async {
    try {
      await _channel.stopBlocking();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isBlockingActive = false;
      notifyListeners();
    }
  }

  /// Poll how many times the Focus Guard caught the user opening a blocked app
  /// during the running session, so the focus screen can surface it live.
  Future<void> refreshBlockedAttempts() async {
    try {
      final count = await _channel.getBlockCount();
      if (count != _blockedAttempts) {
        _blockedAttempts = count;
        notifyListeners();
      }
    } catch (_) {
      // Best-effort: counter stays at its last value if the channel fails.
    }
  }
}
