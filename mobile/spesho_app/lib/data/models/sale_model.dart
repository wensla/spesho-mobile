import '../../domain/entities/sale_entity.dart';

class SaleModel extends SaleEntity {
  const SaleModel({
    required super.id,
    required super.productId,
    super.productName,
    required super.quantity,
    required super.price,
    required super.discount,
    required super.total,
    required super.paid,
    required super.debt,
    super.note,
    required super.soldBy,
    super.soldByName,
    required super.date,
    required super.createdAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> j) => SaleModel(
        id: j['id'],
        productId: j['product_id'],
        productName: j['product_name'],
        quantity: (j['quantity'] as num).toDouble(),
        price: (j['price'] as num).toDouble(),
        discount: (j['discount'] as num?)?.toDouble() ?? 0,
        total: (j['total'] as num).toDouble(),
        paid: (j['paid'] as num?)?.toDouble() ?? 0,
        debt: (j['debt'] as num?)?.toDouble() ?? 0,
        note: j['note'],
        soldBy: j['sold_by'],
        soldByName: j['sold_by_name'],
        date: j['date'] ?? '',
        createdAt: j['created_at'] ?? '',
      );
}
