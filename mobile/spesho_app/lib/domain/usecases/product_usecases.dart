import '../entities/product_entity.dart';
import '../repositories/i_product_repository.dart';

class GetProductsUseCase {
  final IProductRepository _repo;
  GetProductsUseCase(this._repo);
  Future<List<ProductEntity>> call({bool includeStock = false}) =>
      _repo.getProducts(includeStock: includeStock);
}

class CreateProductUseCase {
  final IProductRepository _repo;
  CreateProductUseCase(this._repo);
  Future<ProductEntity> call(String name, double price, {int packageSize = 5, String category = 'unga', double? buyingPrice}) =>
      _repo.createProduct(name, price, packageSize: packageSize, category: category, buyingPrice: buyingPrice);
}

class UpdateProductUseCase {
  final IProductRepository _repo;
  UpdateProductUseCase(this._repo);
  Future<ProductEntity> call(int id, {String? name, double? price, int? packageSize, String? category, double? buyingPrice}) =>
      _repo.updateProduct(id, name: name, price: price, packageSize: packageSize, category: category, buyingPrice: buyingPrice);
}

class DeleteProductUseCase {
  final IProductRepository _repo;
  DeleteProductUseCase(this._repo);
  Future<void> call(int id) => _repo.deleteProduct(id);
}

class ProductUseCases {
  final GetProductsUseCase getProducts;
  final CreateProductUseCase createProduct;
  final UpdateProductUseCase updateProduct;
  final DeleteProductUseCase deleteProduct;

  ProductUseCases(IProductRepository repo)
      : getProducts = GetProductsUseCase(repo),
        createProduct = CreateProductUseCase(repo),
        updateProduct = UpdateProductUseCase(repo),
        deleteProduct = DeleteProductUseCase(repo);
}
