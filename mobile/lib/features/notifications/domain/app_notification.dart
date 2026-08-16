/// Mirrors `App\Http\Resources\NotificationResource` exactly. `title`/
/// `message` are populated only for the `admin_announcement` type (Module
/// 9) — every other type still carries no display text of its own, so the
/// Flutter client keeps deriving its label purely from `type` for those
/// (same polymorphic-by-convention pattern already used by `Reminder`).
class AppNotification {
  final String id;
  final String type;
  final String? title;
  final String? message;
  final String relatedEntityType;
  final String relatedEntityId;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    this.title,
    this.message,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        type: json['type'] as String,
        title: json['title'] as String?,
        message: json['message'] as String?,
        relatedEntityType: json['related_entity_type'] as String,
        relatedEntityId: json['related_entity_id'].toString(),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    relatedEntityType: relatedEntityType,
    relatedEntityId: relatedEntityId,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );
}
