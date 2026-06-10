import 'dart:async';

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

  /// Reloads streak state from local storage (wiped on account switch) so a
  /// new account starts at zero instead of showing the previous user's run.
  void resetForAccountSwitch() {
    _streak = _repository.loadStreak();
    _lastFocusDate = _repository.loadLastFocusDate();
    notifyListeners();
  }

  void syncFromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    _streak = json['currentStreak'] as int? ?? _streak;
    final rawDate = json['lastFocusDate'] as String?;
    _lastFocusDate = rawDate?.split('T').first ?? _lastFocusDate;
    // Persist server truth so the local cache belongs to the current user
    // even if the app restarts offline.
    unawaited(_repository.saveStreak(_streak));
    final date = _lastFocusDate;
    if (date != null) unawaited(_repository.saveLastFocusDate(date));
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
