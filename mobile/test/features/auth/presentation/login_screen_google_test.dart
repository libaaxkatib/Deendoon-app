import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/app/router/route_paths.dart';
import 'package:mobile/core/google_auth/google_auth_service.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/domain/google_login_result.dart';
import 'package:mobile/features/auth/domain/google_registration_input.dart';
import 'package:mobile/features/auth/presentation/screens/google_register_screen.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

Future<void> _pumpLoginScreen(
  WidgetTester tester, {
  required AuthApi authApi,
  required GoogleAuthService googleAuthService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        googleAuthServiceProvider.overrideWithValue(googleAuthService),
      ],
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
  late _MockGoogleAuthService mockGoogleAuthService;

  setUp(() {
    mockApi = _MockAuthApi();
    mockGoogleAuthService = _MockGoogleAuthService();
    when(() => mockGoogleAuthService.isConfigured).thenReturn(true);
  });

  testWidgets('renders a "Continue with Google" button', (tester) async {
    await _pumpLoginScreen(
      tester,
      authApi: mockApi,
      googleAuthService: mockGoogleAuthService,
    );

    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets(
    'shows a message instead of calling the SDK when Google sign-in is not configured',
    (tester) async {
      when(() => mockGoogleAuthService.isConfigured).thenReturn(false);
      await _pumpLoginScreen(
        tester,
        authApi: mockApi,
        googleAuthService: mockGoogleAuthService,
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(
        find.text('Google sign-in is not available right now.'),
        findsOneWidget,
      );
      verifyNever(() => mockGoogleAuthService.signIn());
    },
  );

  testWidgets(
    'does nothing (no error, no navigation) when the user cancels the picker',
    (tester) async {
      when(() => mockGoogleAuthService.signIn()).thenAnswer((_) async => null);
      await _pumpLoginScreen(
        tester,
        authApi: mockApi,
        googleAuthService: mockGoogleAuthService,
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      verifyNever(() => mockApi.googleLogin(any()));
    },
  );

  testWidgets(
    'surfaces a generic message on a real GoogleSignInException, not the raw SDK error',
    (tester) async {
      when(() => mockGoogleAuthService.signIn()).thenThrow(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        ),
      );
      await _pumpLoginScreen(
        tester,
        authApi: mockApi,
        googleAuthService: mockGoogleAuthService,
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(
        find.text('Google sign-in failed. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'surfaces the backend message on a 401 invalid token',
    (tester) async {
      when(
        () => mockGoogleAuthService.signIn(),
      ).thenAnswer((_) async => 'invalid-token');
      when(() => mockApi.googleLogin('invalid-token')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/google-login'),
          response: Response(
            requestOptions: RequestOptions(path: '/google-login'),
            statusCode: 401,
            data: {
              'success': false,
              'message': 'Invalid or expired Google credential.',
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpLoginScreen(
        tester,
        authApi: mockApi,
        googleAuthService: mockGoogleAuthService,
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid or expired Google credential.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'surfaces the backend message on a 409 email-already-linked collision',
    (tester) async {
      const collisionMessage =
          'An account with this email already exists. Log in with your '
          'password to continue, then link your Google account from Settings.';
      when(
        () => mockGoogleAuthService.signIn(),
      ).thenAnswer((_) async => 'colliding-token');
      when(() => mockApi.googleLogin('colliding-token')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/google-login'),
          response: Response(
            requestOptions: RequestOptions(path: '/google-login'),
            statusCode: 409,
            data: {
              'success': false,
              'message': collisionMessage,
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpLoginScreen(
        tester,
        authApi: mockApi,
        googleAuthService: mockGoogleAuthService,
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text(collisionMessage), findsOneWidget);
    },
  );

  testWidgets(
    'a registration-required outcome navigates to the business-name-collection '
    'screen with the backend-verified email/name — never anything read locally',
    (tester) async {
      when(
        () => mockGoogleAuthService.signIn(),
      ).thenAnswer((_) async => 'new-user-token');
      when(() => mockApi.googleLogin('new-user-token')).thenAnswer(
        (_) async => const GoogleLoginRegistrationRequired(
          email: 'brandnew@example.com',
          name: 'Brand New',
        ),
      );

      // Real route handoff — mirrors app_router.dart's actual registration
      // (builder reads `state.extra as GoogleRegistrationInput`).
      final router = GoRouter(
        initialLocation: RoutePaths.login,
        routes: [
          GoRoute(
            path: RoutePaths.login,
            builder: (_, _) => const LoginScreen(),
          ),
          GoRoute(
            path: RoutePaths.googleRegister,
            builder: (_, state) => GoogleRegisterScreen(
              input: state.extra! as GoogleRegistrationInput,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authApiProvider.overrideWithValue(mockApi),
            googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          ],
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

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(GoogleRegisterScreen), findsOneWidget);
      expect(find.textContaining('brandnew@example.com'), findsOneWidget);
    },
  );
}
