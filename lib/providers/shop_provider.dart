import 'package:flutter/foundation.dart';

import '../core/errors/friendly_error.dart';
import '../data/api/api_client.dart';
import '../data/repositories/shop_repository.dart';
import '../models/shop_item.dart';
import '../models/pet.dart';
import '../models/wallet.dart';
import 'pet_provider.dart';
import 'token_provider.dart';

class ShopProvider extends ChangeNotifier {
  ShopProvider(this._repository, this._api)
    : _inventoryQuantities = Map.of(_repository.loadInventoryQuantities());

  final ShopRepository _repository;
  final ApiClient _api;
  final Map<String, int> _inventoryQuantities;
  List<ShopItem>? _remoteCatalog;
  Wallet? _latestWallet;
  Pet? _latestPet;
  bool _isLoading = false;
  String? _error;
  String? _purchasingItemId;

  List<ShopItem> get catalog => _remoteCatalog ?? _repository.catalog;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True while the remote catalog has never loaded — used to show a loading
  /// state on first open instead of a misleading empty/local grid.
  bool get hasLoadedRemote => _remoteCatalog != null;

  /// The item currently being purchased (network in flight), so the UI can
  /// disable just that Buy button and prevent a double-charge double-tap.
  String? get purchasingItemId => _purchasingItemId;
  bool isPurchasing(String itemId) => _purchasingItemId == itemId;
  List<String> get ownedItems => _inventoryQuantities.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toList(growable: false);
  Map<String, int> get inventoryQuantities =>
      Map.unmodifiable(_inventoryQuantities);
  Wallet? get latestWallet => _latestWallet;
  Pet? get latestPet => _latestPet;

  int quantityFor(String itemId) => _inventoryQuantities[itemId] ?? 0;
  bool isOwned(String itemId) => quantityFor(itemId) > 0;
  bool isCompanionUnlocked(String code) {
    if (code == 'kiki') return true;
    return catalog.any((item) => item.code == code && quantityFor(item.id) > 0);
  }

  List<String> get ownedCompanionCodes {
    return catalog
        .where((item) => item.isCompanion && quantityFor(item.id) > 0)
        .map((item) => item.code)
        .toList(growable: false);
  }

  /// Drops the previous account's inventory and cached catalog after a
  /// different account signs in; the next [loadCatalog] refetches both.
  void resetForAccountSwitch() {
    _inventoryQuantities
      ..clear()
      ..addAll(_repository.loadInventoryQuantities());
    _remoteCatalog = null;
    _latestWallet = null;
    _latestPet = null;
    _purchasingItemId = null;
    _error = null;
    notifyListeners();
  }

  Future<void> loadCatalog() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.get('/shop/items') as Map<String, dynamic>;
      _remoteCatalog = (response['items'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ShopItem.fromJson)
          .toList();
      await _syncInventory(response['inventory'] as List<dynamic>? ?? const []);
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buy({
    required ShopItem item,
    required TokenProvider tokens,
    required PetProvider pet,
  }) async {
    // Guard against a double-tap firing two purchase requests (double-charge).
    if (_purchasingItemId != null) return false;
    _purchasingItemId = item.id;
    notifyListeners();
    try {
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
      final inventory = response['inventory'] as List<dynamic>?;
      if (inventory == null) {
        _inventoryQuantities[item.id] = quantityFor(item.id) + 1;
        await _saveInventory();
      } else {
        await _syncInventory(inventory);
      }
      return true;
    } finally {
      _purchasingItemId = null;
      notifyListeners();
    }
  }

  Future<bool> useItem({
    required ShopItem item,
    required PetProvider pet,
  }) async {
    final response =
        await _api.post('/shop/items/${item.id}/use') as Map<String, dynamic>;
    _latestPet = Pet.fromJson(
      response['pet'] as Map<String, dynamic>? ?? const {},
    );
    pet.syncPet(_latestPet!);
    await _syncInventory(response['inventory'] as List<dynamic>? ?? const []);
    notifyListeners();
    return true;
  }

  List<ShopItem> ownedItemsForEffect(Set<PetEffectType> effects) {
    return catalog
        .where(
          (item) =>
              !item.isCompanion &&
              effects.contains(item.effectType) &&
              quantityFor(item.id) > 0,
        )
        .toList(growable: false);
  }

  Future<void> _syncInventory(List<dynamic> inventory) async {
    _inventoryQuantities
      ..clear()
      ..addEntries(
        inventory
            .cast<Map<String, dynamic>>()
            .map((item) {
              return MapEntry(
                item['shopItemId'] as String? ?? '',
                item['quantity'] as int? ?? 0,
              );
            })
            .where((entry) => entry.key.isNotEmpty && entry.value > 0),
      );
    await _saveInventory();
  }

  Future<void> _saveInventory() async {
    await _repository.saveInventoryQuantities(_inventoryQuantities);
    await _repository.saveOwnedItems(ownedItems);
  }
}
