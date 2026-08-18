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
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'remembered_password',
          value: 'CorrectHorseBatteryStaple123!',
        ),
      ).called(1);
    },
  );

  test('readEmail reads the dedicated remembered_email key', () async {
    when(
      () => mockStorage.read(key: 'remembered_email'),
    ).thenAnswer((_) async => 'owner@example.com');

    expect(await storage.readEmail(), 'owner@example.com');
  });

  test('readPassword reads the dedicated remembered_password key', () async {
    when(
      () => mockStorage.read(key: 'remembered_password'),
    ).thenAnswer((_) async => 'CorrectHorseBatteryStaple123!');

    expect(await storage.readPassword(), 'CorrectHorseBatteryStaple123!');
  });

  test('clear deletes both the email and password keys', () async {
    when(
      () => mockStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    await storage.clear();

    verify(() => mockStorage.delete(key: 'remembered_email')).called(1);
    verify(() => mockStorage.delete(key: 'remembered_password')).called(1);
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
        ),
      ).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        if (key == 'remembered_email') savedEmail = value;
        if (key == 'remembered_password') savedPassword = value;
      });
      when(
        () => mockStorage.read(key: 'remembered_email'),
      ).thenAnswer((_) async => savedEmail);
      when(
        () => mockStorage.read(key: 'remembered_password'),
      ).thenAnswer((_) async => savedPassword);

      await storage.saveCredentials(
        email: 'tenant-b@example.com',
        password: 'Sup3rSecret!',
      );

      expect(await storage.readEmail(), 'tenant-b@example.com');
      expect(await storage.readPassword(), 'Sup3rSecret!');
    },
  );
}
