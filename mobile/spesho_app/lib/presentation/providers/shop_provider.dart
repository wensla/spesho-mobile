import 'package:flutter/foundation.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/shop_usecases.dart';

class ShopProvider extends ChangeNotifier {
  final ShopUseCases _useCases;

  List<ShopEntity> _shops = [];
  bool _loading = false;
  String? _error;

  ShopProvider(this._useCases);

  List<ShopEntity> get shops => _shops;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadShops() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _shops = await _useCases.getShops();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createShop(String name, {String? location, String? address, int? ownerId}) async {
    try {
      final shop = await _useCases.createShop(name, location: location, address: address, ownerId: ownerId);
      _shops.add(shop);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateShop(int id, {String? name, String? location, String? address, bool? isActive, int? ownerId}) async {
    try {
      final updated = await _useCases.updateShop(id, name: name, location: location, address: address, isActive: isActive, ownerId: ownerId);
      final idx = _shops.indexWhere((s) => s.id == id);
      if (idx != -1) _shops[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignUser(int shopId, int userId) async {
    try {
      await _useCases.assignUser(shopId, userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeUser(int shopId, int userId) async {
    try {
      await _useCases.removeUser(shopId, userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
