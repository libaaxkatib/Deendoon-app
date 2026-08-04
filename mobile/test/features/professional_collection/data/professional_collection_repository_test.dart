import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_api.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request_page.dart';
import 'package:mobile/features/professional_collection/domain/request_message.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionApi extends Mock implements ProfessionalCollectionApi {}

const _request = ProfessionalCollectionRequest(
  id: '1',
  collectionCaseId: '01CASE',
  referenceNumber: 'PCR-0001',
  status: 'submitted',
  submittedByUserId: '01USER',
  actionedByUserId: null,
  createdAt: '2026-08-01T00:00:00.000000Z',
  closedAt: null,
);

const _message = RequestMessage(
  id: '1',
  professionalCollectionRequestId: '1',
  senderUserId: '01USER',
  content: 'Hello',
  createdAt: '2026-08-01T00:00:00.000000Z',
);

void main() {
  late _MockProfessionalCollectionApi mockApi;
  late ProfessionalCollectionRepository repository;

  setUp(() {
    mockApi = _MockProfessionalCollectionApi();
    repository = ProfessionalCollectionRepository(mockApi);
  });

  test('submit delegates to the api', () async {
    when(() => mockApi.submit('01CASE')).thenAnswer((_) async => _request);

    final result = await repository.submit('01CASE');

    expect(result, _request);
  });

  test('submit throws ApiException with the server message on a 409 conflict', () async {
    when(() => mockApi.submit('01CASE')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/collection-cases/01CASE/professional-requests'),
        response: Response(
          requestOptions: RequestOptions(path: '/collection-cases/01CASE/professional-requests'),
          statusCode: 409,
          data: {
            'success': false,
            'message': 'This Collection Case already has an active Professional Collection Request.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.submit('01CASE'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
    );
  });

  test('fetchRequests passes page/status through and returns the page', () async {
    const page = ProfessionalCollectionRequestPage(requests: [_request], currentPage: 1, lastPage: 1, total: 1);
    when(() => mockApi.list(page: 1, status: 'submitted')).thenAnswer((_) async => page);

    final result = await repository.fetchRequests(page: 1, status: 'submitted');

    expect(result.requests, [_request]);
  });

  test('fetchRequest returns the request straight through', () async {
    when(() => mockApi.show('1')).thenAnswer((_) async => _request);

    expect(await repository.fetchRequest('1'), _request);
  });

  test('fetchMessages delegates to the api', () async {
    when(() => mockApi.messages('1')).thenAnswer((_) async => [_message]);

    final result = await repository.fetchMessages('1');

    expect(result, [_message]);
  });

  test('postMessage delegates content to the api', () async {
    when(() => mockApi.postMessage(id: '1', content: 'Hello')).thenAnswer((_) async => _message);

    final result = await repository.postMessage(id: '1', content: 'Hello');

    expect(result, _message);
  });

  test('postMessage throws ApiException with the server message on a 409 conflict', () async {
    when(() => mockApi.postMessage(id: '1', content: 'Hello')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/professional-requests/1/messages'),
        response: Response(
          requestOptions: RequestOptions(path: '/professional-requests/1/messages'),
          statusCode: 409,
          data: {
            'success': false,
            'message': 'This Professional Collection Request is closed; new messages are not accepted.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.postMessage(id: '1', content: 'Hello'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
    );
  });
}
