import 'package:flutter/material.dart';

import '../../../../core/models/payment.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// Reports > Payments row — new widget, since `Payment` had no standalone
/// list-card before this sprint (previously only shown inline within
/// Customer Details/Debt Details). Shows only what `PaymentResource`
/// actually returns: amount, date, method, debt id — no customer/debt
/// name (not present on this resource; resolving one would mean an N+1
/// lookup per row).
class PaymentReportCard extends StatelessWidget {
  final Payment payment;

  const PaymentReportCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.amount,
                  style: AppTypography.subheading.copyWith(color: AppColors.primary, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.paymentMethod ?? 'Method not recorded',
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
              Text(payment.paymentDate, style: AppTypography.caption),
              const SizedBox(height: 2),
              Text('Debt #${payment.debtId}', style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}
