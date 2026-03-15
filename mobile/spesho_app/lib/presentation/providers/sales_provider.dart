import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/sales_usecases.dart';

class SalesProvider extends ChangeNotifier {
  final SalesUseCases _useCases;

  // ── Sales history ────────────────────────────────────────────────────────
  List<SaleEntity> _sales = [];
  bool _loading = false;
  String? _error;
  String? _successMessage;

  // ── Cart ─────────────────────────────────────────────────────────────────
  final List<CartItem> _cart = [];
  List<CartItem> _lastCartItems = [];

  SalesProvider(this._useCases);

  List<SaleEntity> get sales => _sales;
  bool get loading => _loading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  List<CartItem> get cart => List.unmodifiable(_cart);
  List<CartItem> get lastCartItems => List.unmodifiable(_lastCartItems);
  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  int get cartCount => _cart.length;

  void clearMessages() {
    _error = null;
    _successMessage = null;
  }

  // ── Cart operations ───────────────────────────────────────────────────────

  void addToCart(CartItem item) {
    _cart.add(item);
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ── Record single sale ────────────────────────────────────────────────────

  Future<bool> recordSale({
    required int productId,
    required double quantity,
    required double price,
    double discount = 0,
    double? paid,
    String? note,
    String? date,
  }) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final result = await _useCases.recordSale(
        productId: productId,
        quantity: quantity,
        price: price,
        discount: discount,
        paid: paid,
        note: note,
        date: date,
      );
      _successMessage =
          'Sale recorded. Total: TZS ${result.sale.total.toStringAsFixed(2)}';
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Record all cart items ─────────────────────────────────────────────────

  Future<bool> recordCartSales({
    String? note,
    String? date,
    double? totalPaid,
  }) async {
    if (_cart.isEmpty) return false;
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      // Calculate paid amount per item proportionally if totalPaid is provided
      final grandTotal = cartTotal;

      // Fire all sale requests in parallel for speed
      final results = await Future.wait(
        _cart.map((item) {
          // Calculate proportional paid amount for this item
          double? itemPaid;
          if (totalPaid != null && grandTotal > 0) {
            final proportion = item.subtotal / grandTotal;
            itemPaid = totalPaid * proportion;
          }

          return _useCases.recordSale(
            productId: item.product.id,
            quantity: item.quantity * item.product.packageSize,  // packages → kg
            price: item.price,
            discount: item.discount,
            paid: itemPaid,
            note: note,
            date: date,
          );
        }),
      );
      final count = _cart.length;
      final totalRecorded = results.fold(0.0, (s, r) => s + r.sale.total);
      _lastCartItems = List.of(_cart);
      _cart.clear();
      _successMessage =
          '$count item(s) recorded. Total: TZS ${totalRecorded.toStringAsFixed(2)}';
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Load sales ────────────────────────────────────────────────────────────

  Future<void> loadSales({
    int? productId,
    String? startDate,
    String? endDate,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _sales = await _useCases.getSales(
        productId: productId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodaySales() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await loadSales(startDate: today, endDate: today);
  }
}
