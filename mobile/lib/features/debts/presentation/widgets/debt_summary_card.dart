import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/debt.dart';

/// Debt Summary + Collection Status — everything `GET /debts/{id}`
/// (`DebtResource`) actually returns, in one card.
class DebtSummaryCard extends StatelessWidget {
  final Debt debt;

  const DebtSummaryCard({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    final overdueDays = debt.daysOverdue();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  debt.referenceNumber,
                  style: AppTypography.subheading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: debt.debtStatus),
            ],
          ),
          const Divider(height: 32, color: AppColors.background),
          _InfoRow(label: 'Original Amount', value: debt.amount),
          const SizedBox(height: 12),
          _InfoRow(label: 'Remaining Balance', value: debt.remainingBalance),
          const SizedBox(height: 12),
          _InfoRow(label: 'Due Date', value: debt.dueDate),
          if (overdueDays != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Days Overdue',
              value: '$overdueDays',
              valueColor: AppColors.danger,
            ),
          ],
          if (debt.notes != null && debt.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Notes', style: AppTypography.caption),
            const SizedBox(height: 4),
            Text(debt.notes!, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption),
        Text(value, style: AppTypography.body.copyWith(color: valueColor ?? AppColors.primary)),
      ],
    );
  }
}
