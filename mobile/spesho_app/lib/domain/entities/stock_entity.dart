class StockMovementEntity {
  final int id;
  final int productId;
  final String? productName;
  final double quantityIn;
  final double quantityOut;
  final double? unitPrice;
  final String? note;
  final String movementType;
  final String? date;

  const StockMovementEntity({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantityIn,
    required this.quantityOut,
    this.unitPrice,
    this.note,
    required this.movementType,
    this.date,
  });
}

class StockBalanceEntity {
  final int productId;
  final String productName;
  final double unitPrice;
  final int packageSize; // kg per bag
  final double currentStock;
  final double stockValue;

  const StockBalanceEntity({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.packageSize = 5,
    required this.currentStock,
    required this.stockValue,
  });
}

class StockInResult {
  final double newBalance;
  final String message;

  const StockInResult({required this.newBalance, required this.message});
}
