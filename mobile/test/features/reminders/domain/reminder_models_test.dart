import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reminders/domain/message_template.dart';
import 'package:mobile/features/reminders/domain/reminder.dart';
import 'package:mobile/features/reminders/domain/reminder_page.dart';
import 'package:mobile/features/reminders/domain/reminder_summary.dart';
import 'package:mobile/core/models/sent_message.dart';

Map<String, dynamic> _reminderJson({
  String status = 'upcoming',
  String? relatedCaseId,
  String? amountDue,
  String? completedAt,
}) => {
  'id': '01REM',
  'type': 'payment_due',
  'title': 'Payment Due',
  'related_entity_type': 'debt',
  'related_entity_id': '01DEBT',
  'related_case_id': relatedCaseId,
  'due_date': '2026-08-01T10:00:00.000000Z',
  'amount_due': amountDue,
  'timing_rule': 'one_day_before',
  'custom_fire_at': null,
  'delivery_methods': ['in_app', 'whatsapp'],
  'notes': 'Call before visiting',
  'status': status,
  'created_by_user_id': '01USER',
  'created_at': '2026-07-25T09:00:00.000000Z',
  'updated_at': '2026-07-25T09:00:00.000000Z',
  'completed_at': completedAt,
};

void main() {
  group('Reminder', () {
    test('parses the exact ReminderResource shape', () {
      final reminder = Reminder.fromJson(_reminderJson(amountDue: '250.00'));

      expect(reminder.id, '01REM');
      expect(reminder.type, 'payment_due');
      expect(reminder.title, 'Payment Due');
      expect(reminder.relatedEntityType, 'debt');
      expect(reminder.relatedEntityId, '01DEBT');
      expect(reminder.relatedCaseId, isNull);
      expect(reminder.dueDate, '2026-08-01T10:00:00.000000Z');
      expect(reminder.amountDue, '250.00');
      expect(reminder.timingRule, 'one_day_before');
      expect(reminder.deliveryMethods, ['in_app', 'whatsapp']);
      expect(reminder.notes, 'Call before visiting');
      expect(reminder.status, 'upcoming');
      expect(reminder.completedAt, isNull);
    });

    test('parses a completed reminder with a related case id', () {
      final reminder = Reminder.fromJson(
        _reminderJson(
          status: 'completed',
          relatedCaseId: '01CASE',
          completedAt: '2026-07-30T09:00:00.000000Z',
        ),
      );

      expect(reminder.status, 'completed');
      expect(reminder.relatedCaseId, '01CASE');
      expect(reminder.completedAt, '2026-07-30T09:00:00.000000Z');
    });

    test('parses a null amount_due for a type that does not carry one', () {
      final reminder = Reminder.fromJson(_reminderJson());

      expect(reminder.amountDue, isNull);
    });
  });

  group('ReminderPage', () {
    test('parses the reminders + pagination envelope from GET /reminders', () {
      final page = ReminderPage.fromJson({
        'reminders': [_reminderJson()],
        'pagination': {
          'current_page': 1,
          'per_page': 15,
          'total': 3,
          'last_page': 1,
        },
      });

      expect(page.reminders, hasLength(1));
      expect(page.currentPage, 1);
      expect(page.lastPage, 1);
      expect(page.total, 3);
    });
  });

  group('ReminderSummary', () {
    test(
      'parses total_due_today, overdue_count, and all five per_type keys',
      () {
        final summary = ReminderSummary.fromJson({
          'total_due_today': 7,
          'overdue_count': 2,
          'per_type': {
            'client_visit': 1,
            'follow_up_call': 2,
            'payment_due': 3,
            'contract_renewal': 0,
            'promise_to_pay': 1,
          },
        });

        expect(summary.totalDueToday, 7);
        expect(summary.overdueCount, 2);
        expect(summary.clientVisits, 1);
        expect(summary.followUpCalls, 2);
        expect(summary.paymentsDue, 3);
        expect(summary.contractRenewals, 0);
        expect(summary.promisesToPay, 1);
      },
    );

    test('defaults a missing per_type key to zero', () {
      final summary = ReminderSummary.fromJson({
        'total_due_today': 0,
        'overdue_count': 0,
        'per_type': <String, dynamic>{},
      });

      expect(summary.clientVisits, 0);
      expect(summary.promisesToPay, 0);
    });
  });

  group('MessageTemplate', () {
    test('parses the exact MessageTemplateResource shape', () {
      final template = MessageTemplate.fromJson({
        'id': '01TPL',
        'name': 'Friendly Reminder',
        'channel': 'whatsapp',
        'body':
            'Hi {customer_name}, your payment of {amount_due} is due {due_date}.',
        'created_at': '2026-07-01T00:00:00.000000Z',
        'updated_at': '2026-07-01T00:00:00.000000Z',
      });

      expect(template.id, '01TPL');
      expect(template.name, 'Friendly Reminder');
      expect(template.channel, 'whatsapp');
      expect(template.body, contains('{customer_name}'));
    });
  });

  group('SentMessage', () {
    test('parses the exact SentMessageResource shape', () {
      final sentMessage = SentMessage.fromJson({
        'id': '01SENT',
        'reminder_id': '01REM',
        'case_id': null,
        'document_type': null,
        'document_id': null,
        'channel': 'whatsapp',
        'recipient_phone': '+252612345678',
        'rendered_text': 'Hi Moshe, your payment of 250.00 is due Aug 1, 2026.',
        'status': 'sent',
        'sent_at': '2026-07-28T10:00:00.000000Z',
      });

      expect(sentMessage.id, '01SENT');
      expect(sentMessage.reminderId, '01REM');
      expect(sentMessage.caseId, isNull);
      expect(sentMessage.channel, 'whatsapp');
      expect(sentMessage.status, 'sent');
    });
  });
}
