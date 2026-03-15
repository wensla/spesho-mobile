class SalesGraphPointEntity {
  final String date;
  final double total;
  final int count;
  const SalesGraphPointEntity({required this.date, required this.total, required this.count});
}

class SalesPeriodPointEntity {
  final String label;
  final double total;
  const SalesPeriodPointEntity({required this.label, required this.total});
}

class StockTrendPointEntity {
  final String date;
  final double qtyIn;
  final double qtyOut;
  const StockTrendPointEntity({required this.date, required this.qtyIn, required this.qtyOut});
}

class StockLevelEntity {
  final String product;
  final double stock;
  final double value;
  const StockLevelEntity({required this.product, required this.stock, required this.value});
}

class DashboardEntity {
  final double totalSalesToday;
  final double totalSalesWeek;
  final double totalSalesMonth;
  final double totalSalesYear;
  final double totalDiscountsMonth;
  final int totalDebtors;
  final double totalOutstanding;
  final double totalDebtCollectedToday;
  final double totalStockKg;
  final double totalStockValue;
  final List<SalesGraphPointEntity> salesGraph;
  final List<StockLevelEntity> stockLevels;
  final List<SalesPeriodPointEntity> salesDaily7d;
  final List<SalesPeriodPointEntity> salesWeekly;
  final List<SalesPeriodPointEntity> salesMonthly;
  final List<StockTrendPointEntity> stockTrend;

  const DashboardEntity({
    required this.totalSalesToday,
    required this.totalSalesWeek,
    required this.totalSalesMonth,
    required this.totalSalesYear,
    required this.totalDiscountsMonth,
    required this.totalDebtors,
    required this.totalOutstanding,
    required this.totalDebtCollectedToday,
    required this.totalStockKg,
    required this.totalStockValue,
    required this.salesGraph,
    required this.stockLevels,
    required this.salesDaily7d,
    required this.salesWeekly,
    required this.salesMonthly,
    required this.stockTrend,
  });
}
