class ProductEntity {
  final int id;
  final String name;
  final double unitPrice;
  final double? buyingPrice; // cost price for profit/COGS calculation
  final bool isActive;
  final double? currentStock;
  final int packageSize;
  final String category; // 'unga', 'mchele', 'maharage'

  const ProductEntity({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.buyingPrice,
    this.isActive = true,
    this.currentStock,
    this.packageSize = 5,
    this.category = 'unga',
  });

  double? get profitMargin {
    if (buyingPrice == null || buyingPrice! <= 0) return null;
    return ((unitPrice - buyingPrice!) / buyingPrice!) * 100;
  }

  @override
  bool operator ==(Object other) => other is ProductEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
