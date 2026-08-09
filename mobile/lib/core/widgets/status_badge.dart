import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Generic status pill, shared across every module. Real, distinct status
/// vocabularies feed it today:
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
/// - Professional Collection Request `status` (the real Postgres CHECK
///   constraint on `professional_collection_requests.status`): submitted,
///   under_review, need_more_information, accepted, assigned,
///   in_progress, recovered, closed. `recovered`/`closed` already exist
///   above (customer_status/case_status) and are reused as-is — same
///   meaning (successful outcome / terminal-neutral), same color. Of the
///   6 new values, only `need_more_information` is the one status where
///   the Business Owner has an actionable item (respond via Messages), so
///   it alone gets `warning`; the other 5 are neutral in-progress states
///   and get `info`, matching how `pending`/`upcoming` are colored above.
/// - Promise to Pay `status` (`promises_to_pay.status`, the real Postgres
///   CHECK constraint): open, fulfilled, broken. `open` already exists
///   above (case_status) and is reused as-is; `fulfilled` gets `success`
///   (matching `paid`/`recovered`'s "good outcome" tone), `broken` gets
///   `danger` (matching `overdue`'s "needs attention now" tone).
/// - Subscription `subscription_status` (`tenant_subscriptions.status`):
///   trialing, active, expired. `active` already exists above
///   (customer_status) and is reused as-is. `trialing` gets `info`
///   (matching `pending`/`upcoming`'s "in progress, nothing wrong" tone);
///   `expired` gets `danger` (matching `overdue`'s "needs attention now").
/// No value collides across these with a different meaning, so one
/// widget/mapping serves all rather than duplicating a near-identical
/// pill per module.
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
      // professional_collection_request status (submitted/under_review/
      // need_more_information/accepted/assigned/in_progress only —
      // recovered/closed are already mapped above and reused as-is)
      'submitted' => (AppColors.info, 'Submitted'),
      'under_review' => (AppColors.info, 'Under Review'),
      'need_more_information' => (AppColors.warning, 'Need More Information'),
      'accepted' => (AppColors.info, 'Accepted'),
      'assigned' => (AppColors.info, 'Assigned'),
      'in_progress' => (AppColors.info, 'In Progress'),
      // promise_to_pay status (open reuses case_status's mapping above)
      'fulfilled' => (AppColors.success, 'Fulfilled'),
      'broken' => (AppColors.danger, 'Broken'),
      // subscription_status (active reuses customer_status's mapping above)
      'trialing' => (AppColors.info, 'Trial'),
      'expired' => (AppColors.danger, 'Expired'),
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
