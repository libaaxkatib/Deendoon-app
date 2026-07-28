import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/debt.dart';

/// Premium debt card for the Debt List — reference number, original
/// amount, remaining balance, due date, days overdue (real client-side
/// date arithmetic on `due_date`/`debt_status`, not fabricated data),
/// collection status, and risk level (passed in from the already-fetched
/// parent Customer — no `risk_level` exists on `DebtResource` itself).
class DebtCard extends StatelessWidget {
  final Debt debt;
  final String? riskLevel;
  final VoidCallback onTap;

  const DebtCard({super.key, required this.debt, required this.riskLevel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdueDays = debt.daysOverdue();

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  debt.referenceNumber,
                  style: AppTypography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(status: debt.debtStatus),
                  const SizedBox(width: 6),
                  RiskBadge(riskLevel: riskLevel),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _AmountColumn(label: 'Original Amount', value: debt.amount)),
              const SizedBox(width: 8),
              Expanded(child: _AmountColumn(label: 'Remaining Balance', value: debt.remainingBalance)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Due ${debt.dueDate}',
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (overdueDays != null)
                Text(
                  '$overdueDays day${overdueDays == 1 ? '' : 's'} overdue',
                  style: AppTypography.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final String value;

  const _AmountColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.subheading.copyWith(color: AppColors.primary, fontSize: 16)),
      ],
    );
  }
}
