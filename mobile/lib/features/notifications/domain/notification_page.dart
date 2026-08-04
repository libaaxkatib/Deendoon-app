import 'app_notification.dart';

/// One page of `GET /notifications` or `GET /notifications/history`,
/// mirroring `NotificationController`'s pagination envelope exactly —
/// same shape as `ReminderPage`, keyed `notifications`.
class NotificationPage {
  final List<AppNotification> notifications;
  final int currentPage;
  final int lastPage;
  final int total;

  const NotificationPage({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['notifications'] as List<dynamic>;
    return NotificationPage(
      notifications: items.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
