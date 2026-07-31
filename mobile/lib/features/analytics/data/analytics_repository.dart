import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../cases/domain/collection_case_page.dart';
import '../../customers/domain/customer_page.dart';
import '../../debts/domain/debt_page.dart';
import '../domain/aging_analysis.dart';
import '../domain/collection_analytics.dart';
import '../domain/collections_trend.dart';
import '../domain/payment_page.dart';
import '../domain/risk_distribution.dart';
import 'analytics_api.dart';

final analyticsRepositoryProvider =
    Provider<AnalyticsRepository>((ref) => AnalyticsRepository(ref.read(analyticsApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as every
/// other repository in the app. No caching, no business logic.
class AnalyticsRepository {
  final AnalyticsApi _api;

  const AnalyticsRepository(this._api);

  Future<CollectionAnalytics> fetchCollectionAnalytics({required String dateFrom, required String dateTo}) =>
      _guard(() => _api.collectionAnalytics(dateFrom: dateFrom, dateTo: dateTo));

  Future<RiskDistribution> fetchRiskDistribution() => _guard(() => _api.riskDistribution());

  Future<CollectionsTrend> fetchCollectionsTrend({required String dateFrom, required String dateTo}) =>
      _guard(() => _api.collectionsTrend(dateFrom: dateFrom, dateTo: dateTo));

  Future<AgingAnalysis> fetchAgingAnalysis() => _guard(() => _api.agingAnalysis());

  Future<CustomerPage> fetchReportCustomers({required int page, String? customerStatus, String? riskLevel}) =>
      _guard(() => _api.reportCustomers(page: page, customerStatus: customerStatus, riskLevel: riskLevel));

  Future<DebtPage> fetchReportDebts({required int page, String? status}) =>
      _guard(() => _api.reportDebts(page: page, status: status));

  Future<CollectionCasePage> fetchReportCollectionCases({required int page, String? status}) =>
      _guard(() => _api.reportCollectionCases(page: page, status: status));

  Future<PaymentPage> fetchReportPayments({required int page, String? dateFrom, String? dateTo}) =>
      _guard(() => _api.reportPayments(page: page, dateFrom: dateFrom, dateTo: dateTo));

  Future<CustomerPage> fetchReportCreditRisk({required int page, String? riskLevel}) =>
      _guard(() => _api.reportCreditRisk(page: page, riskLevel: riskLevel));

  Future<List<int>> exportReport({
    required String reportType,
    required String format,
    Map<String, dynamic> filters = const {},
  }) =>
      _guard(() => _api.export(reportType: reportType, format: format, filters: filters));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
