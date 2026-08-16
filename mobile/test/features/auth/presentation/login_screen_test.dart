import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

Future<void> _pumpLoginScreen(
  WidgetTester tester, {
  required AuthApi authApi,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authApiProvider.overrideWithValue(authApi)],
      child: MaterialApp(
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
        home: const LoginScreen(),
      ),
    ),
  );
}

void main() {
  late _MockAuthApi mockApi;

  setUp(() {
    mockApi = _MockAuthApi();
  });

  testWidgets('renders email and password fields with a submit button', (
    tester,
  ) async {
    await _pumpLoginScreen(tester, authApi: mockApi);

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitted empty', (tester) async {
    await _pumpLoginScreen(tester, authApi: mockApi);

    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(() => mockApi.login(any(), any()));
  });

  testWidgets('surfaces the API error message on invalid credentials', (
    tester,
  ) async {
    when(() => mockApi.login('test@example.com', 'wrong')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 401,
          data: {
            'success': false,
            'message': 'Invalid credentials',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await _pumpLoginScreen(tester, authApi: mockApi);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong',
    );
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets(
    'the password field is obscured by default and reveals via the eye icon',
    (tester) async {
      await _pumpLoginScreen(tester, authApi: mockApi);

      final passwordField = find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    },
  );

  testWidgets(
    'surfaces a field-specific 422 validation error inline on the Email field, not as a combined message',
    (tester) async {
      when(() => mockApi.login('taken@example.com', 'ValidPass123!')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'email': ['The selected email is invalid.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpLoginScreen(tester, authApi: mockApi);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'taken@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'ValidPass123!',
      );
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Shown exactly once — on the field, not duplicated as a combined
      // message below the form (Mobile Fix #10, Decision 2).
      expect(find.text('The selected email is invalid.'), findsOneWidget);
    },
  );

  testWidgets(
    'shows distinct inline errors when the backend returns multiple simultaneous field errors',
    (tester) async {
      when(() => mockApi.login('bad@example.com', 'short')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'email': ['The selected email is invalid.'],
                'password': ['The password field is required.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpLoginScreen(tester, authApi: mockApi);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bad@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'short',
      );
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('The selected email is invalid.'), findsOneWidget);
      expect(find.text('The password field is required.'), findsOneWidget);
    },
  );

  testWidgets(
    'a stale field error is cleared before resubmitting, so a fixed value is not blocked from a fresh attempt',
    (tester) async {
      when(() => mockApi.login('taken@example.com', 'ValidPass123!')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'email': ['The selected email is invalid.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      when(() => mockApi.login('fixed@example.com', 'ValidPass123!')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 401,
            data: {
              'success': false,
              'message': 'Invalid credentials',
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpLoginScreen(tester, authApi: mockApi);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'taken@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'ValidPass123!',
      );
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('The selected email is invalid.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'fixed@example.com',
      );
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('The selected email is invalid.'), findsNothing);
      expect(find.text('Invalid credentials'), findsOneWidget);
      verify(
        () => mockApi.login('fixed@example.com', 'ValidPass123!'),
      ).called(1);
    },
  );
}
