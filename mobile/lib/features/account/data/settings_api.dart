import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/system_settings.dart';

final settingsApiProvider = Provider<SettingsApi>((ref) => SettingsApi(ref.read(dioProvider)));

class SettingsApi {
  final Dio _dio;
  const SettingsApi(this._dio);

  Future<SystemSettings> fetch() async {
    final response = await _dio.get('admin/settings/preferences');
    final systemSettings = response.data['data']['system_settings'] as Map<String, dynamic>;
    return SystemSettings.fromJson(systemSettings);
  }

  Future<SystemSettings> update({
    required String defaultCreditLimit,
    required bool creditLimitReminderEnabled,
    String? softLimitWarningThreshold,
    required List<int> whatsappReminderDays,
    required List<int> smsReminderDays,
    required List<int> callReminderDays,
    int? professionalCollectionThresholdDays,
    required bool pushNotificationsEnabled,
    required bool reminderNotificationsEnabled,
    required bool paymentNotificationsEnabled,
  }) async {
    final response = await _dio.put('admin/settings/preferences', data: {
      'default_credit_limit': defaultCreditLimit,
      'credit_limit_reminder_enabled': creditLimitReminderEnabled,
      'soft_limit_warning_threshold': ?softLimitWarningThreshold,
      'whatsapp_reminder_days': whatsappReminderDays,
      'sms_reminder_days': smsReminderDays,
      'call_reminder_days': callReminderDays,
      'professional_collection_threshold_days': ?professionalCollectionThresholdDays,
      'notification_settings': {
        'push_enabled': pushNotificationsEnabled,
        'reminder_enabled': reminderNotificationsEnabled,
        'payment_enabled': paymentNotificationsEnabled,
      },
    });
    final systemSettings = response.data['data']['system_settings'] as Map<String, dynamic>;
    return SystemSettings.fromJson(systemSettings);
  }
}
