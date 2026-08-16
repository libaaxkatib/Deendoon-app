/// Mirrors the fields `CollectionCaseResource` exposes that the Home
/// Dashboard's Recent Cases section (§4.5) actually renders — customer
/// name, outstanding amount, risk badge, last activity. Other resource
/// fields (case_status, closure_outcome, etc.) belong to the Cases module,
/// out of scope this sprint.
class RecentCase {
  final String id;
  final String customerName;
  final String outstandingAmount;
  final String? riskLevel;
  final DateTime lastActivityAt;

  const RecentCase({
    required this.id,
    required this.customerName,
    required this.outstandingAmount,
    required this.riskLevel,
    required this.lastActivityAt,
  });

  factory RecentCase.fromJson(Map<String, dynamic> json) => RecentCase(
    id: json['id'].toString(),
    customerName: json['customer_name'] as String? ?? 'Unknown Customer',
    outstandingAmount: json['outstanding_amount'] as String? ?? '0.00',
    riskLevel: json['risk_level'] as String?,
    lastActivityAt: DateTime.parse(json['last_activity_at'] as String),
  );
}
