import 'package:flutter/material.dart';
import '../../data/repositories/debt_repository.dart';
import '../../domain/entities/debt_entity.dart';

class DebtProvider extends ChangeNotifier {
  final DebtRepository _repo;
  DebtProvider(this._repo);

  List<DebtEntity> debts = [];
  DebtSummaryEntity? summary;
  DebtReportEntity? report;
  bool loading = false;
  bool reportLoading = false;
  String? error;

  Future<void> loadDebts({String? status, String? customer}) async {
    loading = true; error = null; notifyListeners();
    try {
      debts   = await _repo.getDebts(status: status, customer: customer);
      summary = await _repo.getSummary();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> loadReports() async {
    reportLoading = true; error = null; notifyListeners();
    try {
      report = await _repo.getReports();
    } catch (e) {
      error = e.toString();
    } finally {
      reportLoading = false; notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getDebt(int id) async {
    try {
      return await _repo.getDebt(id);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createDebt({
    required String customerName,
    String? customerPhone,
    required int productId,
    required double quantity,
    required double unitPrice,
    String? note,
    String? date,
  }) async {
    loading = true; notifyListeners();
    try {
      await _repo.createDebt(
        customerName:  customerName,
        customerPhone: customerPhone,
        productId:     productId,
        quantity:      quantity,
        unitPrice:     unitPrice,
        note:          note,
        date:          date,
      );
      await loadDebts();
      return true;
    } catch (e) {
      error = e.toString(); loading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> createDebtFromSale({
    required String customerName,
    String? customerPhone,
    required double totalAmount,
    required double amountPaid,
    String? note,
    String? date,
  }) async {
    try {
      await _repo.createDebtFromSale(
        customerName:  customerName,
        customerPhone: customerPhone,
        totalAmount:   totalAmount,
        amountPaid:    amountPaid,
        note:          note,
        date:          date,
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment(int debtId, double amount, {String? note, String? date}) async {
    loading = true; notifyListeners();
    try {
      await _repo.recordPayment(debtId, amount, note: note, date: date);
      await loadDebts();
      return true;
    } catch (e) {
      error = e.toString(); loading = false; notifyListeners();
      return false;
    }
  }
}
