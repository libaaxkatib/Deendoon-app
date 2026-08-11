import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_initial.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/customer.dart';

/// Premium customer card — avatar initial, name, phone, outstanding
/// amount, status pill, risk badge. Matches the case-card visual language
/// already approved for the Home Dashboard's Recent Cases (§6.1's "avatar
/// initial, customer name, outstanding amount, a status pill, a risk
/// badge"). No "company" field is shown — none exists on the Customer
/// model/resource.
///
/// An archived customer (`archived_at` set) cannot be opened — the
/// backend's `show`/`update` routes are not `->withTrashed()`, so Detail
/// would 404 — so this renders a muted "Archived" row with a Restore
/// button instead of the normal tap-to-detail card, and [onTap] is never
/// invoked for it.
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback? onRestore;

  const CustomerCard({super.key, required this.customer, required this.onTap, this.onRestore});

  @override
  Widget build(BuildContext context) {
    if (customer.isArchived) {
      return AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarInitial(name: customer.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: AppTypography.body.copyWith(color: context.colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(customer.phone, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: 8),
                  const _ArchivedBadge(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: onRestore, child: const Text('Restore')),
          ],
        ),
      );
    }

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarInitial(name: customer.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        customer.name,
                        style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (customer.isReadOnly) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_outline, size: 14, color: AppColors.warning),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone,
                  style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  customer.outstandingBalance,
                  style: AppTypography.subheading.copyWith(color: AppColors.primary, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: customer.customerStatus),
              const SizedBox(height: 6),
              RiskBadge(riskLevel: customer.riskLevel),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchivedBadge extends StatelessWidget {
  const _ArchivedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('Archived', style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
    );
  }
}
