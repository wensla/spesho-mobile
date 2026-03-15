import '../../core/network/api_client.dart';

class DaySalesSummary {
  final String date;
  final double total;
  final double cashPaid;
  final double debt;
  final int entries;

  const DaySalesSummary({
    required this.date,
    required this.total,
    required this.cashPaid,
    required this.debt,
    required this.entries,
  });
}

class SalesSummaryReport {
  final String startDate;
  final String endDate;
  final List<DaySalesSummary> days;
  final double grandTotal;
  final double grandCash;
  final double grandDebt;

  const SalesSummaryReport({
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.grandTotal,
    required this.grandCash,
    required this.grandDebt,
  });
}

class StockBalanceItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final int packageSize;
  final double currentStock; // kg
  final double stockValue;

  const StockBalanceItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.packageSize,
    required this.currentStock,
    required this.stockValue,
  });

  double get packages => currentStock / packageSize;
}

class ReportsRepository {
  final ApiClient _api;
  ReportsRepository(this._api);

  Future<SalesSummaryReport> getSalesSummary({
    required String startDate,
    required String endDate,
  }) async {
    final res = await _api.get('/reports/sales-summary', query: {
      'start_date': startDate,
      'end_date':   endDate,
    });
    return SalesSummaryReport(
      startDate:  res['start_date'],
      endDate:    res['end_date'],
      grandTotal: (res['grand_total'] as num).toDouble(),
      grandCash:  (res['grand_cash']  as num).toDouble(),
      grandDebt:  (res['grand_debt']  as num).toDouble(),
      days: (res['days'] as List).map((d) => DaySalesSummary(
        date:     d['date'],
        total:    (d['total']     as num).toDouble(),
        cashPaid: (d['cash_paid'] as num).toDouble(),
        debt:     (d['debt']      as num).toDouble(),
        entries:  d['entries'],
      )).toList(),
    );
  }

  Future<List<StockBalanceItem>> getStockBalance() async {
    final res = await _api.get('/stock/balance');
    return (res['balances'] as List).map((b) => StockBalanceItem(
      productId:    b['product_id'],
      productName:  b['product_name'],
      unitPrice:    (b['unit_price']    as num).toDouble(),
      packageSize:  b['package_size'],
      currentStock: (b['current_stock'] as num).toDouble(),
      stockValue:   (b['stock_value']   as num).toDouble(),
    )).toList();
  }
}
