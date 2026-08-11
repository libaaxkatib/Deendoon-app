import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../domain/aging_analysis.dart';
import '../providers/aging_analysis_provider.dart';
import '../providers/collection_analytics_provider.dart';
import '../providers/collections_trend_provider.dart';
import '../providers/date_range_providers.dart';
import '../providers/risk_distribution_provider.dart';
import '../widgets/date_range_field.dart';
import '../widgets/donut_chart.dart';
import '../widgets/kpi_card.dart';
import '../widgets/trend_line_chart.dart';

const _riskColors = <String, Color>{
  'high': AppColors.danger,
  'medium': AppColors.warning,
  'low': AppColors.success,
};

const _riskLabels = <String, String>{'high': 'High Risk', 'medium': 'Medium Risk', 'low': 'Low Risk'};

const _agingColors = <String, Color>{
  'current': AppColors.success,
  '1_30': AppColors.info,
  '31_60': AppColors.warning,
  '61_90': AppColors.accent,
  'over_90': AppColors.danger,
};

/// §5.1 Overview — the default Analytics tab: date range selector,
/// Collection Analytics (§5.4), Collections Trend (§5.3, compact), and
/// Aging Analysis (§5.5), in that order, exactly as the approved layout's
/// prose walkthrough describes.
///
/// Risk Distribution (§5.6) is placed here too, appended after Aging
/// Analysis: the approved board fully specifies it (API, chart, legend,
/// tap-through) as a component of the Analytics screen, but — unlike
/// §5.4/§5.5 — never states which of the three tabs hosts it. Reports is a
/// category list (no chart fits there) and Trends is time-series only, so
/// Overview is the only tab it fits thematically (a current-state
/// snapshot chart, same as Aging Analysis). Flagged here for correction if
/// a different placement was actually intended.
class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(overviewDateRangeProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        DateRangeField(
          value: range,
          onChanged: (next) => ref.read(overviewDateRangeProvider.notifier).state = next,
        ),
        const SizedBox(height: 28),
        const _SectionTitle('Collection Analytics'),
        const SizedBox(height: 14),
        _CollectionAnalyticsRow(range: range),
        const SizedBox(height: 28),
        const _SectionTitle('Collections Trend'),
        const SizedBox(height: 14),
        AppCard(child: _CollectionsTrendSection(range: range)),
        const SizedBox(height: 28),
        const _SectionTitle('Aging Analysis'),
        const SizedBox(height: 14),
        const AppCard(child: _AgingAnalysisSection()),
        const SizedBox(height: 28),
        const _SectionTitle('Risk Distribution'),
        const SizedBox(height: 14),
        const AppCard(child: _RiskDistributionSection()),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.heading.copyWith(fontSize: 18, color: context.colors.textPrimary),
    );
  }
}

class _CollectionAnalyticsRow extends ConsumerWidget {
  final DateTimeRange range;

  const _CollectionAnalyticsRow({required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(collectionAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: 'Could not load Collection Analytics.',
        onRetry: () => ref.invalidate(collectionAnalyticsProvider),
      ),
      data: (analytics) {
        final dateFrom = range.start.toIso8601String().split('T').first;
        final dateTo = range.end.toIso8601String().split('T').first;

        return Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Collection Rate',
                value: '${analytics.collectionRate.toStringAsFixed(1)}%',
                onTap: () => context.push('/analytics/collection-rate-detail'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'Total Collected',
                value: analytics.totalCollected,
                onTap: () => context.push('/analytics/reports/payments?dateFrom=$dateFrom&dateTo=$dateTo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'Average Days',
                value: analytics.averageDays?.toStringAsFixed(1) ?? '—',
                onTap: () => context.push('/analytics/average-days-detail'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CollectionsTrendSection extends ConsumerWidget {
  final DateTimeRange range;

  const _CollectionsTrendSection({required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(collectionsTrendProvider(range));

    return trendAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: 'Could not load Collections Trend.',
        onRetry: () => ref.invalidate(collectionsTrendProvider(range)),
      ),
      data: (trend) => TrendLineChart(series: trend.series),
    );
  }
}

class _AgingAnalysisSection extends ConsumerWidget {
  const _AgingAnalysisSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agingAsync = ref.watch(agingAnalysisProvider);

    return agingAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: 'Could not load Aging Analysis.',
        onRetry: () => ref.invalidate(agingAnalysisProvider),
      ),
      data: (aging) {
        final total = aging.buckets.values.fold<double>(
          0,
          (sum, b) => sum + (double.tryParse(b.totalRemainingBalance) ?? 0),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DonutChart(
              centerValue: total.toStringAsFixed(2),
              centerLabel: 'Total Outstanding',
              segments: [
                for (final key in agingBucketOrder)
                  DonutSegment(
                    label: agingBucketLabels[key]!,
                    value: double.tryParse(aging.buckets[key]?.totalRemainingBalance ?? '0') ?? 0,
                    color: _agingColors[key]!,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final key in agingBucketOrder)
                    _agingLegendRow(context, key, aging.buckets[key] ?? const AgingBucket(count: 0, totalRemainingBalance: '0.00'), total),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _agingLegendRow(BuildContext context, String key, AgingBucket bucket, double total) {
    final value = double.tryParse(bucket.totalRemainingBalance) ?? 0;
    final percentage = total > 0 ? (value / total) * 100 : 0.0;

    return DonutLegendRow(
      color: _agingColors[key]!,
      label: agingBucketLabels[key]!,
      value: '${bucket.count} debt${bucket.count == 1 ? '' : 's'} · ${bucket.totalRemainingBalance}',
      percentage: percentage,
      onTap: () => context.push('/analytics/reports/debts/aging/$key'),
    );
  }
}

class _RiskDistributionSection extends ConsumerWidget {
  const _RiskDistributionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskAsync = ref.watch(riskDistributionProvider);

    return riskAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: 'Could not load Risk Distribution.',
        onRetry: () => ref.invalidate(riskDistributionProvider),
      ),
      data: (distribution) {
        final totalCustomers = distribution.segments.fold<int>(0, (sum, s) => sum + s.customerCount);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DonutChart(
              centerValue: '$totalCustomers',
              centerLabel: 'Classified Customers',
              segments: [
                for (final segment in distribution.segments)
                  DonutSegment(
                    label: _riskLabels[segment.riskLevel] ?? segment.riskLevel,
                    value: segment.customerCount.toDouble(),
                    color: _riskColors[segment.riskLevel] ?? context.colors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final segment in distribution.segments)
                    DonutLegendRow(
                      color: _riskColors[segment.riskLevel] ?? context.colors.textSecondary,
                      label: _riskLabels[segment.riskLevel] ?? segment.riskLevel,
                      value: '${segment.customerCount} customer${segment.customerCount == 1 ? '' : 's'}',
                      percentage: segment.percentage,
                      onTap: () => context.push('/analytics/reports/customers?riskLevel=${segment.riskLevel}'),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
