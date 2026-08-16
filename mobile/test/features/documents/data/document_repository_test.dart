import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/core/models/sent_message.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/documents/data/document_api.dart';
import 'package:mobile/features/documents/data/document_repository.dart';
import 'package:mobile/features/documents/domain/document_event.dart';
import 'package:mobile/features/documents/domain/document_page.dart';
import 'package:mobile/features/documents/domain/storage_usage.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentApi extends Mock implements DocumentApi {}

const _document = DocumentSummary(
  id: '1',
  documentType: 'invoice',
  referenceNumber: 'INV-000123',
  generatedAt: '2026-07-20T10:00:00.000000Z',
  fileSize: 2048,
);

void main() {
  late _MockDocumentApi mockApi;
  late DocumentRepository repository;

  setUp(() {
    mockApi = _MockDocumentApi();
    repository = DocumentRepository(mockApi);
  });

  test(
    'fetchDocuments passes type/search through and returns the page',
    () async {
      const page = DocumentPage(
        documents: [_document],
        currentPage: 1,
        lastPage: 2,
        total: 21,
      );
      when(
        () => mockApi.list(page: 1, type: 'invoices', search: 'INV'),
      ).thenAnswer((_) async => page);

      final result = await repository.fetchDocuments(
        page: 1,
        type: 'invoices',
        search: 'INV',
      );

      expect(result.documents, [_document]);
    },
  );

  test('fetchDocuments throws ApiException on failure', () async {
    when(() => mockApi.list(page: 1, type: null, search: '')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/documents'),
        response: Response(
          requestOptions: RequestOptions(path: '/documents'),
          statusCode: 401,
          data: {
            'success': false,
            'message': 'Unauthenticated.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchDocuments(page: 1),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('fetchStorageUsage delegates to the api', () async {
    const usage = StorageUsage(
      usedBytes: 1024,
      totalBytes: 10737418240,
      usedPercentage: 0.01,
    );
    when(() => mockApi.storageUsage()).thenAnswer((_) async => usage);

    expect(await repository.fetchStorageUsage(), usage);
  });

  test('fetchDocument returns the document straight through', () async {
    when(() => mockApi.show('1')).thenAnswer((_) async => _document);

    expect(await repository.fetchDocument('1'), _document);
  });

  test('downloadDocument delegates to the api', () async {
    when(() => mockApi.download('1')).thenAnswer((_) async => [1, 2, 3]);

    expect(await repository.downloadDocument('1'), [1, 2, 3]);
  });

  test('fetchHistory delegates to the api', () async {
    const event = DocumentEvent(
      id: '1',
      documentType: 'invoice',
      documentId: '1',
      eventType: 'downloaded',
      userId: '01USER',
      occurredAt: '2026-07-28T10:00:00.000000Z',
    );
    when(() => mockApi.history('1')).thenAnswer((_) async => [event]);

    expect(await repository.fetchHistory('1'), [event]);
  });

  test('shareDocument delegates to the api', () async {
    const sentMessage = SentMessage(
      id: '1',
      reminderId: null,
      caseId: null,
      documentType: 'invoice',
      documentId: '1',
      channel: 'whatsapp',
      recipientPhone: '+252612345678',
      renderedText: 'Hi there',
      status: 'sent',
      sentAt: '2026-07-28T10:00:00.000000Z',
    );
    when(
      () => mockApi.share(id: '1', channel: 'whatsapp', templateId: '01TPL'),
    ).thenAnswer((_) async => sentMessage);

    final result = await repository.shareDocument(
      id: '1',
      channel: 'whatsapp',
      templateId: '01TPL',
    );

    expect(result, sentMessage);
  });
}
