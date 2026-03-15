import '../../core/network/api_client.dart';
import '../../domain/entities/debt_entity.dart';

class DebtRepository {
  final ApiClient _api;
  DebtRepository(this._api);

  DebtEntity _fromMap(Map<String, dynamic> m) => DebtEntity(
        id:              m['id'],
        customerName:    m['customer_name'],
        customerPhone:   m['customer_phone'],
        productId:       m['product_id'],
        productName:     m['product_name'],
        quantity:        m['quantity']   != null ? (m['quantity']   as num).toDouble() : null,
        unitPrice:       m['unit_price'] != null ? (m['unit_price'] as num).toDouble() : null,
        totalAmount:     (m['total_amount'] as num).toDouble(),
        amountPaid:      (m['amount_paid']  as num).toDouble(),
        balance:         (m['balance']      as num).toDouble(),
        note:            m['note'],
        date:            m['date'],
        status:          m['status'],
        daysOutstanding: (m['days_outstanding'] as num?)?.toInt() ?? 0,
        createdAt:       m['created_at'],
      );

  DebtPaymentEntity _paymentFromMap(Map<String, dynamic> m) => DebtPaymentEntity(
        id:          m['id'],
        debtId:      m['debt_id'],
        amount:      (m['amount'] as num).toDouble(),
        note:        m['note'],
        paymentDate: m['payment_date'],
        createdAt:   m['created_at'],
      );

  Future<List<DebtEntity>> getDebts({String? status, String? customer}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (customer != null) params['customer'] = customer;
    final res = await _api.get('/debts/', query: params);
    return (res['debts'] as List).map((e) => _fromMap(e)).toList();
  }

  Future<DebtSummaryEntity> getSummary() async {
    final res = await _api.get('/debts/summary');
    return DebtSummaryEntity(
      totalDebts:   res['total_debts'],
      pending:      res['pending'],
      partial:      res['partial'],
      paid:         res['paid'],
      totalAmount:  (res['total_amount']  as num).toDouble(),
      totalPaid:    (res['total_paid']    as num).toDouble(),
      totalBalance: (res['total_balance'] as num).toDouble(),
    );
  }

  Future<Map<String, dynamic>> getDebt(int id) async {
    final res = await _api.get('/debts/$id');
    return {
      'debt':     _fromMap(res['debt']),
      'payments': (res['payments'] as List).map((e) => _paymentFromMap(e)).toList(),
    };
  }

  Future<DebtReportEntity> getReports() async {
    final res = await _api.get('/debts/reports');
    final today = res['today'] as Map<String, dynamic>;

    DebtPeriodStatEntity stat(Map<String, dynamic> m) => DebtPeriodStatEntity(
          label:       m['label'],
          count:       (m['count'] as num).toInt(),
          totalAmount: (m['total_amount'] as num).toDouble(),
        );

    return DebtReportEntity(
      todayNewDebts:  (today['new_debts'] as num).toInt(),
      todayCollected: (today['collected'] as num).toDouble(),
      daily:          (res['daily']   as List).map((e) => stat(e)).toList(),
      monthly:        (res['monthly'] as List).map((e) => stat(e)).toList(),
      yearly:         (res['yearly']  as List).map((e) => stat(e)).toList(),
      chronicDebtors: (res['chronic_debtors'] as List).map((e) => _fromMap(e)).toList(),
    );
  }

  Future<DebtEntity> createDebt({
    required String customerName,
    String? customerPhone,
    required int productId,
    required double quantity,
    required double unitPrice,
    String? note,
    String? date,
  }) async {
    final res = await _api.post('/debts/', {
      'customer_name':  customerName,
      'customer_phone': customerPhone,
      'product_id':     productId,
      'quantity':       quantity,
      'unit_price':     unitPrice,
      'note':           note,
      'date':           date,
    });
    return _fromMap(res['debt']);
  }

  Future<DebtEntity> createDebtFromSale({
    required String customerName,
    String? customerPhone,
    required double totalAmount,
    required double amountPaid,
    String? note,
    String? date,
  }) async {
    final res = await _api.post('/debts/from-sale', {
      'customer_name':  customerName,
      'customer_phone': customerPhone,
      'total_amount':   totalAmount,
      'amount_paid':    amountPaid,
      'note':           note,
      'date':           date,
    });
    return _fromMap(res['debt']);
  }

  Future<DebtEntity> recordPayment(int debtId, double amount, {String? note, String? date}) async {
    final res = await _api.post('/debts/$debtId/payments', {
      'amount': amount,
      'note':   note,
      'date':   date,
    });
    return _fromMap(res['debt']);
  }
}
