class SaleEntity {
  final int id;
  final int productId;
  final String? productName;
  final double quantity;
  final double price;
  final double discount;
  final double total;
  final double paid;
  final double debt;
  final String? note;
  final int soldBy;
  final String? soldByName;
  final String date;
  final String createdAt;

  const SaleEntity({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.total,
    required this.paid,
    required this.debt,
    this.note,
    required this.soldBy,
    this.soldByName,
    required this.date,
    required this.createdAt,
  });
}

class RecordSaleResult {
  final SaleEntity sale;
  final double newBalance;
  final String message;

  const RecordSaleResult({
    required this.sale,
    required this.newBalance,
    required this.message,
  });
}
