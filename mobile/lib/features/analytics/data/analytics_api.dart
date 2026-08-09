import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../cases/domain/collection_case_page.dart';
import '../../customers/domain/customer_page.dart';
import '../../debts/domain/debt_page.dart';
import '../domain/aging_analysis.dart';
import '../domain/collection_analytics.dart';
import '../domain/collections_trend.dart';
import '../domain/payment_page.dart';
import '../domain/risk_distribution.dart';

final analyticsApiProvider = Provider<AnalyticsApi>((ref) => AnalyticsApi(ref.read(dioProvider)));

/// Thin wrapper around `GET /reports/*` — mirrors `ReportController`
/// exactly (Sprint 16 backend audit). `reports/customers`, `reports/debts`,
/// and `reports/collection-cases` return the exact same envelope shape as
/// the Customers/Debts/Cases modules' own list endpoints (`{entity_key:
/// [...], pagination: {...}}`), so this reuses `CustomerPage`/`DebtPage`/
/// `CollectionCasePage` directly rather than duplicating an identical
/// parser.
class AnalyticsApi {
  final Dio _dio;

  const AnalyticsApi(this._dio);

  Future<CollectionAnalytics> collectionAnalytics({required String dateFrom, required String dateTo}) async {
    final response = await _dio.get('reports/collection-analytics', queryParameters: {
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    });
    return CollectionAnalytics.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RiskDistribution> riskDistribution() async {
    final response = await _dio.get('reports/risk-distribution');
    return RiskDistribution.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CollectionsTrend> collectionsTrend({required String dateFrom, required String dateTo}) async {
    final response = await _dio.get('reports/collections-trend', queryParameters: {
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'metric': 'collected_amount',
    });
    return CollectionsTrend.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `perPage: 100` (the backend's documented max, `ApiResponse::perPage()`)
  /// — the aging drill-down reuses whichever debts this single call
  /// returns rather than issuing a second request, so this widens that one
  /// request as far as the backend allows instead of settling for its
  /// 15-row default.
  Future<AgingAnalysis> agingAnalysis() async {
    final response = await _dio.get('reports/aging-analysis', queryParameters: {'perPage': 100});
    return AgingAnalysis.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CustomerPage> reportCustomers({
    required int page,
    String? customerStatus,
    String? riskLevel,
  }) async {
    final response = await _dio.get('reports/customers', queryParameters: {
      'page': page,
      'customer_status': ?customerStatus,
      'riskLevel': ?riskLevel,
    });
    return CustomerPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<DebtPage> reportDebts({
    required int page,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? paidDateFrom,
    String? paidDateTo,
    int? perPage,
  }) async {
    final response = await _dio.get('reports/debts', queryParameters: {
      'page': page,
      'status': ?status,
      'dateFrom': ?dateFrom,
      'dateTo': ?dateTo,
      'paidDateFrom': ?paidDateFrom,
      'paidDateTo': ?paidDateTo,
      'perPage': ?perPage,
    });
    return DebtPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CollectionCasePage> reportCollectionCases({required int page, String? status}) async {
    final response = await _dio.get('reports/collection-cases', queryParameters: {
      'page': page,
      'status': ?status,
    });
    return CollectionCasePage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaymentPage> reportPayments({required int page, String? dateFrom, String? dateTo}) async {
    final response = await _dio.get('reports/payments', queryParameters: {
      'page': page,
      'dateFrom': ?dateFrom,
      'dateTo': ?dateTo,
    });
    return PaymentPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Credit Risk reuses the identical `CustomerResource`/pagination shape
  /// as `reports/customers` (`ReportController::creditRisk()` calls the
  /// exact same private `customersQuery()`), just ordered by
  /// `credit_score` desc server-side.
  Future<CustomerPage> reportCreditRisk({required int page, String? riskLevel}) async {
    final response = await _dio.get('reports/credit-risk', queryParameters: {
      'page': page,
      'riskLevel': ?riskLevel,
    });
    return CustomerPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `reportType` is one of the 6 real, exportable categories —
  /// `aging-analysis`, `customers`, `debts`, `collection-cases`,
  /// `payments`, `credit-risk` (`collection-analytics`/`risk-distribution`/
  /// `collections-trend` are aggregates, not exportable — confirmed 404 in
  /// `ReportController::export()`). `format` is `pdf`/`excel`/`csv`. Not
  /// the standard JSON envelope — a raw file body, same pattern as
  /// `DocumentApi.download()`.
  Future<List<int>> export({
    required String reportType,
    required String format,
    Map<String, dynamic> filters = const {},
  }) async {
    final response = await _dio.get<List<int>>(
      'reports/$reportType/export',
      queryParameters: {'format': format, ...filters},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }
}
