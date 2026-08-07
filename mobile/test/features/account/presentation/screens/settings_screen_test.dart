import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/biometrics/biometric_auth_service.dart';
import 'package:mobile/core/localization/locale_provider.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/account/data/settings_repository.dart';
import 'package:mobile/features/account/domain/system_settings.dart';
import 'package:mobile/features/account/presentation/screens/settings_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockBiometricAuthService extends Mock implements BiometricAuthService {}

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
  reminderNotificationsEnabled: false,
  paymentNotificationsEnabled: false,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockSettingsRepository repository,
  required _MockBiometricAuthService biometricAuthService,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        biometricAuthServiceProvider.overrideWithValue(biometricAuthService),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(localeProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            SomaliMaterialLocalizationsDelegate(),
            SomaliCupertinoLocalizationsDelegate(),
          ],
          home: const SettingsScreen(),
        ),
      ),
    ),
  );
}

void main() {
  late _MockSettingsRepository mockRepository;
  late _MockBiometricAuthService mockBiometricAuthService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepository = _MockSettingsRepository();
    mockBiometricAuthService = _MockBiometricAuthService();
    when(() => mockBiometricAuthService.isSupported()).thenAnswer((_) async => false);
  });

  testWidgets('shows a retry affordance when settings fail to load', (tester) async {
    when(() => mockRepository.fetchSettings()).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository, biometricAuthService: mockBiometricAuthService);
    await tester.pumpAndSettle();

    expect(find.text('Could not load Settings.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('prefills the business and notification fields with the real settings', (tester) async {
    when(() => mockRepository.fetchSettings()).thenAnswer((_) async => _settings);

    await _pumpScreen(tester, repository: mockRepository, biometricAuthService: mockBiometricAuthService);
    await tester.pumpAndSettle();

    expect(find.text('500.00'), findsOneWidget);
    expect(find.text('80.00'), findsOneWidget);
    expect(find.text('1, 3, 7'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('shows Coming soon for biometric login when the device does not support it', (tester) async {
    when(() => mockRepository.fetchSettings()).thenAnswer((_) async => _settings);

    await _pumpScreen(tester, repository: mockRepository, biometricAuthService: mockBiometricAuthService);
    await tester.pumpAndSettle();

    expect(find.text('Biometric Login'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('shows a validation error instead of saving an empty default credit limit', (tester) async {
    when(() => mockRepository.fetchSettings()).thenAnswer((_) async => _settings);

    await _pumpScreen(tester, repository: mockRepository, biometricAuthService: mockBiometricAuthService);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Default Credit Limit'), '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    verifyNever(() => mockRepository.updateSettings(
          defaultCreditLimit: any(named: 'defaultCreditLimit'),
          creditLimitReminderEnabled: any(named: 'creditLimitReminderEnabled'),
          whatsappReminderDays: any(named: 'whatsappReminderDays'),
          smsReminderDays: any(named: 'smsReminderDays'),
          callReminderDays: any(named: 'callReminderDays'),
          pushNotificationsEnabled: any(named: 'pushNotificationsEnabled'),
          reminderNotificationsEnabled: any(named: 'reminderNotificationsEnabled'),
          paymentNotificationsEnabled: any(named: 'paymentNotificationsEnabled'),
        ));
  });

  testWidgets('shows a validation error for a soft limit threshold above 100', (tester) async {
    when(() => mockRepository.fetchSettings()).thenAnswer((_) async => _settings);

    await _pumpScreen(tester, repository: mockRepository, biometricAuthService: mockBiometricAuthService);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Soft Limit Warning Threshold (%)'), '150');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a value between 0 and 100'), findsOneWidget);
  });

  testWidgets('saves the entered fields and shows a success message', (tester) async {
    when(() => mockRepository.fetchSettings()).thenAnswer((_) async => _settings);
    when(() => mockRepository.updateSettings(
          defaultCreditLimit: '500.00',
          creditLimitReminderEnabled: true,
          softLimitWarningThreshold: '80.00',
          whatsappReminderDays: [1, 3, 7],
          smsReminderDays: [3],
          callReminderDays: [7],
          professionalCollectionThresholdDays: 30,
          pushNotificationsEnabled: true,
          reminderNotificationsEnabled: false,
          paymentNotificationsEnabled: false,
        )).thenAnswer((_) async => _settings);

    await _pumpScreen(tester, repository: mockRepository, biometricAuthService: mockBiometricAuthService);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Settings updated successfully'), findsOneWidget);
    verify(() => mockRepository.updateSettings(
          defaultCreditLimit: '500.00',
          creditLimitReminderEnabled: true,
          softLimitWarningThreshold: '80.00',
          whatsappReminderDays: [1, 3, 7],
          smsReminderDays: [3],
          callReminderDays: [7],
          professionalCollectionThresholdDays: 30,
          pushNotificationsEnabled: true,
          reminderNotificationsEnabled: false,
          paymentNotificationsEnabled: false,
        )).called(1);
  });

  testWidgets('shows the real server error message when saving fails', (tester) async {
    when(() => mockRepository.fetchSettings()).thenAnswer((_) async => _settings);
    when(() => mockRepository.updateSettings(
          defaultCreditLimit: any(named: 'defaultCreditLimit'),
          creditLimitReminderEnabled: any(named: 'creditLimitReminderEnabled'),
          softLimitWarningThreshold: any(named: 'softLimitWarningThreshold'),
          whatsappReminderDays: any(named: 'whatsappReminderDays'),
          smsReminderDays: any(named: 'smsReminderDays'),
          callReminderDays: any(named: 'callReminderDays'),
          professionalCollectionThresholdDays: any(named: 'professionalCollectionThresholdDays'),
          pushNotificationsEnabled: any(named: 'pushNotificationsEnabled'),
          reminderNotificationsEnabled: any(named: 'reminderNotificationsEnabled'),
          paymentNotificationsEnabled: any(named: 'paymentNotificationsEnabled'),
        )).thenThrow(const ApiException(message: 'Something went wrong. Please try again.'));

    await _pumpScreen(tester, repository: mockRepository, biometricAuthService: mockBiometricAuthService);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.text('Settings updated successfully'), findsNothing);
  });

  testWidgets('switching the language dropdown to Somali updates the whole screen immediately', (tester) async {
    when(() => mockRepository.fetchSettings()).thenAnswer((_) async => _settings);

    await _pumpScreen(tester, repository: mockRepository, biometricAuthService: mockBiometricAuthService);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Somali').last);
    await tester.pumpAndSettle();

    expect(find.text('Dejinta'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
  });
}
