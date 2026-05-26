enum ShopItemType { potion, food }

enum PetEffectType { energy, mood, hunger, love }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.priceTokens,
    required this.type,
    required this.effectType,
    required this.effectValue,
    this.isHot = false,
  });

  final String id;
  final String name;
  final String emoji;
  final int priceTokens;
  final ShopItemType type;
  final PetEffectType effectType;
  final int effectValue;
  final bool isHot;
}
