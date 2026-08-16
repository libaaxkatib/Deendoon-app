/// Mirrors `App\Http\Resources\RequestMessageResource` exactly.
class RequestMessage {
  final String id;
  final String professionalCollectionRequestId;
  final String senderUserId;
  final String content;
  final String createdAt;

  const RequestMessage({
    required this.id,
    required this.professionalCollectionRequestId,
    required this.senderUserId,
    required this.content,
    required this.createdAt,
  });

  factory RequestMessage.fromJson(Map<String, dynamic> json) => RequestMessage(
    id: json['id'].toString(),
    professionalCollectionRequestId: json['professional_collection_request_id']
        .toString(),
    senderUserId: json['sender_user_id'].toString().trim(),
    content: json['content'] as String,
    createdAt: json['created_at'] as String,
  );
}
