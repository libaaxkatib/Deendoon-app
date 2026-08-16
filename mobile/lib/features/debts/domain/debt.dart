/// Mirrors `App\Http\Resources\DebtResource` exactly. `debt_status` is one
/// of: draft, pending, overdue, partial_paid, paid, cancelled, written_off
/// (the real Postgres CHECK constraint on `debts.debt_status`).
class Debt {
  final String id;
  final String customerId;
  final String referenceNumber;
  final String amount;
  final String dueDate;
  final String debtStatus;
  final String remainingBalance;
  final int recoveryStage;
  final String? notes;
  final String? archivedAt;

  const Debt({
    required this.id,
    required this.customerId,
    required this.referenceNumber,
    required this.amount,
    required this.dueDate,
    required this.debtStatus,
    required this.remainingBalance,
    required this.recoveryStage,
    required this.notes,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    id: json['id'].toString(),
    customerId: json['customer_id'].toString(),
    referenceNumber: json['reference_number'] as String,
    amount: json['amount'] as String,
    dueDate: json['due_date'] as String,
    debtStatus: json['debt_status'] as String,
    remainingBalance: json['remaining_balance'] as String,
    recoveryStage: json['recovery_stage'] as int,
    notes: json['notes'] as String?,
    archivedAt: json['archived_at'] as String?,
  );

  /// Days between `due_date` and today — pure client-side date arithmetic
  /// on two already-real fields, not a business calculation (contrast with
  /// the Dashboard's KPI deltas/Business Health, which need data the
  /// backend doesn't provide at all). Null when not meaningfully overdue.
  int? daysOverdue({DateTime? now}) {
    const closedStatuses = {'paid', 'cancelled', 'written_off'};
    if (closedStatuses.contains(debtStatus)) return null;

    final due = DateTime.tryParse(dueDate);
    if (due == null) return null;

    final today = now ?? DateTime.now();
    final days = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(due.year, due.month, due.day)).inDays;
    return days > 0 ? days : null;
  }
}
