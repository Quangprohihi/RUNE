import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/repositories/token_repository.dart';
import '../models/wallet.dart';

class TokenProvider extends ChangeNotifier {
  TokenProvider(this._repository, this._api) : _tokens = _repository.load();

  final TokenRepository _repository;
  final ApiClient _api;
  int _tokens;
  int _energy = 0;
  int _diamonds = 0;

  int get tokens => _tokens;
  int get energy => _energy;
  int get diamonds => _diamonds;

  /// Drops the previous account's wallet counters and reloads from local
  /// storage (already wiped on account switch, so this yields zeros until
  /// the new user's server wallet arrives via [syncWallet]).
  void resetForAccountSwitch() {
    _tokens = _repository.load();
    _energy = 0;
    _diamonds = 0;
    notifyListeners();
  }

  void syncWallet(Wallet wallet) {
    _tokens = wallet.tokens;
    _energy = wallet.energy;
    _diamonds = wallet.diamonds;
    // Persist server truth so the local cache belongs to the current user
    // even if the app restarts offline.
    unawaited(_repository.save(_tokens));
    notifyListeners();
  }

  Future<void> add(int value) async {
    _tokens += value;
    await _repository.save(_tokens);
    notifyListeners();
  }

  Future<bool> spend(int value) async {
    if (_tokens < value) return false;
    _tokens -= value;
    await _repository.save(_tokens);
    notifyListeners();
    return true;
  }

  Future<void> refresh() async {
    final response = await _api.get('/me/bootstrap') as Map<String, dynamic>;
    syncWallet(
      Wallet.fromJson(response['wallet'] as Map<String, dynamic>? ?? const {}),
    );
  }
}
