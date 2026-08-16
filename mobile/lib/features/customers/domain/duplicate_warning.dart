/// Mirrors the `warning` object `CustomerController::duplicateWarning()`
/// attaches to `store`/`update` responses, and that `POST
/// /customers/check-duplicate` returns standalone — same shape either way.
/// BRL-013: a phone match or a case-insensitive exact name match against
/// an existing customer is surfaced as a possible duplicate; this is
/// informational only and never blocks the create/update it's attached to.
class DuplicateWarning {
  final String type;
  final String message;
  final String matchedCustomerId;

  const DuplicateWarning({
    required this.type,
    required this.message,
    required this.matchedCustomerId,
  });

  factory DuplicateWarning.fromJson(Map<String, dynamic> json) =>
      DuplicateWarning(
        type: json['type'] as String,
        message: json['message'] as String,
        matchedCustomerId: json['matched_customer_id'].toString(),
      );
}
