import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/debts/data/debt_api.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/credit_limit_warning.dart';
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
    const promise = PromiseToPay(
      id: '1',
      debtId: '1',
      promisedDate: '2026-08-01',
      status: 'open',
      createdAt: '2026-07-28T10:00:00.000000Z',
    );
    when(() => mockApi.promiseToPay(debtId: '1', promisedDate: '2026-08-01')).thenAnswer((_) async => promise);

    final result = await repository.promiseToPay(debtId: '1', promisedDate: '2026-08-01');

    expect(result, promise);
  });

  test('fetchPromiseToPayHistory delegates to the api', () async {
    const promise = PromiseToPay(
      id: '1',
      debtId: '1',
      promisedDate: '2026-08-01',
      status: 'open',
      createdAt: '2026-07-28T10:00:00.000000Z',
    );
    when(() => mockApi.promiseToPayHistory('1')).thenAnswer((_) async => [promise]);

    final result = await repository.fetchPromiseToPayHistory('1');

    expect(result, [promise]);
  });

  test('fetchPromiseToPayById delegates to the api (Item 14)', () async {
    const promise = PromiseToPay(
      id: '1',
      debtId: '1',
      promisedDate: '2026-08-01',
      status: 'open',
      createdAt: '2026-07-28T10:00:00.000000Z',
    );
    when(() => mockApi.showPromiseToPay('1')).thenAnswer((_) async => promise);

    final result = await repository.fetchPromiseToPayById('1');

    expect(result, promise);
  });

  test('fetchRelatedCase returns the case straight through on success', () async {
    const collectionCase = CollectionCase(
      id: '01CASE',
      debtId: '1',
      customerId: '01CUST',
      customerName: 'Somali Builders',
      outstandingAmount: '1000.00',
      riskLevel: 'high',
      referenceNumber: 'COL-0001',
      assignedOfficerUserId: null,
      caseStatus: 'open',
      closureOutcome: null,
      notes: null,
      lastActivityAt: '2026-08-01T10:00:00.000000Z',
      createdAt: '2026-08-01T10:00:00.000000Z',
      closedAt: null,
    );
    when(() => mockApi.relatedCase('1')).thenAnswer((_) async => collectionCase);

    expect(await repository.fetchRelatedCase('1'), collectionCase);
  });

  test('fetchRelatedCase returns null on a 404 (no case yet) instead of throwing', () async {
    when(() => mockApi.relatedCase('1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/debts/1/collection-case'),
        response: Response(
          requestOptions: RequestOptions(path: '/debts/1/collection-case'),
          statusCode: 404,
          data: {'success': false, 'message': 'This debt has no collection case.', 'data': null, 'errors': null},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(await repository.fetchRelatedCase('1'), isNull);
  });

  test('fetchRelatedCase rethrows a non-404 failure as ApiException', () async {
    when(() => mockApi.relatedCase('1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/debts/1/collection-case'),
        response: Response(
          requestOptions: RequestOptions(path: '/debts/1/collection-case'),
          statusCode: 403,
          data: {'success': false, 'message': 'This action is unauthorized.', 'data': null, 'errors': null},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchRelatedCase('1'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
  });

  test('openCase delegates to the api and returns the created case', () async {
    const collectionCase = CollectionCase(
      id: '01CASE',
      debtId: '1',
      customerId: '01CUST',
      customerName: 'Somali Builders',
      outstandingAmount: '1000.00',
      riskLevel: 'high',
      referenceNumber: 'COL-0001',
      assignedOfficerUserId: null,
      caseStatus: 'open',
      closureOutcome: null,
      notes: null,
      lastActivityAt: '2026-08-01T10:00:00.000000Z',
      createdAt: '2026-08-01T10:00:00.000000Z',
      closedAt: null,
    );
    when(() => mockApi.openCase('1')).thenAnswer((_) async => collectionCase);

    final result = await repository.openCase('1');

    expect(result, collectionCase);
    verify(() => mockApi.openCase('1')).called(1);
  });

  test('fetchTimeline delegates to the api', () async {
    const timeline = DebtTimeline(debtId: '1', stages: []);
    when(() => mockApi.timeline('1')).thenAnswer((_) async => timeline);

    expect(await repository.fetchTimeline('1'), timeline);
  });

  test('createDebt delegates every field to the api and returns the save result', () async {
    const result = (debt: _debt, warning: null);
    when(() => mockApi.store(customerId: '01CUST', amount: '1000.00', dueDate: '2026-07-01', notes: 'Call first'))
        .thenAnswer((_) async => result);

    final saved = await repository.createDebt(
      customerId: '01CUST',
      amount: '1000.00',
      dueDate: '2026-07-01',
      notes: 'Call first',
    );

    expect(saved.debt, _debt);
    expect(saved.warning, isNull);
  });

  test('createDebt surfaces a credit-limit-exceeded warning when present', () async {
    const warning = CreditLimitWarning(
      type: 'CREDIT_LIMIT_EXCEEDED',
      message: 'This customer has exceeded the approved credit limit.',
      creditLimit: '5000.00',
      projectedOutstanding: '5500.00',
    );
    const result = (debt: _debt, warning: warning);
    when(() => mockApi.store(customerId: '01CUST', amount: '1000.00', dueDate: '2026-07-01', notes: null))
        .thenAnswer((_) async => result);

    final saved = await repository.createDebt(customerId: '01CUST', amount: '1000.00', dueDate: '2026-07-01');

    expect(saved.warning, warning);
  });

  test('updateDebt delegates to the api', () async {
    when(() => mockApi.update(debtId: '1', dueDate: '2026-08-01', notes: 'Updated notes'))
        .thenAnswer((_) async => _debt);

    final result = await repository.updateDebt(debtId: '1', dueDate: '2026-08-01', notes: 'Updated notes');

    expect(result, _debt);
  });

  test('generateStatement delegates to the api', () async {
    const statement = DocumentSummary(
      id: '3',
      documentType: 'statement',
      referenceNumber: 'STM-0001',
      generatedAt: '2026-08-01T00:00:00.000000Z',
      fileSize: 3000,
    );
    when(() => mockApi.generateStatement('1')).thenAnswer((_) async => statement);

    final result = await repository.generateStatement('1');

    expect(result, statement);
  });

  test('logWhatsAppReminder delegates the details to the api', () async {
    when(() => mockApi.logWhatsAppReminder(debtId: '1', details: 'Sent via WhatsApp'))
        .thenAnswer((_) async => _debt);

    final result = await repository.logWhatsAppReminder(debtId: '1', details: 'Sent via WhatsApp');

    expect(result, _debt);
  });

  test('logSmsReminder delegates the details to the api', () async {
    when(() => mockApi.logSmsReminder(debtId: '1', details: null)).thenAnswer((_) async => _debt);

    final result = await repository.logSmsReminder(debtId: '1');

    expect(result, _debt);
  });

  test('logCallReminder delegates the details to the api', () async {
    when(() => mockApi.logCallReminder(debtId: '1', details: 'No answer')).thenAnswer((_) async => _debt);

    final result = await repository.logCallReminder(debtId: '1', details: 'No answer');

    expect(result, _debt);
  });
}
