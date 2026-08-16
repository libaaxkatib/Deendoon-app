import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/debt_detail_providers.dart';

/// Payment History — `GET /debts/{id}/payments`
/// (`PaymentController::index`), already ordered most-recent-first.
class DebtPaymentHistory extends ConsumerWidget {
  final String debtId;

  const DebtPaymentHistory({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final paymentsAsync = ref.watch(debtPaymentsProvider(debtId));

    return paymentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.debtPaymentHistoryLoadError,
        onRetry: () => ref.invalidate(debtPaymentsProvider(debtId)),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.debtPaymentHistoryEmptyState,
              style: AppTypography.body,
            ),
          );
        }

        return Column(
          children: [
            for (final payment in payments) ...[
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.amount,
                          style: AppTypography.body.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payment.paymentMethod ??
                              l10n.customerPaymentsMethodNotRecorded,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    Text(payment.paymentDate, style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}
