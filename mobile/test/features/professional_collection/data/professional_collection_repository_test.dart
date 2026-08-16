import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_api.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_attachment.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request_page.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_timeline_event.dart';
import 'package:mobile/features/professional_collection/domain/request_message.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionApi extends Mock
    implements ProfessionalCollectionApi {}

const _request = ProfessionalCollectionRequest(
  id: '1',
  collectionCaseId: '01CASE',
  referenceNumber: 'PCR-0001',
  status: 'submitted',
  submittedByUserId: '01USER',
  actionedByUserId: null,
  reasons: ['Repeated missed promises'],
  notes: 'Customer stopped responding.',
  requestedServices: ['Field Visit'],
  declarationAcceptedAt: '2026-08-01T00:00:00.000000Z',
  declarationAcceptedBy: '01USER',
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

  test('submit delegates the exact payload to the api', () async {
    when(
      () => mockApi.submit(
        caseId: '01CASE',
        reasons: ['Repeated missed promises'],
        services: ['Field Visit'],
        notes: 'Customer stopped responding.',
        declarationAccepted: true,
      ),
    ).thenAnswer((_) async => _request);

    final result = await repository.submit(
      caseId: '01CASE',
      reasons: ['Repeated missed promises'],
      services: ['Field Visit'],
      notes: 'Customer stopped responding.',
      declarationAccepted: true,
    );

    expect(result, _request);
  });

  test(
    'submit throws ApiException with the server message on a 409 conflict',
    () async {
      when(
        () => mockApi.submit(
          caseId: '01CASE',
          reasons: ['Repeated missed promises'],
          services: ['Field Visit'],
          notes: null,
          declarationAccepted: true,
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/collection-cases/01CASE/professional-requests',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/collection-cases/01CASE/professional-requests',
            ),
            statusCode: 409,
            data: {
              'success': false,
              'message':
                  'This Collection Case already has an active Professional Collection Request.',
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.submit(
          caseId: '01CASE',
          reasons: ['Repeated missed promises'],
          services: ['Field Visit'],
          notes: null,
          declarationAccepted: true,
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    },
  );

  test(
    'submit throws ApiException with field errors on a 422 validation failure',
    () async {
      when(
        () => mockApi.submit(
          caseId: '01CASE',
          reasons: [],
          services: [],
          notes: null,
          declarationAccepted: false,
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/collection-cases/01CASE/professional-requests',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/collection-cases/01CASE/professional-requests',
            ),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'reasons': ['The reasons field is required.'],
                'services': ['The services field is required.'],
                'declaration_accepted': [
                  'The declaration accepted field must be accepted.',
                ],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.submit(
          caseId: '01CASE',
          reasons: [],
          services: [],
          notes: null,
          declarationAccepted: false,
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    },
  );

  test(
    'fetchRequests passes page/status through and returns the page',
    () async {
      const page = ProfessionalCollectionRequestPage(
        requests: [_request],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      );
      when(
        () => mockApi.list(page: 1, status: 'submitted'),
      ).thenAnswer((_) async => page);

      final result = await repository.fetchRequests(
        page: 1,
        status: 'submitted',
      );

      expect(result.requests, [_request]);
    },
  );

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
    when(
      () => mockApi.postMessage(id: '1', content: 'Hello'),
    ).thenAnswer((_) async => _message);

    final result = await repository.postMessage(id: '1', content: 'Hello');

    expect(result, _message);
  });

  test(
    'postMessage throws ApiException with the server message on a 409 conflict',
    () async {
      when(() => mockApi.postMessage(id: '1', content: 'Hello')).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/professional-requests/1/messages',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/professional-requests/1/messages',
            ),
            statusCode: 409,
            data: {
              'success': false,
              'message':
                  'This Professional Collection Request is closed; new messages are not accepted.',
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.postMessage(id: '1', content: 'Hello'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    },
  );

  test('fetchDocuments delegates to the api', () async {
    const document = DocumentSummary(
      id: '1',
      documentType: 'receipt',
      referenceNumber: 'RCT-0001',
      generatedAt: '2026-08-01T00:00:00.000000Z',
      fileSize: 2000,
    );
    when(() => mockApi.documents('1')).thenAnswer((_) async => [document]);

    expect(await repository.fetchDocuments('1'), [document]);
  });

  test('fetchAttachments delegates to the api', () async {
    const attachment = ProfessionalCollectionAttachment(
      id: '1',
      professionalCollectionRequestId: '1',
      timelineEventId: null,
      uploadedByUserId: '01USER',
      originalFilename: 'evidence.pdf',
      mimeType: 'application/pdf',
      fileSize: 1500,
      createdAt: '2026-08-01T00:00:00.000000Z',
    );
    when(() => mockApi.attachments('1')).thenAnswer((_) async => [attachment]);

    expect(await repository.fetchAttachments('1'), [attachment]);
  });

  test(
    'uploadAttachment delegates the exact file path and name to the api',
    () async {
      const attachment = ProfessionalCollectionAttachment(
        id: '1',
        professionalCollectionRequestId: '1',
        timelineEventId: null,
        uploadedByUserId: '01USER',
        originalFilename: 'evidence.pdf',
        mimeType: 'application/pdf',
        fileSize: 1500,
        createdAt: '2026-08-01T00:00:00.000000Z',
      );
      when(
        () => mockApi.uploadAttachment(
          id: '1',
          filePath: '/tmp/evidence.pdf',
          fileName: 'evidence.pdf',
        ),
      ).thenAnswer((_) async => attachment);

      final result = await repository.uploadAttachment(
        id: '1',
        filePath: '/tmp/evidence.pdf',
        fileName: 'evidence.pdf',
      );

      expect(result, attachment);
    },
  );

  test('fetchTimeline delegates to the api', () async {
    const event = ProfessionalCollectionTimelineEvent(
      id: '1',
      professionalCollectionRequestId: '1',
      eventType: 'field_visit',
      officerUserId: '02USER',
      occurredAt: '2026-08-02T00:00:00.000000Z',
      notes: 'Visited the customer premises.',
      outcome: 'no_answer',
      attachments: [],
      createdAt: '2026-08-02T00:00:00.000000Z',
      updatedAt: '2026-08-02T00:00:00.000000Z',
    );
    when(() => mockApi.timeline('1')).thenAnswer((_) async => [event]);

    expect(await repository.fetchTimeline('1'), [event]);
  });
}
