import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/customer_import/data/customer_import_api.dart';
import 'package:mobile/features/customer_import/data/customer_import_repository.dart';
import 'package:mobile/features/customer_import/domain/import_commit_result.dart';
import 'package:mobile/features/customer_import/domain/import_preview.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerImportApi extends Mock implements CustomerImportApi {}

void main() {
  late _MockCustomerImportApi mockApi;
  late CustomerImportRepository repository;

  setUp(() {
    mockApi = _MockCustomerImportApi();
    repository = CustomerImportRepository(mockApi);
  });

  test(
    'downloadTemplate delegates to the api and returns the raw bytes',
    () async {
      when(() => mockApi.downloadTemplate()).thenAnswer((_) async => [1, 2, 3]);

      expect(await repository.downloadTemplate(), [1, 2, 3]);
    },
  );

  test('downloadTemplate throws ApiException on failure', () async {
    when(() => mockApi.downloadTemplate()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/customers/import/template'),
        response: Response(
          requestOptions: RequestOptions(path: '/customers/import/template'),
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
      () => repository.downloadTemplate(),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });

  test(
    'previewImport delegates to the api and returns the parsed preview',
    () async {
      const preview = ImportPreview(
        batchId: '01BATCH',
        status: 'preview',
        rows: [],
      );
      when(
        () => mockApi.preview(
          filePath: '/tmp/customers.xlsx',
          fileName: 'customers.xlsx',
        ),
      ).thenAnswer((_) async => preview);

      final result = await repository.previewImport(
        filePath: '/tmp/customers.xlsx',
        fileName: 'customers.xlsx',
      );

      expect(result.batchId, '01BATCH');
    },
  );

  test('previewImport throws ApiException on failure', () async {
    when(
      () => mockApi.preview(
        filePath: any(named: 'filePath'),
        fileName: any(named: 'fileName'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/customers/import'),
        response: Response(
          requestOptions: RequestOptions(path: '/customers/import'),
          statusCode: 422,
          data: {
            'success': false,
            'message':
                'The uploaded file could not be read. It may be corrupted or in an unsupported format.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.previewImport(
        filePath: '/tmp/bad.xlsx',
        fileName: 'bad.xlsx',
      ),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
      ),
    );
  });

  test(
    'commitImport delegates to the api and returns the parsed result',
    () async {
      const result = ImportCommitResult(
        batchId: '01BATCH',
        status: 'committed',
        results: [],
        message: 'Import committed successfully',
      );
      when(
        () => mockApi.commit(batchId: '01BATCH'),
      ).thenAnswer((_) async => result);

      final commitResult = await repository.commitImport(batchId: '01BATCH');

      expect(commitResult.status, 'committed');
      expect(commitResult.message, 'Import committed successfully');
    },
  );

  test(
    'commitImport throws ApiException on an already-committed batch',
    () async {
      when(() => mockApi.commit(batchId: '01BATCH')).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/customers/import/01BATCH/commit',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/customers/import/01BATCH/commit',
            ),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'This import batch has already been committed.',
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.commitImport(batchId: '01BATCH'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'This import batch has already been committed.',
          ),
        ),
      );
    },
  );
}
