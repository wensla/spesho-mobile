import 'package:flutter_test/flutter_test.dart';
import 'package:spesho_app/domain/entities/product_entity.dart';
import 'package:spesho_app/domain/repositories/i_product_repository.dart';
import 'package:spesho_app/domain/usecases/product_usecases.dart';
import 'package:spesho_app/presentation/providers/product_provider.dart';

class _MockProductRepository implements IProductRepository {
  List<ProductEntity> productsResult = [];
  Exception? error;
  ProductEntity? createResult;
  ProductEntity? updateResult;

  @override
  Future<List<ProductEntity>> getProducts({bool includeStock = false}) async {
    if (error != null) throw error!;
    return productsResult;
  }

  @override
  Future<ProductEntity> getProduct(int id) async =>
      productsResult.firstWhere((p) => p.id == id);

  @override
  Future<ProductEntity> createProduct(String name, double price,
      {int packageSize = 5}) async {
    if (error != null) throw error!;
    return createResult!;
  }

  @override
  Future<ProductEntity> updateProduct(int id,
      {String? name, double? price, int? packageSize}) async {
    if (error != null) throw error!;
    return updateResult!;
  }

  @override
  Future<void> deleteProduct(int id) async {
    if (error != null) throw error!;
  }
}

void main() {
  late _MockProductRepository mockRepo;
  late ProductProvider provider;

  const tProduct = ProductEntity(
    id: 1,
    name: 'Sembe',
    unitPrice: 1200,
    currentStock: 50,
  );

  setUp(() {
    mockRepo = _MockProductRepository();
    provider = ProductProvider(ProductUseCases(mockRepo));
  });

  tearDown(() {
    provider.dispose();
  });

  group('loadProducts', () {
    test('populates products list on success', () async {
      mockRepo.productsResult = [tProduct];

      await provider.loadProducts();

      expect(provider.products.length, 1);
      expect(provider.products.first.name, 'Sembe');
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
    });

    test('sets error on failure', () async {
      mockRepo.error = Exception('Network error');

      await provider.loadProducts();

      expect(provider.products, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
    });
  });

  group('createProduct', () {
    test('adds product to list and returns true on success', () async {
      mockRepo.createResult = tProduct;

      final result = await provider.createProduct('Sembe', 1200);

      expect(result, isTrue);
      expect(provider.products.length, 1);
      expect(provider.products.first.name, 'Sembe');
    });

    test('sets error and returns false on failure', () async {
      mockRepo.error = Exception('Duplicate name');

      final result = await provider.createProduct('Sembe', 1200);

      expect(result, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.products, isEmpty);
    });
  });

  group('deleteProduct', () {
    test('removes product from list on success', () async {
      mockRepo.productsResult = [tProduct];
      await provider.loadProducts();

      final result = await provider.deleteProduct(1);

      expect(result, isTrue);
      expect(provider.products, isEmpty);
    });

    test('returns false on failure', () async {
      mockRepo.productsResult = [tProduct];
      await provider.loadProducts();
      mockRepo.error = Exception('Cannot delete');

      final result = await provider.deleteProduct(1);

      expect(result, isFalse);
      expect(provider.products.length, 1);
    });
  });
}
