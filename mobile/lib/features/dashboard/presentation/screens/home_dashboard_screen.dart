import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/kpi_grid.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_cases_section.dart';
import '../widgets/todays_overview_list.dart';

/// §4 Home Dashboard — top to bottom: greeting header, KPI Overview,
/// Today's Overview, Quick Actions, Recent Cases.
///
/// Business Health (§4.1) is deliberately not rendered here — no
/// `GET /dashboard/business-health` endpoint exists in the backend, and
/// per this project's "never use mock data" rule the section is hidden
/// entirely rather than shown with a placeholder/fabricated value. Add it
/// back as the first child below, backed by a real provider, once that
/// API exists.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        title: const DashboardGreeting(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: () => ref.read(authProvider.notifier).forceLogout(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshDashboard(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: const [
            KpiGrid(),
            SizedBox(height: 24),
            Text("Today's Overview", style: AppTypography.heading),
            SizedBox(height: 12),
            TodaysOverviewList(),
            SizedBox(height: 24),
            Text('Quick Actions', style: AppTypography.heading),
            SizedBox(height: 12),
            QuickActionsGrid(),
            SizedBox(height: 24),
            RecentCasesSection(),
          ],
        ),
      ),
    );
  }
}
