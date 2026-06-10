import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/repositories/pet_repository.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';
import '../models/wallet.dart';

class PetProvider extends ChangeNotifier {
  PetProvider(this._repository, this._api)
    : _pet = _repository.load(),
      _companions = List<Pet>.of(_repository.loadRoster()) {
    applyPassiveDecay();
  }

  final PetRepository _repository;
  final ApiClient _api;
  Pet _pet;
  final List<Pet> _companions;
  Wallet? _latestWallet;

  /// The active pet (Kiki) — backend-synced, earns focus rewards, evolves.
  Pet get pet => _pet;

  /// Every pet that lives on the island: Kiki first, then the companions.
  List<Pet> get pets => [_pet, ..._companions];

  Wallet? get latestWallet => _latestWallet;

  /// Whether [id] refers to the active backend-synced pet (Kiki).
  bool isActivePet(String id) => id == _pet.id;

  /// Resolves a pet by id; falls back to the active pet if not found.
  Pet petById(String id) {
    if (id == _pet.id) return _pet;
    for (final companion in _companions) {
      if (companion.id == id) return companion;
    }
    return _pet;
  }

  void syncPet(Pet pet) {
    _pet = pet;
    // Persist server truth so the local cache belongs to the current user
    // even if the app restarts offline.
    unawaited(_repository.save(_pet));
    notifyListeners();
  }

  /// Reloads Kiki and the companion roster from local storage after a
  /// different account signs in. Storage was wiped first, so this restores
  /// the fresh-install defaults; Kiki then syncs from the server bootstrap.
  void resetForAccountSwitch() {
    _pet = _repository.load();
    _companions
      ..clear()
      ..addAll(_repository.loadRoster());
    _latestWallet = null;
    notifyListeners();
  }

  Future<void> applyPassiveDecay() async {
    var changed = false;

    final petTicks = _decayTicks(_pet.lastUpdatedAt);
    if (petTicks > 0) {
      _pet = _decay(_pet, petTicks);
      await _repository.save(_pet);
      changed = true;
    }

    var rosterChanged = false;
    for (var i = 0; i < _companions.length; i++) {
      final ticks = _decayTicks(_companions[i].lastUpdatedAt);
      if (ticks <= 0) continue;
      _companions[i] = _decay(_companions[i], ticks);
      rosterChanged = true;
    }
    if (rosterChanged) {
      await _repository.saveRoster(_companions);
      changed = true;
    }

    if (changed) notifyListeners();
  }

  int _decayTicks(DateTime lastUpdatedAt) {
    final ticks = DateTime.now().difference(lastUpdatedAt).inMinutes ~/ 30;
    return ticks.clamp(0, 24).toInt();
  }

  Pet _decay(Pet pet, int ticks) {
    return pet.copyWith(
      hunger: (pet.hunger - ticks * 2).clamp(0, 100),
      mood: (pet.mood - ticks).clamp(0, 100),
      love: (pet.love - ticks).clamp(0, 100),
      lastUpdatedAt: DateTime.now(),
    );
  }

  Future<void> addFocusReward({required int exp, required int minutes}) async {
    final totalExp = _pet.exp + exp;
    final leveledUp = totalExp >= _pet.expToNext;
    _pet = _pet.copyWith(
      level: leveledUp ? _pet.level + 1 : _pet.level,
      exp: leveledUp ? totalExp - _pet.expToNext : totalExp,
      expToNext: leveledUp ? _pet.expToNext + 100 : _pet.expToNext,
      mood: (_pet.mood + 4).clamp(0, 100),
      love: (_pet.love + 4).clamp(0, 100),
      energy: (_pet.energy - minutes ~/ 5).clamp(0, 100),
      lastUpdatedAt: DateTime.now(),
    );
    await _repository.save(_pet);
    notifyListeners();
  }

  Future<void> feed() => applyEffect(PetEffectType.hunger, 20);

  Future<void> play() => applyEffect(PetEffectType.mood, 18);

  Future<void> petKiki() => applyEffect(PetEffectType.love, 16);

  Future<bool> performRemoteAction({
    required String action,
    required int cost,
  }) async {
    final response =
        await _api.post('/pet/actions', body: {'action': action, 'cost': cost})
            as Map<String, dynamic>;
    _pet = Pet.fromJson(response['pet'] as Map<String, dynamic>? ?? const {});
    _latestWallet = Wallet.fromJson(
      response['wallet'] as Map<String, dynamic>? ?? const {},
    );
    await _repository.save(_pet);
    notifyListeners();
    return true;
  }

  Future<bool> selectEvolutionSkin(String skinCode) async {
    final response =
        await _api.post('/pet/evolution/select', body: {'skinCode': skinCode})
            as Map<String, dynamic>;
    _pet = Pet.fromJson(response['pet'] as Map<String, dynamic>? ?? const {});
    await _repository.save(_pet);
    notifyListeners();
    return true;
  }

  /// Routes a care effect to any pet by id. The active pet (Kiki) goes through
  /// the backend-aware [applyEffect]; companions are updated locally and saved
  /// to the roster.
  Future<void> applyEffectTo(
    String id,
    PetEffectType effectType,
    int value,
  ) async {
    if (id == _pet.id) {
      await applyEffect(effectType, value);
      return;
    }
    final index = _companions.indexWhere((pet) => pet.id == id);
    if (index < 0) return;
    _companions[index] = _withEffect(_companions[index], effectType, value);
    await _repository.saveRoster(_companions);
    notifyListeners();
  }

  Pet _withEffect(Pet pet, PetEffectType effectType, int value) {
    return pet.copyWith(
      hunger: effectType == PetEffectType.hunger
          ? (pet.hunger + value).clamp(0, 100)
          : pet.hunger,
      energy: effectType == PetEffectType.energy
          ? (pet.energy + value).clamp(0, 100)
          : pet.energy,
      mood: effectType == PetEffectType.mood
          ? (pet.mood + value).clamp(0, 100)
          : pet.mood,
      love: effectType == PetEffectType.love
          ? (pet.love + value).clamp(0, 100)
          : pet.love,
      lastUpdatedAt: DateTime.now(),
    );
  }

  Future<void> applyEffect(PetEffectType effectType, int value) async {
    _pet = _pet.copyWith(
      hunger: effectType == PetEffectType.hunger
          ? (_pet.hunger + value).clamp(0, 100)
          : _pet.hunger,
      energy: effectType == PetEffectType.energy
          ? (_pet.energy + value).clamp(0, 100)
          : _pet.energy,
      mood: effectType == PetEffectType.mood
          ? (_pet.mood + value).clamp(0, 100)
          : _pet.mood,
      love: effectType == PetEffectType.love
          ? (_pet.love + value).clamp(0, 100)
          : _pet.love,
      lastUpdatedAt: DateTime.now(),
    );
    await _repository.save(_pet);
    notifyListeners();
  }
}
