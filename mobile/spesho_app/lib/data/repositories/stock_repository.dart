import '../../core/network/api_client.dart';
import '../models/stock_movement_model.dart';
import '../../domain/entities/stock_entity.dart';
import '../../domain/repositories/i_stock_repository.dart';

class StockBalance extends StockBalanceEntity {
  const StockBalance({
    required super.productId,
    required super.productName,
    required super.unitPrice,
    super.packageSize = 5,
    required super.currentStock,
    required super.stockValue,
  });

  factory StockBalance.fromJson(Map<String, dynamic> j) => StockBalance(
        productId: j['product_id'],
        productName: j['product_name'],
        unitPrice: (j['unit_price'] as num).toDouble(),
        packageSize: (j['package_size'] as num?)?.toInt() ?? 5,
        currentStock: (j['current_stock'] as num).toDouble(),
        stockValue: (j['stock_value'] as num).toDouble(),
      );
}

class StockRepository implements IStockRepository {
  final ApiClient _api;
  StockRepository(this._api);

  @override
  Future<StockInResult> stockIn({
    required int productId,
    required double quantity,
    required double unitPrice,
    String? note,
    String? date,
  }) async {
    final res = await _api.post('/stock/in', {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
    });
    return StockInResult(
      newBalance: (res['new_balance'] as num).toDouble(),
      message: res['message'] ?? 'Stock added successfully',
    );
  }

  @override
  Future<List<StockBalanceEntity>> getStockBalance() async {
    final res = await _api.get('/stock/balance');
    return (res['balances'] as List)
        .map<StockBalanceEntity>((e) => StockBalance.fromJson(e))
        .toList();
  }

  @override
  Future<List<StockMovementEntity>> getMovements({
    int? productId,
    String? startDate,
    String? endDate,
    String? type,
    int page = 1,
  }) async {
    final query = <String, String>{'page': page.toString()};
    if (productId != null) query['product_id'] = productId.toString();
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;
    if (type != null) query['type'] = type;

    final res = await _api.get('/stock/movements', query: query);
    return (res['movements'] as List)
        .map<StockMovementEntity>((e) => StockMovementModel.fromJson(e))
        .toList();
  }

  @override
  Future<StockInResult> stockAdjust({
    required int productId,
    required double newQuantity,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'product_id': productId,
      'new_quantity': newQuantity,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    final res = await _api.post('/stock/adjust', body);
    return StockInResult(
      newBalance: (res['new_balance'] as num).toDouble(),
      message: res['message'] ?? 'Stock adjusted',
    );
  }
}
