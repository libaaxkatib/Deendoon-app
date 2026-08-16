import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/calendar_entry.dart';

/// `follow_up` entries carry the real `FollowUpHistory.action_type` value
/// as their `label` (`deendoon/app/Http/Controllers/CalendarController.php`
/// — `self::FOLLOW_UP_TYPES = ['manual_whatsapp', 'manual_sms',
/// 'call_logged']`); this maps those exact three real values to a
/// friendly label, same pattern as Debt Detail's `_stageLabels`.
Map<String, String> _followUpLabels(AppLocalizations l10n) => {
  'manual_whatsapp': l10n.calendarFollowUpWhatsApp,
  'manual_sms': l10n.calendarFollowUpSms,
  'call_logged': l10n.calendarFollowUpCallLogged,
};

/// One icon/color per real `CalendarEntry.type` aggregation bucket
/// (`due_date`, `promise_to_pay`, `follow_up`, `reminder`) — distinct from
/// `ReminderTypeIcon`, which is keyed by a `Reminder`'s own `type` field.
(IconData, Color) calendarEntryIconAndColor(
  BuildContext context,
  String type,
) => switch (type) {
  'due_date' => (Icons.event_outlined, AppColors.danger),
  'promise_to_pay' => (Icons.handshake_outlined, AppColors.primary),
  'follow_up' => (Icons.call_outlined, AppColors.warning),
  'reminder' => (Icons.notifications_outlined, AppColors.info),
  _ => (Icons.circle_outlined, context.colors.textSecondary),
};

/// A short, honest title for the agenda row. Never invents a customer or
/// debt name the backend didn't provide — `due_date` falls back to the
/// debt's reference number (the only label the backend sends), and
/// `promise_to_pay` has no label at all server-side.
String calendarEntryTitle(BuildContext context, CalendarEntry entry) {
  final l10n = AppLocalizations.of(context);
  switch (entry.type) {
    case 'due_date':
      return entry.label == null
          ? l10n.calendarEntryTitleDebtDue
          : l10n.calendarEntryTitleDue(entry.label!);
    case 'promise_to_pay':
      return l10n.promiseToPayTitle;
    case 'follow_up':
      return _followUpLabels(l10n)[entry.label] ??
          entry.label ??
          l10n.calendarEntryTitleFollowUpFallback;
    case 'reminder':
      return entry.label ?? l10n.calendarEntryTitleReminderFallback;
    default:
      return entry.label ?? entry.type;
  }
}
