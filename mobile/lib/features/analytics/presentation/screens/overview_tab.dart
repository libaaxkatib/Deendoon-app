import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

Map<String, String> _riskLabels(AppLocalizations l10n) => {
  'high': l10n.overviewRiskLabelHigh,
  'medium': l10n.overviewRiskLabelMedium,
  'low': l10n.overviewRiskLabelLow,
};

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
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(overviewDateRangeProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        DateRangeField(
          value: range,
          onChanged: (next) =>
              ref.read(overviewDateRangeProvider.notifier).state = next,
        ),
        const SizedBox(height: 28),
        _SectionTitle(l10n.overviewSectionCollectionAnalytics),
        const SizedBox(height: 14),
        _CollectionAnalyticsRow(range: range),
        const SizedBox(height: 28),
        _SectionTitle(l10n.overviewSectionCollectionsTrend),
        const SizedBox(height: 14),
        AppCard(child: _CollectionsTrendSection(range: range)),
        const SizedBox(height: 28),
        _SectionTitle(l10n.overviewSectionAgingAnalysis),
        const SizedBox(height: 14),
        const AppCard(child: _AgingAnalysisSection()),
        const SizedBox(height: 28),
        _SectionTitle(l10n.overviewSectionRiskDistribution),
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
      style: AppTypography.heading.copyWith(
        fontSize: 18,
        color: context.colors.textPrimary,
      ),
    );
  }
}

class _CollectionAnalyticsRow extends ConsumerWidget {
  final DateTimeRange range;

  const _CollectionAnalyticsRow({required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final analyticsAsync = ref.watch(collectionAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.overviewCollectionAnalyticsLoadError,
        onRetry: () => ref.invalidate(collectionAnalyticsProvider),
      ),
      data: (analytics) {
        final dateFrom = range.start.toIso8601String().split('T').first;
        final dateTo = range.end.toIso8601String().split('T').first;

        return Row(
          children: [
            Expanded(
              child: KpiCard(
                label: l10n.overviewKpiCollectionRate,
                value: '${analytics.collectionRate.toStringAsFixed(1)}%',
                onTap: () => context.push('/analytics/collection-rate-detail'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: l10n.overviewKpiTotalCollected,
                value: analytics.totalCollected,
                onTap: () => context.push(
                  '/analytics/reports/payments?dateFrom=$dateFrom&dateTo=$dateTo',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: l10n.overviewKpiAverageDays,
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
    final l10n = AppLocalizations.of(context);
    final trendAsync = ref.watch(collectionsTrendProvider(range));

    return trendAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.overviewCollectionsTrendLoadError,
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
    final l10n = AppLocalizations.of(context);
    final agingAsync = ref.watch(agingAnalysisProvider);
    final labels = agingBucketLabels(l10n);

    return agingAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.overviewAgingAnalysisLoadError,
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
              centerLabel: l10n.overviewDonutTotalOutstanding,
              segments: [
                for (final key in agingBucketOrder)
                  DonutSegment(
                    label: labels[key]!,
                    value:
                        double.tryParse(
                          aging.buckets[key]?.totalRemainingBalance ?? '0',
                        ) ??
                        0,
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
                    _agingLegendRow(
                      context,
                      l10n,
                      key,
                      aging.buckets[key] ??
                          const AgingBucket(
                            count: 0,
                            totalRemainingBalance: '0.00',
                          ),
                      total,
                      labels,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _agingLegendRow(
    BuildContext context,
    AppLocalizations l10n,
    String key,
    AgingBucket bucket,
    double total,
    Map<String, String> labels,
  ) {
    final value = double.tryParse(bucket.totalRemainingBalance) ?? 0;
    final percentage = total > 0 ? (value / total) * 100 : 0.0;

    return DonutLegendRow(
      color: _agingColors[key]!,
      label: labels[key]!,
      value: l10n.overviewAgingLegendValue(
        bucket.count,
        bucket.totalRemainingBalance,
      ),
      percentage: percentage,
      onTap: () => context.push('/analytics/reports/debts/aging/$key'),
    );
  }
}

class _RiskDistributionSection extends ConsumerWidget {
  const _RiskDistributionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final riskAsync = ref.watch(riskDistributionProvider);
    final riskLabels = _riskLabels(l10n);

    return riskAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.overviewRiskDistributionLoadError,
        onRetry: () => ref.invalidate(riskDistributionProvider),
      ),
      data: (distribution) {
        final totalCustomers = distribution.segments.fold<int>(
          0,
          (sum, s) => sum + s.customerCount,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DonutChart(
              centerValue: '$totalCustomers',
              centerLabel: l10n.overviewDonutClassifiedCustomers,
              segments: [
                for (final segment in distribution.segments)
                  DonutSegment(
                    label: riskLabels[segment.riskLevel] ?? segment.riskLevel,
                    value: segment.customerCount.toDouble(),
                    color:
                        _riskColors[segment.riskLevel] ??
                        context.colors.textSecondary,
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
                      color:
                          _riskColors[segment.riskLevel] ??
                          context.colors.textSecondary,
                      label: riskLabels[segment.riskLevel] ?? segment.riskLevel,
                      value: l10n.overviewRiskLegendValue(
                        segment.customerCount,
                      ),
                      percentage: segment.percentage,
                      onTap: () => context.push(
                        '/analytics/reports/customers?riskLevel=${segment.riskLevel}',
                      ),
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
