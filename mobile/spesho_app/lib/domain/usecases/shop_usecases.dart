import '../entities/shop_entity.dart';
import '../repositories/i_shop_repository.dart';

class ShopUseCases {
  final IShopRepository _repo;
  ShopUseCases(this._repo);

  Future<List<ShopEntity>> getShops() => _repo.getShops();

  Future<ShopEntity> createShop(String name, {String? location, String? address, int? ownerId}) =>
      _repo.createShop(name, location: location, address: address, ownerId: ownerId);

  Future<ShopEntity> updateShop(int id, {String? name, String? location, String? address, bool? isActive, int? ownerId}) =>
      _repo.updateShop(id, name: name, location: location, address: address, isActive: isActive, ownerId: ownerId);

  Future<void> assignUser(int shopId, int userId) => _repo.assignUser(shopId, userId);
  Future<void> removeUser(int shopId, int userId) => _repo.removeUser(shopId, userId);
}
