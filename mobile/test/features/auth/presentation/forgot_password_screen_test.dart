import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

Future<void> _pumpScreen(WidgetTester tester, {required AuthApi authApi}) async {
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
        home: const ForgotPasswordScreen(),
      ),
    ),
  );
}

void main() {
  late _MockAuthApi mockApi;

  setUp(() {
    mockApi = _MockAuthApi();
  });

  testWidgets('renders the email field and submit button', (tester) async {
    await _pumpScreen(tester, authApi: mockApi);

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets('shows a validation error when submitted empty', (tester) async {
    await _pumpScreen(tester, authApi: mockApi);

    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    verifyNever(() => mockApi.forgotPassword(any()));
  });

  testWidgets('shows the generic server message on success', (tester) async {
    when(() => mockApi.forgotPassword('test@example.com')).thenAnswer(
      (_) async => 'If an account with that email exists, a password reset link has been sent.',
    );

    await _pumpScreen(tester, authApi: mockApi);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.textContaining('password reset link has been sent'), findsOneWidget);
  });

  testWidgets('surfaces an API error message on failure', (tester) async {
    when(() => mockApi.forgotPassword('bad@example.com')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/forgot-password'),
        response: Response(
          requestOptions: RequestOptions(path: '/forgot-password'),
          statusCode: 429,
          data: {
            'success': false,
            'message': 'Too many attempts. Please try again later.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await _pumpScreen(tester, authApi: mockApi);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'bad@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Too many attempts. Please try again later.'), findsOneWidget);
  });
}
