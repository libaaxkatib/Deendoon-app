import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerCard({super.key, required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  customer.name,
                  style: AppTypography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone,
                  style: AppTypography.caption,
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
