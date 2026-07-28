import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/coming_soon.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/dashboard_providers.dart';
import 'kpi_card.dart';

/// §4.2 KPI Cards — 2x2 grid: Total Outstanding, Collected This Month,
/// Overdue Amount, High Risk Customers. Their real destinations (Debts
/// view, Analytics, Cases filtered to High Risk) are out of scope this
/// sprint, so taps surface a "coming soon" notice instead of navigating.
class KpiGrid extends ConsumerWidget {
  const KpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dashboardKpisProvider);

    return kpis.when(
      loading: () => const SectionLoading(),
      error: (error, _) => RetrySection(
        message: 'Could not load KPIs.',
        onRetry: () => ref.invalidate(dashboardKpisProvider),
      ),
      data: (data) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          KpiCard(
            label: 'Total Outstanding',
            value: data.totalOutstandingAmount,
            onTap: () => showComingSoon(context, 'Debts'),
          ),
          KpiCard(
            label: 'Collected This Month',
            value: data.totalCollectedPeriod,
            onTap: () => showComingSoon(context, 'Analytics'),
          ),
          KpiCard(
            label: 'Overdue Amount',
            value: data.overdueValue,
            onTap: () => showComingSoon(context, 'Debts'),
          ),
          KpiCard(
            label: 'High Risk Customers',
            value: '${data.highRiskCustomers}',
            onTap: () => showComingSoon(context, 'Cases'),
          ),
        ],
      ),
    );
  }
}
