/// Mirrors `App\Http\Resources\ReminderResource` exactly. `status` is
/// never persisted server-side — it's computed fresh on every read by
/// `SmartReminderEngine::status()` from `due_date`/`completed_at`, so it
/// must never be cached/assumed stale-safe client-side either.
///
/// `related_entity_type`/`related_entity_id` are a polymorphic-by-
/// convention pair (not a real Eloquent morphTo, same pattern as
/// `AuditLog`) — the backend does not embed the related entity's display
/// data anywhere on this resource, and does not validate that the id
/// actually exists. The Flutter client resolves the related entity itself
/// (dispatching to the matching Customer/Debt/Case repository by
/// `related_entity_type`) and must handle a dangling/not-found reference
/// gracefully rather than crashing the screen.
class Reminder {
  final String id;
  final String type;
  final String title;
  final String relatedEntityType;
  final String relatedEntityId;
  final String? relatedCaseId;
  final String dueDate;
  final String? amountDue;
  final String timingRule;
  final String? customFireAt;
  final List<String> deliveryMethods;
  final String? notes;
  final String status;
  final String createdByUserId;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;

  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.relatedCaseId,
    required this.dueDate,
    required this.amountDue,
    required this.timingRule,
    required this.customFireAt,
    required this.deliveryMethods,
    required this.notes,
    required this.status,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'].toString(),
        type: json['type'] as String,
        title: json['title'] as String,
        relatedEntityType: json['related_entity_type'] as String,
        relatedEntityId: json['related_entity_id'].toString(),
        relatedCaseId: json['related_case_id']?.toString(),
        dueDate: json['due_date'] as String,
        amountDue: json['amount_due'] as String?,
        timingRule: json['timing_rule'] as String,
        customFireAt: json['custom_fire_at'] as String?,
        deliveryMethods: (json['delivery_methods'] as List<dynamic>).map((e) => e as String).toList(),
        notes: json['notes'] as String?,
        status: json['status'] as String,
        createdByUserId: json['created_by_user_id'].toString(),
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        completedAt: json['completed_at'] as String?,
      );
}
