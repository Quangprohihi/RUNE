import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FocusSilenceService {
  const FocusSilenceService();

  static const _channel = MethodChannel('zenzoo/focus_silence');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasNotificationPolicyAccess() async {
    if (!_isAndroid) return false;
    return await _channel.invokeMethod<bool>('hasNotificationPolicyAccess') ??
        false;
  }

  Future<void> openNotificationPolicySettings() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('openNotificationPolicySettings');
  }

  Future<bool> enableFocusSilence() async {
    if (!_isAndroid) return false;
    return await _channel.invokeMethod<bool>('enableFocusSilence') ?? false;
  }

  Future<void> disableFocusSilence() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('disableFocusSilence');
  }
}
