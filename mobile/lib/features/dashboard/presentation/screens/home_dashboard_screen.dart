import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/kpi_grid.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_cases_section.dart';
import '../widgets/todays_overview_list.dart';

/// §4 Home Dashboard — top to bottom: KPI grid, Today's Overview, Quick
/// Actions, Recent Cases (Business Health is out of scope this sprint —
/// no backend endpoint exists for it; see the Sprint 10 summary).
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authProvider.notifier).forceLogout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshDashboard(ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Text('Overview', style: AppTypography.heading),
            SizedBox(height: 12),
            KpiGrid(),
            SizedBox(height: 24),
            Text("Today's Overview", style: AppTypography.heading),
            SizedBox(height: 8),
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
