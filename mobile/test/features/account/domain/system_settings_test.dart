import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/account/domain/system_settings.dart';

void main() {
  test('parses the exact SystemSettingResource shape', () {
    final settings = SystemSettings.fromJson({
      'id': '1',
      'default_credit_limit': '500.00',
      'credit_limit_reminder_enabled': true,
      'soft_limit_warning_threshold': '80.00',
      'whatsapp_reminder_days': [1, 3, 7],
      'sms_reminder_days': [3],
      'call_reminder_days': [7],
      'professional_collection_threshold_days': 30,
      'notification_settings': {
        'push_enabled': true,
        'reminder_enabled': true,
        'payment_enabled': false,
      },
      'updated_at': '2026-08-03T12:00:00.000000Z',
    });

    expect(settings.id, '1');
    expect(settings.defaultCreditLimit, '500.00');
    expect(settings.creditLimitReminderEnabled, true);
    expect(settings.softLimitWarningThreshold, '80.00');
    expect(settings.whatsappReminderDays, [1, 3, 7]);
    expect(settings.smsReminderDays, [3]);
    expect(settings.callReminderDays, [7]);
    expect(settings.professionalCollectionThresholdDays, 30);
    expect(settings.pushNotificationsEnabled, true);
    expect(settings.reminderNotificationsEnabled, true);
    expect(settings.paymentNotificationsEnabled, false);
  });

  test(
    'defaults every nullable field to a safe value on a freshly-created row',
    () {
      final settings = SystemSettings.fromJson({
        'id': '2',
        'default_credit_limit': '0.00',
        'credit_limit_reminder_enabled': true,
        'soft_limit_warning_threshold': null,
        'whatsapp_reminder_days': null,
        'sms_reminder_days': null,
        'call_reminder_days': null,
        'professional_collection_threshold_days': null,
        'notification_settings': null,
        'updated_at': '2026-08-03T12:00:00.000000Z',
      });

      expect(settings.softLimitWarningThreshold, isNull);
      expect(settings.whatsappReminderDays, isEmpty);
      expect(settings.smsReminderDays, isEmpty);
      expect(settings.callReminderDays, isEmpty);
      expect(settings.professionalCollectionThresholdDays, isNull);
      expect(settings.pushNotificationsEnabled, false);
      expect(settings.reminderNotificationsEnabled, false);
      expect(settings.paymentNotificationsEnabled, false);
    },
  );
}
