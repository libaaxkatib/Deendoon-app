import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/system_settings.dart';
import 'settings_api.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.read(settingsApiProvider)),
);

class SettingsRepository {
  final SettingsApi _api;
  const SettingsRepository(this._api);

  Future<SystemSettings> fetchSettings() => _guard(() => _api.fetch());

  Future<SystemSettings> updateSettings({
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
  }) => _guard(
    () => _api.update(
      defaultCreditLimit: defaultCreditLimit,
      creditLimitReminderEnabled: creditLimitReminderEnabled,
      softLimitWarningThreshold: softLimitWarningThreshold,
      whatsappReminderDays: whatsappReminderDays,
      smsReminderDays: smsReminderDays,
      callReminderDays: callReminderDays,
      professionalCollectionThresholdDays: professionalCollectionThresholdDays,
      pushNotificationsEnabled: pushNotificationsEnabled,
      reminderNotificationsEnabled: reminderNotificationsEnabled,
      paymentNotificationsEnabled: paymentNotificationsEnabled,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
