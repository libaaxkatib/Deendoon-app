import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_initial.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/debt.dart';

/// Premium debt card for the Debt List — reference number, original
/// amount, remaining balance, due date, days overdue (real client-side
/// date arithmetic on `due_date`/`debt_status`, not fabricated data),
/// collection status, and risk level (passed in from the already-fetched
/// parent Customer — no `risk_level` exists on `DebtResource` itself).
///
/// An archived debt (`archived_at` set) renders a muted "Archived" row
/// with a Restore button instead of the normal tap-to-detail card — same
/// convention as `CustomerCard`, so [onTap] is never invoked for it.
class DebtCard extends StatelessWidget {
  final Debt debt;
  final String? riskLevel;
  final VoidCallback onTap;
  final VoidCallback? onRestore;

  const DebtCard({
    super.key,
    required this.debt,
    required this.riskLevel,
    required this.onTap,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overdueDays = debt.daysOverdue();

    if (debt.isArchived) {
      return AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarInitial(name: debt.referenceNumber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.referenceNumber,
                    style: AppTypography.body.copyWith(
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.debtRemainingBalanceLabel,
                    style: AppTypography.caption.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ArchivedBadge(label: l10n.debtCardArchivedBadge),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onRestore,
              child: Text(l10n.debtCardRestoreButton),
            ),
          ],
        ),
      );
    }

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
              Expanded(
                child: _AmountColumn(
                  label: l10n.debtOriginalAmountLabel,
                  value: debt.amount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountColumn(
                  label: l10n.debtRemainingBalanceLabel,
                  value: debt.remainingBalance,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.debtCardDueDateLabel(debt.dueDate),
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (overdueDays != null)
                Text(
                  l10n.debtCardOverdueDays(overdueDays),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
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
        Text(
          value,
          style: AppTypography.subheading.copyWith(
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ArchivedBadge extends StatelessWidget {
  final String label;

  const _ArchivedBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
