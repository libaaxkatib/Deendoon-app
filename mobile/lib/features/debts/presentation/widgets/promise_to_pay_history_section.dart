import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/debt_detail_providers.dart';

/// Promise to Pay History (mobile Item 11) — `GET /debts/{id}/promise-to-pay`
/// (`PromiseToPayController::index`), newest first.
class PromiseToPayHistorySection extends ConsumerWidget {
  final String debtId;

  const PromiseToPayHistorySection({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(debtPromiseToPayHistoryProvider(debtId));

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.promiseToPayHistoryLoadError,
        onRetry: () => ref.invalidate(debtPromiseToPayHistoryProvider(debtId)),
      ),
      data: (promises) {
        if (promises.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.promiseToPayHistoryEmptyState,
              style: AppTypography.body,
            ),
          );
        }

        return Column(
          children: [
            for (final promise in promises) ...[
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.promiseToPayHistoryPromisedLabel(
                              promise.promisedDate,
                            ),
                            style: AppTypography.body,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.promiseToPayHistoryRecordedLabel(
                              promise.createdAt.split('T').first,
                            ),
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: promise.status),
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
