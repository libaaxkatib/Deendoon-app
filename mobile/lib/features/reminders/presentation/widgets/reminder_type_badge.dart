import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Small type-label pill for the Reminder List cards (Deendoon V1 Reminder
/// Workflow Update — final polish). Distinct from `StatusBadge`: this
/// labels the reminder's `type` (client_visit/follow_up_call/payment_due/
/// contract_renewal/promise_to_pay), a different vocabulary than
/// `StatusBadge`'s status pills, so it isn't folded into that shared
/// widget. Colors mirror `ReminderTypeIcon`'s per-type color so the badge
/// and icon always agree.
class ReminderTypeBadge extends StatelessWidget {
  final String type;

  const ReminderTypeBadge({super.key, required this.type});

  static (Color, String) _colorAndLabel(
    BuildContext context,
    AppLocalizations l10n,
    String type,
  ) => switch (type) {
    'client_visit' => (AppColors.accent, l10n.reminderTypeBadgeVisit),
    'follow_up_call' => (AppColors.warning, l10n.reminderTypeBadgeFollowUp),
    'payment_due' => (AppColors.success, l10n.reminderTypeBadgePayment),
    'contract_renewal' => (AppColors.info, l10n.reminderTypeBadgeRenewal),
    'promise_to_pay' => (AppColors.primary, l10n.reminderTypeBadgePromise),
    _ => (context.colors.textSecondary, type.toUpperCase()),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, label) = _colorAndLabel(context, l10n, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
