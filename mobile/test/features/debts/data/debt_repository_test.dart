import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/debts/data/debt_api.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mobile/features/debts/domain/debt_timeline.dart';
import 'package:mobile/features/debts/domain/promise_to_pay.dart';
import 'package:mocktail/mocktail.dart';

class _MockDebtApi extends Mock implements DebtApi {}

const _debt = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '1000.00',
  dueDate: '2026-07-01',
  debtStatus: 'overdue',
  remainingBalance: '400.00',
  recoveryStage: 3,
  notes: null,
);

void main() {
  late _MockDebtApi mockApi;
  late DebtRepository repository;

  setUp(() {
    mockApi = _MockDebtApi();
    repository = DebtRepository(mockApi);
  });

  test('fetchDebts passes customerId/status through and returns the page', () async {
    const page = DebtPage(debts: [_debt], currentPage: 1, lastPage: 2, total: 21);
    when(() => mockApi.list(page: 1, customerId: '01CUST', status: 'overdue', dateFrom: null, dateTo: null))
        .thenAnswer((_) async => page);

    final result = await repository.fetchDebts(page: 1, customerId: '01CUST', status: 'overdue');

    expect(result.debts, [_debt]);
  });

  test('fetchDebts throws ApiException on failure', () async {
    when(() => mockApi.list(page: 1, customerId: null, status: null, dateFrom: null, dateTo: null)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/debts'),
        response: Response(
          requestOptions: RequestOptions(path: '/debts'),
          statusCode: 401,
          data: {'success': false, 'message': 'Unauthenticated.', 'data': null, 'errors': null},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchDebts(page: 1),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('fetchDebt returns the debt straight through', () async {
    when(() => mockApi.show('1')).thenAnswer((_) async => _debt);

    expect(await repository.fetchDebt('1'), _debt);
  });

  test('recordPayment delegates to the api with the given fields', () async {
    const payment = Payment(id: '1', debtId: '1', amount: '100.00', paymentDate: '2026-07-28', paymentMethod: 'cash');
    when(() => mockApi.recordPayment(
          debtId: '1',
          amount: '100.00',
          paymentDate: '2026-07-28',
          paymentMethod: 'cash',
          referenceNotes: null,
        )).thenAnswer((_) async => payment);

    final result = await repository.recordPayment(
      debtId: '1',
      amount: '100.00',
      paymentDate: '2026-07-28',
      paymentMethod: 'cash',
    );

    expect(result, payment);
  });

  test('promiseToPay delegates to the api', () async {
    const promise = PromiseToPay(id: '1', debtId: '1', promisedDate: '2026-08-01', status: 'open');
    when(() => mockApi.promiseToPay(debtId: '1', promisedDate: '2026-08-01')).thenAnswer((_) async => promise);

    final result = await repository.promiseToPay(debtId: '1', promisedDate: '2026-08-01');

    expect(result, promise);
  });

  test('openCase delegates to the api', () async {
    when(() => mockApi.openCase('1')).thenAnswer((_) async {});

    await repository.openCase('1');

    verify(() => mockApi.openCase('1')).called(1);
  });

  test('fetchTimeline delegates to the api', () async {
    const timeline = DebtTimeline(debtId: '1', stages: []);
    when(() => mockApi.timeline('1')).thenAnswer((_) async => timeline);

    expect(await repository.fetchTimeline('1'), timeline);
  });
}
