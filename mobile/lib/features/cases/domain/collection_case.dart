/// Mirrors `App\Http\Resources\CollectionCaseResource` exactly.
/// `customer_id`, `customer_name`, `outstanding_amount`, and `risk_level`
/// are embedded from the case's debt/customer (only populated when the
/// backend eager-loads `debt.customer`, which `index()`/`show()` both do).
/// `assigned_officer_user_id` is an id only — there is no embedded officer
/// name, and no endpoint reachable by a non-admin role resolves one to a
/// name (see the Sprint 13 summary's "Missing Backend Support Required").
/// `case_status` is one of exactly two real values: `open`, `closed` (the
/// Postgres CHECK constraint on `collection_cases.case_status`).
class CollectionCase {
  final String id;
  final String debtId;
  final String? customerId;
  final String? customerName;
  final String? outstandingAmount;
  final String? riskLevel;
  final String referenceNumber;
  final String? assignedOfficerUserId;
  final String caseStatus;
  final String? closureOutcome;
  final String? notes;
  final String lastActivityAt;
  final String createdAt;
  final String? closedAt;

  const CollectionCase({
    required this.id,
    required this.debtId,
    required this.customerId,
    required this.customerName,
    required this.outstandingAmount,
    required this.riskLevel,
    required this.referenceNumber,
    required this.assignedOfficerUserId,
    required this.caseStatus,
    required this.closureOutcome,
    required this.notes,
    required this.lastActivityAt,
    required this.createdAt,
    required this.closedAt,
  });

  factory CollectionCase.fromJson(Map<String, dynamic> json) => CollectionCase(
    id: json['id'].toString(),
    debtId: json['debt_id'].toString(),
    customerId: json['customer_id']?.toString(),
    customerName: json['customer_name'] as String?,
    outstandingAmount: json['outstanding_amount'] as String?,
    riskLevel: json['risk_level'] as String?,
    referenceNumber: json['reference_number'] as String,
    assignedOfficerUserId: json['assigned_officer_user_id']?.toString(),
    caseStatus: json['case_status'] as String,
    closureOutcome: json['closure_outcome'] as String?,
    notes: json['notes'] as String?,
    lastActivityAt: json['last_activity_at'] as String,
    createdAt: json['created_at'] as String,
    closedAt: json['closed_at'] as String?,
  );
}
