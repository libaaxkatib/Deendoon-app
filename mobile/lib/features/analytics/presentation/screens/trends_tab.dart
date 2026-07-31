import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/collections_trend_provider.dart';
import '../providers/date_range_providers.dart';
import '../widgets/date_range_field.dart';
import '../widgets/trend_line_chart.dart';

/// §5.3 Trends — its own extended-range date selector (independent of the
/// Overview's), and the same `collected_amount` chart at full size. Only
/// the one backend-supported metric is shown — no metric switcher, per
/// explicit product decision this sprint ("Do NOT build a metric
/// switcher... until the backend supports them").
class TrendsTab extends ConsumerWidget {
  const TrendsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(trendsDateRangeProvider);
    final trendAsync = ref.watch(collectionsTrendProvider(range));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        DateRangeField(
          value: range,
          onChanged: (next) => ref.read(trendsDateRangeProvider.notifier).state = next,
        ),
        const SizedBox(height: 28),
        AppCard(
          child: trendAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => RetrySection(
              message: 'Could not load Collections Trend.',
              onRetry: () => ref.invalidate(collectionsTrendProvider(range)),
            ),
            data: (trend) => TrendLineChart(series: trend.series, height: 240),
          ),
        ),
      ],
    );
  }
}
