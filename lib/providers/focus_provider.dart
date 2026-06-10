import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../data/api/api_client.dart';
import '../data/repositories/focus_repository.dart';

enum FocusPhase { idle, focusing, breakTime, done }

class FocusProvider extends ChangeNotifier {
  FocusProvider(this._repository, this._api)
    : _sessionsToday = _repository.loadSessionsToday(),
      _todayFocusMinutes = _repository.loadTodayFocusMinutes(),
      _totalFocusMinutes = _repository.loadTotalFocusMinutes() {
    _resetDailyProgressIfNeeded();
  }

  final FocusRepository _repository;
  final ApiClient _api;
  Timer? _timer;
  FocusPhase _phase = FocusPhase.idle;
  DateTime? _phaseStartedAt;
  int _phaseDurationSeconds = AppConstants.focusDurationSeconds;
  int _remainingSeconds = AppConstants.focusDurationSeconds;
  int _plannedFocusDurationSeconds = AppConstants.focusMinutes * 60;
  int _sessionsToday;
  int _todayFocusMinutes;
  int _totalFocusMinutes;
  String _label = 'Study';
  String _companionCode = 'kiki';
  bool _rewardClaimed = false;
  String? _remoteSessionId;
  bool _breakReturnsToDone = false;
  bool _breakTakenForSession = false;

  FocusPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  int get sessionsToday => _sessionsToday;
  int get todayFocusMinutes => _todayFocusMinutes;
  int get totalFocusMinutes => _totalFocusMinutes;
  String get label => _label;
  String get companionCode => _companionCode;
  int get plannedFocusMinutes => (_plannedFocusDurationSeconds / 60).round();
  int get dailyGoalMinutes => AppConstants.dailyGoalMinutes;
  double get dailyGoalProgress =>
      (_todayFocusMinutes / dailyGoalMinutes).clamp(0, 1).toDouble();
  int get dailyGoalRemainingMinutes => (dailyGoalMinutes - _todayFocusMinutes)
      .clamp(0, dailyGoalMinutes)
      .toInt();
  bool get dailyGoalCompleted => _todayFocusMinutes >= dailyGoalMinutes;
  bool get isRunning =>
      _phase == FocusPhase.focusing || _phase == FocusPhase.breakTime;
  bool get canClaim => _phase == FocusPhase.done && !_rewardClaimed;
  bool get canStartBreakAfterFocus =>
      _phase == FocusPhase.done && !_rewardClaimed && !_breakTakenForSession;
  int get pomodoroCount => plannedFocusMinutes <= 25 ? 1 : 2;
  String get pomodoroLabel =>
      plannedFocusMinutes <= 25 ? '1 Pomodoro' : 'Deep Focus · 2 Pomodoros';

  double get progress {
    if (_phaseDurationSeconds == 0) return 0;
    return 1 - (_remainingSeconds / _phaseDurationSeconds);
  }

