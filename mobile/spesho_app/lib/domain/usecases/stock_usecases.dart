import '../entities/stock_entity.dart';
import '../repositories/i_stock_repository.dart';

class StockInUseCase {
  final IStockRepository _repo;
  StockInUseCase(this._repo);
  Future<StockInResult> call({
    required int productId,
    required double quantity,
    required double unitPrice,
    String? note,
    String? date,
  }) =>
      _repo.stockIn(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        note: note,
        date: date,
      );
}

class GetStockBalanceUseCase {
  final IStockRepository _repo;
  GetStockBalanceUseCase(this._repo);
  Future<List<StockBalanceEntity>> call() => _repo.getStockBalance();
}

class GetStockMovementsUseCase {
  final IStockRepository _repo;
  GetStockMovementsUseCase(this._repo);
  Future<List<StockMovementEntity>> call({
    int? productId,
    String? startDate,
    String? endDate,
    String? type,
    int page = 1,
  }) =>
      _repo.getMovements(
        productId: productId,
        startDate: startDate,
        endDate: endDate,
        type: type,
        page: page,
      );
}

class StockAdjustUseCase {
  final IStockRepository _repo;
  StockAdjustUseCase(this._repo);
  Future<StockInResult> call({
    required int productId,
    required double newQuantity,
    String? reason,
  }) =>
      _repo.stockAdjust(
        productId: productId,
        newQuantity: newQuantity,
        reason: reason,
      );
}

class StockUseCases {
  final StockInUseCase stockIn;
  final GetStockBalanceUseCase getBalance;
  final GetStockMovementsUseCase getMovements;
  final StockAdjustUseCase stockAdjust;

  StockUseCases(IStockRepository repo)
      : stockIn = StockInUseCase(repo),
        getBalance = GetStockBalanceUseCase(repo),
        getMovements = GetStockMovementsUseCase(repo),
        stockAdjust = StockAdjustUseCase(repo);
}
