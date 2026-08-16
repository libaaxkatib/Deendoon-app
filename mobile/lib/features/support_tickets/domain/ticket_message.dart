class TicketMessage {
  final String id;
  final String supportTicketId;
  final String senderUserId;
  final String? senderName;
  final String content;
  final String createdAt;

  const TicketMessage({
    required this.id,
    required this.supportTicketId,
    required this.senderUserId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    id: json['id'].toString(),
    supportTicketId: json['support_ticket_id'].toString(),
    senderUserId: json['sender_user_id'].toString().trim(),
    senderName: json['sender_name'] as String?,
    content: json['content'] as String,
    createdAt: json['created_at'] as String,
  );
}
