import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/analytics/data/analytics_api.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/aging_analysis.dart';
import 'package:mobile/features/analytics/domain/collection_analytics.dart';
import 'package:mobile/features/analytics/domain/payment_page.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsApi extends Mock implements AnalyticsApi {}

const _customer = Customer(
  id: '1',
  name: 'Moshe Nienow Jr.',
  phone: '254790835674',
  customerStatus: 'active',
  creditLimit: '1000.00',
  outstandingBalance: '500.00',
  remainingCredit: '500.00',
  riskLevel: 'high',
  creditScore: 700,
  creditScoreBand: 'good',
  archivedAt: null,
);

const _debt = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '500.00',
  dueDate: '2026-01-15',
  debtStatus: 'paid',
  remainingBalance: '0.00',
  recoveryStage: 1,
  notes: null,
);

void main() {
  late _MockAnalyticsApi mockApi;
  late AnalyticsRepository repository;

  setUp(() {
    mockApi = _MockAnalyticsApi();
    repository = AnalyticsRepository(mockApi);
  });

  test(
    'fetchCollectionAnalytics passes the date range through and returns the result',
    () async {
      const analytics = CollectionAnalytics(
        collectionRate: 40.0,
        totalCollected: '400.00',
        averageDays: 10.0,
      );
      when(
        () => mockApi.collectionAnalytics(
          dateFrom: '2026-07-01',
          dateTo: '2026-07-28',
        ),
      ).thenAnswer((_) async => analytics);

      final result = await repository.fetchCollectionAnalytics(
        dateFrom: '2026-07-01',
        dateTo: '2026-07-28',
      );

      expect(result, analytics);
    },
  );

  test('fetchCollectionAnalytics throws ApiException on failure', () async {
    when(
      () => mockApi.collectionAnalytics(
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/collection-analytics'),
        response: Response(
          requestOptions: RequestOptions(path: '/reports/collection-analytics'),
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
      () => repository.fetchCollectionAnalytics(
        dateFrom: '2026-07-01',
        dateTo: '2026-07-28',
      ),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });

  test('fetchAgingAnalysis delegates to the api', () async {
    const aging = AgingAnalysis(
      buckets: {},
      debts: [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    );
    when(() => mockApi.agingAnalysis()).thenAnswer((_) async => aging);

    expect(await repository.fetchAgingAnalysis(), aging);
  });

  test(
    'fetchReportCustomers passes filters through and returns the page',
    () async {
      const page = CustomerPage(
        customers: [_customer],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      );
      when(
        () => mockApi.reportCustomers(
          page: 1,
          customerStatus: null,
          riskLevel: 'high',
        ),
      ).thenAnswer((_) async => page);

      final result = await repository.fetchReportCustomers(
        page: 1,
        riskLevel: 'high',
      );

      expect(result.customers, [_customer]);
    },
  );

  test('fetchReportPayments delegates to the api', () async {
    const payment = Payment(
      id: '1',
      debtId: '1',
      amount: '100.00',
      paymentDate: '2026-07-28',
      paymentMethod: null,
    );
    const page = PaymentPage(
      payments: [payment],
      currentPage: 1,
      lastPage: 1,
      total: 1,
    );
    when(
      () => mockApi.reportPayments(page: 1, dateFrom: null, dateTo: null),
    ).thenAnswer((_) async => page);

    final result = await repository.fetchReportPayments(page: 1);

    expect(result.payments, [payment]);
  });

  test(
    'fetchReportDebts passes dateFrom/dateTo/perPage through (Collection Rate detail, Item 9)',
    () async {
      const page = DebtPage(
        debts: [_debt],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      );
      when(
        () => mockApi.reportDebts(
          page: 1,
          status: null,
          dateFrom: '2026-01-01',
          dateTo: '2026-01-31',
          paidDateFrom: null,
          paidDateTo: null,
          perPage: 100,
        ),
      ).thenAnswer((_) async => page);

      final result = await repository.fetchReportDebts(
        page: 1,
        dateFrom: '2026-01-01',
        dateTo: '2026-01-31',
        perPage: 100,
      );

      expect(result.debts, [_debt]);
    },
  );

  test(
    'fetchReportDebts passes paidDateFrom/paidDateTo through (Average Days detail, Item 10)',
    () async {
      const page = DebtPage(
        debts: [_debt],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      );
      when(
        () => mockApi.reportDebts(
          page: 1,
          status: null,
          dateFrom: null,
          dateTo: null,
          paidDateFrom: '2026-01-01',
          paidDateTo: '2026-01-31',
          perPage: 100,
        ),
      ).thenAnswer((_) async => page);

      final result = await repository.fetchReportDebts(
        page: 1,
        paidDateFrom: '2026-01-01',
        paidDateTo: '2026-01-31',
        perPage: 100,
      );

      expect(result.debts, [_debt]);
    },
  );

  test('exportReport delegates to the api and returns raw bytes', () async {
    when(
      () => mockApi.export(reportType: 'customers', format: 'csv', filters: {}),
    ).thenAnswer((_) async => [1, 2, 3]);

    final result = await repository.exportReport(
      reportType: 'customers',
      format: 'csv',
    );

    expect(result, [1, 2, 3]);
  });
}
