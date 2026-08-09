import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../debts/presentation/widgets/debt_card.dart';
import '../providers/average_days_debts_provider.dart';
import '../providers/collection_analytics_provider.dart';
import '../providers/date_range_providers.dart';

/// Average Days detail view (mobile Item 10) — reached from the Overview
/// tab's Average Days KPI card. `average_days` (already fetched by
/// `collectionAnalyticsProvider`, same provider the Overview KPI row
/// itself uses — no duplicate fetch) is the mean days between a debt's
/// due date and the date it was fully paid; this screen shows the actual
/// debts behind that average via `averageDaysDebtsProvider`, backed by
/// the real `GET /reports/debts?paidDateFrom=&paidDateTo=` filter —
/// `ReportingService::debtsPaidWithin()`, the exact same population the
/// backend calculation itself uses.
class AverageDaysDetailScreen extends ConsumerWidget {
  const AverageDaysDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(collectionAnalyticsProvider);
    final range = ref.watch(overviewDateRangeProvider);
    final debtsAsync = ref.watch(averageDaysDebtsProvider(range));

    return Scaffold(
      appBar: AppBar(title: const Text('Average Days')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(collectionAnalyticsProvider);
          ref.invalidate(averageDaysDebtsProvider(range));
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
                message: 'Could not load Collection Analytics.',
                onRetry: () => ref.invalidate(collectionAnalyticsProvider),
              ),
              data: (analytics) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analytics.averageDays?.toStringAsFixed(1) ?? '—',
                        style: AppTypography.heading.copyWith(fontSize: 32, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    const Text(
                      'Mean days between a debt\'s due date and the date it was fully paid, '
                      'for debts paid within this period.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Debts Paid in This Period', style: AppTypography.heading),
            const SizedBox(height: 12),
            debtsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => RetrySection(
                message: 'Could not load debts.',
                onRetry: () => ref.invalidate(averageDaysDebtsProvider(range)),
              ),
              data: (debts) {
                if (debts.isEmpty) {
                  return const Text('No debts were paid off within this period.', style: AppTypography.body);
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
