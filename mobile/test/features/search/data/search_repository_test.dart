import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/search/data/search_api.dart';
import 'package:mobile/features/search/data/search_repository.dart';
import 'package:mobile/features/search/domain/search_results.dart';
import 'package:mocktail/mocktail.dart';

class _MockSearchApi extends Mock implements SearchApi {}

const _results = SearchResults(
  customers: [],
  debts: [],
  payments: null,
  receipts: [],
  demandLetters: [],
  statements: [],
  collectionCases: [],
);

void main() {
  late _MockSearchApi mockApi;
  late SearchRepository repository;

  setUp(() {
    mockApi = _MockSearchApi();
    repository = SearchRepository(mockApi);
  });

  test('search delegates the query to the api and returns the results', () async {
    when(() => mockApi.search('asad')).thenAnswer((_) async => _results);

    final result = await repository.search('asad');

    expect(result, _results);
    verify(() => mockApi.search('asad')).called(1);
  });

  test('search throws ApiException on failure', () async {
    when(() => mockApi.search('asad')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: 'search'),
        response: Response(
          requestOptions: RequestOptions(path: 'search'),
          statusCode: 422,
          data: {
            'success': false,
            'message': 'The given data was invalid.',
            'data': null,
            'errors': {
              'q': ['The q field is required.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.search('asad'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422)),
    );
  });
}
