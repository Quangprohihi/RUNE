import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/pet.dart';
import '../local/prefs_keys.dart';

class PetRepository {
  PetRepository(this._prefs);

  final SharedPreferences _prefs;

  Pet load() {
    final raw = _prefs.getString(PrefsKeys.pet);
    if (raw == null) return Pet.initial();
    return Pet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Pet pet) {
    return _prefs.setString(PrefsKeys.pet, jsonEncode(pet.toJson()));
  }
}
