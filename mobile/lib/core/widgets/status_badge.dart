import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final (color, label) = switch (status) {
      // customer_status
      'active' => (context.colors.success, l10n.statusActive),
      'good_standing' => (context.colors.success, l10n.statusGoodStanding),
      'late_payer' => (context.colors.warning, l10n.statusLatePayer),
      'high_risk' => (context.colors.danger, l10n.statusHighRisk),
      'in_collection' => (context.colors.danger, l10n.statusInCollection),
      'recovered' => (context.colors.success, l10n.statusRecovered),
      'blocked' => (context.colors.textSecondary, l10n.statusBlocked),
      // debt_status
      'draft' => (context.colors.textSecondary, l10n.statusDraft),
      'pending' => (context.colors.info, l10n.statusPending),
      'overdue' => (context.colors.danger, l10n.statusOverdue),
      'partial_paid' => (context.colors.warning, l10n.statusPartiallyPaid),
      'paid' => (context.colors.success, l10n.statusPaid),
      'cancelled' => (context.colors.textSecondary, l10n.statusCancelled),
      'written_off' => (context.colors.textSecondary, l10n.statusWrittenOff),
      // case_status
      'open' => (context.colors.info, l10n.statusOpen),
      'closed' => (context.colors.textSecondary, l10n.statusClosed),
      // reminder status
      'today' => (context.colors.warning, l10n.statusToday),
      'upcoming' => (context.colors.info, l10n.statusUpcoming),
      'completed' => (context.colors.success, l10n.statusCompleted),
      // professional_collection_request status (submitted/under_review/
      // need_more_information/accepted/assigned/in_progress only —
      // recovered/closed are already mapped above and reused as-is)
      'submitted' => (context.colors.info, l10n.statusSubmitted),
      'under_review' => (context.colors.info, l10n.statusUnderReview),
      'need_more_information' => (context.colors.warning, l10n.statusNeedMoreInformation),
      'accepted' => (context.colors.info, l10n.statusAccepted),
      'assigned' => (context.colors.info, l10n.statusAssigned),
      'in_progress' => (context.colors.info, l10n.statusInProgress),
      // promise_to_pay status (open reuses case_status's mapping above)
      'fulfilled' => (context.colors.success, l10n.statusFulfilled),
      'broken' => (context.colors.danger, l10n.statusBroken),
      // subscription_status (active reuses customer_status's mapping above)
      'trialing' => (context.colors.info, l10n.statusTrial),
      'expired' => (context.colors.danger, l10n.statusExpired),
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
