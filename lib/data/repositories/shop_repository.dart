import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/shop_item.dart';
import '../local/prefs_keys.dart';

class ShopRepository {
  ShopRepository(this._prefs);

  final SharedPreferences _prefs;

  List<ShopItem> get catalog => const [
    ShopItem(
      id: 'energy_potion',
      code: 'energy_potion',
      name: 'Energy Potion',
      emoji: '⚡',
      priceTokens: 150,
      type: ShopItemType.potion,
      effectType: PetEffectType.energy,
      effectValue: 20,
      isHot: true,
    ),
    ShopItem(
      id: 'mood_booster',
      code: 'mood_booster',
      name: 'Mood Booster',
      emoji: '🌸',
      priceTokens: 120,
      type: ShopItemType.potion,
      effectType: PetEffectType.mood,
      effectValue: 20,
    ),
    ShopItem(
      id: 'fresh_berries',
      code: 'fresh_berries',
      name: 'Fresh Berries',
      emoji: '🍓',
      priceTokens: 100,
      type: ShopItemType.food,
      effectType: PetEffectType.hunger,
      effectValue: 24,
      isHot: true,
    ),
    ShopItem(
      id: 'cozy_pet',
      code: 'cozy_pet',
      name: 'Cozy Pet',
      emoji: '✨',
      priceTokens: 90,
      type: ShopItemType.potion,
      effectType: PetEffectType.love,
      effectValue: 18,
    ),
    ShopItem(
      id: 'companion_eagle',
      code: 'companion_eagle',
      name: 'Eagle',
      emoji: '🦅',
      priceTokens: 260,
      type: ShopItemType.companion,
      effectType: PetEffectType.love,
      effectValue: 0,
      isHot: true,
    ),
    ShopItem(
      id: 'companion_frog',
      code: 'companion_frog',
      name: 'Frog',
      emoji: '🐸',
      priceTokens: 180,
      type: ShopItemType.companion,
      effectType: PetEffectType.love,
      effectValue: 0,
    ),
    ShopItem(
      id: 'companion_giraffe',
      code: 'companion_giraffe',
      name: 'Giraffe',
      emoji: '🦒',
      priceTokens: 320,
      type: ShopItemType.companion,
      effectType: PetEffectType.love,
      effectValue: 0,
    ),
  ];

  List<String> loadOwnedItems() {
    return _prefs.getStringList(PrefsKeys.ownedItems) ?? const [];
  }

  Future<void> saveOwnedItems(List<String> value) {
    return _prefs.setStringList(PrefsKeys.ownedItems, value);
  }

  Map<String, int> loadInventoryQuantities() {
    final raw = _prefs.getString(PrefsKeys.inventoryQuantities);
    if (raw == null) {
      return {for (final itemId in loadOwnedItems()) itemId: 1};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) =>
          MapEntry(key, value is int ? value : int.tryParse('$value') ?? 0),
    )..removeWhere((_, quantity) => quantity <= 0);
  }

  Future<void> saveInventoryQuantities(Map<String, int> value) {
    return _prefs.setString(PrefsKeys.inventoryQuantities, jsonEncode(value));
  }
}
