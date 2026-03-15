import '../entities/sale_entity.dart';
import '../repositories/i_sales_repository.dart';

class RecordSaleUseCase {
  final ISalesRepository _repo;
  RecordSaleUseCase(this._repo);
  Future<RecordSaleResult> call({
    required int productId,
    required double quantity,
    required double price,
    double discount = 0,
    double? paid,
    String? note,
    String? date,
  }) =>
      _repo.recordSale(
        productId: productId,
        quantity: quantity,
        price: price,
        discount: discount,
        paid: paid,
        note: note,
        date: date,
      );
}

class GetSalesUseCase {
  final ISalesRepository _repo;
  GetSalesUseCase(this._repo);
  Future<List<SaleEntity>> call({
    int? productId,
    String? startDate,
    String? endDate,
    int page = 1,
  }) =>
      _repo.getSales(
        productId: productId,
        startDate: startDate,
        endDate: endDate,
        page: page,
      );
}

class SalesUseCases {
  final RecordSaleUseCase recordSale;
  final GetSalesUseCase getSales;

  SalesUseCases(ISalesRepository repo)
      : recordSale = RecordSaleUseCase(repo),
        getSales = GetSalesUseCase(repo);
}
