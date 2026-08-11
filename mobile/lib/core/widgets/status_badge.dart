import 'package:flutter/material.dart';

import '../theme/deendoon_colors.dart';

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
      'active' => (context.colors.success, 'Active'),
      'good_standing' => (context.colors.success, 'Good Standing'),
      'late_payer' => (context.colors.warning, 'Late Payer'),
      'high_risk' => (context.colors.danger, 'High Risk'),
      'in_collection' => (context.colors.danger, 'In Collection'),
      'recovered' => (context.colors.success, 'Recovered'),
      'blocked' => (context.colors.textSecondary, 'Blocked'),
      // debt_status
      'draft' => (context.colors.textSecondary, 'Draft'),
      'pending' => (context.colors.info, 'Pending'),
      'overdue' => (context.colors.danger, 'Overdue'),
      'partial_paid' => (context.colors.warning, 'Partially Paid'),
      'paid' => (context.colors.success, 'Paid'),
      'cancelled' => (context.colors.textSecondary, 'Cancelled'),
      'written_off' => (context.colors.textSecondary, 'Written Off'),
      // case_status
      'open' => (context.colors.info, 'Open'),
      'closed' => (context.colors.textSecondary, 'Closed'),
      // reminder status
      'today' => (context.colors.warning, 'Today'),
      'upcoming' => (context.colors.info, 'Upcoming'),
      'completed' => (context.colors.success, 'Completed'),
      // professional_collection_request status (submitted/under_review/
      // need_more_information/accepted/assigned/in_progress only —
      // recovered/closed are already mapped above and reused as-is)
      'submitted' => (context.colors.info, 'Submitted'),
      'under_review' => (context.colors.info, 'Under Review'),
      'need_more_information' => (context.colors.warning, 'Need More Information'),
      'accepted' => (context.colors.info, 'Accepted'),
      'assigned' => (context.colors.info, 'Assigned'),
      'in_progress' => (context.colors.info, 'In Progress'),
      // promise_to_pay status (open reuses case_status's mapping above)
      'fulfilled' => (context.colors.success, 'Fulfilled'),
      'broken' => (context.colors.danger, 'Broken'),
      // subscription_status (active reuses customer_status's mapping above)
      'trialing' => (context.colors.info, 'Trial'),
      'expired' => (context.colors.danger, 'Expired'),
      _ => (context.colors.textSecondary, status),
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
