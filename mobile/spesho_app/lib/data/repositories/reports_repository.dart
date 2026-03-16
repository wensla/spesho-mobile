import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

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

class PaymentMethodBreakdown {
  final String method;
  final double total;
  final int count;
  const PaymentMethodBreakdown({required this.method, required this.total, required this.count});
}

class SalesSummaryReport {
  final String startDate;
  final String endDate;
  final List<DaySalesSummary> days;
  final double grandTotal;
  final double grandCash;
  final double grandDebt;
  final List<PaymentMethodBreakdown> paymentBreakdown;

  const SalesSummaryReport({
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.grandTotal,
    required this.grandCash,
    required this.grandDebt,
    this.paymentBreakdown = const [],
  });
}

class StockBalanceItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final double? buyingPrice;
  final int packageSize;
  final double currentStock; // kg
  final double stockValue;

  const StockBalanceItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.buyingPrice,
    required this.packageSize,
    required this.currentStock,
    required this.stockValue,
  });

  double get packages => currentStock / packageSize;

  double? get profitMargin {
    if (buyingPrice == null || buyingPrice! <= 0) return null;
    return ((unitPrice - buyingPrice!) / buyingPrice!) * 100;
  }
}

const _paymentLabels = {
  'cash':          'Cash',
  'mpesa':         'M-Pesa',
  'tigopesa':      'Tigo Pesa',
  'airtel_money':  'Airtel Money',
  'mobile_money':  'Mobile Money',
  'bank_transfer': 'Bank Transfer',
  'credit':        'Credit',
};

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

  /// Fetches payment method breakdown for a given period endpoint.
  Future<List<PaymentMethodBreakdown>> getPaymentBreakdown({
    required String endpoint,
    Map<String, String>? query,
  }) async {
    try {
      final res = await _api.get(endpoint, query: query);
      final rows = res['payment_breakdown'] as List? ?? [];
      return rows.map((r) => PaymentMethodBreakdown(
        method: _paymentLabels[r['method']] ?? r['method'] ?? 'Other',
        total:  (r['total'] as num).toDouble(),
        count:  r['count'] as int,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StockBalanceItem>> getStockBalance() async {
    final res = await _api.get('/stock/balance');
    return (res['balances'] as List).map((b) => StockBalanceItem(
      productId:    b['product_id'],
      productName:  b['product_name'],
      unitPrice:    (b['unit_price']    as num).toDouble(),
      buyingPrice:  b['buying_price'] != null ? (b['buying_price'] as num).toDouble() : null,
      packageSize:  b['package_size'],
      currentStock: (b['current_stock'] as num).toDouble(),
      stockValue:   (b['stock_value']   as num).toDouble(),
    )).toList();
  }

  String buildUrl(String path) => '${AppConstants.baseUrl}$path';
}
