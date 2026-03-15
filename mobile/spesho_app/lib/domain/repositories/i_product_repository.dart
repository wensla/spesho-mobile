import '../entities/product_entity.dart';

abstract class IProductRepository {
  Future<List<ProductEntity>> getProducts({bool includeStock = false});
  Future<ProductEntity> getProduct(int id);
  Future<ProductEntity> createProduct(String name, double price, {int packageSize = 5, String category = 'unga'});
  Future<ProductEntity> updateProduct(int id, {String? name, double? price, int? packageSize, String? category});
  Future<void> deleteProduct(int id);
}
