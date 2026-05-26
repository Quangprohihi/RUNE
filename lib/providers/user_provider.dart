import 'package:flutter/foundation.dart';

import '../data/repositories/user_repository.dart';
import '../models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProvider(this._repository) : _profile = _repository.load();

  final UserRepository _repository;
  UserProfile _profile;

  UserProfile get profile => _profile;

  bool get hasLoggedIn => _profile.hasLoggedIn;

  Future<void> mockLogin(String email) async {
    final name = email.trim().isEmpty ? 'Friend' : email.split('@').first;
    _profile = UserProfile(
      displayName: name,
      email: email.trim(),
      hasLoggedIn: true,
    );
    await _repository.save(_profile);
    notifyListeners();
  }
}
