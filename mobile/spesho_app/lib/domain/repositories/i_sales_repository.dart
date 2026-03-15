import '../entities/sale_entity.dart';

abstract class ISalesRepository {
  Future<RecordSaleResult> recordSale({
    required int productId,
    required double quantity,
    required double price,
    double discount,
    double? paid,
    String? note,
    String? date,
  });

  Future<List<SaleEntity>> getSales({
    int? productId,
    String? startDate,
    String? endDate,
    int page,
  });
}
