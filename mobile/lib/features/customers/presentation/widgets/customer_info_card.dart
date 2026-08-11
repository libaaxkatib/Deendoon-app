import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_initial.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/customer.dart';

/// Customer Information + Contact Details + Outstanding Balance + Credit
/// Limit + Risk Level — everything `GET /customers/{id}` (`CustomerResource`)
/// actually returns, in one card. [onEditCreditLimit]/[onEditStatus] are
/// optional so this card can still be reused read-only elsewhere (e.g.
/// `CaseDetailScreen`'s Customer Summary).
class CustomerInfoCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onEditCreditLimit;
  final VoidCallback? onEditStatus;

  const CustomerInfoCard({super.key, required this.customer, this.onEditCreditLimit, this.onEditStatus});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarInitial(name: customer.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AppTypography.subheading.copyWith(color: context.colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(customer.phone, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
                    if (customer.address != null && customer.address!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.address!,
                        style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      StatusBadge(status: customer.customerStatus),
                      if (onEditStatus != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          tooltip: 'Change Customer Status',
                          onPressed: onEditStatus,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.only(left: 6),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RiskBadge(riskLevel: customer.riskLevel),
                ],
              ),
            ],
          ),
          Divider(height: 32, color: context.colors.background),
          _InfoRow(label: 'Outstanding Balance', value: customer.outstandingBalance),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _InfoRow(label: 'Credit Limit', value: customer.creditLimit)),
              if (onEditCreditLimit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Credit Limit',
                  onPressed: onEditCreditLimit,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Remaining Credit', value: customer.remainingCredit),
          if (customer.creditScore != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Credit Score',
              value: '${customer.creditScore}${customer.creditScoreBand != null ? ' (${customer.creditScoreBand})' : ''}',
            ),
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
        Text(value, style: AppTypography.body.copyWith(color: AppColors.primary)),
      ],
    );
  }
}
