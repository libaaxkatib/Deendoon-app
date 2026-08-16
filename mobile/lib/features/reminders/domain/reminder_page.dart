import 'reminder.dart';

/// One page of `GET /reminders`, mirroring the controller's pagination
/// envelope exactly (`current_page`, `per_page`, `total`, `last_page`) —
/// same shape as `DebtPage`/`CollectionCasePage`, keyed `reminders`.
class ReminderPage {
  final List<Reminder> reminders;
  final int currentPage;
  final int lastPage;
  final int total;

  const ReminderPage({
    required this.reminders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory ReminderPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['reminders'] as List<dynamic>;
    return ReminderPage(
      reminders: items
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
