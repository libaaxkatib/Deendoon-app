import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/customer_detail_providers.dart';

/// Recent Payments — `GET /customers/{id}/payments`, already ordered
/// most-recent-first by the backend; shown truncated to a small preview
/// count here (display-only truncation of real, correctly-ordered data,
/// not a fabricated "recent" calculation).
class CustomerRecentPayments extends ConsumerWidget {
  final String customerId;

  static const _previewCount = 5;

  const CustomerRecentPayments({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final paymentsAsync = ref.watch(customerPaymentsProvider(customerId));

    return paymentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.customerPaymentsLoadError,
        onRetry: () => ref.invalidate(customerPaymentsProvider(customerId)),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.customerPaymentsEmptyState, style: AppTypography.body),
          );
        }

        final preview = payments.take(_previewCount).toList();
        return Column(
          children: [
            for (final payment in preview) ...[
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment.amount, style: AppTypography.body.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text(payment.paymentMethod ?? l10n.customerPaymentsMethodNotRecorded, style: AppTypography.caption),
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
