import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../models/activity_event.dart';

class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._api);

  final ApiClient _api;
  final List<ActivityEvent> _events = [];
  final List<FocusHistorySession> _focusSessions = [];
  bool _isLoading = false;
  String? _error;

  List<ActivityEvent> get events => List.unmodifiable(_events);
  List<FocusHistorySession> get focusSessions =>
      List.unmodifiable(_focusSessions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalFocusMinutes {
    return _focusSessions.fold(
      0,
      (sum, session) => sum + session.plannedMinutes,
    );
  }

  int get sessionsToday {
    final now = DateTime.now();
    return _focusSessions.where((session) {
      final completed = session.completedAt ?? session.startedAt;
      return completed.year == now.year &&
          completed.month == now.month &&
          completed.day == now.day;
    }).length;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.get('/activity-events') as Map<String, dynamic>;
      _events
        ..clear()
        ..addAll(
          (response['events'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(ActivityEvent.fromJson),
        );
      _focusSessions
        ..clear()
        ..addAll(
          (response['focusSessions'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(FocusHistorySession.fromJson),
        );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
