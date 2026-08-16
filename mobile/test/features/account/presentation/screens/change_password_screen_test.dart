import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/account/presentation/screens/change_password_screen.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

/// Focused coverage for Mobile Fix #7 (Show/Hide Password) only — the
/// change-password flow itself (submit/validation/API behavior) is not
/// re-tested here, per the scope of this fix.
Future<void> _pumpChangePasswordScreen(
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
        home: const ChangePasswordScreen(),
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
    'Current, New, and Confirm password fields are obscured by default and each reveal independently',
    (tester) async {
      await _pumpChangePasswordScreen(tester, authApi: mockApi);

      final currentField = find.descendant(
        of: find.widgetWithText(TextFormField, 'Current Password'),
        matching: find.byType(TextField),
      );
      final newField = find.descendant(
        of: find.widgetWithText(TextFormField, 'New Password'),
        matching: find.byType(TextField),
      );
      final confirmField = find.descendant(
        of: find.widgetWithText(TextFormField, 'Confirm New Password'),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(currentField).obscureText, isTrue);
      expect(tester.widget<TextField>(newField).obscureText, isTrue);
      expect(tester.widget<TextField>(confirmField).obscureText, isTrue);

      final eyeIcons = find.byIcon(Icons.visibility_outlined);
      expect(eyeIcons, findsNWidgets(3));

      await tester.tap(eyeIcons.at(1));
      await tester.pump();

      expect(tester.widget<TextField>(currentField).obscureText, isTrue);
      expect(tester.widget<TextField>(newField).obscureText, isFalse);
      expect(tester.widget<TextField>(confirmField).obscureText, isTrue);
    },
  );

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current Password'),
      'CurrentPassword123!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New Password'),
      'a-very-long-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm New Password'),
      'a-very-long-password',
    );
  }

  testWidgets(
    'surfaces a field-specific 422 error inline on the Current Password field',
    (tester) async {
      when(
        () => mockApi.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/change-password'),
          response: Response(
            requestOptions: RequestOptions(path: '/change-password'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'current_password': ['The current password is incorrect.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await _pumpChangePasswordScreen(tester, authApi: mockApi);
      await fillValidForm(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('The current password is incorrect.'), findsOneWidget);
    },
  );

  testWidgets(
    'a password-confirmation mismatch from the backend shows on both New Password and Confirm New Password fields',
    (tester) async {
      when(
        () => mockApi.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/change-password'),
          response: Response(
            requestOptions: RequestOptions(path: '/change-password'),
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

      await _pumpChangePasswordScreen(tester, authApi: mockApi);
      await fillValidForm(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Change Password'));
      await tester.pumpAndSettle();

      expect(
        find.text('The password confirmation does not match.'),
        findsNWidgets(2),
      );
    },
  );
}
