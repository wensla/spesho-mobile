class DebtEntity {
  final int id;
  final String customerName;
  final String? customerPhone;
  final int? productId;
  final String? productName;
  final double? quantity;
  final double? unitPrice;
  final double totalAmount;
  final double amountPaid;
  final double balance;
  final String? note;
  final String date;
  final String status; // pending | partial | paid
  final int daysOutstanding;
  final String createdAt;

  const DebtEntity({
    required this.id,
    required this.customerName,
    this.customerPhone,
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
    this.note,
    required this.date,
    required this.status,
    this.daysOutstanding = 0,
    required this.createdAt,
  });

  bool get isChronic => status != 'paid' && daysOutstanding >= 30;
}

class DebtPaymentEntity {
  final int id;
  final int debtId;
  final double amount;
  final String? note;
  final String paymentDate;
  final String createdAt;

  const DebtPaymentEntity({
    required this.id,
    required this.debtId,
    required this.amount,
    this.note,
    required this.paymentDate,
    required this.createdAt,
  });
}

class DebtSummaryEntity {
  final int totalDebts;
  final int pending;
  final int partial;
  final int paid;
  final double totalAmount;
  final double totalPaid;
  final double totalBalance;

  const DebtSummaryEntity({
    required this.totalDebts,
    required this.pending,
    required this.partial,
    required this.paid,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalBalance,
  });
}

class DebtPeriodStatEntity {
  final String label;
  final int count;
  final double totalAmount;
  const DebtPeriodStatEntity({
    required this.label,
    required this.count,
    required this.totalAmount,
  });
}

class DebtReportEntity {
  final int todayNewDebts;
  final double todayCollected;
  final List<DebtPeriodStatEntity> daily;
  final List<DebtPeriodStatEntity> monthly;
  final List<DebtPeriodStatEntity> yearly;
  final List<DebtEntity> chronicDebtors;

  const DebtReportEntity({
    required this.todayNewDebts,
    required this.todayCollected,
    required this.daily,
    required this.monthly,
    required this.yearly,
    required this.chronicDebtors,
  });
}
