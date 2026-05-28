enum ShopItemType { potion, food, companion }

enum PetEffectType { energy, mood, hunger, love }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.code,
    required this.name,
    required this.emoji,
    required this.priceTokens,
    required this.type,
    required this.effectType,
    required this.effectValue,
    this.isHot = false,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Item',
      emoji: json['emoji'] as String? ?? '✨',
      priceTokens: json['priceTokens'] as int? ?? 0,
      type: ShopItemType.values.firstWhere(
        (type) => type.name == (json['itemType'] as String? ?? 'potion'),
        orElse: () => ShopItemType.potion,
      ),
      effectType: PetEffectType.values.firstWhere(
        (type) => type.name == (json['effectType'] as String? ?? 'energy'),
        orElse: () => PetEffectType.energy,
      ),
      effectValue: json['effectValue'] as int? ?? 0,
      isHot: json['isHot'] as bool? ?? false,
    );
  }

  final String id;
  final String code;
  final String name;
  final String emoji;
  final int priceTokens;
  final ShopItemType type;
  final PetEffectType effectType;
  final int effectValue;
  final bool isHot;

  bool get isCompanion => type == ShopItemType.companion;

  String get companionBonus {
    return switch (code) {
      'companion_eagle' => '+5% Vision',
      'companion_frog' => '+5% Calm',
      'companion_giraffe' => '+5% Stamina',
      _ => '+5% Focus',
    };
  }

  String? get companionAssetPath {
    return switch (code) {
      'companion_eagle' => 'assets/images/companion_eagle.png',
      'companion_frog' => 'assets/images/companion_frog.png',
      'companion_giraffe' => 'assets/images/companion_giraffe.png',
      _ => null,
    };
  }
}
