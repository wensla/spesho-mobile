import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.unitPrice,
    super.buyingPrice,
    super.isActive = true,
    super.currentStock,
    super.packageSize = 5,
    super.category = 'unga',
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: j['id'],
        name: j['name'],
        unitPrice: (j['unit_price'] as num).toDouble(),
        buyingPrice: j['buying_price'] != null
            ? (j['buying_price'] as num).toDouble()
            : null,
        isActive: j['is_active'] ?? true,
        currentStock: j['current_stock'] != null
            ? (j['current_stock'] as num).toDouble()
            : null,
        packageSize: (j['package_size'] as num?)?.toInt() ?? 5,
        category: j['category'] ?? 'unga',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit_price': unitPrice,
        'buying_price': buyingPrice,
        'package_size': packageSize,
        'category': category,
        'is_active': isActive,
        'current_stock': currentStock,
      };
}
