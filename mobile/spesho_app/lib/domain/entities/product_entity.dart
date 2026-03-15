class ProductEntity {
  final int id;
  final String name;
  final double unitPrice;
  final bool isActive;
  final double? currentStock;
  final int packageSize;
  final String category; // 'unga', 'mchele', 'maharage'

  const ProductEntity({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.isActive = true,
    this.currentStock,
    this.packageSize = 5,
    this.category = 'unga',
  });

  @override
  bool operator ==(Object other) => other is ProductEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
