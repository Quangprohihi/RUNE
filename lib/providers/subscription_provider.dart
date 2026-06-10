import 'package:flutter/foundation.dart';

import '../core/errors/friendly_error.dart';
import '../data/api/api_client.dart';
import '../models/subscription.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._api);

  final ApiClient _api;
  Subscription _subscription = Subscription.free();
  bool _isLoading = false;
  String? _error;

  Subscription get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Drops the previous account's subscription state after an account
  /// switch; the premium screen refetches on open.
  void resetForAccountSwitch() {
    _subscription = Subscription.free();
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.get('/me/subscription') as Map<String, dynamic>;
      _subscription = Subscription.fromJson(response);
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> demoUpgrade() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.post('/me/subscription/demo-upgrade')
              as Map<String, dynamic>;
      _subscription = Subscription.fromJson(response);
    } catch (error) {
      _error = friendlyError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
