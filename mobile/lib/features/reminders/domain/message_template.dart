/// Mirrors `App\Http\Resources\MessageTemplateResource` exactly.
class MessageTemplate {
  final String id;
  final String name;
  final String channel;
  final String body;
  final String createdAt;
  final String updatedAt;

  const MessageTemplate({
    required this.id,
    required this.name,
    required this.channel,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> json) => MessageTemplate(
        id: json['id'].toString(),
        name: json['name'] as String,
        channel: json['channel'] as String,
        body: json['body'] as String,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
}
