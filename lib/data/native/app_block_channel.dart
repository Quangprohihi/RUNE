import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppBlockChannel {
  static const MethodChannel _channel = MethodChannel('zenzoo/app_block');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasUsageAccess() async {
    if (!_isAndroid) return false;
    return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
  }

  Future<void> openUsageAccessSettings() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('openUsageAccessSettings');
  }

  Future<bool> hasNotificationPermission() async {
    if (!_isAndroid) return true;
    return await _channel.invokeMethod<bool>('hasNotificationPermission') ??
        false;
  }

  Future<bool> requestNotificationPermission() async {
    if (!_isAndroid) return true;
    return await _channel.invokeMethod<bool>('requestNotificationPermission') ??
        false;
  }

  Future<bool> hasAccessibilityPermission() async {
    if (!_isAndroid) return false;
    return await _channel.invokeMethod<bool>('hasAccessibilityPermission') ??
        false;
  }

  Future<void> openAccessibilitySettings() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('openAccessibilitySettings');
  }

  Future<void> startBlocking(Set<String> packages) async {
    if (!_isAndroid || packages.isEmpty) return;
    await _channel.invokeMethod<void>('startBlocking', {
      'packages': packages.toList(growable: false),
    });
  }

  Future<void> stopBlocking() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('stopBlocking');
  }

  /// Number of times the Focus Guard caught the user opening a blocked app
  /// during the current session. Reset when a new session starts.
  Future<int> getBlockCount() async {
    if (!_isAndroid) return 0;
    return await _channel.invokeMethod<int>('getBlockCount') ?? 0;
  }

  Future<void> resetBlockCount() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('resetBlockCount');
  }
}
