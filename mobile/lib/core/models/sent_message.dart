/// Mirrors `App\Http\Resources\SentMessageResource` exactly — the direct
/// result of both `POST /reminders/{id}/send` (Sprint 14) and
/// `POST /documents/{id}/share` (Sprint 15), which return an identical
/// shape. Promoted to `core/models/` once Documents needed the same
/// resource Reminders already modeled — same reuse rationale as
/// `Payment` and `DocumentSummary`. There is no backend endpoint to list
/// past delivery attempts for either a reminder or a document (confirmed
/// absent from `routes/api.php`); this shape is only ever seen as the
/// immediate response of a real Send/Share action, never fetched as
/// history.
class SentMessage {
  final String id;
  final String? reminderId;
  final String? caseId;
  final String? documentType;
  final String? documentId;
  final String channel;
  final String recipientPhone;
  final String renderedText;
  final String status;
  final String sentAt;

  const SentMessage({
    required this.id,
    required this.reminderId,
    required this.caseId,
    required this.documentType,
    required this.documentId,
    required this.channel,
    required this.recipientPhone,
    required this.renderedText,
    required this.status,
    required this.sentAt,
  });

  factory SentMessage.fromJson(Map<String, dynamic> json) => SentMessage(
    id: json['id'].toString(),
    reminderId: json['reminder_id']?.toString(),
    caseId: json['case_id']?.toString(),
    documentType: json['document_type'] as String?,
    documentId: json['document_id']?.toString(),
    channel: json['channel'] as String,
    recipientPhone: json['recipient_phone'] as String,
    renderedText: json['rendered_text'] as String,
    status: json['status'] as String,
    sentAt: json['sent_at'] as String,
  );
}
