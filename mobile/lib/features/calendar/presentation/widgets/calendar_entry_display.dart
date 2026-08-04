import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/calendar_entry.dart';

/// `follow_up` entries carry the real `FollowUpHistory.action_type` value
/// as their `label` (`deendoon/app/Http/Controllers/CalendarController.php`
/// — `self::FOLLOW_UP_TYPES = ['manual_whatsapp', 'manual_sms',
/// 'call_logged']`); this maps those exact three real values to a
/// friendly label, same pattern as Debt Detail's `_stageLabels`.
const _followUpLabels = {
  'manual_whatsapp': 'WhatsApp Follow-up',
  'manual_sms': 'SMS Follow-up',
  'call_logged': 'Call Logged',
};

/// One icon/color per real `CalendarEntry.type` aggregation bucket
/// (`due_date`, `promise_to_pay`, `follow_up`, `reminder`) — distinct from
/// `ReminderTypeIcon`, which is keyed by a `Reminder`'s own `type` field.
(IconData, Color) calendarEntryIconAndColor(String type) => switch (type) {
      'due_date' => (Icons.event_outlined, AppColors.danger),
      'promise_to_pay' => (Icons.handshake_outlined, AppColors.primary),
      'follow_up' => (Icons.call_outlined, AppColors.warning),
      'reminder' => (Icons.notifications_outlined, AppColors.info),
      _ => (Icons.circle_outlined, AppColors.textSecondary),
    };

/// A short, honest title for the agenda row. Never invents a customer or
/// debt name the backend didn't provide — `due_date` falls back to the
/// debt's reference number (the only label the backend sends), and
/// `promise_to_pay` has no label at all server-side.
String calendarEntryTitle(CalendarEntry entry) {
  switch (entry.type) {
    case 'due_date':
      return entry.label == null ? 'Debt Due' : 'Due: ${entry.label}';
    case 'promise_to_pay':
      return 'Promise to Pay';
    case 'follow_up':
      return _followUpLabels[entry.label] ?? entry.label ?? 'Follow-up';
    case 'reminder':
      return entry.label ?? 'Reminder';
    default:
      return entry.label ?? entry.type;
  }
}
