/// Mirrors `App\Http\Resources\NotificationResource` exactly. There is no
/// `title`/`message` field on the backend resource — `type` plus
/// `related_entity_type`/`related_entity_id` are the only content, so the
/// Flutter client renders the display text itself from `type` (same
/// polymorphic-by-convention pattern already used by `Reminder`).
class AppNotification {
  final String id;
  final String type;
  final String relatedEntityType;
  final String relatedEntityId;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        type: json['type'] as String,
        relatedEntityType: json['related_entity_type'] as String,
        relatedEntityId: json['related_entity_id'].toString(),
        readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id: id,
        type: type,
        relatedEntityType: relatedEntityType,
        relatedEntityId: relatedEntityId,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );
}
