import 'package:flutter/material.dart';

import '../../../../core/theme/deendoon_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Support Ticket `priority` — a genuinely new concept (no existing badge
/// in the app covers it), so kept local to this feature rather than
/// folded into the shared `StatusBadge` (which maps `status` vocabularies,
/// not priority).
class TicketPriorityBadge extends StatelessWidget {
  final String priority;

  const TicketPriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, label) = switch (priority) {
      'low' => (context.colors.textSecondary, l10n.supportTicketPriorityLow),
      'medium' => (context.colors.info, l10n.supportTicketPriorityMedium),
      'high' => (context.colors.warning, l10n.supportTicketPriorityHigh),
      'urgent' => (context.colors.danger, l10n.supportTicketPriorityUrgent),
      _ => (context.colors.textSecondary, priority),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String ticketCategoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'technical_issue' => l10n.supportTicketCategoryTechnicalIssue,
      'payment_billing' => l10n.supportTicketCategoryPaymentBilling,
      'account' => l10n.supportTicketCategoryAccount,
      'subscription' => l10n.supportTicketCategorySubscription,
      'debt_recovery' => l10n.supportTicketCategoryDebtRecovery,
      'professional_collection' =>
        l10n.supportTicketCategoryProfessionalCollection,
      'feature_request' => l10n.supportTicketCategoryFeatureRequest,
      'other' => l10n.supportTicketCategoryOther,
      _ => category,
    };
