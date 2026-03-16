import 'package:flutter/foundation.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/product_usecases.dart';

class ProductProvider extends ChangeNotifier {
  final ProductUseCases _useCases;

  List<ProductEntity> _products = [];
  bool _loading = false;
  String? _error;

  ProductProvider(this._useCases);

  List<ProductEntity> get products => _products;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadProducts({bool includeStock = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _useCases.getProducts(includeStock: includeStock);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct(String name, double price, {int packageSize = 5, String category = 'unga', double? buyingPrice}) async {
    try {
      final p = await _useCases.createProduct(name, price, packageSize: packageSize, category: category, buyingPrice: buyingPrice);
      _products.add(p);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(int id, {String? name, double? price, int? packageSize, String? category, double? buyingPrice}) async {
    try {
      final updated = await _useCases.updateProduct(id, name: name, price: price, packageSize: packageSize, category: category, buyingPrice: buyingPrice);
      final idx = _products.indexWhere((p) => p.id == id);
      if (idx != -1) _products[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _useCases.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
