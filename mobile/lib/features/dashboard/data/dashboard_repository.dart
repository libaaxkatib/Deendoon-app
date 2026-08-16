import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/business_health.dart';
import '../domain/dashboard_kpis.dart';
import '../domain/recent_case.dart';
import '../domain/todays_overview.dart';
import 'dashboard_api.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(dashboardApiProvider)),
);

/// Translates raw Dio failures into `ApiException` — same pattern as
/// `AuthRepository`. No caching, no calculation: each method is a direct
/// pass-through to the matching `DashboardApi` call.
class DashboardRepository {
  final DashboardApi _api;

  const DashboardRepository(this._api);

  Future<BusinessHealth> fetchBusinessHealth() =>
      _guard(() => _api.businessHealth());

  Future<DashboardKpis> fetchKpis({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  }) => _guard(
    () => _api.kpis(period: period, dateFrom: dateFrom, dateTo: dateTo),
  );

  Future<TodaysOverview> fetchTodaysOverview() =>
      _guard(() => _api.todaysOverview());

  Future<List<RecentCase>> fetchRecentCases({int limit = 5}) =>
      _guard(() => _api.recentCases(limit: limit));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
