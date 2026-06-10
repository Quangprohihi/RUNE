import 'package:flutter/foundation.dart';

import '../core/errors/friendly_error.dart';
import '../data/repositories/notification_repository.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repository);

  final NotificationRepository _repository;
  final List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  /// Clears the previous account's cached notifications after an account
  /// switch; the notifications screen refetches on open.
  void resetForAccountSwitch() {
    _notifications.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final notifications = await _repository.loadNotifications();
      _notifications
        ..clear()
        ..addAll(notifications);
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    await load();
  }
}
