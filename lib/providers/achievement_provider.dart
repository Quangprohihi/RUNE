import 'package:flutter/foundation.dart';

import '../core/errors/friendly_error.dart';
import '../data/api/api_client.dart';
import '../models/achievement_progress.dart';
import '../models/pet.dart';
import '../models/wallet.dart';

class AchievementProvider extends ChangeNotifier {
  AchievementProvider(this._api);

  final ApiClient _api;

  List<AchievementProgress> _achievements = const [];
  Wallet? _latestWallet;
  Pet? _latestPet;
  bool _isLoading = false;
  bool _isClaiming = false;
  String? _error;

  List<AchievementProgress> get achievements => _achievements;
  AchievementProgress get productivePartner {
    for (final achievement in _achievements) {
      if (achievement.code == 'productive_partner_i') return achievement;
    }
    return AchievementProgress.empty();
  }

  Wallet? get latestWallet => _latestWallet;
  Pet? get latestPet => _latestPet;
  bool get isLoading => _isLoading;
  bool get isClaiming => _isClaiming;
  String? get error => _error;

  /// Clears the previous account's cached achievements after an account
  /// switch; the achievements screen refetches on open.
  void resetForAccountSwitch() {
    _achievements = const [];
    _latestWallet = null;
    _latestPet = null;
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.get('/achievements') as Map<String, dynamic>;
      _achievements = (response['achievements'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(AchievementProgress.fromJson)
          .toList();
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> claimProductivePartner() async {
    return claim('productive_partner_i');
  }

  Future<bool> claim(String code) async {
    final achievement = _achievementByCode(code);
    if (achievement == null || !achievement.canClaim || _isClaiming) {
      return false;
    }
    _isClaiming = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.post('/achievements/$code/claim') as Map<String, dynamic>;
      final updatedAchievement = AchievementProgress.fromJson(
        response['achievement'] as Map<String, dynamic>? ?? const {},
      );
      _upsertAchievement(updatedAchievement);
      _latestWallet = Wallet.fromJson(
        response['wallet'] as Map<String, dynamic>? ?? const {},
      );
      _latestPet = Pet.fromJson(
        response['pet'] as Map<String, dynamic>? ?? const {},
      );
      return true;
    } catch (error) {
      _error = friendlyError(error);
      return false;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }

  AchievementProgress? _achievementByCode(String code) {
    for (final achievement in _achievements) {
      if (achievement.code == code) return achievement;
    }
    return null;
  }

  void _upsertAchievement(AchievementProgress achievement) {
    final index = _achievements.indexWhere(
      (item) => item.code == achievement.code,
    );
    if (index == -1) {
      _achievements = [..._achievements, achievement];
      return;
    }
    _achievements = [
      ..._achievements.take(index),
      achievement,
      ..._achievements.skip(index + 1),
    ];
  }
}
