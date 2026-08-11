import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/dashboard_providers.dart';
import '../providers/kpi_period_provider.dart';
import 'kpi_card.dart';
import 'kpi_period_selector.dart';

/// §4.2 KPI Cards — "KPI Overview" header (with a real period selector,
/// Section 10's own UI state — see `kpi_period_provider.dart`) and a 2x2
/// grid: Total Outstanding, Collected (selected period), Overdue Amount,
/// High Risk Customers. Each card navigates to its real destination: Total
/// Outstanding and Overdue Amount open the tenant-wide Debts report
/// (Overdue pre-filtered to `status=overdue`), Collected opens the
/// Analytics tab, and High Risk Customers opens the Cases tab
/// pre-filtered to the `high_risk` tab.
///
/// Only "Collected" is period-scoped — `ReportingService::dashboardKpis()`
/// computes Total Outstanding, Overdue Amount, and High Risk Customers as
/// current-state snapshots (right now), not historical reconstructions;
/// there's no point-in-time history retained anywhere in the schema for
/// them (`ReportingService::collectionsTrend()`'s own doc comment says the
/// same about outstanding/risk data), so the period selector correctly
/// leaves those three unchanged and only re-sums "Collected" for the
/// selected period. The card's label reflects the selected period so this
/// reads as intentional, not stale.
class KpiGrid extends ConsumerWidget {
  const KpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kpis = ref.watch(dashboardKpisProvider);
    final periodLabel = kpiPeriodDisplayLabel(l10n, ref.watch(kpiPeriodProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.kpiOverviewTitle, style: AppTypography.heading)),
            const KpiPeriodSelector(),
          ],
        ),
        const SizedBox(height: 4),
        kpis.when(
          loading: () => const SectionLoading(),
          error: (error, _) => RetrySection(
            message: l10n.kpiLoadError,
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
                label: l10n.kpiTotalOutstanding,
                value: data.totalOutstandingAmount,
                onTap: () => context.push('/analytics/reports/debts'),
              ),
              KpiCard(
                icon: Icons.savings_outlined,
                label: l10n.kpiCollectedPeriod(periodLabel),
                value: data.totalCollectedPeriod,
                onTap: () => context.go(RoutePaths.analytics),
              ),
              KpiCard(
                icon: Icons.warning_amber_outlined,
                label: l10n.kpiOverdueAmount,
                value: data.overdueValue,
                valueColor: AppColors.danger,
                onTap: () => context.push('/analytics/reports/debts?status=overdue'),
              ),
              KpiCard(
                icon: Icons.groups_outlined,
                label: l10n.kpiHighRiskCustomers,
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
