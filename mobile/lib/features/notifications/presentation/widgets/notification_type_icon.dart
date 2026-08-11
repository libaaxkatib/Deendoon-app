import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Client-side rendering for the 9 real `NotificationType` enum values
/// (`deendoon/app/Enums/NotificationType.php`) — the backend resource
/// carries no title/message text, so icon, color, and label are all
/// derived from `type` here, the same polymorphic-by-convention pattern
/// already used by `ReminderTypeIcon`.
class NotificationTypeIcon extends StatelessWidget {
  final String type;
  final double size;

  const NotificationTypeIcon({super.key, required this.type, this.size = 40});

  static (IconData, Color) _iconAndColor(BuildContext context, String type) => switch (type) {
        'credit_limit_reached' => (Icons.warning_amber_outlined, AppColors.danger),
        'payment_received' => (Icons.payments_outlined, AppColors.success),
        'document_available' => (Icons.description_outlined, AppColors.info),
        'collection_assignment' => (Icons.assignment_outlined, AppColors.accent),
        'reminder_sent' => (Icons.notifications_active_outlined, AppColors.primary),
        'promise_to_pay_due' => (Icons.handshake_outlined, AppColors.warning),
        'professional_collection_request_update' => (Icons.support_agent_outlined, AppColors.accent),
        'subscription_request_update' => (Icons.card_membership_outlined, AppColors.accent),
        'storage_request_update' => (Icons.storage_outlined, AppColors.accent),
        _ => (Icons.notifications_outlined, context.colors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(context, type);
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
String notificationTypeLabel(BuildContext context, String type) {
  final l10n = AppLocalizations.of(context);
  return switch (type) {
    'credit_limit_reached' => l10n.notificationTypeCreditLimitReached,
    'payment_received' => l10n.notificationTypePaymentReceived,
    'document_available' => l10n.notificationTypeDocumentAvailable,
    'collection_assignment' => l10n.notificationTypeCollectionAssignment,
    'reminder_sent' => l10n.notificationTypeReminderSent,
    'promise_to_pay_due' => l10n.notificationTypePromiseToPayDue,
    'professional_collection_request_update' => l10n.notificationTypeCollectionRequestUpdate,
    'subscription_request_update' => l10n.notificationTypeSubscriptionUpdate,
    'storage_request_update' => l10n.notificationTypeStorageAddonUpdate,
    _ => l10n.notificationTypeFallback,
  };
}
