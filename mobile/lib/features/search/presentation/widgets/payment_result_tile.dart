import 'package:flutter/material.dart';

import '../../../../core/models/payment.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// Global Search has no dedicated Payment list/detail screen to mirror
/// (payments are always shown embedded within a Debt elsewhere in this
/// app) — this is a small, honest result row: amount, date, method, and
/// the matched `reference_notes` field itself, since that's what the
/// backend actually searched.
class PaymentResultTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;

  const PaymentResultTile({
    super.key,
    required this.payment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.amount,
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.paymentMethod ?? payment.paymentDate,
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(payment.paymentDate, style: AppTypography.caption),
        ],
      ),
    );
  }
}
