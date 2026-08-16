import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

/// Focused coverage for Mobile Fix #7 (Show/Hide Password) only — the
/// registration flow itself (submit/validation/API behavior) is not
/// re-tested here, per the scope of this fix.
Future<void> _pumpRegisterScreen(
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
        home: const RegisterScreen(),
      ),
    ),
  );
}

void main() {
  late _MockAuthApi mockApi;

  setUp(() {
    mockApi = _MockAuthApi();
  });

  testWidgets(
    'Password and Confirm Password are obscured by default and reveal independently via their own eye icon',
    (tester) async {
      await _pumpRegisterScreen(tester, authApi: mockApi);

      final passwordField = find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(TextField),
      );
      final confirmField = find.descendant(
        of: find.widgetWithText(TextFormField, 'Confirm Password'),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
      expect(tester.widget<TextField>(confirmField).obscureText, isTrue);

      final eyeIcons = find.byIcon(Icons.visibility_outlined);
      expect(eyeIcons, findsNWidgets(2));

      await tester.tap(eyeIcons.last);
      await tester.pump();

      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
      expect(tester.widget<TextField>(confirmField).obscureText, isFalse);
    },
  );

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Business Name'),
      'Acme Trading',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full Name'),
      'Jane Doe',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '0615178666',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'jane@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'a-very-long-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'a-very-long-password',
    );
  }

  testWidgets(
    'surfaces multiple simultaneous field-specific 422 errors inline on their own fields',
    (tester) async {
      when(
        () => mockApi.register(
          businessName: any(named: 'businessName'),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/register'),
          response: Response(
            requestOptions: RequestOptions(path: '/register'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'email': ['The email has already been taken.'],
                'phone': ['The phone field is invalid.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpRegisterScreen(tester, authApi: mockApi);
      await fillValidForm(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('The email has already been taken.'), findsOneWidget);
      expect(find.text('The phone field is invalid.'), findsOneWidget);
    },
  );

  testWidgets(
    'a password-confirmation mismatch from the backend shows on both New Password and Confirm Password fields',
    (tester) async {
      when(
        () => mockApi.register(
          businessName: any(named: 'businessName'),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/register'),
          response: Response(
            requestOptions: RequestOptions(path: '/register'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'password': ['The password confirmation does not match.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpRegisterScreen(tester, authApi: mockApi);
      await fillValidForm(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(
        find.text('The password confirmation does not match.'),
        findsNWidgets(2),
      );
    },
  );

  testWidgets(
    'a plain password strength/length error from the backend shows only on the New Password field',
    (tester) async {
      when(
        () => mockApi.register(
          businessName: any(named: 'businessName'),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/register'),
          response: Response(
            requestOptions: RequestOptions(path: '/register'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'password': [
                  'The password field must be at least 12 characters.',
                ],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpRegisterScreen(tester, authApi: mockApi);
      await fillValidForm(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(
        find.text('The password field must be at least 12 characters.'),
        findsOneWidget,
      );
    },
  );
}
