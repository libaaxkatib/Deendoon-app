import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/report_category_tile.dart';

/// §5.2 Reports — the 5 real report categories exposed by
/// `ReportController`: Customers, Debts, Collection Cases, Payments,
/// Credit Risk. Aging Analysis (also a real report endpoint) is not
/// listed again here — it's already the Overview tab's own chart, and its
/// backing debt list is reached via that chart's per-bucket drill-down,
/// not a second, separate category tile.
class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportCategoryTile(
          icon: Icons.people_outline,
          label: l10n.reportCategoryCustomers,
          onTap: () => context.push('/analytics/reports/customers'),
        ),
        const SizedBox(height: 10),
        ReportCategoryTile(
          icon: Icons.receipt_long_outlined,
          label: l10n.reportCategoryDebts,
          onTap: () => context.push('/analytics/reports/debts'),
        ),
        const SizedBox(height: 10),
        ReportCategoryTile(
          icon: Icons.folder_outlined,
          label: l10n.reportCategoryCollectionCases,
          onTap: () => context.push('/analytics/reports/collection-cases'),
        ),
        const SizedBox(height: 10),
        ReportCategoryTile(
          icon: Icons.payments_outlined,
          label: l10n.reportCategoryPayments,
          onTap: () => context.push('/analytics/reports/payments'),
        ),
        const SizedBox(height: 10),
        ReportCategoryTile(
          icon: Icons.shield_outlined,
          label: l10n.reportCategoryCreditRisk,
          onTap: () => context.push('/analytics/reports/credit-risk'),
        ),
      ],
    );
  }
}
