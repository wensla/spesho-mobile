import '../../core/network/api_client.dart';
import '../../domain/entities/daily_sale_entity.dart';

class DailySalesRepository {
  final ApiClient _api;
  DailySalesRepository(this._api);

  DailySaleEntity _fromMap(Map<String, dynamic> m) => DailySaleEntity(
        id:             m['id'],
        date:           m['date'],
        totalAmount:    (m['total_amount'] as num).toDouble(),
        cashPaid:       (m['cash_paid'] as num).toDouble(),
        debt:           (m['debt'] as num).toDouble(),
        note:           m['note'],
        customerName:   m['customer_name'],
        customerPhone:  m['customer_phone'],
        recordedByName: m['recorded_by_name'],
        createdAt:      m['created_at'],
      );

  Future<DailySaleEntity> recordSale({
    required double totalAmount,
    required double cashPaid,
    String? note,
    String? customerName,
    String? customerPhone,
    String? date,
  }) async {
    final res = await _api.post('/daily-sales/', {
      'total_amount':   totalAmount,
      'cash_paid':      cashPaid,
      'note':           note,
      'customer_name':  customerName,
      'customer_phone': customerPhone,
      'date':           date,
    });
    return _fromMap(res['sale']);
  }

  Future<List<DailySaleEntity>> getSales({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate   != null) params['end_date']   = endDate;
    final res = await _api.get('/daily-sales/', query: params);
    return (res['sales'] as List).map((e) => _fromMap(e)).toList();
  }

  Future<void> deleteSale(int id) async {
    await _api.delete('/daily-sales/$id');
  }
}
