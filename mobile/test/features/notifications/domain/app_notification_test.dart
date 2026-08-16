import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/domain/app_notification.dart';

Map<String, dynamic> _json({String? title, String? message, String? readAt}) =>
    {
      'id': '1',
      'type': 'admin_announcement',
      'title': title,
      'message': message,
      'related_entity_type': 'announcement',
      'related_entity_id': 'batch-1',
      'read_at': readAt,
      'created_at': '2026-08-01T09:00:00.000000Z',
    };

void main() {
  test('parses title and message when present', () {
    final notification = AppNotification.fromJson(
      _json(title: 'Heads up', message: 'Body text'),
    );

    expect(notification.title, 'Heads up');
    expect(notification.message, 'Body text');
  });

  test(
    'title and message are null when absent, matching every pre-existing notification type',
    () {
      final notification = AppNotification.fromJson(_json());

      expect(notification.title, isNull);
      expect(notification.message, isNull);
    },
  );

  test('isRead reflects read_at', () {
    expect(AppNotification.fromJson(_json(readAt: null)).isRead, isFalse);
    expect(
      AppNotification.fromJson(
        _json(readAt: '2026-08-02T09:00:00.000000Z'),
      ).isRead,
      isTrue,
    );
  });
}
