/// Mirrors `App\Http\Resources\ProfessionalCollectionRequestAttachmentResource`
/// exactly. `uploadedByUserId` is an id only — same gap as every other
/// user-id-only field in this module (no name-resolution endpoint
/// reachable by the Business Owner role).
class ProfessionalCollectionAttachment {
  final String id;
  final String professionalCollectionRequestId;
  final String? timelineEventId;
  final String? uploadedByUserId;
  final String originalFilename;
  final String mimeType;
  final int fileSize;
  final String createdAt;

  const ProfessionalCollectionAttachment({
    required this.id,
    required this.professionalCollectionRequestId,
    required this.timelineEventId,
    required this.uploadedByUserId,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
  });

  factory ProfessionalCollectionAttachment.fromJson(Map<String, dynamic> json) => ProfessionalCollectionAttachment(
        id: json['id'].toString(),
        professionalCollectionRequestId: json['professional_collection_request_id'].toString(),
        timelineEventId: json['timeline_event_id']?.toString(),
        uploadedByUserId: json['uploaded_by_user_id']?.toString(),
        originalFilename: json['original_filename'] as String,
        mimeType: json['mime_type'] as String,
        fileSize: json['file_size'] as int,
        createdAt: json['created_at'] as String,
      );
}
