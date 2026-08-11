import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/collection_case.dart';

/// Case Summary + Assigned Officer — everything `GET
/// /collection-cases/{id}` (`CollectionCaseResource`) actually returns,
/// in one card. `assignedOfficerUserId` is shown as a raw id, never a
/// fabricated name — no endpoint reachable by this app's roles resolves
/// an officer id to a display name (see the Sprint 13 summary).
class CaseSummaryCard extends StatelessWidget {
  final CollectionCase collectionCase;

  const CaseSummaryCard({super.key, required this.collectionCase});

  @override
  Widget build(BuildContext context) {
    final officerId = collectionCase.assignedOfficerUserId;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  collectionCase.referenceNumber,
                  style: AppTypography.subheading.copyWith(color: context.colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: collectionCase.caseStatus),
            ],
          ),
          Divider(height: 32, color: context.colors.background),
          _InfoRow(label: 'Outstanding Amount', value: collectionCase.outstandingAmount ?? '—'),
          const SizedBox(height: 12),
          _InfoRow(label: 'Assigned Officer', value: officerId == null ? 'Unassigned' : 'Officer $officerId'),
          const SizedBox(height: 12),
          _InfoRow(label: 'Last Activity', value: collectionCase.lastActivityAt),
          if (collectionCase.closureOutcome != null) ...[
            const SizedBox(height: 12),
            _InfoRow(label: 'Closure Outcome', value: collectionCase.closureOutcome!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.body.copyWith(color: AppColors.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
