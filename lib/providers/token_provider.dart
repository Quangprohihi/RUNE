import 'package:flutter/foundation.dart';

import '../data/repositories/token_repository.dart';

class TokenProvider extends ChangeNotifier {
  TokenProvider(this._repository) : _tokens = _repository.load();

  final TokenRepository _repository;
  int _tokens;

  int get tokens => _tokens;

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
}
