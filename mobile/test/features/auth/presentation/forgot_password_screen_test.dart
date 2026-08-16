import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/router/route_paths.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

Future<void> _pumpScreen(
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
      (_) async =>
          'If an account with that email exists, a password reset link has been sent.',
    );

    await _pumpScreen(tester, authApi: mockApi);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'test@example.com',
    );
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('password reset link has been sent'),
      findsOneWidget,
    );
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'bad@example.com',
    );
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(
      find.text('Too many attempts. Please try again later.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'surfaces a field-specific 422 validation error inline on the Email field',
    (tester) async {
      when(() => mockApi.forgotPassword('bad@example.com')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/forgot-password'),
          response: Response(
            requestOptions: RequestOptions(path: '/forgot-password'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'email': ['The email field must be a valid email address.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpScreen(tester, authApi: mockApi);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bad@example.com',
      );
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(
        find.text('The email field must be a valid email address.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'after a successful submission, "I already have a reset code" navigates to Reset Password with the email pre-filled',
    (tester) async {
      when(() => mockApi.forgotPassword('test@example.com')).thenAnswer(
        (_) async =>
            'If an account with that email exists, a password reset link has been sent.',
      );

      // Mirrors app_router.dart's real /reset-password registration exactly
      // (builder reads `state.extra as String?` into `initialEmail`), so
      // this exercises the real route handoff rather than a stand-in.
      final router = GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: RoutePaths.resetPassword,
            builder: (_, state) =>
                ResetPasswordScreen(initialEmail: state.extra as String?),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authApiProvider.overrideWithValue(mockApi)],
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

      // Not visible before a successful submission.
      expect(find.text('I already have a reset code'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('password reset link has been sent'),
        findsOneWidget,
      );
      expect(find.text('I already have a reset code'), findsOneWidget);

      await tester.tap(find.text('I already have a reset code'));
      await tester.pumpAndSettle();

      // Real route handoff — landed on Reset Password, not just a tapped
      // callback — with the submitted email passed through the route
      // `extra` and pre-filled in the email field.
      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    },
  );
}