  String get formattedRemaining {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get _idleFocusDurationSeconds {
    return AppConstants.useTestFocusDuration
        ? AppConstants.testFocusSeconds
        : _plannedFocusDurationSeconds;
  }

  /// Clears any running timer and reloads daily/total focus stats from local
  /// storage (wiped on account switch) so a new account starts at zero.
  void resetForAccountSwitch() {
    _timer?.cancel();
    _phase = FocusPhase.idle;
    _rewardClaimed = false;
    _remoteSessionId = null;
    _breakReturnsToDone = false;
    _breakTakenForSession = false;
    _sessionsToday = _repository.loadSessionsToday();
    _todayFocusMinutes = _repository.loadTodayFocusMinutes();
    _totalFocusMinutes = _repository.loadTotalFocusMinutes();
    _plannedFocusDurationSeconds = AppConstants.focusMinutes * 60;
    _remainingSeconds = _idleFocusDurationSeconds;
    notifyListeners();
  }

  void start({
    String label = 'Study',
    int? durationSeconds,
    String companionCode = 'kiki',
  }) {
    _label = label;
    _companionCode = companionCode;
    _plannedFocusDurationSeconds =
        durationSeconds ?? AppConstants.focusMinutes * 60;
    _rewardClaimed = false;
    _remoteSessionId = null;
    _breakReturnsToDone = false;
    _breakTakenForSession = false;
    _createRemoteSession();
    _startPhase(FocusPhase.focusing, _idleFocusDurationSeconds);
  }

  void startBreak() {
    _breakReturnsToDone = false;
    _startPhase(FocusPhase.breakTime, AppConstants.breakDurationSeconds);
  }

  void startBreakAfterFocus() {
    if (!canStartBreakAfterFocus) return;
    _breakReturnsToDone = true;
    _breakTakenForSession = true;
    _startPhase(FocusPhase.breakTime, AppConstants.breakDurationSeconds);
  }

  void cancel() {
    _timer?.cancel();
    _phase = FocusPhase.idle;
    _breakReturnsToDone = false;
    _remainingSeconds = _idleFocusDurationSeconds;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> claimReward() async {
    if (!canClaim) return null;
    _rewardClaimed = true;
    _sessionsToday += 1;
    _todayFocusMinutes += plannedFocusMinutes;
    _totalFocusMinutes += plannedFocusMinutes;
    final todayKey = _todayKey();
    await _repository.saveSessionsToday(_sessionsToday);
    await _repository.saveTodayFocusMinutes(_todayFocusMinutes);
    await _repository.saveTotalFocusMinutes(_totalFocusMinutes);
    await _repository.saveLastFocusDate(todayKey);
    final remoteResult = await _completeRemoteSession();
    _phase = FocusPhase.idle;
    _remainingSeconds = _idleFocusDurationSeconds;
    notifyListeners();
    return remoteResult;
  }

  void _resetDailyProgressIfNeeded() {
    final todayKey = _todayKey();
    final lastFocusDate = _repository.loadLastFocusDate();
    if (lastFocusDate == todayKey) return;
    _sessionsToday = 0;
    _todayFocusMinutes = 0;
    unawaited(_repository.saveSessionsToday(_sessionsToday));
    unawaited(_repository.saveTodayFocusMinutes(_todayFocusMinutes));
    unawaited(_repository.saveLastFocusDate(todayKey));
  }

  String _todayKey() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _createRemoteSession() async {
    try {
      final response =
          await _api.post(
                '/focus-sessions/start',
                body: {
                  'label': _label,
                  'plannedMinutes': plannedFocusMinutes,
                  'companionCode': _companionCode,
                },
              )
              as Map<String, dynamic>;
      _remoteSessionId = response['id'] as String?;
    } catch (_) {
      // Keep local timer usable if the API is temporarily unavailable.
    }
  }

  Future<Map<String, dynamic>?> _completeRemoteSession() async {
    final sessionId = _remoteSessionId;
    if (sessionId == null || sessionId.isEmpty) return null;
    try {
      return await _api.post(
            '/focus-sessions/$sessionId/complete',
            body: {'actualSeconds': _plannedFocusDurationSeconds},
          )
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _startPhase(FocusPhase phase, int seconds) {
    _timer?.cancel();
    _phase = phase;
    _phaseStartedAt = DateTime.now();
    _phaseDurationSeconds = seconds;
    _remainingSeconds = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    final startedAt = _phaseStartedAt;
    if (startedAt == null) return;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    _remainingSeconds = (_phaseDurationSeconds - elapsed).clamp(0, 999999);
    if (_remainingSeconds == 0) {
      _timer?.cancel();
      if (_phase == FocusPhase.focusing) {
        _phase = FocusPhase.done;
      } else if (_phase == FocusPhase.breakTime) {
        if (_breakReturnsToDone) {
          _breakReturnsToDone = false;
          _phase = FocusPhase.done;
        } else {
          _phase = FocusPhase.idle;
          _remainingSeconds = _idleFocusDurationSeconds;
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
