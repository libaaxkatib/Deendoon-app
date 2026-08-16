/// Shared shape for `CustomerAttachmentResource`/`DebtAttachmentResource`/
/// `CollectionCaseAttachmentResource` — all three are identical except the
/// parent-id field name (`customer_id`/`debt_id`/`collection_case_id`),
/// which `fromJson` resolves generically into [entityId]. One model, one
/// API client, one repository, one screen serve all three entities (a
/// shared Flutter repository parameterized by an `entityPathPrefix`
/// hitting three near-identical REST paths) — matching the backend's own
/// three-separate-tables-same-shape architecture (P1.6) without
/// duplicating client code per entity.
class Attachment {
  final String id;
  final String entityId;
  final String? uploadedByUserId;
  final String originalFilename;
  final String mimeType;
  final int fileSize;
  final String? description;
  final String createdAt;

  const Attachment({
    required this.id,
    required this.entityId,
    required this.uploadedByUserId,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSize,
    required this.description,
    required this.createdAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'].toString(),
    entityId:
        (json['customer_id'] ?? json['debt_id'] ?? json['collection_case_id'])
            .toString(),
    uploadedByUserId: json['uploaded_by_user_id']?.toString(),
    originalFilename: json['original_filename'] as String,
    mimeType: json['mime_type'] as String,
    fileSize: json['file_size'] as int,
    description: json['description'] as String?,
    createdAt: json['created_at'] as String,
  );
}
