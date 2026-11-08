import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/remembered_credentials_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockFlutterSecureStorage mockStorage;
  late RememberedCredentialsStorage storage;

  setUp(() {
    mockStorage = _MockFlutterSecureStorage();
    storage = RememberedCredentialsStorage(mockStorage);
  });

  test(
    'saveCredentials writes email and password through flutter_secure_storage, '
    'never SharedPreferences or any other mechanism',
    () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async {});

      await storage.saveCredentials(
        email: 'owner@example.com',
        password: 'CorrectHorseBatteryStaple123!',
      );

      verify(
        () => mockStorage.write(
          key: 'remembered_email',
          value: 'owner@example.com',
          aOptions: any(named: 'aOptions'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'remembered_password',
          value: 'CorrectHorseBatteryStaple123!',
          aOptions: any(named: 'aOptions'),
        ),
      ).called(1);
    },
  );

  test('readEmail reads the dedicated remembered_email key', () async {
    when(
      () => mockStorage.read(
        key: 'remembered_email',
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async => 'owner@example.com');

    expect(await storage.readEmail(), 'owner@example.com');
  });

  test('readPassword reads the dedicated remembered_password key', () async {
    when(
      () => mockStorage.read(
        key: 'remembered_password',
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async => 'CorrectHorseBatteryStaple123!');

    expect(await storage.readPassword(), 'CorrectHorseBatteryStaple123!');
  });

  test('clear deletes both the email and password keys', () async {
    when(
      () => mockStorage.delete(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async {});

    await storage.clear();

    verify(
      () => mockStorage.delete(
        key: 'remembered_email',
        aOptions: any(named: 'aOptions'),
      ),
    ).called(1);
    verify(
      () => mockStorage.delete(
        key: 'remembered_password',
        aOptions: any(named: 'aOptions'),
      ),
    ).called(1);
  });

  test(
    'round-trip: saveCredentials then read returns exactly what was saved',
    () async {
      String? savedEmail;
      String? savedPassword;
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        if (key == 'remembered_email') savedEmail = value;
        if (key == 'remembered_password') savedPassword = value;
      });
      when(
        () => mockStorage.read(
          key: 'remembered_email',
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => savedEmail);
      when(
        () => mockStorage.read(
          key: 'remembered_password',
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => savedPassword);

      await storage.saveCredentials(
        email: 'tenant-b@example.com',
        password: 'Sup3rSecret!',
      );

      expect(await storage.readEmail(), 'tenant-b@example.com');
      expect(await storage.readPassword(), 'Sup3rSecret!');
    },
  );

  group('Mobile QA Fix — Remember Me reliability (root-cause audit)', () {
    test(
      'the Android options passed to flutter_secure_storage enable resetOnError',
      () async {
        AndroidOptions? capturedOptions;
        when(
          () => mockStorage.read(
            key: any(named: 'key'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenAnswer((invocation) async {
          capturedOptions =
              invocation.namedArguments[#aOptions] as AndroidOptions;
          return null;
        });

        await storage.readEmail();

        expect(capturedOptions, isNotNull);
        expect(capturedOptions!.toMap()['resetOnError'], 'true');
      },
    );

    test(
      'readEmail returns null instead of throwing when secure storage '
      'throws a PlatformException (e.g. a Keystore decryption failure)',
      () async {
        when(
          () => mockStorage.read(
            key: 'remembered_email',
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(
          PlatformException(code: 'decrypt_error', message: 'bad padding'),
        );

        expect(await storage.readEmail(), isNull);
      },
    );

    test(
      'readPassword returns null instead of throwing when secure storage '
      'throws a PlatformException (e.g. a Keystore decryption failure)',
      () async {
        when(
          () => mockStorage.read(
            key: 'remembered_password',
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(
          PlatformException(code: 'decrypt_error', message: 'bad padding'),
        );

        expect(await storage.readPassword(), isNull);
      },
    );

    test(
      'a PlatformException from readEmail/readPassword never carries the '
      'password itself (it is not echoed back in place of a value)',
      () async {
        when(
          () => mockStorage.read(
            key: 'remembered_password',
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(
          PlatformException(
            code: 'decrypt_error',
            message: 'bad padding',
            details: 'CorrectHorseBatteryStaple123!',
          ),
        );

        final result = await storage.readPassword();

        expect(result, isNull);
      },
    );
  });

  group('Root-cause audit fix — C.1 (write failure) and C.3 (resetOnError sentinel)', () {
    test(
      'C.1: saveCredentials swallows a write failure instead of letting it '
      'propagate uncaught (a real Android Keystore write can throw '
      'something other than a PlatformException, e.g. first-time key '
      'generation failing under load)',
      () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(Exception('Keystore write failed'));
        when(
          () => mockStorage.delete(
            key: any(named: 'key'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenAnswer((_) async {});

        // Must not throw — a write failure must never make an already
        // successful login look like it also failed.
        await storage.saveCredentials(
          email: 'owner@example.com',
          password: 'CorrectHorseBatteryStaple123!',
        );
      },
    );

    test(
      'C.1: saveCredentials cleans up (clears) after a write failure so a '
      'half-saved email/password pair can never restore into a misleading '
      'state next time the Login screen mounts',
      () async {
        var emailWritten = false;
        when(
          () => mockStorage.write(
            key: 'remembered_email',
            value: any(named: 'value'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenAnswer((_) async => emailWritten = true);
        when(
          () => mockStorage.write(
            key: 'remembered_password',
            value: any(named: 'value'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(Exception('Keystore write failed on the second key'));
        when(
          () => mockStorage.delete(
            key: any(named: 'key'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenAnswer((_) async {});

        await storage.saveCredentials(
          email: 'owner@example.com',
          password: 'CorrectHorseBatteryStaple123!',
        );

        expect(emailWritten, isTrue);
        verify(
          () => mockStorage.delete(
            key: 'remembered_email',
            aOptions: any(named: 'aOptions'),
          ),
        ).called(1);
        verify(
          () => mockStorage.delete(
            key: 'remembered_password',
            aOptions: any(named: 'aOptions'),
          ),
        ).called(1);
      },
    );

    test(
      'C.1: even a failure during the best-effort cleanup itself does not '
      'propagate',
      () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(Exception('Keystore write failed'));
        when(
          () => mockStorage.delete(
            key: any(named: 'key'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(Exception('cleanup also failed'));

        await storage.saveCredentials(
          email: 'owner@example.com',
          password: 'CorrectHorseBatteryStaple123!',
        );
      },
    );

    test(
      'C.3: readEmail treats the flutter_secure_storage resetOnError '
      'sentinel ("Data has been reset", confirmed against the actual '
      'plugin source — not null, not a thrown exception) the same as '
      '"nothing was ever saved", instead of displaying it',
      () async {
        when(
          () => mockStorage.read(
            key: 'remembered_email',
            aOptions: any(named: 'aOptions'),
          ),
        ).thenAnswer((_) async => 'Data has been reset');

        expect(await storage.readEmail(), isNull);
      },
    );

    test(
      'C.3: readPassword treats the resetOnError sentinel the same as '
      '"nothing was ever saved"',
      () async {
        when(
          () => mockStorage.read(
            key: 'remembered_password',
            aOptions: any(named: 'aOptions'),
          ),
        ).thenAnswer((_) async => 'Data has been reset');

        expect(await storage.readPassword(), isNull);
      },
    );

    test(
      'C.3: a genuinely saved password that merely happens to differ from '
      'the sentinel is still returned normally (the check is exact, not a '
      'substring/prefix match that could misfire on a real password)',
      () async {
        when(
          () => mockStorage.read(
            key: 'remembered_password',
            aOptions: any(named: 'aOptions'),
          ),
        ).thenAnswer((_) async => 'Data has been reset today!'); // real value

        expect(await storage.readPassword(), 'Data has been reset today!');
      },
    );
  });
}
