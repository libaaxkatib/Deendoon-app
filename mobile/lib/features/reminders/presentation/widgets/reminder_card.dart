import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/reminder.dart';
import '../providers/related_entity_provider.dart';
import 'reminder_type_badge.dart';
import 'reminder_type_icon.dart';

/// Reminder List card (§7.3): type icon, title, related customer/entity
/// name, a due label, and an inline "Complete" action — only shown when
/// the reminder isn't already completed, matching §7.3's validation rule
/// ("Complete is unavailable on an already-completed reminder"). The
/// approved layout also mentions "Call" and "Send Reminder" as possible
/// inline actions; both are deliberately not offered per-row here (would
/// require an extra related-entity/phone lookup per row — an N+1 the List
/// avoids, same call made for Collection Stage on the Case List in
/// Sprint 13) — both remain available from Reminder Details, one tap away.
class ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const ReminderCard({super.key, required this.reminder, required this.onTap, required this.onComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedEntityProvider('${reminder.relatedEntityType}:${reminder.relatedEntityId}'));
    final isCompleted = reminder.status == 'completed';

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReminderTypeIcon(type: reminder.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title, style: AppTypography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ReminderTypeBadge(type: reminder.type),
                const SizedBox(height: 4),
                Text(
                  relatedAsync.valueOrNull?.name ?? '…',
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  formatFriendlyDateTimeFromIso(reminder.dueDate),
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: reminder.status),
              if (!isCompleted) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: onComplete,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Complete', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
