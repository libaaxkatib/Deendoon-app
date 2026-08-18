import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final rememberedCredentialsStorageProvider =
    Provider<RememberedCredentialsStorage>(
      (ref) => const RememberedCredentialsStorage(),
    );

/// Mobile QA Fix — Remember Me (Product Decision: 2026-08-18). Persists the
/// Login screen's email/password so the form can restore both automatically
/// on its next appearance, satisfying "already filled" — something platform
/// Autofill cannot do on its own, since it only ever offers a tap-triggered
/// suggestion, never a silent auto-fill on screen load.
///
/// Deliberately separate from [SecureTokenStorage]: the session token and
/// these remembered credentials have different clearing rules (a normal
/// logout wipes the token but must leave these alone when Remember Me is
/// on; closing the account wipes both) — mixing them into one class would
/// risk one lifecycle accidentally governing the other.
///
/// Backed by `flutter_secure_storage` (Android Keystore / iOS Keychain) —
/// never `SharedPreferences`, never a database, never a plain file.
class RememberedCredentialsStorage {
  static const _emailKey = 'remembered_email';
  static const _passwordKey = 'remembered_password';

  final FlutterSecureStorage _storage;

  const RememberedCredentialsStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<String?> readEmail() => _storage.read(key: _emailKey);

  Future<String?> readPassword() => _storage.read(key: _passwordKey);

  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
