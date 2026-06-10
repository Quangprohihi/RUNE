import 'package:flutter/foundation.dart';

import '../core/errors/friendly_error.dart';
import '../data/api/api_client.dart';
import '../models/focus_plan.dart';

enum FocusPlanStatus { idle, loading, ready, error }

class FocusPlanProvider extends ChangeNotifier {
  FocusPlanProvider(this._api);

  final ApiClient _api;
  FocusPlanStatus _status = FocusPlanStatus.idle;
  FocusPlan? _plan;
  String? _error;

  FocusPlanStatus get status => _status;
  FocusPlan? get plan => _plan;
  String? get error => _error;
  bool get isLoading => _status == FocusPlanStatus.loading;

  Future<void> analyze({
    required String goal,
    required int selectedMinutes,
    required String selectedTask,
  }) async {
    if (goal.trim().isEmpty) {
      _plan = FocusPlan.fallback(
        goal: goal,
        selectedMinutes: selectedMinutes,
        selectedTask: selectedTask,
      );
      _status = FocusPlanStatus.ready;
      _error = null;
      notifyListeners();
      return;
    }

    _status = FocusPlanStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _api.post(
                '/focus-plans/analyze',
                body: {
                  'goal': goal.trim(),
                  'selectedMinutes': selectedMinutes,
                  'selectedTask': selectedTask,
                },
              )
              as Map<String, dynamic>;
      _plan = FocusPlan.fromJson(response);
      _status = FocusPlanStatus.ready;
    } catch (error) {
      _plan = FocusPlan.fallback(
        goal: goal,
        selectedMinutes: selectedMinutes,
        selectedTask: selectedTask,
      );
      _status = FocusPlanStatus.error;
      _error = friendlyError(error);
    }
    notifyListeners();
  }

  void clear() {
    _status = FocusPlanStatus.idle;
    _plan = null;
    _error = null;
    notifyListeners();
  }
}
