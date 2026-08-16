import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/attachments/data/attachment_api.dart';
import 'package:mobile/features/attachments/data/attachment_repository.dart';
import 'package:mobile/features/attachments/domain/attachment.dart';
import 'package:mocktail/mocktail.dart';

class _MockAttachmentApi extends Mock implements AttachmentApi {}

const _attachment = Attachment(
  id: '1',
  entityId: '01CUST',
  uploadedByUserId: '01USER',
  originalFilename: 'id-card.pdf',
  mimeType: 'application/pdf',
  fileSize: 2000,
  description: 'ID card',
  createdAt: '2026-08-01T00:00:00.000000Z',
);

void main() {
  late _MockAttachmentApi mockApi;
  late AttachmentRepository repository;

  setUp(() {
    mockApi = _MockAttachmentApi();
    repository = AttachmentRepository(mockApi);
  });

  test(
    'fetchAttachments delegates the entity path prefix to the api',
    () async {
      when(
        () => mockApi.list('customers/01CUST'),
      ).thenAnswer((_) async => [_attachment]);

      expect(await repository.fetchAttachments('customers/01CUST'), [
        _attachment,
      ]);
    },
  );

  test('fetchAttachments throws ApiException on failure', () async {
    when(() => mockApi.list('customers/01CUST')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/customers/01CUST/attachments'),
        response: Response(
          requestOptions: RequestOptions(path: '/customers/01CUST/attachments'),
          statusCode: 404,
          data: {
            'success': false,
            'message': 'Not found.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchAttachments('customers/01CUST'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });

  test(
    'uploadAttachment delegates the exact file path, name, and description to the api',
    () async {
      when(
        () => mockApi.upload(
          entityPathPrefix: 'customers/01CUST',
          filePath: '/tmp/id-card.pdf',
          fileName: 'id-card.pdf',
          description: 'ID card',
        ),
      ).thenAnswer((_) async => _attachment);

      final result = await repository.uploadAttachment(
        entityPathPrefix: 'customers/01CUST',
        filePath: '/tmp/id-card.pdf',
        fileName: 'id-card.pdf',
        description: 'ID card',
      );

      expect(result, _attachment);
    },
  );

  test('uploadAttachment throws ApiException on a read-only 403', () async {
    when(
      () => mockApi.upload(
        entityPathPrefix: 'customers/01CUST',
        filePath: '/tmp/id-card.pdf',
        fileName: 'id-card.pdf',
        description: null,
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/customers/01CUST/attachments'),
        response: Response(
          requestOptions: RequestOptions(path: '/customers/01CUST/attachments'),
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
      () => repository.uploadAttachment(
        entityPathPrefix: 'customers/01CUST',
        filePath: '/tmp/id-card.pdf',
        fileName: 'id-card.pdf',
      ),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });

  test('deleteAttachment delegates to the api', () async {
    when(
      () => mockApi.delete('customers/01CUST', '1'),
    ).thenAnswer((_) async {});

    await repository.deleteAttachment('customers/01CUST', '1');

    verify(() => mockApi.delete('customers/01CUST', '1')).called(1);
  });

  test(
    'deleteAttachment throws ApiException on a 403 (not the uploader)',
    () async {
      when(() => mockApi.delete('customers/01CUST', '1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/customers/01CUST/attachments/1',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/customers/01CUST/attachments/1',
            ),
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
        () => repository.deleteAttachment('customers/01CUST', '1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    },
  );
}
