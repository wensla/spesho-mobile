import '../../core/network/api_client.dart';
import '../models/sale_model.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/i_sales_repository.dart';

class SalesRepository implements ISalesRepository {
  final ApiClient _api;
  SalesRepository(this._api);

  @override
  Future<RecordSaleResult> recordSale({
    required int productId,
    required double quantity,
    required double price,
    double discount = 0,
    double? paid,
    String? note,
    String? date,
  }) async {
    final res = await _api.post('/sales/', {
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      if (paid != null) 'paid': paid,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
    });
    return RecordSaleResult(
      sale: SaleModel.fromJson(res['sale']),
      newBalance: (res['new_balance'] as num).toDouble(),
      message: res['message'] ?? 'Sale recorded successfully',
    );
  }

  @override
  Future<List<SaleEntity>> getSales({
    int? productId,
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final query = <String, String>{'page': page.toString()};
    if (productId != null) query['product_id'] = productId.toString();
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;

    final res = await _api.get('/sales/', query: query);
    return (res['sales'] as List)
        .map<SaleEntity>((e) => SaleModel.fromJson(e))
        .toList();
  }
}
