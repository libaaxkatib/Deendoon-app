import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'overview_tab.dart';
import 'reports_tab.dart';
import 'trends_tab.dart';

/// §5 Analytics — "Three tabs: Overview, Reports, and Trends." Overview is
/// the default tab on entering Analytics, per §5.1.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(20),
                labelColor: AppColors.background,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Reports'),
                  Tab(text: 'Trends'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            OverviewTab(),
            ReportsTab(),
            TrendsTab(),
          ],
        ),
      ),
    );
  }
}
