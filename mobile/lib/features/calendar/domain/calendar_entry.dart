/// Mirrors one entry of `CalendarController::index`'s `entries` array
/// exactly (`deendoon/app/Http/Controllers/CalendarController.php`) —
/// FR-062/BRL-068's read-only aggregation over Debt due dates, open
/// Promise to Pay dates, manual follow-up history (WhatsApp/SMS/call), and
/// open Reminders. `type` is the aggregation bucket (`due_date`,
/// `promise_to_pay`, `follow_up`, `reminder`), distinct from a `Reminder`
/// model's own `type` field (Client Visit, Payment Due, etc.) — the
/// backend never conflates the two. `label` is nullable: `promise_to_pay`
/// entries carry no label at all.
///
/// Collection Appointments (Module 7) are not included here — the
/// controller's own docblock flags this as an unresolved backend gap
/// (BRL-068/DD-036): there is no date field on `collection_cases` to
/// aggregate.
class CalendarEntry {
  final String type;
  final String date;
  final String relatedEntityType;
  final String relatedEntityId;
  final String? label;

  const CalendarEntry({
    required this.type,
    required this.date,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.label,
  });

  factory CalendarEntry.fromJson(Map<String, dynamic> json) => CalendarEntry(
    type: json['type'] as String,
    date: json['date'] as String,
    relatedEntityType: json['related_entity_type'] as String,
    relatedEntityId: json['related_entity_id'].toString(),
    label: json['label'] as String?,
  );
}
