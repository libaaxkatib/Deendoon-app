import 'subscription_plan.dart';

/// Mirrors `App\Http\Resources\SubscriptionChangeRequestResource` exactly —
/// returned by `GET /subscription/change-requests`, `POST /subscription/
/// upgrade-request`, and `POST /subscription/change-requests/{id}/cancel`.
///
/// `tenantName` is null for every Business Owner-scoped call (this feature's
/// only scope — the Platform Admin Approval Center is out of Flutter's
/// scope): the backend only eager-loads `tenant` for the admin endpoint.
/// `requestedPlan`/`currentPlan` are always present in practice (the
/// Business Owner-scoped controller methods always eager-load both), but
/// stay nullable to match the resource's own `whenLoaded` contract.
///
/// Manual Mobile-Money Subscription Payment Flow (Product Owner decision):
/// `paymentPhone` (the mobile-money number the payment was sent from) is
/// now required at submission, so it's always present on a request created
/// through the new flow — but stays nullable here since older/other rows in
/// the same table may not have one. `paymentReference` (the mobile-money
/// transaction reference) became optional at submission for the same
/// decision, so it's nullable too.
class SubscriptionChangeRequest {
  final String id;
  final String tenantId;
  final String? tenantName;
  final SubscriptionPlan? requestedPlan;
  final SubscriptionPlan? currentPlan;
  final String? paymentPhone;
  final String? paymentReference;
  final String status;
  final DateTime requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final List<String>? rejectionReasons;

  const SubscriptionChangeRequest({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.requestedPlan,
    required this.currentPlan,
    required this.paymentPhone,
    required this.paymentReference,
    required this.status,
    required this.requestedAt,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.rejectionReason,
    required this.rejectionReasons,
  });

  factory SubscriptionChangeRequest.fromJson(Map<String, dynamic> json) =>
      SubscriptionChangeRequest(
        id: json['id'].toString(),
        tenantId: json['tenant_id'].toString(),
        tenantName: json['tenant_name'] as String?,
        requestedPlan: json['requested_plan'] == null
            ? null
            : SubscriptionPlan.fromJson(
                json['requested_plan'] as Map<String, dynamic>,
              ),
        currentPlan: json['current_plan'] == null
            ? null
            : SubscriptionPlan.fromJson(
                json['current_plan'] as Map<String, dynamic>,
              ),
        paymentPhone: json['payment_phone'] as String?,
        paymentReference: json['payment_reference'] as String?,
        status: json['status'] as String,
        requestedAt: DateTime.parse(json['requested_at'] as String),
        reviewedBy: json['reviewed_by']?.toString(),
        reviewedAt: json['reviewed_at'] == null
            ? null
            : DateTime.parse(json['reviewed_at'] as String),
        rejectionReason: json['rejection_reason'] as String?,
        rejectionReasons: (json['rejection_reasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
}
