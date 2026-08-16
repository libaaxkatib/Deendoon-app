import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/account/data/settings_api.dart';
import 'package:mobile/features/account/data/settings_repository.dart';
import 'package:mobile/features/account/domain/system_settings.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsApi extends Mock implements SettingsApi {}

const _settings = SystemSettings(
  id: '1',
  defaultCreditLimit: '500.00',
  creditLimitReminderEnabled: true,
  softLimitWarningThreshold: '80.00',
  whatsappReminderDays: [1, 3, 7],
  smsReminderDays: [3],
  callReminderDays: [7],
  professionalCollectionThresholdDays: 30,
  pushNotificationsEnabled: true,
  reminderNotificationsEnabled: true,
  paymentNotificationsEnabled: false,
);

void main() {
  late _MockSettingsApi mockApi;
  late SettingsRepository repository;

  setUp(() {
    mockApi = _MockSettingsApi();
    repository = SettingsRepository(mockApi);
  });

  test('fetchSettings returns the settings straight through', () async {
    when(() => mockApi.fetch()).thenAnswer((_) async => _settings);

    final result = await repository.fetchSettings();

    expect(result, _settings);
  });

  test('fetchSettings throws ApiException on failure', () async {
    when(() => mockApi.fetch()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: 'admin/settings/preferences'),
        response: Response(
          requestOptions: RequestOptions(path: 'admin/settings/preferences'),
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
      () => repository.fetchSettings(),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('updateSettings delegates every field to the api', () async {
    when(
      () => mockApi.update(
        defaultCreditLimit: '500.00',
        creditLimitReminderEnabled: true,
        softLimitWarningThreshold: '80.00',
        whatsappReminderDays: [1, 3, 7],
        smsReminderDays: [3],
        callReminderDays: [7],
        professionalCollectionThresholdDays: 30,
        pushNotificationsEnabled: true,
        reminderNotificationsEnabled: true,
        paymentNotificationsEnabled: false,
      ),
    ).thenAnswer((_) async => _settings);

    final result = await repository.updateSettings(
      defaultCreditLimit: '500.00',
      creditLimitReminderEnabled: true,
      softLimitWarningThreshold: '80.00',
      whatsappReminderDays: const [1, 3, 7],
      smsReminderDays: const [3],
      callReminderDays: const [7],
      professionalCollectionThresholdDays: 30,
      pushNotificationsEnabled: true,
      reminderNotificationsEnabled: true,
      paymentNotificationsEnabled: false,
    );

    expect(result, _settings);
    verify(
      () => mockApi.update(
        defaultCreditLimit: '500.00',
        creditLimitReminderEnabled: true,
        softLimitWarningThreshold: '80.00',
        whatsappReminderDays: [1, 3, 7],
        smsReminderDays: [3],
        callReminderDays: [7],
        professionalCollectionThresholdDays: 30,
        pushNotificationsEnabled: true,
        reminderNotificationsEnabled: true,
        paymentNotificationsEnabled: false,
      ),
    ).called(1);
  });

  test(
    'updateSettings surfaces field validation errors via ApiException',
    () async {
      when(
        () => mockApi.update(
          defaultCreditLimit: any(named: 'defaultCreditLimit'),
          creditLimitReminderEnabled: any(named: 'creditLimitReminderEnabled'),
          softLimitWarningThreshold: any(named: 'softLimitWarningThreshold'),
          whatsappReminderDays: any(named: 'whatsappReminderDays'),
          smsReminderDays: any(named: 'smsReminderDays'),
          callReminderDays: any(named: 'callReminderDays'),
          professionalCollectionThresholdDays: any(
            named: 'professionalCollectionThresholdDays',
          ),
          pushNotificationsEnabled: any(named: 'pushNotificationsEnabled'),
          reminderNotificationsEnabled: any(
            named: 'reminderNotificationsEnabled',
          ),
          paymentNotificationsEnabled: any(
            named: 'paymentNotificationsEnabled',
          ),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'admin/settings/preferences'),
          response: Response(
            requestOptions: RequestOptions(path: 'admin/settings/preferences'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'default_credit_limit': [
                  'The default credit limit field is required.',
                ],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.updateSettings(
          defaultCreditLimit: '',
          creditLimitReminderEnabled: true,
          whatsappReminderDays: const [],
          smsReminderDays: const [],
          callReminderDays: const [],
          pushNotificationsEnabled: false,
          reminderNotificationsEnabled: false,
          paymentNotificationsEnabled: false,
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    },
  );
}
