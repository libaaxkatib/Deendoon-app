import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/dashboard/data/dashboard_api.dart';
import 'package:mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/dashboard_kpis.dart';
import 'package:mocktail/mocktail.dart';

class _MockDashboardApi extends Mock implements DashboardApi {}

const _kpis = DashboardKpis(
  totalOutstandingAmount: '800.00',
  totalCollectedPeriod: '100.00',
  highRiskCustomers: 2,
  overdueCount: 2,
  overdueValue: '400.00',
  customersOverCreditLimit: 1,
  activeCollectionCases: 3,
);

void main() {
  late _MockDashboardApi mockApi;
  late DashboardRepository repository;

  setUp(() {
    mockApi = _MockDashboardApi();
    repository = DashboardRepository(mockApi);
  });

  test('fetchKpis returns the value straight through on success', () async {
    when(() => mockApi.kpis()).thenAnswer((_) async => _kpis);

    final result = await repository.fetchKpis();

    expect(result, _kpis);
  });

  test('fetchKpis throws ApiException with the server message on failure', () async {
    when(() => mockApi.kpis()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/dashboard/kpis'),
        response: Response(
          requestOptions: RequestOptions(path: '/dashboard/kpis'),
          statusCode: 403,
          data: {
            'success': false,
            'message': 'This action is unauthorized.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchKpis(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
  });

  test('fetchRecentCases passes the limit through and translates failures independently', () async {
    when(() => mockApi.recentCases(limit: 5)).thenAnswer((_) async => []);

    final result = await repository.fetchRecentCases();

    expect(result, isEmpty);
    verify(() => mockApi.recentCases(limit: 5)).called(1);
  });
}
