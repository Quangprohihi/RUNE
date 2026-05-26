import 'package:flutter/foundation.dart';

import '../data/repositories/shop_repository.dart';
import '../models/shop_item.dart';
import 'pet_provider.dart';
import 'token_provider.dart';

class ShopProvider extends ChangeNotifier {
  ShopProvider(this._repository)
    : _ownedItems = List.of(_repository.loadOwnedItems());

  final ShopRepository _repository;
  final List<String> _ownedItems;

  List<ShopItem> get catalog => _repository.catalog;
  List<String> get ownedItems => List.unmodifiable(_ownedItems);

  bool isOwned(String itemId) => _ownedItems.contains(itemId);

  Future<bool> buy({
    required ShopItem item,
    required TokenProvider tokens,
    required PetProvider pet,
  }) async {
    final paid = await tokens.spend(item.priceTokens);
    if (!paid) return false;
    _ownedItems.add(item.id);
    await pet.applyEffect(item.effectType, item.effectValue);
    await _repository.saveOwnedItems(_ownedItems);
    notifyListeners();
    return true;
  }
}
