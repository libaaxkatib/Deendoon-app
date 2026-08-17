import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/google_login_result.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

const _user = User(id: '1', name: 'Test User', email: 'test@example.com');

void main() {
  late _MockAuthApi mockApi;
  late _MockSecureTokenStorage mockStorage;
  late ProviderContainer container;
  late AuthRepository repository;

  setUp(() {
    mockApi = _MockAuthApi();
    mockStorage = _MockSecureTokenStorage();

    container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(mockApi),
        secureTokenStorageProvider.overrideWithValue(mockStorage),
      ],
    );
    addTearDown(container.dispose);

    repository = container.read(authRepositoryProvider);
  });

  group('login', () {
    test('persists the session and returns Authenticated on success', () async {
      when(
        () => mockApi.login('test@example.com', 'password'),
      ).thenAnswer((_) async => (_user, 'new-token'));
      when(
        () => mockStorage.saveSession(
          token: any(named: 'token'),
          userJson: any(named: 'userJson'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.login('test@example.com', 'password');

      expect(result.user, _user);
      expect(result.token, 'new-token');
      verify(
        () => mockStorage.saveSession(
          token: 'new-token',
          userJson: any(named: 'userJson'),
        ),
      ).called(1);
    });

    test(
      'throws ApiException with the server message on invalid credentials',
      () async {
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

        expect(
          () => repository.login('test@example.com', 'wrong'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Invalid credentials',
            ),
          ),
        );
      },
    );
  });

  group('googleLogin', () {
    test(
      'persists the session and returns GoogleLoginAuthenticated for an existing account',
      () async {
        when(() => mockApi.googleLogin('valid-id-token')).thenAnswer(
          (_) async =>
              const GoogleLoginAuthenticated(user: _user, token: 'g-token'),
        );
        when(
          () => mockStorage.saveSession(
            token: any(named: 'token'),
            userJson: any(named: 'userJson'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.googleLogin('valid-id-token');

        expect(result, isA<GoogleLoginAuthenticated>());
        expect((result as GoogleLoginAuthenticated).token, 'g-token');
        verify(
          () => mockStorage.saveSession(
            token: 'g-token',
            userJson: any(named: 'userJson'),
          ),
        ).called(1);
      },
    );

    test(
      'persists nothing and returns GoogleLoginRegistrationRequired for a new identity',
      () async {
        when(() => mockApi.googleLogin('new-id-token')).thenAnswer(
          (_) async => const GoogleLoginRegistrationRequired(
            email: 'new@example.com',
            name: 'New User',
          ),
        );

        final result = await repository.googleLogin('new-id-token');

        expect(result, isA<GoogleLoginRegistrationRequired>());
        expect(
          (result as GoogleLoginRegistrationRequired).email,
          'new@example.com',
        );
        verifyNever(
          () => mockStorage.saveSession(
            token: any(named: 'token'),
            userJson: any(named: 'userJson'),
          ),
        );
      },
    );

    test(
      'throws ApiException on an invalid/expired token, never reaching saveSession',
      () async {
        when(() => mockApi.googleLogin('bad-token')).thenThrow(
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

        expect(
          () => repository.googleLogin('bad-token'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      },
    );

    test(
      'throws ApiException on an email already tied to a password account',
      () async {
        when(() => mockApi.googleLogin('collides')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/google-login'),
            response: Response(
              requestOptions: RequestOptions(path: '/google-login'),
              statusCode: 409,
              data: {
                'success': false,
                'message':
                    'An account with this email already exists. Log in with your password to continue, then link your Google account from Settings.',
                'data': null,
                'errors': null,
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => repository.googleLogin('collides'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
          ),
        );
      },
    );
  });

  group('googleRegister', () {
    test('persists the session and returns Authenticated on success', () async {
      when(
        () => mockApi.googleRegister(
          idToken: 'valid-id-token',
          businessName: 'Acme Traders',
          phone: null,
        ),
      ).thenAnswer((_) async => (_user, 'new-account-token'));
      when(
        () => mockStorage.saveSession(
          token: any(named: 'token'),
          userJson: any(named: 'userJson'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.googleRegister(
        idToken: 'valid-id-token',
        businessName: 'Acme Traders',
      );

      expect(result.user, _user);
      expect(result.token, 'new-account-token');
      verify(
        () => mockStorage.saveSession(
          token: 'new-account-token',
          userJson: any(named: 'userJson'),
        ),
      ).called(1);
    });

    test(
      'throws ApiException when the identity was registered by a concurrent request',
      () async {
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

        expect(
          () => repository.googleRegister(
            idToken: 'valid-id-token',
            businessName: 'Acme Traders',
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
          ),
        );
      },
    );
  });

  group('readCachedSession', () {
    test('returns null when nothing is stored', () async {
      when(() => mockStorage.readToken()).thenAnswer((_) async => null);
      when(() => mockStorage.readUserJson()).thenAnswer((_) async => null);

      expect(await repository.readCachedSession(), isNull);
    });

    test('returns Authenticated when a token and cached user exist', () async {
      when(
        () => mockStorage.readToken(),
      ).thenAnswer((_) async => 'cached-token');
      when(() => mockStorage.readUserJson()).thenAnswer(
        (_) async => '{"id":"1","name":"Test User","email":"test@example.com"}',
      );

      final result = await repository.readCachedSession();

      expect(result, isNotNull);
      expect(result!.token, 'cached-token');
      expect(result.user.email, 'test@example.com');
    });
  });

  group('validateAndRotate', () {
    test(
      'persists the rotated token and returns Authenticated on success',
      () async {
        when(
          () => mockApi.refresh(),
        ).thenAnswer((_) async => (_user, 'rotated-token'));
        when(
          () => mockStorage.saveSession(
            token: any(named: 'token'),
            userJson: any(named: 'userJson'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.validateAndRotate();

        expect(result.token, 'rotated-token');
        verify(
          () => mockStorage.saveSession(
            token: 'rotated-token',
            userJson: any(named: 'userJson'),
          ),
        ).called(1);
      },
    );

    test('throws ApiException on an idle-expired token (401)', () async {
      when(() => mockApi.refresh()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/refresh'),
          response: Response(
            requestOptions: RequestOptions(path: '/refresh'),
            statusCode: 401,
            data: {
              'success': false,
              'message': 'Unauthenticated.',
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.validateAndRotate(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('logout', () {
    test('clears local storage even when the server call fails', () async {
      when(() => mockApi.logout()).thenThrow(Exception('network down'));
      when(() => mockStorage.clear()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockStorage.clear()).called(1);
    });
  });

  group('forgotPassword', () {
    test('returns the generic server message on success', () async {
      when(() => mockApi.forgotPassword('test@example.com')).thenAnswer(
        (_) async =>
            'If an account with that email exists, a password reset link has been sent.',
      );

      final message = await repository.forgotPassword('test@example.com');

      expect(message, contains('password reset link has been sent'));
    });

    test('throws ApiException on a network/validation failure', () async {
      when(() => mockApi.forgotPassword('bad')).thenThrow(
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

      expect(
        () => repository.forgotPassword('bad'),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'The given data was invalid.',
              )
              .having(
                (e) => e.fieldErrors?['email'],
                'fieldErrors[email]',
                isNotNull,
              ),
        ),
      );
    });
  });

  group('changePassword', () {
    test(
      'returns the success message when the current password is correct',
      () async {
        when(
          () => mockApi.changePassword(
            currentPassword: 'old-password-123',
            newPassword: 'a-very-long-password',
          ),
        ).thenAnswer((_) async => 'Password changed successfully');

        final message = await repository.changePassword(
          currentPassword: 'old-password-123',
          newPassword: 'a-very-long-password',
        );

        expect(message, 'Password changed successfully');
      },
    );

    test(
      'throws ApiException with the server message when the current password is wrong',
      () async {
        when(
          () => mockApi.changePassword(
            currentPassword: 'wrong-password',
            newPassword: 'a-very-long-password',
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/change-password'),
            response: Response(
              requestOptions: RequestOptions(path: '/change-password'),
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

        expect(
          () => repository.changePassword(
            currentPassword: 'wrong-password',
            newPassword: 'a-very-long-password',
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'The current password is incorrect.',
            ),
          ),
        );
      },
    );
  });

  group('resetPassword', () {
    test('returns the success message when the token is valid', () async {
      when(
        () => mockApi.resetPassword(
          email: 'test@example.com',
          token: 'valid-token',
          password: 'a-very-long-password',
          passwordConfirmation: 'a-very-long-password',
        ),
      ).thenAnswer((_) async => 'Password reset successfully');

      final message = await repository.resetPassword(
        email: 'test@example.com',
        token: 'valid-token',
        password: 'a-very-long-password',
        passwordConfirmation: 'a-very-long-password',
      );

      expect(message, 'Password reset successfully');
    });

    test(
      'throws ApiException with the server message on an invalid/expired token',
      () async {
        when(
          () => mockApi.resetPassword(
            email: 'test@example.com',
            token: 'bad-token',
            password: 'a-very-long-password',
            passwordConfirmation: 'a-very-long-password',
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/reset-password'),
            response: Response(
              requestOptions: RequestOptions(path: '/reset-password'),
              statusCode: 422,
              data: {
                'success': false,
                'message':
                    'This password reset token is invalid or has expired.',
                'data': null,
                'errors': null,
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => repository.resetPassword(
            email: 'test@example.com',
            token: 'bad-token',
            password: 'a-very-long-password',
            passwordConfirmation: 'a-very-long-password',
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'This password reset token is invalid or has expired.',
            ),
          ),
        );
      },
    );
  });
}
