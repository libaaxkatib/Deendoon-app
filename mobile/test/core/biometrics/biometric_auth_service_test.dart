import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile/core/biometrics/biometric_auth_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late _MockLocalAuthentication mockAuth;
  late BiometricAuthService service;

  setUp(() {
    mockAuth = _MockLocalAuthentication();
    service = BiometricAuthService(mockAuth);
  });

  group('isSupported', () {
    test(
      'is true when both canCheckBiometrics and isDeviceSupported are true',
      () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

        expect(await service.isSupported(), isTrue);
      },
    );

    test('is false when canCheckBiometrics is false', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

      expect(await service.isSupported(), isFalse);
    });

    test('is false when isDeviceSupported is false', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

      expect(await service.isSupported(), isFalse);
    });

    test('is false, not thrown, when the platform channel throws', () async {
      when(
        () => mockAuth.canCheckBiometrics,
      ).thenThrow(PlatformException(code: 'error'));

      expect(await service.isSupported(), isFalse);
    });
  });

  group('authenticate', () {
    test('returns true on a real successful prompt', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: 'reason',
          options: const AuthenticationOptions(biometricOnly: true),
        ),
      ).thenAnswer((_) async => true);

      expect(await service.authenticate('reason'), isTrue);
    });

    test('returns false on a cancelled/failed prompt', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: 'reason',
          options: const AuthenticationOptions(biometricOnly: true),
        ),
      ).thenAnswer((_) async => false);

      expect(await service.authenticate('reason'), isFalse);
    });

    test('returns false, not thrown, on a platform error — this is the exact '
        'path Mobile Fix #17\'s Android FlutterActivity bug used to hit '
        '(ERROR_NOT_FRAGMENT_ACTIVITY), silently swallowed here', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: 'reason',
          options: const AuthenticationOptions(biometricOnly: true),
        ),
      ).thenThrow(PlatformException(code: 'NotEnrolled'));

      expect(await service.authenticate('reason'), isFalse);
    });
  });
}
