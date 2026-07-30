/// Mirrors `App\Http\Resources\DocumentEventResource` exactly — one entry
/// of `GET /documents/{id}/history`. `event_type` is one of `generated`,
/// `downloaded`, `regenerated` — there is genuinely no `shared` event
/// type anywhere in the backend (`App\Enums\DocumentEventType` has only
/// these three cases, confirmed by reading it directly), so a document's
/// share history never appears in this timeline — only in `SentMessage`,
/// which has no retrieval endpoint scoped by document (see the Sprint 15
/// summary's "Backend Blockers").
class DocumentEvent {
  final String id;
  final String documentType;
  final String documentId;
  final String eventType;
  final String? userId;
  final String occurredAt;

  const DocumentEvent({
    required this.id,
    required this.documentType,
    required this.documentId,
    required this.eventType,
    required this.userId,
    required this.occurredAt,
  });

  factory DocumentEvent.fromJson(Map<String, dynamic> json) => DocumentEvent(
        id: json['id'].toString(),
        documentType: json['document_type'] as String,
        documentId: json['document_id'].toString(),
        eventType: json['event_type'] as String,
        userId: json['user_id']?.toString(),
        occurredAt: json['occurred_at'] as String,
      );
}
