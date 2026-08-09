import 'professional_collection_attachment.dart';

/// Mirrors `App\Http\Resources\ProfessionalCollectionTimelineEventResource`
/// exactly — the Deendoon Recovery Team's own operational activity log for
/// a Request, independent of the Audit Log and the Customer Collection
/// Timeline. Business Owner (this app) may only view it —
/// `createTimelineEvent`/`updateTimelineEvent` are Deendoon Platform
/// Administrator-only, so no write path is wrapped anywhere in this
/// feature for this resource.
class ProfessionalCollectionTimelineEvent {
  final String id;
  final String professionalCollectionRequestId;
  final String eventType;
  final String? officerUserId;
  final String occurredAt;
  final String? notes;
  final String? outcome;
  final List<ProfessionalCollectionAttachment> attachments;
  final String createdAt;
  final String updatedAt;

  const ProfessionalCollectionTimelineEvent({
    required this.id,
    required this.professionalCollectionRequestId,
    required this.eventType,
    required this.officerUserId,
    required this.occurredAt,
    required this.notes,
    required this.outcome,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfessionalCollectionTimelineEvent.fromJson(Map<String, dynamic> json) =>
      ProfessionalCollectionTimelineEvent(
        id: json['id'].toString(),
        professionalCollectionRequestId: json['professional_collection_request_id'].toString(),
        eventType: json['event_type'] as String,
        officerUserId: json['officer_user_id']?.toString(),
        occurredAt: json['occurred_at'] as String,
        notes: json['notes'] as String?,
        outcome: json['outcome'] as String?,
        attachments: (json['attachments'] as List<dynamic>? ?? [])
            .map((e) => ProfessionalCollectionAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
}
