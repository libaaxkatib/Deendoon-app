import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/notification_list_provider.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_type_icon.dart';

/// Sprint 4 — Notification Filter. One chip per real `NotificationType`
/// enum value (`deendoon/app/Enums/NotificationType.php`) plus "All" —
/// every chip is a real `GET /notifications?type=...` call via the
/// already-existing `NotificationListNotifier.filterByType`, which was
/// built (but never wired to any UI) when this screen was first built.
/// No client-side filtering: switching chips always re-fetches page 1
/// under the new `type`, same principle as the Reminder Center's and
/// Customer List's filter chips.
const _notificationTypeFilters = <String>[
  'credit_limit_reached',
  'payment_received',
  'document_available',
  'collection_assignment',
  'reminder_sent',
  'promise_to_pay_due',
  'professional_collection_request_update',
];

/// Notifications module — Module 10 (FR-058–062), already approved and
/// frozen in the SRS, and already fully built on the backend
/// (`NotificationController`). This screen is real: no TODO/placeholder
/// data anywhere, wired directly to `GET /notifications`,
/// `PATCH /notifications/{id}/read`, and
/// `PATCH /notifications/mark-all-read`.
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends ConsumerState<NotificationListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationsAsync.valueOrNull?.hasUnread ?? false)
            TextButton(
              onPressed: () => ref.read(notificationListProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _NotificationTypeChip(
                  label: 'All',
                  selected: notificationsAsync.valueOrNull?.type == null,
                  onTap: () => ref.read(notificationListProvider.notifier).filterByType(null),
                ),
                const SizedBox(width: 8),
                for (final type in _notificationTypeFilters) ...[
                  _NotificationTypeChip(
                    label: notificationTypeLabel(type),
                    selected: notificationsAsync.valueOrNull?.type == type,
                    onTap: () => ref.read(notificationListProvider.notifier).filterByType(type),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: RetrySection(
                  message: 'Could not load notifications.',
                  onRetry: () => ref.invalidate(notificationListProvider),
                ),
              ),
              data: (state) {
                if (state.notifications.isEmpty) {
                  return Center(
                    child: Text(
                      state.type == null
                          ? 'No notifications yet'
                          : 'No ${notificationTypeLabel(state.type!)} notifications',
                      style: AppTypography.body,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= state.notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final notification = state.notifications[index];
                      return NotificationCard(
                        notification: notification,
                        onTap: () async {
                          await ref.read(notificationListProvider.notifier).markRead(notification.id);
                          if (context.mounted) {
                            context.push('/notifications/${notification.id}', extra: notification);
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NotificationTypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
    );
  }
}
