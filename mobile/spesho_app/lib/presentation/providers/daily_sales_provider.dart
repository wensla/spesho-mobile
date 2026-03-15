import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/daily_sales_repository.dart';
import '../../domain/entities/daily_sale_entity.dart';

class DailySalesProvider extends ChangeNotifier {
  final DailySalesRepository _repo;
  DailySalesProvider(this._repo);

  List<DailySaleEntity> sales = [];
  bool loading = false;
  String? error;
  String? successMessage;

  void clearMessages() {
    error = null;
    successMessage = null;
  }

  Future<bool> recordSale({
    required double totalAmount,
    required double cashPaid,
    String? note,
    String? customerName,
    String? customerPhone,
    String? date,
  }) async {
    loading = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      final sale = await _repo.recordSale(
        totalAmount:   totalAmount,
        cashPaid:      cashPaid,
        note:          note,
        customerName:  customerName,
        customerPhone: customerPhone,
        date:          date,
      );
      successMessage = 'Sale recorded — TZS ${sale.totalAmount.toStringAsFixed(0)}';
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSales({String? startDate, String? endDate}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      sales = await _repo.getSales(startDate: startDate, endDate: endDate);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodaySales() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await loadSales(startDate: today, endDate: today);
  }

  Future<bool> deleteSale(int id) async {
    try {
      await _repo.deleteSale(id);
      sales.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
