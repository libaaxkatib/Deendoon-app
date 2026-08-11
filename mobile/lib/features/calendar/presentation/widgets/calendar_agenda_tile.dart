import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/calendar_entry.dart';
import 'calendar_entry_display.dart';

/// One agenda row for the selected day — icon, title, related entity type.
/// Only navigates through when the controller's own mapping actually
/// exposes a usable id: `due_date`/`follow_up` entries carry the debt's id
/// (`/debts/:id` already exists), `reminder` entries carry the reminder's
/// id (`/reminders/:id` already exists). `promise_to_pay` entries carry
/// only the Promise to Pay record's own id, which has no detail screen —
/// left non-interactive rather than guessing a destination.
class CalendarAgendaTile extends StatelessWidget {
  final CalendarEntry entry;

  const CalendarAgendaTile({super.key, required this.entry});

  String? get _destination => switch (entry.relatedEntityType) {
        'debt' => '/debts/${entry.relatedEntityId}',
        'reminder' => '/reminders/${entry.relatedEntityId}',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = calendarEntryIconAndColor(context, entry.type);
    final destination = _destination;

    return AppCard(
      onTap: destination == null ? null : () => context.push(destination),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calendarEntryTitle(context, entry),
                  style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                ),
                Text(entry.relatedEntityType, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
          if (destination != null) Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}
