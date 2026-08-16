import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
  // Phase 5 Step 6 added subscription_request_update/storage_request_update;
  // Module 9 added the 5 support_ticket_* types (previously renderable via
  // notificationTypeLabel but missing from this filter row — a real gap,
  // not a deliberate omission) plus admin_announcement, its own new type.
  // Same real-API-filter treatment as every other type here, no
  // client-side filtering.
  'credit_limit_reached',
  'payment_received',
  'document_available',
  'collection_assignment',
  'reminder_sent',
  'promise_to_pay_due',
  'professional_collection_request_update',
  'subscription_request_update',
  'storage_request_update',
  'support_ticket_created',
  'support_ticket_replied',
  'support_ticket_status_changed',
  'support_ticket_closed',
  'support_ticket_reopened',
  'admin_announcement',
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
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sectionNotifications),
        actions: [
          if (notificationsAsync.valueOrNull?.hasUnread ?? false)
            TextButton(
              onPressed: () =>
                  ref.read(notificationListProvider.notifier).markAllRead(),
              child: Text(l10n.notificationMarkAllReadButton),
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
                  label: l10n.notificationFilterAll,
                  selected: notificationsAsync.valueOrNull?.type == null,
                  onTap: () => ref
                      .read(notificationListProvider.notifier)
                      .filterByType(null),
                ),
                const SizedBox(width: 8),
                for (final type in _notificationTypeFilters) ...[
                  _NotificationTypeChip(
                    label: notificationTypeLabel(context, type),
                    selected: notificationsAsync.valueOrNull?.type == type,
                    onTap: () => ref
                        .read(notificationListProvider.notifier)
                        .filterByType(type),
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
                  message: l10n.notificationListLoadError,
                  onRetry: () => ref.invalidate(notificationListProvider),
                ),
              ),
              data: (state) {
                if (state.notifications.isEmpty) {
                  return Center(
                    child: Text(
                      state.type == null
                          ? l10n.notificationListEmptyState
                          : l10n.notificationListEmptyFilteredState(
                              notificationTypeLabel(context, state.type!),
                            ),
                      style: AppTypography.body.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(notificationListProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        state.notifications.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= state.notifications.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: state.loadMoreError
                                ? RetrySection(
                                    message: l10n.paginationLoadMoreError,
                                    onRetry: () => ref
                                        .read(notificationListProvider.notifier)
                                        .loadMore(),
                                  )
                                : const CircularProgressIndicator(),
                          ),
                        );
                      }
                      final notification = state.notifications[index];
                      return Dismissible(
                        key: ValueKey(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => ref
                            .read(notificationListProvider.notifier)
                            .delete(notification.id),
                        child: NotificationCard(
                          notification: notification,
                          onTap: () async {
                            await ref
                                .read(notificationListProvider.notifier)
                                .markRead(notification.id);
                            if (context.mounted) {
                              context.push(
                                '/notifications/${notification.id}',
                                extra: notification,
                              );
                            }
                          },
                        ),
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

  const _NotificationTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : context.colors.textSecondary,
      ),
      backgroundColor: context.colors.surface,
      side: BorderSide.none,
    );
  }
}
