import 'package:flutter/foundation.dart';

import '../core/errors/friendly_error.dart';
import '../data/repositories/activity_repository.dart';
import '../models/activity_event.dart';

class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._repository);

  final ActivityRepository _repository;
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

  /// Clears the previous account's cached history after an account switch;
  /// the history screen refetches on open.
  void resetForAccountSwitch() {
    _events.clear();
    _focusSessions.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final history = await _repository.loadHistory();
      _events
        ..clear()
        ..addAll(history.events);
      _focusSessions
        ..clear()
        ..addAll(history.focusSessions);
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
