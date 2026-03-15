class DailySaleEntity {
  final int id;
  final String date;
  final double totalAmount;
  final double cashPaid;
  final double debt;
  final String? note;
  final String? customerName;
  final String? customerPhone;
  final String? recordedByName;
  final String createdAt;

  const DailySaleEntity({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.cashPaid,
    required this.debt,
    this.note,
    this.customerName,
    this.customerPhone,
    this.recordedByName,
    required this.createdAt,
  });
}
