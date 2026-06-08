import '../../models/app_notification.dart';
import '../api/api_client.dart';

class NotificationRepository {
  const NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> loadNotifications() async {
    final response = await _api.get('/notifications') as List<dynamic>;
    return response
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/mark-all-read');
  }
}
