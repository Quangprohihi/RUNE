import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../models/daily_task.dart';
import '../models/wallet.dart';

class DailyTaskProvider extends ChangeNotifier {
  DailyTaskProvider(this._api);

  final ApiClient _api;
  final List<DailyTask> _tasks = [];
  final List<DailyMilestone> _milestones = [];
  int _totalPoints = 0;
  bool _isLoading = false;
  String? _error;
  Wallet? _latestWallet;

  List<DailyTask> get tasks => List.unmodifiable(_tasks);
  List<DailyMilestone> get milestones => List.unmodifiable(_milestones);
  int get totalPoints => _totalPoints;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Wallet? get latestWallet => _latestWallet;

  Future<void> loadToday() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.get('/daily-tasks/today') as Map<String, dynamic>;
      _tasks
        ..clear()
        ..addAll(
          (response['tasks'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(DailyTask.fromJson),
        );
      _milestones
        ..clear()
        ..addAll(
          (response['milestones'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(DailyMilestone.fromJson),
        );
      _totalPoints = response['totalPoints'] as int? ?? 0;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> claim(String taskId) async {
    final response =
        await _api.post('/daily-tasks/$taskId/claim') as Map<String, dynamic>;
    _latestWallet = Wallet.fromJson(
      response['wallet'] as Map<String, dynamic>? ?? const {},
    );
    await loadToday();
  }
}
