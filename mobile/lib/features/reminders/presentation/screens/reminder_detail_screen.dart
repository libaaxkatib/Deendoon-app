import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/reminder_actions.dart';
import '../providers/reminder_detail_providers.dart';
import '../providers/related_entity_provider.dart';
import '../widgets/reminder_type_icon.dart';

/// Reminder Details (§7.4): header with edit/delete icons; icon, title,
/// related entity name, due label; details list (Type, Due Date, Amount
/// Due, Related Case, Created By, Created On); Notes; three actions
/// (Send Reminder, Mark as Completed, Reschedule). `Created By` is shown
/// as a raw user id — there is no endpoint reachable by non-admin roles
/// to resolve a user id to a name (same gap as Assigned Officer on
/// Collection Cases, Sprint 13).
class ReminderDetailScreen extends ConsumerWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  static const _amountDueTypes = {'payment_due', 'promise_to_pay'};

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('This reminder will no longer appear in any view. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(reminderActionsProvider).delete(reminderId);
      router.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reminderActionsProvider).complete(reminderId);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(reminderDetailProvider(reminderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: reminderAsync.valueOrNull == null
                ? null
                : () => context.push('/reminders/$reminderId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: reminderAsync.valueOrNull == null ? null : () => _delete(context, ref),
          ),
        ],
      ),
      body: reminderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: RetrySection(
              message: 'Could not load this reminder.',
              onRetry: () => ref.invalidate(reminderDetailProvider(reminderId)),
            ),
          ),
        ),
        data: (reminder) {
          final relatedAsync =
              ref.watch(relatedEntityProvider('${reminder.relatedEntityType}:${reminder.relatedEntityId}'));
          final isCompleted = reminder.status == 'completed';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  ReminderTypeIcon(type: reminder.type, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reminder.title, style: AppTypography.subheading),
                        const SizedBox(height: 2),
                        Text(relatedAsync.valueOrNull?.name ?? '…', style: AppTypography.caption),
                        const SizedBox(height: 2),
                        Text(reminder.dueDate, style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Type', value: reminder.title),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Due Date', value: reminder.dueDate),
                    if (_amountDueTypes.contains(reminder.type) && reminder.amountDue != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Amount Due', value: reminder.amountDue!),
                    ],
                    if (reminder.relatedCaseId != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Related Case',
                        value: 'View Case',
                        onTap: () => context.push('/cases/${reminder.relatedCaseId}'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Created By', value: 'User ${reminder.createdByUserId}'),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Created On', value: reminder.createdAt),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Notes', style: AppTypography.heading),
              const SizedBox(height: 12),
              AppCard(
                child: Text(
                  (reminder.notes?.trim().isNotEmpty ?? false) ? reminder.notes! : 'No notes added',
                  style: AppTypography.body,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/reminders/$reminderId/send'),
                child: const Text('Send Reminder'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isCompleted ? null : () => _complete(context, ref),
                child: const Text('Mark as Completed'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                onPressed: () => context.push('/reminders/$reminderId/edit'),
                child: const Text('Reschedule'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.body.copyWith(color: onTap != null ? AppColors.primary : AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
