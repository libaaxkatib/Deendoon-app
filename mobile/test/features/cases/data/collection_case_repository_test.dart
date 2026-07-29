import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/cases/data/collection_case_api.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/cases/domain/case_history.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/domain/collection_case_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollectionCaseApi extends Mock implements CollectionCaseApi {}

const _case = CollectionCase(
  id: '1',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  lastActivityAt: '2026-07-28T10:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: null,
);

void main() {
  late _MockCollectionCaseApi mockApi;
  late CollectionCaseRepository repository;

  setUp(() {
    mockApi = _MockCollectionCaseApi();
    repository = CollectionCaseRepository(mockApi);
  });

  test('fetchCases passes tab through and returns the page', () async {
    const page = CollectionCasePage(cases: [_case], currentPage: 1, lastPage: 2, total: 21);
    when(() => mockApi.list(page: 1, tab: 'high_risk')).thenAnswer((_) async => page);

    final result = await repository.fetchCases(page: 1, tab: 'high_risk');

    expect(result.cases, [_case]);
  });

  test('fetchCases throws ApiException on failure', () async {
    when(() => mockApi.list(page: 1, tab: null)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/collection-cases'),
        response: Response(
          requestOptions: RequestOptions(path: '/collection-cases'),
          statusCode: 401,
          data: {'success': false, 'message': 'Unauthenticated.', 'data': null, 'errors': null},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchCases(page: 1),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('fetchCase returns the case straight through', () async {
    when(() => mockApi.show('1')).thenAnswer((_) async => _case);

    expect(await repository.fetchCase('1'), _case);
  });

  test('recordActivity delegates to the api with the given details', () async {
    when(() => mockApi.recordActivity(caseId: '1', details: 'Contacted — spoke to customer'))
        .thenAnswer((_) async {});

    await repository.recordActivity(caseId: '1', details: 'Contacted — spoke to customer');

    verify(() => mockApi.recordActivity(caseId: '1', details: 'Contacted — spoke to customer')).called(1);
  });

  test('close delegates to the api and returns the closed case', () async {
    const closed = CollectionCase(
      id: '1',
      debtId: '01DEBT',
      customerId: '01CUST',
      customerName: 'Somali Builders',
      outstandingAmount: '4467.40',
      riskLevel: 'high',
      referenceNumber: 'COL-0001',
      assignedOfficerUserId: null,
      caseStatus: 'closed',
      closureOutcome: 'Paid in full',
      lastActivityAt: '2026-07-28T11:00:00.000000Z',
      createdAt: '2026-07-01T10:00:00.000000Z',
      closedAt: '2026-07-28T11:00:00.000000Z',
    );
    when(() => mockApi.close(caseId: '1', closureOutcome: 'Paid in full')).thenAnswer((_) async => closed);

    final result = await repository.close(caseId: '1', closureOutcome: 'Paid in full');

    expect(result, closed);
  });

  test('fetchHistory delegates to the api', () async {
    const history = CaseHistory(collectionCaseId: '1', entries: []);
    when(() => mockApi.history('1')).thenAnswer((_) async => history);

    expect(await repository.fetchHistory('1'), history);
  });
}
