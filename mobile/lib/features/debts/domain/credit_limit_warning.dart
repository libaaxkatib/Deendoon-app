/// Mirrors the `warning` object `DebtController::store()` attaches when
/// BRL-023's prospective-outstanding check exceeds the customer's credit
/// limit — informational only, the debt is still created either way.
class CreditLimitWarning {
  final String type;
  final String message;
  final String creditLimit;
  final String projectedOutstanding;

  const CreditLimitWarning({
    required this.type,
    required this.message,
    required this.creditLimit,
    required this.projectedOutstanding,
  });

  factory CreditLimitWarning.fromJson(Map<String, dynamic> json) =>
      CreditLimitWarning(
        type: json['type'] as String,
        message: json['message'] as String,
        creditLimit: json['credit_limit'] as String,
        projectedOutstanding: json['projected_outstanding'] as String,
      );
}
