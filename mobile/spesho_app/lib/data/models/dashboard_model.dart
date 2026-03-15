import '../../domain/entities/dashboard_entity.dart';

class SalesGraphPoint extends SalesGraphPointEntity {
  const SalesGraphPoint({required super.date, required super.total, required super.count});

  factory SalesGraphPoint.fromJson(Map<String, dynamic> j) => SalesGraphPoint(
        date:  j['date'] ?? '',
        total: (j['total'] as num? ?? 0).toDouble(),
        count: (j['count'] as num? ?? 0).toInt(),
      );
}

class SalesPeriodPoint extends SalesPeriodPointEntity {
  const SalesPeriodPoint({required super.label, required super.total});

  factory SalesPeriodPoint.fromJson(Map<String, dynamic> j) => SalesPeriodPoint(
        label: j['label'] ?? '',
        total: (j['total'] as num? ?? 0).toDouble(),
      );
}

class StockTrendPoint extends StockTrendPointEntity {
  const StockTrendPoint({required super.date, required super.qtyIn, required super.qtyOut});

  factory StockTrendPoint.fromJson(Map<String, dynamic> j) => StockTrendPoint(
        date:   j['date'] ?? '',
        qtyIn:  (j['qty_in']  as num? ?? 0).toDouble(),
        qtyOut: (j['qty_out'] as num? ?? 0).toDouble(),
      );
}

class StockLevel extends StockLevelEntity {
  const StockLevel({required super.product, required super.stock, required super.value});

  factory StockLevel.fromJson(Map<String, dynamic> j) => StockLevel(
        product: j['product'] ?? '',
        stock:   (j['stock'] as num? ?? 0).toDouble(),
        value:   (j['value'] as num? ?? 0).toDouble(),
      );
}

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required super.totalSalesToday,
    required super.totalSalesWeek,
    required super.totalSalesMonth,
    required super.totalSalesYear,
    required super.totalDiscountsMonth,
    required super.totalDebtors,
    required super.totalOutstanding,
    required super.totalDebtCollectedToday,
    required super.totalStockKg,
    required super.totalStockValue,
    required super.salesGraph,
    required super.stockLevels,
    required super.salesDaily7d,
    required super.salesWeekly,
    required super.salesMonthly,
    required super.stockTrend,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> j) => DashboardModel(
        totalSalesToday:          (j['total_sales_today']           as num? ?? 0).toDouble(),
        totalSalesWeek:           (j['total_sales_week']            as num? ?? 0).toDouble(),
        totalSalesMonth:          (j['total_sales_month']           as num? ?? 0).toDouble(),
        totalSalesYear:           (j['total_sales_year']            as num? ?? 0).toDouble(),
        totalDiscountsMonth:      (j['total_discounts_month']       as num? ?? 0).toDouble(),
        totalDebtors:             (j['total_debtors']               as num? ?? 0).toInt(),
        totalOutstanding:         (j['total_outstanding']           as num? ?? 0).toDouble(),
        totalDebtCollectedToday:  (j['total_debt_collected_today']  as num? ?? 0).toDouble(),
        totalStockKg:             (j['total_stock_kg']              as num? ?? 0).toDouble(),
        totalStockValue:          (j['total_stock_value']           as num? ?? 0).toDouble(),
        salesGraph:    (j['sales_graph']    as List? ?? []).map((e) => SalesGraphPoint.fromJson(e)).toList(),
        stockLevels:   (j['stock_levels']   as List? ?? []).map((e) => StockLevel.fromJson(e)).toList(),
        salesDaily7d:  (j['sales_daily_7d'] as List? ?? []).map((e) => SalesPeriodPoint.fromJson(e)).toList(),
        salesWeekly:   (j['sales_weekly']   as List? ?? []).map((e) => SalesPeriodPoint.fromJson(e)).toList(),
        salesMonthly:  (j['sales_monthly']  as List? ?? []).map((e) => SalesPeriodPoint.fromJson(e)).toList(),
        stockTrend:    (j['stock_trend']    as List? ?? []).map((e) => StockTrendPoint.fromJson(e)).toList(),
      );
}
