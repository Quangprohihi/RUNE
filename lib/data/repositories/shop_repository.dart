import 'package:shared_preferences/shared_preferences.dart';

import '../../models/shop_item.dart';
import '../local/prefs_keys.dart';

class ShopRepository {
  ShopRepository(this._prefs);

  final SharedPreferences _prefs;

  List<ShopItem> get catalog => const [
    ShopItem(
      id: 'energy_potion',
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
      name: 'Mood Booster',
      emoji: '🌸',
      priceTokens: 120,
      type: ShopItemType.potion,
      effectType: PetEffectType.mood,
      effectValue: 20,
    ),
    ShopItem(
      id: 'fresh_berries',
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
      name: 'Cozy Pet',
      emoji: '✨',
      priceTokens: 90,
      type: ShopItemType.potion,
      effectType: PetEffectType.love,
      effectValue: 18,
    ),
  ];

  List<String> loadOwnedItems() {
    return _prefs.getStringList(PrefsKeys.ownedItems) ?? const [];
  }

  Future<void> saveOwnedItems(List<String> value) {
    return _prefs.setStringList(PrefsKeys.ownedItems, value);
  }
}
