import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/domain/google_registration_input.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/screens/google_register_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

const _input = GoogleRegistrationInput(
  idToken: 'valid-id-token',
  email: 'brandnew@example.com',
  name: 'Brand New',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required AuthApi authApi,
  SecureTokenStorage? secureTokenStorage,
  GoogleRegistrationInput input = _input,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        if (secureTokenStorage != null)
          secureTokenStorageProvider.overrideWithValue(secureTokenStorage),
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
        home: GoogleRegisterScreen(input: input),
      ),
    ),
  );
}

void main() {
  late _MockAuthApi mockApi;

  setUp(() {
    mockApi = _MockAuthApi();
  });

  testWidgets('renders the business name field and the verified email', (
    tester,
  ) async {
    await _pumpScreen(tester, authApi: mockApi);

    expect(
      find.widgetWithText(TextFormField, 'Business Name'),
      findsOneWidget,
    );
    expect(find.textContaining('brandnew@example.com'), findsOneWidget);
  });

  testWidgets('shows a validation error when submitted with an empty business name', (
    tester,
  ) async {
    await _pumpScreen(tester, authApi: mockApi);

    await tester.tap(find.text('Complete Registration'));
    await tester.pump();

    expect(find.text('Business name is required'), findsOneWidget);
    verifyNever(
      () => mockApi.googleRegister(
        idToken: any(named: 'idToken'),
        businessName: any(named: 'businessName'),
        phone: any(named: 'phone'),
      ),
    );
  });

  testWidgets(
    'submits the same idToken with the entered business name, phone omitted when blank',
    (tester) async {
      when(
        () => mockApi.googleRegister(
          idToken: 'valid-id-token',
          businessName: 'Acme Traders',
          phone: null,
        ),
      ).thenAnswer(
        (_) async => (
          const User(id: '1', name: 'Brand New', email: 'brandnew@example.com'),
          'new-account-token',
        ),
      );
      final mockStorage = _MockSecureTokenStorage();
      when(
        () => mockStorage.saveSession(
          token: any(named: 'token'),
          userJson: any(named: 'userJson'),
        ),
      ).thenAnswer((_) async {});

      await _pumpScreen(
        tester,
        authApi: mockApi,
        secureTokenStorage: mockStorage,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Business Name'),
        'Acme Traders',
      );
      await tester.tap(find.text('Complete Registration'));
      await tester.pumpAndSettle();

      verify(
        () => mockApi.googleRegister(
          idToken: 'valid-id-token',
          businessName: 'Acme Traders',
          phone: null,
        ),
      ).called(1);
      verify(
        () => mockStorage.saveSession(
          token: 'new-account-token',
          userJson: any(named: 'userJson'),
        ),
      ).called(1);
    },
  );

  testWidgets('surfaces the backend error message on a 409 duplicate identity', (
    tester,
  ) async {
    when(
      () => mockApi.googleRegister(
        idToken: 'valid-id-token',
        businessName: 'Acme Traders',
        phone: null,
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/google-register'),
        response: Response(
          requestOptions: RequestOptions(path: '/google-register'),
          statusCode: 409,
          data: {
            'success': false,
            'message': 'An account for this Google identity already exists.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await _pumpScreen(tester, authApi: mockApi);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Business Name'),
      'Acme Traders',
    );
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();

    expect(
      find.text('An account for this Google identity already exists.'),
      findsOneWidget,
    );
  });
}
