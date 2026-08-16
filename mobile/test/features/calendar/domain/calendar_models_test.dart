import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/calendar/domain/calendar_data.dart';
import 'package:mobile/features/calendar/domain/calendar_entry.dart';

void main() {
  group('CalendarEntry', () {
    test('parses a due_date entry with a label', () {
      final entry = CalendarEntry.fromJson({
        'type': 'due_date',
        'date': '2026-08-10',
        'related_entity_type': 'debt',
        'related_entity_id': '01DEBT',
        'label': 'INV-1001',
      });

      expect(entry.type, 'due_date');
      expect(entry.date, '2026-08-10');
      expect(entry.relatedEntityType, 'debt');
      expect(entry.relatedEntityId, '01DEBT');
      expect(entry.label, 'INV-1001');
    });

    test('parses a promise_to_pay entry with a null label', () {
      final entry = CalendarEntry.fromJson({
        'type': 'promise_to_pay',
        'date': '2026-08-12',
        'related_entity_type': 'promise_to_pay',
        'related_entity_id': '01PROMISE',
        'label': null,
      });

      expect(entry.type, 'promise_to_pay');
      expect(entry.label, isNull);
    });

    test('parses a follow_up entry whose related_entity_id is the debt id', () {
      final entry = CalendarEntry.fromJson({
        'type': 'follow_up',
        'date': '2026-08-05',
        'related_entity_type': 'debt',
        'related_entity_id': '01DEBT',
        'label': 'call_logged',
      });

      expect(entry.type, 'follow_up');
      expect(entry.relatedEntityType, 'debt');
      expect(entry.label, 'call_logged');
    });

    test('parses a reminder entry carrying the reminder type label', () {
      final entry = CalendarEntry.fromJson({
        'type': 'reminder',
        'date': '2026-08-07',
        'related_entity_type': 'reminder',
        'related_entity_id': '01REM',
        'label': 'Client Visit',
      });

      expect(entry.type, 'reminder');
      expect(entry.relatedEntityType, 'reminder');
      expect(entry.label, 'Client Visit');
    });
  });

  group('CalendarData', () {
    test('parses the from/to/entries envelope from GET /calendar', () {
      final data = CalendarData.fromJson({
        'from': '2026-08-01',
        'to': '2026-08-31',
        'entries': [
          {
            'type': 'due_date',
            'date': '2026-08-10',
            'related_entity_type': 'debt',
            'related_entity_id': '01DEBT',
            'label': 'INV-1001',
          },
        ],
      });

      expect(data.from, '2026-08-01');
      expect(data.to, '2026-08-31');
      expect(data.entries, hasLength(1));
      expect(data.entries.single.type, 'due_date');
    });

    test('parses an empty entries array', () {
      final data = CalendarData.fromJson({
        'from': '2026-08-01',
        'to': '2026-08-31',
        'entries': [],
      });

      expect(data.entries, isEmpty);
    });
  });
}
