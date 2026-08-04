import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Client-side rendering for the 7 real `NotificationType` enum values
/// (`deendoon/app/Enums/NotificationType.php`) — the backend resource
/// carries no title/message text, so icon, color, and label are all
/// derived from `type` here, the same polymorphic-by-convention pattern
/// already used by `ReminderTypeIcon`.
class NotificationTypeIcon extends StatelessWidget {
  final String type;
  final double size;

  const NotificationTypeIcon({super.key, required this.type, this.size = 40});

  static (IconData, Color) _iconAndColor(String type) => switch (type) {
        'credit_limit_reached' => (Icons.warning_amber_outlined, AppColors.danger),
        'payment_received' => (Icons.payments_outlined, AppColors.success),
        'document_available' => (Icons.description_outlined, AppColors.info),
        'collection_assignment' => (Icons.assignment_outlined, AppColors.accent),
        'reminder_sent' => (Icons.notifications_active_outlined, AppColors.primary),
        'promise_to_pay_due' => (Icons.handshake_outlined, AppColors.warning),
        'professional_collection_request_update' => (Icons.support_agent_outlined, AppColors.accent),
        _ => (Icons.notifications_outlined, AppColors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// The corresponding human-readable label for each type, used everywhere
/// [NotificationTypeIcon] appears since the backend never sends display
/// text for a notification.
String notificationTypeLabel(String type) => switch (type) {
      'credit_limit_reached' => 'Credit Limit Reached',
      'payment_received' => 'Payment Received',
      'document_available' => 'Document Available',
      'collection_assignment' => 'Collection Assignment',
      'reminder_sent' => 'Reminder Sent',
      'promise_to_pay_due' => 'Promise to Pay Due',
      'professional_collection_request_update' => 'Collection Request Update',
      _ => 'Notification',
    };
