import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

Future<void> _pumpLoginScreen(WidgetTester tester, {required AuthApi authApi}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authApiProvider.overrideWithValue(authApi)],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
}

void main() {
  late _MockAuthApi mockApi;

  setUp(() {
    mockApi = _MockAuthApi();
  });

  testWidgets('renders email and password fields with a submit button', (tester) async {
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

  testWidgets('surfaces the API error message on invalid credentials', (tester) async {
    when(() => mockApi.login('test@example.com', 'wrong')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 401,
          data: {'success': false, 'message': 'Invalid credentials', 'data': null, 'errors': null},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await _pumpLoginScreen(tester, authApi: mockApi);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrong');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
