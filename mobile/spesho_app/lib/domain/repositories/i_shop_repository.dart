import '../entities/shop_entity.dart';

abstract class IShopRepository {
  Future<List<ShopEntity>> getShops();
  Future<ShopEntity> createShop(String name, {String? location, String? address});
  Future<ShopEntity> updateShop(int id, {String? name, String? location, String? address, bool? isActive});
  Future<void> assignUser(int shopId, int userId);
  Future<void> removeUser(int shopId, int userId);
}
