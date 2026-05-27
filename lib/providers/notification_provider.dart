import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._api);

  final ApiClient _api;
  final List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.get('/notifications') as List<dynamic>;
      _notifications
        ..clear()
        ..addAll(
          response.cast<Map<String, dynamic>>().map(AppNotification.fromJson),
        );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/mark-all-read');
    await load();
  }
}
