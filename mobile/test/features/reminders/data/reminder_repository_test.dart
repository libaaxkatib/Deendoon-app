import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/reminders/data/reminder_api.dart';
import 'package:mobile/features/reminders/data/reminder_repository.dart';
import 'package:mobile/features/reminders/domain/message_template.dart';
import 'package:mobile/features/reminders/domain/reminder.dart';
import 'package:mobile/features/reminders/domain/reminder_page.dart';
import 'package:mobile/features/reminders/domain/reminder_summary.dart';
import 'package:mobile/core/models/sent_message.dart';
import 'package:mocktail/mocktail.dart';

class _MockReminderApi extends Mock implements ReminderApi {}

const _reminder = Reminder(
  id: '1',
  type: 'payment_due',
  title: 'Payment Due',
  relatedEntityType: 'debt',
  relatedEntityId: '01DEBT',
  relatedCaseId: null,
  dueDate: '2026-08-01T10:00:00.000000Z',
  amountDue: '250.00',
  timingRule: 'one_day_before',
  customFireAt: null,
  deliveryMethods: ['in_app'],
  notes: null,
  status: 'upcoming',
  createdByUserId: '01USER',
  createdAt: '2026-07-25T09:00:00.000000Z',
  updatedAt: '2026-07-25T09:00:00.000000Z',
  completedAt: null,
  checkedInAt: null,
);

void main() {
  late _MockReminderApi mockApi;
  late ReminderRepository repository;

  setUp(() {
    mockApi = _MockReminderApi();
    repository = ReminderRepository(mockApi);
  });

  test('fetchSummary delegates to the api', () async {
    const summary = ReminderSummary(
      totalDueToday: 3,
      overdueCount: 1,
      clientVisits: 1,
      followUpCalls: 1,
      paymentsDue: 1,
      contractRenewals: 0,
      promisesToPay: 0,
    );
    when(() => mockApi.summary()).thenAnswer((_) async => summary);

    expect(await repository.fetchSummary(), summary);
  });

  test('fetchReminders passes tab through and returns the page', () async {
    const page = ReminderPage(
      reminders: [_reminder],
      currentPage: 1,
      lastPage: 2,
      total: 21,
    );
    when(
      () => mockApi.list(page: 1, tab: 'today'),
    ).thenAnswer((_) async => page);

    final result = await repository.fetchReminders(page: 1, tab: 'today');

    expect(result.reminders, [_reminder]);
  });

  test('fetchReminders throws ApiException on failure', () async {
    when(() => mockApi.list(page: 1, tab: null)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reminders'),
        response: Response(
          requestOptions: RequestOptions(path: '/reminders'),
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
      () => repository.fetchReminders(page: 1),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('fetchReminder returns the reminder straight through', () async {
    when(() => mockApi.show('1')).thenAnswer((_) async => _reminder);

    expect(await repository.fetchReminder('1'), _reminder);
  });

  test('createReminder delegates every field to the api', () async {
    when(
      () => mockApi.create(
        type: 'payment_due',
        relatedEntityType: 'customer',
        relatedEntityId: '01CUST',
        relatedCaseId: null,
        dueDate: '2026-08-01T10:00:00.000',
        amountDue: '250.00',
        timingRule: 'same_day',
        customFireAt: null,
        deliveryMethods: ['in_app', 'sms'],
        notes: 'Please pay soon',
      ),
    ).thenAnswer((_) async => _reminder);

    final result = await repository.createReminder(
      type: 'payment_due',
      relatedEntityType: 'customer',
      relatedEntityId: '01CUST',
      dueDate: '2026-08-01T10:00:00.000',
      amountDue: '250.00',
      timingRule: 'same_day',
      deliveryMethods: ['in_app', 'sms'],
      notes: 'Please pay soon',
    );

    expect(result, _reminder);
  });

  test('completeReminder delegates to the api', () async {
    when(() => mockApi.complete('1')).thenAnswer((_) async => _reminder);

    expect(await repository.completeReminder('1'), _reminder);
  });

  test('checkInReminder delegates to the api', () async {
    when(() => mockApi.checkIn('1')).thenAnswer((_) async => _reminder);

    expect(await repository.checkInReminder('1'), _reminder);
  });

  test('deleteReminder delegates to the api', () async {
    when(() => mockApi.delete('1')).thenAnswer((_) async {});

    await repository.deleteReminder('1');

    verify(() => mockApi.delete('1')).called(1);
  });

  test('sendReminder delegates to the api', () async {
    const sentMessage = SentMessage(
      id: '1',
      reminderId: '1',
      caseId: null,
      documentType: null,
      documentId: null,
      channel: 'whatsapp',
      recipientPhone: '+252612345678',
      renderedText: 'Hi there',
      status: 'sent',
      sentAt: '2026-07-28T10:00:00.000000Z',
    );
    when(
      () => mockApi.send(id: '1', channel: 'whatsapp', templateId: '01TPL'),
    ).thenAnswer((_) async => sentMessage);

    final result = await repository.sendReminder(
      id: '1',
      channel: 'whatsapp',
      templateId: '01TPL',
    );

    expect(result, sentMessage);
  });

  test('fetchMessageTemplates delegates to the api', () async {
    const template = MessageTemplate(
      id: '1',
      name: 'Reminder',
      channel: 'whatsapp',
      body: 'Hi {customer_name}',
      createdAt: '2026-07-01T00:00:00.000000Z',
      updatedAt: '2026-07-01T00:00:00.000000Z',
    );
    when(
      () => mockApi.messageTemplates(channel: 'whatsapp'),
    ).thenAnswer((_) async => [template]);

    expect(await repository.fetchMessageTemplates(channel: 'whatsapp'), [
      template,
    ]);
  });

  test('renderMessage delegates to the api', () async {
    when(
      () => mockApi.renderMessage(templateId: '1', reminderId: '2'),
    ).thenAnswer(
      (_) async => {
        'rendered_text': 'Hi there',
        'recipient_name': 'Moshe',
        'recipient_phone': '+252612345678',
      },
    );

    final result = await repository.renderMessage(
      templateId: '1',
      reminderId: '2',
    );

    expect(result['recipient_name'], 'Moshe');
  });

  test('Fix #23: renderMessage forwards phoneNumberId to the api', () async {
    when(
      () => mockApi.renderMessage(
        templateId: '1',
        reminderId: '2',
        phoneNumberId: 'p2',
      ),
    ).thenAnswer(
      (_) async => {
        'rendered_text': 'Hi there',
        'recipient_name': 'Moshe',
        'recipient_phone': '+252699999999',
      },
    );

    final result = await repository.renderMessage(
      templateId: '1',
      reminderId: '2',
      phoneNumberId: 'p2',
    );

    expect(result['recipient_phone'], '+252699999999');
  });
}
