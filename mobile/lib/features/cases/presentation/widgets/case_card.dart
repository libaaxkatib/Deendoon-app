import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_initial.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/collection_case.dart';

/// Premium case card for the Case List — customer name, outstanding
/// amount, risk level, last activity, status badge, and an assigned
/// indicator (id-only — no officer name is resolvable, see the Sprint 13
/// summary). Follow-up Status and Promise Due are only ever shown when
/// `activeTab` already guarantees them true for every row (the `tab`
/// query param that produced this list) — the resource doesn't embed a
/// per-case boolean for either, and computing one per row would mean an
/// N+1 lookup per card, so no such badge is shown outside of those two
/// filtered views.
class CaseCard extends StatelessWidget {
  final CollectionCase collectionCase;
  final String? activeTab;
  final VoidCallback onTap;

  const CaseCard({super.key, required this.collectionCase, required this.activeTab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final assigned = collectionCase.assignedOfficerUserId != null;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarInitial(name: collectionCase.customerName ?? '?'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collectionCase.customerName ?? 'Unknown customer',
                      style: AppTypography.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      collectionCase.referenceNumber,
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: collectionCase.caseStatus),
                  const SizedBox(height: 6),
                  RiskBadge(riskLevel: collectionCase.riskLevel),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Outstanding', style: AppTypography.caption),
              Text(
                collectionCase.outstandingAmount ?? '—',
                style: AppTypography.subheading.copyWith(color: AppColors.primary, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                assigned ? Icons.person : Icons.person_outline,
                size: 16,
                color: assigned ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(assigned ? 'Assigned' : 'Unassigned', style: AppTypography.caption),
              if (activeTab == 'follow_up') ...[
                const SizedBox(width: 10),
                _Tag(label: 'Follow Up', color: AppColors.warning),
              ],
              if (activeTab == 'promise_due') ...[
                const SizedBox(width: 10),
                _Tag(label: 'Promise Due', color: AppColors.accent),
              ],
              Expanded(
                child: Text(
                  collectionCase.lastActivityAt,
                  textAlign: TextAlign.end,
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
