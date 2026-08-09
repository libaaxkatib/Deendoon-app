import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        titleSpacing: 16,
        title: InkWell(
          onTap: () => context.push('/account'),
          child: const DashboardGreeting(),
        ),
        actions: const [
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
          children: const [
            BusinessHealthCard(),
            SizedBox(height: 3),
            KpiGrid(),
            SizedBox(height: 3),
            Text("Today's Overview", style: AppTypography.heading),
            SizedBox(height: 2),
            TodaysOverviewList(),
            SizedBox(height: 3),
            Text('Quick Actions', style: AppTypography.heading),
            SizedBox(height: 2),
            QuickActionsGrid(),
            SizedBox(height: 16),
            RecentCasesSection(),
            SizedBox(height: 16),
            ProfessionalCollectionSummaryCard(),
          ],
        ),
      ),
    );
  }
}
