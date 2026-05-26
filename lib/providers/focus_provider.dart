import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/focus_repository.dart';

enum FocusPhase { idle, focusing, breakTime, done }

class FocusProvider extends ChangeNotifier {
  FocusProvider(this._repository)
    : _sessionsToday = _repository.loadSessionsToday(),
      _totalFocusMinutes = _repository.loadTotalFocusMinutes();

  final FocusRepository _repository;
  Timer? _timer;
  FocusPhase _phase = FocusPhase.idle;
  DateTime? _phaseStartedAt;
  int _phaseDurationSeconds = AppConstants.focusDurationSeconds;
  int _remainingSeconds = AppConstants.focusDurationSeconds;
  int _sessionsToday;
  int _totalFocusMinutes;
  String _label = 'Study';
  bool _rewardClaimed = false;

  FocusPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  int get sessionsToday => _sessionsToday;
  int get totalFocusMinutes => _totalFocusMinutes;
  String get label => _label;
  bool get isRunning =>
      _phase == FocusPhase.focusing || _phase == FocusPhase.breakTime;
  bool get canClaim => _phase == FocusPhase.done && !_rewardClaimed;

  double get progress {
    if (_phaseDurationSeconds == 0) return 0;
    return 1 - (_remainingSeconds / _phaseDurationSeconds);
  }

  String get formattedRemaining {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void start({String label = 'Study'}) {
    _label = label;
    _rewardClaimed = false;
    _startPhase(FocusPhase.focusing, AppConstants.focusDurationSeconds);
  }

  void startBreak() {
    _startPhase(FocusPhase.breakTime, AppConstants.breakDurationSeconds);
  }

  void cancel() {
    _timer?.cancel();
    _phase = FocusPhase.idle;
    _remainingSeconds = AppConstants.focusDurationSeconds;
    notifyListeners();
  }

  Future<void> claimReward() async {
    if (!canClaim) return;
    _rewardClaimed = true;
    _sessionsToday += 1;
    _totalFocusMinutes += AppConstants.focusMinutes;
    await _repository.saveSessionsToday(_sessionsToday);
    await _repository.saveTotalFocusMinutes(_totalFocusMinutes);
    _phase = FocusPhase.idle;
    _remainingSeconds = AppConstants.focusDurationSeconds;
    notifyListeners();
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
        _phase = FocusPhase.idle;
        _remainingSeconds = AppConstants.focusDurationSeconds;
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
