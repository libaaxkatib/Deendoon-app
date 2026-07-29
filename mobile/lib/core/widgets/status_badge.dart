import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Generic status pill, shared across every module. Two real, distinct
/// status vocabularies feed it today:
/// - `customer_status` (`UpdateCustomerStatusRequest`): active,
///   good_standing, late_payer, high_risk, in_collection, recovered,
///   blocked.
/// - `debt_status` (the real Postgres CHECK constraint on
///   `debts.debt_status`): draft, pending, overdue, partial_paid, paid,
///   cancelled, written_off.
/// - `case_status` (the real Postgres CHECK constraint on
///   `collection_cases.case_status`): open, closed.
/// - Reminder `status` (never persisted — computed fresh on every read by
///   `SmartReminderEngine::status()`): today, upcoming, overdue,
///   completed. `overdue` already exists above (debt_status) and is
///   reused as-is — identical meaning, identical color.
/// No value collides across these, so one widget/mapping serves all
/// rather than duplicating an near-identical pill per module.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      // customer_status
      'active' => (AppColors.success, 'Active'),
      'good_standing' => (AppColors.success, 'Good Standing'),
      'late_payer' => (AppColors.warning, 'Late Payer'),
      'high_risk' => (AppColors.danger, 'High Risk'),
      'in_collection' => (AppColors.danger, 'In Collection'),
      'recovered' => (AppColors.success, 'Recovered'),
      'blocked' => (AppColors.textSecondary, 'Blocked'),
      // debt_status
      'draft' => (AppColors.textSecondary, 'Draft'),
      'pending' => (AppColors.info, 'Pending'),
      'overdue' => (AppColors.danger, 'Overdue'),
      'partial_paid' => (AppColors.warning, 'Partially Paid'),
      'paid' => (AppColors.success, 'Paid'),
      'cancelled' => (AppColors.textSecondary, 'Cancelled'),
      'written_off' => (AppColors.textSecondary, 'Written Off'),
      // case_status
      'open' => (AppColors.info, 'Open'),
      'closed' => (AppColors.textSecondary, 'Closed'),
      // reminder status
      'today' => (AppColors.warning, 'Today'),
      'upcoming' => (AppColors.info, 'Upcoming'),
      'completed' => (AppColors.success, 'Completed'),
      _ => (AppColors.textSecondary, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
