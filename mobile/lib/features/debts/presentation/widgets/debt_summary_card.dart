import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/debt.dart';

/// Debt Summary + Collection Status — everything `GET /debts/{id}`
/// (`DebtResource`) actually returns, in one card.
class DebtSummaryCard extends StatelessWidget {
  final Debt debt;

  const DebtSummaryCard({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  style: AppTypography.subheading.copyWith(
                    color: context.colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: debt.debtStatus),
            ],
          ),
          Divider(height: 32, color: context.colors.background),
          _InfoRow(label: l10n.debtOriginalAmountLabel, value: debt.amount),
          const SizedBox(height: 12),
          _InfoRow(
            label: l10n.debtRemainingBalanceLabel,
            value: debt.remainingBalance,
          ),
          const SizedBox(height: 12),
          _InfoRow(label: l10n.addEditDebtDueDateHeading, value: debt.dueDate),
          if (overdueDays != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: l10n.debtSummaryDaysOverdueLabel,
              value: '$overdueDays',
              valueColor: AppColors.danger,
            ),
          ],
          if (debt.notes != null && debt.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.addEditDebtNotesHeading,
              style: AppTypography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              debt.notes!,
              style: AppTypography.body.copyWith(
                color: context.colors.textPrimary,
              ),
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
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: valueColor ?? AppColors.primary,
          ),
        ),
      ],
    );
  }
}
