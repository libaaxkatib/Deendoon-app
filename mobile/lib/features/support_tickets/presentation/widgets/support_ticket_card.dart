import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/support_ticket.dart';
import 'ticket_priority_badge.dart';

class SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const SupportTicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.referenceNumber ?? ticket.id,
                  style: AppTypography.caption,
                ),
              ),
              StatusBadge(status: ticket.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ticket.subject,
            style: AppTypography.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TicketPriorityBadge(priority: ticket.priority),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticketCategoryLabel(l10n, ticket.category),
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
