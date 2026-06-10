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

  /// The 3 island companions that live alongside Kiki. Each is an independent
  /// pet with its own stats, persisted locally (Kiki stays backend-synced).
  static List<Pet> defaultCompanions() {
    final now = DateTime.now();
    return [
      Pet(
        id: 'aria',
        name: 'Aria',
        species: 'Sky Eagle',
        level: 2,
        exp: 120,
        expToNext: 400,
        hunger: 64,
        energy: 78,
        mood: 82,
        love: 50,
        selectedSkinCode: 'standard',
        lastUpdatedAt: now,
        assetPath: 'assets/images/companion_eagle.png',
        canEvolve: false,
      ),
      Pet(
        id: 'pip',
        name: 'Pip',
        species: 'Dew Frog',
        level: 1,
        exp: 60,
        expToNext: 300,
        hunger: 70,
        energy: 66,
        mood: 74,
        love: 58,
        selectedSkinCode: 'standard',
        lastUpdatedAt: now,
        assetPath: 'assets/images/companion_frog.png',
        canEvolve: false,
      ),
      Pet(
        id: 'glow',
        name: 'Glow',
        species: 'Sun Giraffe',
        level: 2,
        exp: 200,
        expToNext: 400,
        hunger: 58,
        energy: 72,
        mood: 68,
        love: 62,
        selectedSkinCode: 'standard',
        lastUpdatedAt: now,
        assetPath: 'assets/images/companion_giraffe.png',
        canEvolve: false,
      ),
    ];
  }

  /// Loads the companion roster (excludes Kiki). Seeds the defaults on first run.
  List<Pet> loadRoster() {
    final raw = _prefs.getString(PrefsKeys.petRoster);
    if (raw == null) return defaultCompanions();
    final decoded = jsonDecode(raw) as List<dynamic>;
    if (decoded.isEmpty) return defaultCompanions();
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Pet.fromJson)
        .toList(growable: false);
  }

  Future<void> saveRoster(List<Pet> pets) {
    return _prefs.setString(
      PrefsKeys.petRoster,
      jsonEncode(pets.map((pet) => pet.toJson()).toList()),
    );
  }
}
