import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/app_notification.dart';
import '../widgets/notification_type_icon.dart';

/// There is no `GET /notifications/{id}` endpoint (07_API_Design.md §11)
/// — this screen is only reachable from an already-loaded List item, via
/// the `extra` the List passes on navigation, not deep-linked.
class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({super.key, required this.notification});

  /// Only entity types this app can confidently resolve to a real screen —
  /// document-generating types (receipt/invoice/demand_letter/statement)
  /// and `payment` are deliberately left unmapped rather than guessing at
  /// an id space this resource doesn't confirm.
  ///
  /// `subscription_change_request`/`storage_addon` deliberately route to
  /// the general Subscription/Storage screen, not a per-record detail
  /// screen — there is no `GET /subscription/change-requests/{id}` or
  /// per-id Storage Add-on endpoint reachable by the Business Owner, so
  /// `relatedEntityId` can't be resolved to anything more specific. Both
  /// screens already show the tenant's own real, current request state,
  /// which is the closest honest destination for these two types.
  String? _openRoute() => switch (notification.relatedEntityType) {
        'debt' => '/debts/${notification.relatedEntityId}',
        'customer' => '/customers/${notification.relatedEntityId}',
        'professional_collection_request' => '/professional-requests/${notification.relatedEntityId}',
        'subscription_change_request' => '/account/subscription',
        'storage_addon' => '/account/storage',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final openRoute = _openRoute();

    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NotificationTypeIcon(type: notification.type, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(notificationTypeLabel(notification.type), style: AppTypography.heading),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Related to', value: notification.relatedEntityType),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Reference ID', value: notification.relatedEntityId),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Received', value: notification.createdAt.toLocal().toString()),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Status',
                    value: notification.isRead ? 'Read' : 'Unread',
                    valueColor: notification.isRead ? AppColors.textSecondary : AppColors.primary,
                  ),
                ],
              ),
            ),
            if (openRoute != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push(openRoute),
                  child: const Text('Open'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: AppTypography.caption)),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}
