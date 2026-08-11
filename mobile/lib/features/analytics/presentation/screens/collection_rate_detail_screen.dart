import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../debts/presentation/widgets/debt_card.dart';
import '../providers/collection_analytics_provider.dart';
import '../providers/collection_rate_debts_provider.dart';
import '../providers/date_range_providers.dart';

/// Collection Rate detail view (mobile Item 9) — reached from the
/// Overview tab's Collection Rate KPI card. Breaks the real formula
/// (`CollectionRateService::rateFor()`) into its two real components:
/// Total Collected (already fetched by `collectionAnalyticsProvider`,
/// same provider the Overview KPI row itself uses — no duplicate fetch)
/// and the actual list of debts that became due in the selected period
/// (`collectionRateDebtsProvider`, backed by the real
/// `GET /reports/debts?dateFrom=&dateTo=` due-date filter).
class CollectionRateDetailScreen extends ConsumerWidget {
  const CollectionRateDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final analyticsAsync = ref.watch(collectionAnalyticsProvider);
    final range = ref.watch(overviewDateRangeProvider);
    final debtsAsync = ref.watch(collectionRateDebtsProvider(range));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.overviewKpiCollectionRate)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(collectionAnalyticsProvider);
          ref.invalidate(collectionRateDebtsProvider(range));
          await ref.read(collectionAnalyticsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            analyticsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => RetrySection(
                message: l10n.overviewCollectionAnalyticsLoadError,
                onRetry: () => ref.invalidate(collectionAnalyticsProvider),
              ),
              data: (analytics) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${analytics.collectionRate.toStringAsFixed(1)}%',
                        style: AppTypography.heading.copyWith(fontSize: 32, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(l10n.collectionRateDetailFormulaCaption, style: AppTypography.caption),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.overviewKpiTotalCollected, style: AppTypography.body),
                        Text(analytics.totalCollected, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.collectionRateDetailDebtsHeading, style: AppTypography.heading),
            const SizedBox(height: 12),
            debtsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => RetrySection(
                message: l10n.debtListLoadError,
                onRetry: () => ref.invalidate(collectionRateDebtsProvider(range)),
              ),
              data: (debts) {
                if (debts.isEmpty) {
                  return Text(l10n.collectionRateDetailEmptyState, style: AppTypography.body);
                }
                return Column(
                  children: [
                    for (final debt in debts) ...[
                      DebtCard(debt: debt, riskLevel: null, onTap: () => context.push('/debts/${debt.id}')),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
