import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

/// A minimal router (`/` -> the screen under test, `/login` -> a
/// recognizable placeholder) so `context.go(RoutePaths.login)` on success
/// has somewhere real to navigate to, instead of throwing for lack of an
/// ancestor GoRouter.
Future<void> _pumpScreen(WidgetTester tester, {required AuthApi authApi}) async {
  final router = GoRouter(
    initialLocation: '/reset-password',
    routes: [
      GoRoute(path: '/reset-password', builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(path: '/login', builder: (_, _) => const Scaffold(body: Text('LOGIN_SCREEN_PLACEHOLDER'))),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authApiProvider.overrideWithValue(authApi)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  late _MockAuthApi mockApi;

  setUp(() {
    mockApi = _MockAuthApi();
  });

  Future<void> fillForm(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Reset Code'), '123456');
    await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'a-very-long-password');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'a-very-long-password');
  }

  testWidgets('renders all four fields and the submit button', (tester) async {
    await _pumpScreen(tester, authApi: mockApi);

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Reset Code'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'New Password'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Confirm New Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Reset Password'), findsOneWidget);
  });

  testWidgets('rejects a mismatched password confirmation without calling the API', (tester) async {
    await _pumpScreen(tester, authApi: mockApi);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Reset Code'), '123456');
    await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'a-very-long-password');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'does-not-match');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(() => mockApi.resetPassword(
          email: any(named: 'email'),
          token: any(named: 'token'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ));
  });

  testWidgets('surfaces the server message on an invalid/expired token', (tester) async {
    when(() => mockApi.resetPassword(
          email: 'test@example.com',
          token: '123456',
          password: 'a-very-long-password',
          passwordConfirmation: 'a-very-long-password',
        )).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reset-password'),
        response: Response(
          requestOptions: RequestOptions(path: '/reset-password'),
          statusCode: 422,
          data: {
            'success': false,
            'message': 'This password reset token is invalid or has expired.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await _pumpScreen(tester, authApi: mockApi);
    await fillForm(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('This password reset token is invalid or has expired.'), findsOneWidget);
  });

  testWidgets('shows success then navigates to login after the delay', (tester) async {
    when(() => mockApi.resetPassword(
          email: 'test@example.com',
          token: '123456',
          password: 'a-very-long-password',
          passwordConfirmation: 'a-very-long-password',
        )).thenAnswer((_) async => 'Password reset successfully');

    await _pumpScreen(tester, authApi: mockApi);
    await fillForm(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pump();

    expect(find.text('Password reset successfully'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('LOGIN_SCREEN_PLACEHOLDER'), findsOneWidget);
  });
}
