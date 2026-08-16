import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/support_tickets/data/support_ticket_api.dart';
import 'package:mobile/features/support_tickets/data/support_ticket_repository.dart';
import 'package:mobile/features/support_tickets/domain/support_ticket.dart';
import 'package:mobile/features/support_tickets/domain/support_ticket_page.dart';
import 'package:mobile/features/support_tickets/domain/ticket_attachment.dart';
import 'package:mobile/features/support_tickets/domain/ticket_message.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportTicketApi extends Mock implements SupportTicketApi {}

const _ticket = SupportTicket(
  id: '1',
  tenantId: '01TENANT',
  referenceNumber: 'SUP-000001',
  subject: 'Cannot generate demand letter',
  description: 'The PDF fails to download.',
  status: 'open',
  priority: 'high',
  category: 'technical_issue',
  submittedByUserId: '01USER',
  businessName: 'Hodan Trading',
  createdAt: '2026-08-14T09:00:00.000000Z',
  updatedAt: '2026-08-14T09:00:00.000000Z',
  closedAt: null,
  reopenedAt: null,
);

void main() {
  late _MockSupportTicketApi mockApi;
  late SupportTicketRepository repository;

  setUp(() {
    mockApi = _MockSupportTicketApi();
    repository = SupportTicketRepository(mockApi);
  });

  test('fetchTickets passes status through and returns the page', () async {
    const page = SupportTicketPage(
      tickets: [_ticket],
      currentPage: 1,
      lastPage: 1,
      total: 1,
    );
    when(
      () => mockApi.list(page: 1, status: 'open'),
    ).thenAnswer((_) async => page);

    final result = await repository.fetchTickets(page: 1, status: 'open');

    expect(result.tickets, [_ticket]);
  });

  test('fetchTickets throws ApiException on failure', () async {
    when(() => mockApi.list(page: 1, status: null)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/support-tickets'),
        response: Response(
          requestOptions: RequestOptions(path: '/support-tickets'),
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
      () => repository.fetchTickets(page: 1),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('fetchTicket returns the ticket straight through', () async {
    when(() => mockApi.show('1')).thenAnswer((_) async => _ticket);

    expect(await repository.fetchTicket('1'), _ticket);
  });

  test('createTicket delegates every field to the api', () async {
    when(
      () => mockApi.create(
        subject: 'Cannot generate demand letter',
        description: 'The PDF fails to download.',
        priority: 'high',
        category: 'technical_issue',
      ),
    ).thenAnswer((_) async => _ticket);

    final result = await repository.createTicket(
      subject: 'Cannot generate demand letter',
      description: 'The PDF fails to download.',
      priority: 'high',
      category: 'technical_issue',
    );

    expect(result, _ticket);
  });

  test('fetchMessages delegates to the api', () async {
    const message = TicketMessage(
      id: '1',
      supportTicketId: '1',
      senderUserId: '01USER',
      senderName: 'Amina Ali',
      content: 'Any update?',
      createdAt: '2026-08-14T10:00:00.000000Z',
    );
    when(() => mockApi.messages('1')).thenAnswer((_) async => [message]);

    expect(await repository.fetchMessages('1'), [message]);
  });

  test('postMessage delegates to the api', () async {
    const message = TicketMessage(
      id: '2',
      supportTicketId: '1',
      senderUserId: '01USER',
      senderName: 'Amina Ali',
      content: 'Following up',
      createdAt: '2026-08-14T11:00:00.000000Z',
    );
    when(
      () => mockApi.postMessage(id: '1', content: 'Following up'),
    ).thenAnswer((_) async => message);

    final result = await repository.postMessage(
      id: '1',
      content: 'Following up',
    );

    expect(result, message);
  });

  test('fetchAttachments delegates to the api', () async {
    const attachment = TicketAttachment(
      id: '1',
      supportTicketId: '1',
      uploadedByUserId: '01USER',
      originalFilename: 'screenshot.pdf',
      mimeType: 'application/pdf',
      fileSize: 1024,
      createdAt: '2026-08-14T09:30:00.000000Z',
    );
    when(() => mockApi.attachments('1')).thenAnswer((_) async => [attachment]);

    expect(await repository.fetchAttachments('1'), [attachment]);
  });

  test('uploadAttachment delegates to the api', () async {
    const attachment = TicketAttachment(
      id: '2',
      supportTicketId: '1',
      uploadedByUserId: '01USER',
      originalFilename: 'log.pdf',
      mimeType: 'application/pdf',
      fileSize: 2048,
      createdAt: '2026-08-14T12:00:00.000000Z',
    );
    when(
      () => mockApi.uploadAttachment(
        id: '1',
        filePath: '/tmp/log.pdf',
        fileName: 'log.pdf',
      ),
    ).thenAnswer((_) async => attachment);

    final result = await repository.uploadAttachment(
      id: '1',
      filePath: '/tmp/log.pdf',
      fileName: 'log.pdf',
    );

    expect(result, attachment);
  });
}
