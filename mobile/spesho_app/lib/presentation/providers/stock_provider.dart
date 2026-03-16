import 'package:flutter/foundation.dart';
import '../../domain/entities/stock_entity.dart';
import '../../domain/usecases/stock_usecases.dart';

class StockProvider extends ChangeNotifier {
  final StockUseCases _useCases;

  List<StockBalanceEntity> _balances = [];
  List<StockMovementEntity> _movements = [];
  bool _loading = false;
  String? _error;
  String? _successMessage;

  StockProvider(this._useCases);

  List<StockBalanceEntity> get balances => _balances;
  List<StockMovementEntity> get movements => _movements;
  bool get loading => _loading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _error = null;
    _successMessage = null;
  }

  Future<void> loadBalances() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _balances = await _useCases.getBalance();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> stockIn({
    required int productId,
    required double quantity,
    required double unitPrice,
    String? note,
    String? date,
  }) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final result = await _useCases.stockIn(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        note: note,
        date: date,
      );
      _successMessage = 'Stock added. New balance: ${result.newBalance.toStringAsFixed(2)}';
      await loadBalances();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> stockAdjust({
    required int productId,
    required double newQuantity,
    String? reason,
  }) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final result = await _useCases.stockAdjust(
        productId: productId,
        newQuantity: newQuantity,
        reason: reason,
      );
      _successMessage = 'Stock adjusted. New balance: ${result.newBalance.toStringAsFixed(2)} kg';
      await loadBalances();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMovements({int? productId, String? type}) async {
    _loading = true;
    notifyListeners();
    try {
      _movements = await _useCases.getMovements(productId: productId, type: type);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
