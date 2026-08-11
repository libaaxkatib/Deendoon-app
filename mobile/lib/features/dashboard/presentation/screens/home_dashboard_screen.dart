import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/business_health_card.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/kpi_grid.dart';
import '../widgets/professional_collection_summary_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_cases_section.dart';
import '../widgets/todays_overview_list.dart';

/// §4 Home Dashboard — top to bottom: greeting header, Business Health,
/// KPI Overview, Today's Overview, Quick Actions, Recent Cases,
/// Professional Collection summary. The greeting opens Account
/// (Profile/Business Profile/Settings/Notifications/Logout — Logout moved
/// here from this header, replaced by the Notification Bell as the
/// header's primary action).
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        titleSpacing: 16,
        title: InkWell(
          onTap: () => context.push('/account'),
          child: const DashboardGreeting(),
        ),
        actions: const [
          ThemeToggleButton(),
          Padding(
            padding: EdgeInsets.only(right: 4),
            child: NotificationBellButton(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshDashboard(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            const BusinessHealthCard(),
            const SizedBox(height: 3),
            const KpiGrid(),
            const SizedBox(height: 3),
            Text(l10n.dashboardTodaysOverview, style: AppTypography.heading),
            const SizedBox(height: 2),
            const TodaysOverviewList(),
            const SizedBox(height: 3),
            Text(l10n.dashboardQuickActions, style: AppTypography.heading),
            const SizedBox(height: 2),
            const QuickActionsGrid(),
            const SizedBox(height: 16),
            const RecentCasesSection(),
            const SizedBox(height: 16),
            const ProfessionalCollectionSummaryCard(),
          ],
        ),
      ),
    );
  }
}
