import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/account/presentation/screens/close_account_screen.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

void main() {
  late _MockAuthApi mockApi;
  late _MockSecureTokenStorage mockStorage;

  setUp(() {
    // Mobile Fix #17: closeAccount() now also clears the biometric
    // preference via the real SharedPreferences-backed storage.
    SharedPreferences.setMockInitialValues({});
    mockApi = _MockAuthApi();
    mockStorage = _MockSecureTokenStorage();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/account/close-account',
      routes: [
        GoRoute(
          path: '/account/close-account',
          builder: (_, _) => const CloseAccountScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login Screen')),
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(mockApi),
        secureTokenStorageProvider.overrideWithValue(mockStorage),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            SomaliMaterialLocalizationsDelegate(),
            SomaliCupertinoLocalizationsDelegate(),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows the warning explanation and a password field', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(
      find.text('What happens when you close your account'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Enter your password to confirm'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'Close My Account'),
      findsOneWidget,
    );
  });

  testWidgets(
    'submitting with an empty password shows a validation error and calls nothing',
    (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Close My Account'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
      verifyNever(() => mockApi.closeAccount(password: any(named: 'password')));
    },
  );

  testWidgets(
    'submitting a password shows a confirmation dialog before calling the endpoint',
    (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField), 'CorrectPassword123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Close My Account'));
      await tester.pumpAndSettle();

      expect(find.text('Close your account?'), findsOneWidget);
      verifyNever(() => mockApi.closeAccount(password: any(named: 'password')));
    },
  );

  testWidgets('cancelling the confirmation dialog does not call the endpoint', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), 'CorrectPassword123!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Close My Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => mockApi.closeAccount(password: any(named: 'password')));
    expect(find.text('Close your account?'), findsNothing);
  });

  testWidgets(
    'confirming closes the account, clears the session, and the auth state becomes Unauthenticated',
    (tester) async {
      when(
        () => mockApi.closeAccount(password: 'CorrectPassword123!'),
      ).thenAnswer((_) async {});
      when(() => mockStorage.clear()).thenAnswer((_) async {});

      final container = await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField), 'CorrectPassword123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Close My Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, Close Account'));
      await tester.pumpAndSettle();

      verify(
        () => mockApi.closeAccount(password: 'CorrectPassword123!'),
      ).called(1);
      verify(() => mockStorage.clear()).called(1);
      expect(container.read(authProvider), isA<Unauthenticated>());
    },
  );

  testWidgets(
    'shows the real server error and stays on the screen when the password is wrong',
    (tester) async {
      when(() => mockApi.closeAccount(password: 'WrongPassword123!')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'account/close'),
          response: Response(
            requestOptions: RequestOptions(path: 'account/close'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The current password is incorrect.',
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final container = await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField), 'WrongPassword123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Close My Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, Close Account'));
      await tester.pumpAndSettle();

      expect(find.text('The current password is incorrect.'), findsOneWidget);
      expect(container.read(authProvider), isNot(isA<Unauthenticated>()));
      verifyNever(() => mockStorage.clear());
    },
  );

  testWidgets(
    'surfaces a field-specific 422 error inline on the password field (not just the combined message)',
    (tester) async {
      when(() => mockApi.closeAccount(password: 'WrongPassword123!')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'account/close'),
          response: Response(
            requestOptions: RequestOptions(path: 'account/close'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'password': ['The password field is incorrect.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField), 'WrongPassword123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Close My Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, Close Account'));
      await tester.pumpAndSettle();

      expect(find.text('The password field is incorrect.'), findsOneWidget);
    },
  );

  testWidgets(
    'the password field is obscured by default and reveals via the eye icon',
    (tester) async {
      await pumpScreen(tester);

      final passwordField = find.descendant(
        of: find.widgetWithText(
          TextFormField,
          'Enter your password to confirm',
        ),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    },
  );
}
