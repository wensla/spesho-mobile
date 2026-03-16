import '../entities/stock_entity.dart';

abstract class IStockRepository {
  Future<StockInResult> stockIn({
    required int productId,
    required double quantity,
    required double unitPrice,
    String? note,
    String? date,
  });

  Future<List<StockBalanceEntity>> getStockBalance();

  Future<List<StockMovementEntity>> getMovements({
    int? productId,
    String? startDate,
    String? endDate,
    String? type,
    int page,
  });

  Future<StockInResult> stockAdjust({
    required int productId,
    required double newQuantity,
    String? reason,
  });
}
