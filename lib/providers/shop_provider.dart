import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/repositories/shop_repository.dart';
import '../models/shop_item.dart';
import '../models/pet.dart';
import '../models/wallet.dart';
import 'pet_provider.dart';
import 'token_provider.dart';

class ShopProvider extends ChangeNotifier {
  ShopProvider(this._repository, this._api)
    : _ownedItems = List.of(_repository.loadOwnedItems());

  final ShopRepository _repository;
  final ApiClient _api;
  final List<String> _ownedItems;
  List<ShopItem>? _remoteCatalog;
  Wallet? _latestWallet;
  Pet? _latestPet;

  List<ShopItem> get catalog => _remoteCatalog ?? _repository.catalog;
  List<String> get ownedItems => List.unmodifiable(_ownedItems);
  Wallet? get latestWallet => _latestWallet;
  Pet? get latestPet => _latestPet;

  bool isOwned(String itemId) => _ownedItems.contains(itemId);
  bool isCompanionUnlocked(String code) {
    if (code == 'kiki') return true;
    return catalog.any(
      (item) => item.code == code && _ownedItems.contains(item.id),
    );
  }

  List<String> get ownedCompanionCodes {
    return catalog
        .where((item) => item.isCompanion && _ownedItems.contains(item.id))
        .map((item) => item.code)
        .toList(growable: false);
  }

  Future<void> loadCatalog() async {
    final response = await _api.get('/shop/items') as Map<String, dynamic>;
    _remoteCatalog = (response['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ShopItem.fromJson)
        .toList();
    _ownedItems
      ..clear()
      ..addAll(
        (response['inventory'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map((item) => item['shopItemId'] as String? ?? '')
            .where((id) => id.isNotEmpty),
      );
    await _repository.saveOwnedItems(_ownedItems);
    notifyListeners();
  }

  Future<bool> buy({
    required ShopItem item,
    required TokenProvider tokens,
    required PetProvider pet,
  }) async {
    final response =
        await _api.post('/shop/items/${item.id}/buy') as Map<String, dynamic>;
    _latestWallet = Wallet.fromJson(
      response['wallet'] as Map<String, dynamic>? ?? const {},
    );
    _latestPet = Pet.fromJson(
      response['pet'] as Map<String, dynamic>? ?? const {},
    );
    tokens.syncWallet(_latestWallet!);
    pet.syncPet(_latestPet!);
    if (!_ownedItems.contains(item.id)) _ownedItems.add(item.id);
    await _repository.saveOwnedItems(_ownedItems);
    notifyListeners();
    return true;
  }
}
