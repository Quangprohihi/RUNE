import 'package:flutter/foundation.dart';

import '../data/repositories/pet_repository.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';

class PetProvider extends ChangeNotifier {
  PetProvider(this._repository) : _pet = _repository.load() {
    applyPassiveDecay();
  }

  final PetRepository _repository;
  Pet _pet;

  Pet get pet => _pet;

  Future<void> applyPassiveDecay() async {
    final hours = DateTime.now().difference(_pet.lastUpdatedAt).inHours;
    if (hours <= 0) return;
    _pet = _pet.copyWith(
      hunger: (_pet.hunger - hours * 2).clamp(0, 100),
      energy: (_pet.energy - hours).clamp(0, 100),
      mood: (_pet.mood - hours).clamp(0, 100),
      love: (_pet.love - hours).clamp(0, 100),
      lastUpdatedAt: DateTime.now(),
    );
    await _repository.save(_pet);
    notifyListeners();
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
