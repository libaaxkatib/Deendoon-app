/// Mirrors `App\Http\Resources\ProfessionalCollectionRequestResource`
/// exactly. `status` is one of the real Postgres CHECK constraint values:
/// submitted, under_review, need_more_information, accepted, assigned,
/// in_progress, recovered, closed. `submittedByUserId`/`actionedByUserId`
/// are ids only — there is no endpoint reachable by the Business Owner
/// role to resolve an arbitrary user id to a name (same gap as Assigned
/// Officer on Collection Cases, Created By on Reminders). `reasons`/
/// `requestedServices` are the tenant's own Reference Data value labels
/// selected at submission (`whenLoaded`, always eager-loaded by every
/// controller action that returns this resource). `declarationAcceptedBy`
/// is a user id only, same caveat as `submittedByUserId`.
class ProfessionalCollectionRequest {
  final String id;
  final String collectionCaseId;
  final String referenceNumber;
  final String status;
  final String submittedByUserId;
  final String? actionedByUserId;
  final List<String> reasons;
  final String? notes;
  final List<String> requestedServices;
  final String? declarationAcceptedAt;
  final String? declarationAcceptedBy;
  final String createdAt;
  final String? closedAt;

  const ProfessionalCollectionRequest({
    required this.id,
    required this.collectionCaseId,
    required this.referenceNumber,
    required this.status,
    required this.submittedByUserId,
    required this.actionedByUserId,
    required this.reasons,
    required this.notes,
    required this.requestedServices,
    required this.declarationAcceptedAt,
    required this.declarationAcceptedBy,
    required this.createdAt,
    required this.closedAt,
  });

  bool get isTerminal => status == 'recovered' || status == 'closed';

  factory ProfessionalCollectionRequest.fromJson(Map<String, dynamic> json) =>
      ProfessionalCollectionRequest(
        id: json['id'].toString(),
        collectionCaseId: json['collection_case_id'].toString(),
        referenceNumber: json['reference_number'] as String,
        status: json['status'] as String,
        submittedByUserId: json['submitted_by_user_id'].toString(),
        actionedByUserId: json['actioned_by_user_id']?.toString(),
        reasons:
            (json['reasons'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        notes: json['notes'] as String?,
        requestedServices:
            (json['requested_services'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        declarationAcceptedAt: json['declaration_accepted_at'] as String?,
        declarationAcceptedBy: json['declaration_accepted_by']?.toString(),
        createdAt: json['created_at'] as String,
        closedAt: json['closed_at'] as String?,
      );
}
