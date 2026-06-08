import '../../models/activity_event.dart';
import '../api/api_client.dart';

class ActivityRepository {
  const ActivityRepository(this._api);

  final ApiClient _api;

  Future<ActivityHistory> loadHistory() async {
    final response = await _api.get('/activity-events') as Map<String, dynamic>;
    return ActivityHistory(
      events: (response['events'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ActivityEvent.fromJson)
          .toList(),
      focusSessions: (response['focusSessions'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(FocusHistorySession.fromJson)
          .toList(),
    );
  }
}

class ActivityHistory {
  const ActivityHistory({required this.events, required this.focusSessions});

  final List<ActivityEvent> events;
  final List<FocusHistorySession> focusSessions;
}
