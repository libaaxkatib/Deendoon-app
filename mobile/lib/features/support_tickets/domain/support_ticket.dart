class SupportTicket {
  final String id;
  final String tenantId;
  final String? referenceNumber;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String submittedByUserId;
  final String? businessName;
  final String createdAt;
  final String updatedAt;
  final String? closedAt;
  final String? reopenedAt;

  const SupportTicket({
    required this.id,
    required this.tenantId,
    required this.referenceNumber,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.submittedByUserId,
    required this.businessName,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
    required this.reopenedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id'].toString(),
    tenantId: json['tenant_id'].toString(),
    referenceNumber: json['reference_number'] as String?,
    subject: json['subject'] as String,
    description: json['description'] as String,
    status: json['status'] as String,
    priority: json['priority'] as String,
    category: json['category'] as String,
    submittedByUserId: json['submitted_by_user_id'].toString(),
    businessName: json['business_name'] as String?,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    closedAt: json['closed_at'] as String?,
    reopenedAt: json['reopened_at'] as String?,
  );

  bool get isClosed => status == 'closed';
}
