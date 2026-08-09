import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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

  static (Color, String) _colorAndLabel(String type) => switch (type) {
        'client_visit' => (AppColors.accent, 'VISIT'),
        'follow_up_call' => (AppColors.warning, 'FOLLOW-UP'),
        'payment_due' => (AppColors.success, 'PAYMENT'),
        'contract_renewal' => (AppColors.info, 'RENEWAL'),
        'promise_to_pay' => (AppColors.primary, 'PROMISE'),
        _ => (AppColors.textSecondary, type.toUpperCase()),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _colorAndLabel(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }
}
