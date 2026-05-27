import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/streak_repository.dart';

class StreakProvider extends ChangeNotifier {
  StreakProvider(this._repository)
    : _streak = _repository.loadStreak(),
      _lastFocusDate = _repository.loadLastFocusDate() {
    applySoftDropIfNeeded();
  }

  final StreakRepository _repository;
  int _streak;
  String? _lastFocusDate;

  int get streak => _streak;

  void syncFromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    _streak = json['currentStreak'] as int? ?? _streak;
    final rawDate = json['lastFocusDate'] as String?;
    _lastFocusDate = rawDate?.split('T').first ?? _lastFocusDate;
    notifyListeners();
  }

  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> applySoftDropIfNeeded() async {
    if (_lastFocusDate == null || _lastFocusDate == todayKey) return;
    final last = DateTime.tryParse(_lastFocusDate!);
    if (last == null) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);
    if (_lastFocusDate != yesterdayKey) {
      _streak = (_streak - AppConstants.streakSoftDrop).clamp(0, 999).toInt();
      await _repository.saveStreak(_streak);
      notifyListeners();
    }
  }

  Future<void> markFocusedToday() async {
    if (_lastFocusDate == todayKey) return;
    _streak += 1;
    _lastFocusDate = todayKey;
    await _repository.saveStreak(_streak);
    await _repository.saveLastFocusDate(_lastFocusDate!);
    notifyListeners();
  }
}
