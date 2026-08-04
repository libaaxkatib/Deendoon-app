/// Mirrors `App\Http\Resources\ProfessionalCollectionRequestResource`
/// exactly. `status` is one of the real Postgres CHECK constraint values:
/// submitted, under_review, need_more_information, accepted, assigned,
/// in_progress, recovered, closed. `submittedByUserId`/`actionedByUserId`
/// are ids only — there is no endpoint reachable by the Business Owner
/// role to resolve an arbitrary user id to a name (same gap as Assigned
/// Officer on Collection Cases, Created By on Reminders).
class ProfessionalCollectionRequest {
  final String id;
  final String collectionCaseId;
  final String referenceNumber;
  final String status;
  final String submittedByUserId;
  final String? actionedByUserId;
  final String createdAt;
  final String? closedAt;

  const ProfessionalCollectionRequest({
    required this.id,
    required this.collectionCaseId,
    required this.referenceNumber,
    required this.status,
    required this.submittedByUserId,
    required this.actionedByUserId,
    required this.createdAt,
    required this.closedAt,
  });

  bool get isTerminal => status == 'recovered' || status == 'closed';

  factory ProfessionalCollectionRequest.fromJson(Map<String, dynamic> json) => ProfessionalCollectionRequest(
        id: json['id'].toString(),
        collectionCaseId: json['collection_case_id'].toString(),
        referenceNumber: json['reference_number'] as String,
        status: json['status'] as String,
        submittedByUserId: json['submitted_by_user_id'].toString(),
        actionedByUserId: json['actioned_by_user_id']?.toString(),
        createdAt: json['created_at'] as String,
        closedAt: json['closed_at'] as String?,
      );
}
