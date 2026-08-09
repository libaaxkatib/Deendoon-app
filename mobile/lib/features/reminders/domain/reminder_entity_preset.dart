/// Entity-Aware Reminder Creation (P2.4): carries the originating
/// Customer/Debt/Collection Case through `context.push('/reminders/new',
/// extra: ...)` so `ReminderScheduleScreen` can pre-fill and lock "Related
/// To" instead of showing the generic customer-picker. [type] is always
/// one of the three real, backend-modeled `related_entity_type` values
/// reachable from a detail screen — `customer`, `debt`, `collection_case`
/// (the fourth backend value, `promise_to_pay`, has no detail screen of
/// its own to launch from).
class ReminderEntityPreset {
  final String type;
  final String id;
  final String label;

  const ReminderEntityPreset({required this.type, required this.id, required this.label});
}
