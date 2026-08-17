import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/core/google_auth/google_auth_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late _MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockGoogleSignIn = _MockGoogleSignIn();
    when(
      () => mockGoogleSignIn.initialize(
        serverClientId: any(named: 'serverClientId'),
      ),
    ).thenAnswer((_) async {});
  });

  group('isConfigured', () {
    test('is false with no server client id (the real default build)', () {
      final service = GoogleAuthService(mockGoogleSignIn, '');
      expect(service.isConfigured, isFalse);
    });

    test('is true once a server client id is provided', () {
      final service = GoogleAuthService(mockGoogleSignIn, 'test-client-id');
      expect(service.isConfigured, isTrue);
    });
  });

  group('signIn', () {
    test(
      'throws GoogleSignInNotConfiguredException without ever touching the '
      'native SDK when no server client id is configured',
      () async {
        final service = GoogleAuthService(mockGoogleSignIn, '');

        expect(
          () => service.signIn(),
          throwsA(isA<GoogleSignInNotConfiguredException>()),
        );
        verifyNever(
          () => mockGoogleSignIn.initialize(
            serverClientId: any(named: 'serverClientId'),
          ),
        );
      },
    );

    test('returns the ID token on a successful sign-in', () async {
      final account = _MockGoogleSignInAccount();
      when(
        () => account.authentication,
      ).thenReturn(const GoogleSignInAuthentication(idToken: 'real-id-token'));
      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => account);

      final service = GoogleAuthService(mockGoogleSignIn, 'test-client-id');

      expect(await service.signIn(), 'real-id-token');
      verify(
        () => mockGoogleSignIn.initialize(serverClientId: 'test-client-id'),
      ).called(1);
    });

    test('only initializes the SDK once across repeated sign-ins', () async {
      final account = _MockGoogleSignInAccount();
      when(
        () => account.authentication,
      ).thenReturn(const GoogleSignInAuthentication(idToken: 'token'));
      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => account);

      final service = GoogleAuthService(mockGoogleSignIn, 'test-client-id');
      await service.signIn();
      await service.signIn();

      verify(
        () => mockGoogleSignIn.initialize(
          serverClientId: any(named: 'serverClientId'),
        ),
      ).called(1);
    });

    test(
      'returns null (not an error) when the user cancels the picker',
      () async {
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        );

        final service = GoogleAuthService(mockGoogleSignIn, 'test-client-id');

        expect(await service.signIn(), isNull);
      },
    );

    test(
      'rethrows a genuine GoogleSignInException (e.g. a real SDK failure), '
      'not swallowed the way cancellation is',
      () async {
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.unknownError,
          ),
        );

        final service = GoogleAuthService(mockGoogleSignIn, 'test-client-id');

        expect(
          () => service.signIn(),
          throwsA(isA<GoogleSignInException>()),
        );
      },
    );
  });

  group('signOut', () {
    test('delegates to the underlying GoogleSignIn instance', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async {});
      final service = GoogleAuthService(mockGoogleSignIn, 'test-client-id');

      await service.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
    });
  });
}
