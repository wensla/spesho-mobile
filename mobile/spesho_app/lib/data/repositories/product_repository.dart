import '../../core/network/api_client.dart';
import '../models/product_model.dart';
import '../../domain/repositories/i_product_repository.dart';

class ProductRepository implements IProductRepository {
  final ApiClient _api;
  ProductRepository(this._api);

  @override
  Future<List<ProductModel>> getProducts({bool includeStock = false}) async {
    final res = await _api.get('/products/',
        query: {'include_stock': includeStock.toString()});
    return (res['products'] as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductModel> getProduct(int id) async {
    final res = await _api.get('/products/$id');
    return ProductModel.fromJson(res['product']);
  }

  @override
  @override
  Future<ProductModel> createProduct(String name, double price, {int packageSize = 5, String category = 'unga', double? buyingPrice}) async {
    final body = <String, dynamic>{'name': name, 'unit_price': price, 'package_size': packageSize, 'category': category};
    if (buyingPrice != null) body['buying_price'] = buyingPrice;
    final res = await _api.post('/products/', body);
    return ProductModel.fromJson(res['product']);
  }

  @override
  Future<ProductModel> updateProduct(int id, {String? name, double? price, int? packageSize, String? category, double? buyingPrice}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (price != null) body['unit_price'] = price;
    if (packageSize != null) body['package_size'] = packageSize;
    if (category != null) body['category'] = category;
    if (buyingPrice != null) body['buying_price'] = buyingPrice;
    final res = await _api.put('/products/$id', body);
    return ProductModel.fromJson(res['product']);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await _api.delete('/products/$id');
  }
}
