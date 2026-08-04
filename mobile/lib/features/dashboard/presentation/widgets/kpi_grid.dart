import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/dashboard_providers.dart';
import 'kpi_card.dart';
import 'kpi_period_selector.dart';

/// §4.2 KPI Cards — "KPI Overview" header (with a real period selector,
/// Section 10's own UI state — see `kpi_period_provider.dart`) and a 2x2
/// grid: Total Outstanding, Collected This Month, Overdue Amount, High
/// Risk Customers. Each card navigates to its real destination: Total
/// Outstanding and Overdue Amount open the tenant-wide Debts report
/// (Overdue pre-filtered to `status=overdue`), Collected This Month opens
/// the Analytics tab, and High Risk Customers opens the Cases tab
/// pre-filtered to the `high_risk` tab.
class KpiGrid extends ConsumerWidget {
  const KpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dashboardKpisProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: Text('KPI Overview', style: AppTypography.heading)),
            KpiPeriodSelector(),
          ],
        ),
        const SizedBox(height: 4),
        kpis.when(
          loading: () => const SectionLoading(),
          error: (error, _) => RetrySection(
            message: 'Could not load KPIs.',
            onRetry: () => ref.invalidate(dashboardKpisProvider),
          ),
          data: (data) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 8,
            childAspectRatio: 3.0,
            children: [
              KpiCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total Outstanding',
                value: data.totalOutstandingAmount,
                onTap: () => context.push('/analytics/reports/debts'),
              ),
              KpiCard(
                icon: Icons.savings_outlined,
                label: 'Collected This Month',
                value: data.totalCollectedPeriod,
                onTap: () => context.go(RoutePaths.analytics),
              ),
              KpiCard(
                icon: Icons.warning_amber_outlined,
                label: 'Overdue Amount',
                value: data.overdueValue,
                valueColor: AppColors.danger,
                onTap: () => context.push('/analytics/reports/debts?status=overdue'),
              ),
              KpiCard(
                icon: Icons.groups_outlined,
                label: 'High Risk Customers',
                value: '${data.highRiskCustomers}',
                onTap: () => context.go('${RoutePaths.cases}?tab=high_risk'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
