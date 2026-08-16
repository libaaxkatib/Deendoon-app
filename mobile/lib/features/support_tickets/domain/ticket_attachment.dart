class TicketAttachment {
  final String id;
  final String supportTicketId;
  final String? uploadedByUserId;
  final String originalFilename;
  final String mimeType;
  final int fileSize;
  final String createdAt;

  const TicketAttachment({
    required this.id,
    required this.supportTicketId,
    required this.uploadedByUserId,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) =>
      TicketAttachment(
        id: json['id'].toString(),
        supportTicketId: json['support_ticket_id'].toString(),
        uploadedByUserId: json['uploaded_by_user_id']?.toString(),
        originalFilename: json['original_filename'] as String,
        mimeType: json['mime_type'] as String,
        fileSize: json['file_size'] as int,
        createdAt: json['created_at'] as String,
      );
}
