import '../../domain/entities/stock_entity.dart';

class StockMovementModel extends StockMovementEntity {
  const StockMovementModel({
    required super.id,
    required super.productId,
    super.productName,
    required super.quantityIn,
    required super.quantityOut,
    super.unitPrice,
    super.note,
    required super.movementType,
    super.date,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> j) =>
      StockMovementModel(
        id: j['id'],
        productId: j['product_id'],
        productName: j['product_name'],
        quantityIn: (j['quantity_in'] as num?)?.toDouble() ?? 0,
        quantityOut: (j['quantity_out'] as num?)?.toDouble() ?? 0,
        unitPrice: j['unit_price'] != null
            ? (j['unit_price'] as num).toDouble()
            : null,
        note: j['note'],
        movementType: j['movement_type'] ?? 'in',
        date: j['date'],
      );
}
