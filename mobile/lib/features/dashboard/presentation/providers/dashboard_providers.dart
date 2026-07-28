import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_kpis.dart';
import '../../domain/recent_case.dart';
import '../../domain/todays_overview.dart';

/// Three independent providers, one per Home Dashboard component
/// (§4.2/§4.3/§4.5), matching the frozen spec's requirement that each
/// component "loads independently with its own placeholder" and shows
/// "a retry affordance independently of the other[s]" — a single
/// aggregated fetch would collapse that independence (one failing call
/// would blank out sections whose data actually loaded fine).
final dashboardKpisProvider = FutureProvider<DashboardKpis>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchKpis(),
);

final todaysOverviewProvider = FutureProvider<TodaysOverview>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchTodaysOverview(),
);

final recentCasesProvider = FutureProvider<List<RecentCase>>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchRecentCases(),
);

/// Invalidates and re-awaits all three — used by the screen's
/// `RefreshIndicator` (Pull to Refresh).
Future<void> refreshDashboard(WidgetRef ref) async {
  ref.invalidate(dashboardKpisProvider);
  ref.invalidate(todaysOverviewProvider);
  ref.invalidate(recentCasesProvider);
  await Future.wait([
    ref.read(dashboardKpisProvider.future),
    ref.read(todaysOverviewProvider.future),
    ref.read(recentCasesProvider.future),
  ]);
}
