import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/business_health.dart';
import '../domain/dashboard_kpis.dart';
import '../domain/recent_case.dart';
import '../domain/todays_overview.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) => DashboardApi(ref.read(dioProvider)));

/// Thin wrapper around `GET /dashboard/*` — mirrors
/// `App\Http\Controllers\DashboardController` exactly.
class DashboardApi {
  final Dio _dio;

  const DashboardApi(this._dio);

  Future<BusinessHealth> businessHealth() async {
    final response = await _dio.get('dashboard/business-health');
    return BusinessHealth.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<DashboardKpis> kpis({String period = 'month'}) async {
    final response = await _dio.get('dashboard/kpis', queryParameters: {'period': period});
    return DashboardKpis.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TodaysOverview> todaysOverview() async {
    final response = await _dio.get('dashboard/todays-overview');
    return TodaysOverview.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<RecentCase>> recentCases({int limit = 5}) async {
    final response = await _dio.get('dashboard/recent-cases', queryParameters: {'limit': limit});
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => RecentCase.fromJson(json as Map<String, dynamic>)).toList();
  }
}
