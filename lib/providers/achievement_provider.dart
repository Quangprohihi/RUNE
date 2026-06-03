import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../models/achievement_progress.dart';
import '../models/pet.dart';
import '../models/wallet.dart';

class AchievementProvider extends ChangeNotifier {
  AchievementProvider(this._api);

  final ApiClient _api;

  AchievementProgress _productivePartner = AchievementProgress.empty();
  Wallet? _latestWallet;
  Pet? _latestPet;
  bool _isLoading = false;
  bool _isClaiming = false;
  String? _error;

  AchievementProgress get productivePartner => _productivePartner;
  Wallet? get latestWallet => _latestWallet;
  Pet? get latestPet => _latestPet;
  bool get isLoading => _isLoading;
  bool get isClaiming => _isClaiming;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.get('/achievements') as Map<String, dynamic>;
      final achievements =
          (response['achievements'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
      final matches = achievements.where(
        (achievement) => achievement['code'] == 'productive_partner_i',
      );
      _productivePartner = matches.isEmpty
          ? AchievementProgress.empty()
          : AchievementProgress.fromJson(matches.first);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> claimProductivePartner() async {
    if (!_productivePartner.canClaim || _isClaiming) return false;
    _isClaiming = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.post('/achievements/${_productivePartner.code}/claim')
              as Map<String, dynamic>;
      _productivePartner = AchievementProgress.fromJson(
        response['achievement'] as Map<String, dynamic>? ?? const {},
      );
      _latestWallet = Wallet.fromJson(
        response['wallet'] as Map<String, dynamic>? ?? const {},
      );
      _latestPet = Pet.fromJson(
        response['pet'] as Map<String, dynamic>? ?? const {},
      );
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }
}
