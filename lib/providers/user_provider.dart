import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/repositories/user_repository.dart';
import '../models/user_profile.dart';
import '../models/wallet.dart';
import '../models/pet.dart';

class UserProvider extends ChangeNotifier {
  UserProvider(this._repository, this._api) : _profile = _repository.load() {
    _api.userId = _profile.id;
  }

  final UserRepository _repository;
  final ApiClient _api;
  UserProfile _profile;
  Wallet? _latestWallet;
  Pet? _latestPet;
  Map<String, dynamic>? _latestStreak;
  bool _isLoading = false;
  String? _error;

  UserProfile get profile => _profile;
  Wallet? get latestWallet => _latestWallet;
  Pet? get latestPet => _latestPet;
  Map<String, dynamic>? get latestStreak => _latestStreak;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasLoggedIn => _profile.hasLoggedIn && _profile.id.isNotEmpty;

  Future<void> login(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.post('/auth/demo-login', body: {'email': email.trim()})
              as Map<String, dynamic>;
      _applyBootstrap(response);
      await _repository.save(_profile);
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBootstrap() async {
    if (!hasLoggedIn) return;
    try {
      final response = await _api.get('/me/bootstrap') as Map<String, dynamic>;
      _applyBootstrap(response);
      await _repository.save(_profile);
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _profile = UserProfile.guest();
    _latestWallet = null;
    _latestPet = null;
    _latestStreak = null;
    _api.userId = null;
    await _repository.clear();
    notifyListeners();
  }

  void _applyBootstrap(Map<String, dynamic> response) {
    final user = response['user'] as Map<String, dynamic>? ?? const {};
    _profile = UserProfile(
      id: user['id'] as String? ?? '',
      displayName: user['displayName'] as String? ?? 'Friend',
      email: user['email'] as String? ?? '',
      hasLoggedIn: true,
    );
    _api.userId = _profile.id;
    _latestWallet = Wallet.fromJson(
      response['wallet'] as Map<String, dynamic>? ?? const {},
    );
    _latestPet = Pet.fromJson(
      response['pet'] as Map<String, dynamic>? ?? const {},
    );
    _latestStreak = response['streak'] as Map<String, dynamic>?;
  }
}
