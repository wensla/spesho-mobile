import '../../core/network/api_client.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/i_shop_repository.dart';
import '../models/shop_model.dart';

class ShopRepository implements IShopRepository {
  final ApiClient _api;
  ShopRepository(this._api);

  @override
  Future<List<ShopEntity>> getShops() async {
    final data = await _api.get('/shops/');
    return (data['shops'] as List)
        .map((j) => ShopModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ShopEntity> createShop(String name, {String? location, String? address, int? ownerId}) async {
    final data = await _api.post('/shops/', {
      'name': name,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      if (ownerId != null) 'owner_id': ownerId,
    });
    return ShopModel.fromJson(data['shop'] as Map<String, dynamic>);
  }

  @override
  Future<ShopEntity> updateShop(int id, {String? name, String? location, String? address, bool? isActive, int? ownerId}) async {
    final data = await _api.put('/shops/$id', {
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      if (isActive != null) 'is_active': isActive,
      if (ownerId != null) 'owner_id': ownerId,
    });
    return ShopModel.fromJson(data['shop'] as Map<String, dynamic>);
  }

  @override
  Future<void> assignUser(int shopId, int userId) async {
    await _api.post('/shops/$shopId/users', {'user_id': userId});
  }

  @override
  Future<void> removeUser(int shopId, int userId) async {
    await _api.delete('/shops/$shopId/users/$userId');
  }
}
