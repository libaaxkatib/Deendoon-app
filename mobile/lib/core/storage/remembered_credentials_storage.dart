import 'package:flutter/services.dart';
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

  /// Mobile QA Fix — Remember Me reliability: `resetOnError: true` is the
  /// one Android-secure-storage option this fix changes. Without it, a
  /// Keystore-level decryption failure (a real, ordinary occurrence after
  /// e.g. an app reinstall or a device backup/restore — the Keystore key
  /// never survives those, even though the encrypted value on disk can)
  /// makes `read()` throw instead of returning null, which previously
  /// propagated uncaught out of the Login screen's restore attempt and
  /// left the fields silently blank with no way to recover except
  /// uninstalling. With this set, the plugin clears the unreadable entry
  /// itself and `read()` resolves to null — acceptable here because these
  /// credentials are always re-creatable from the next successful login.
  /// `encryptedSharedPreferences` is deliberately left at its default
  /// (false): switching it would change the on-disk storage format and
  /// make existing users' already-saved credentials unreadable after this
  /// update — a real compatibility cost not required to fix the reported
  /// bug, since `resetOnError` alone already makes a read failure
  /// harmless. See root-cause audit for the full analysis.
  static const _androidOptions = AndroidOptions(resetOnError: true);

  /// Root-cause audit finding (C.3): confirmed directly against the
  /// installed `flutter_secure_storage` 9.2.2 Android source
  /// (`FlutterSecureStoragePlugin.java`'s `MethodRunner.run()`) — when
  /// `resetOnError` is set and a Keystore decrypt failure occurs (e.g. after
  /// a reinstall or a device backup/restore, where the encrypted value
  /// survives but the Keystore key that could decrypt it does not), the
  /// plugin does NOT resolve `read()` to `null` and does NOT throw a
  /// `PlatformException` — it calls `deleteAll()` and returns this literal
  /// string instead. Without checking for it explicitly, that sentinel
  /// would be treated as a real saved value and shown in the Login
  /// screen's email/password fields verbatim.
  static const _resetSentinel = 'Data has been reset';

  final FlutterSecureStorage _storage;

  const RememberedCredentialsStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  /// Root-cause audit finding (C.1): a real Android Keystore write failure
  /// (e.g. first-time key generation under load, a hardware-backed
  /// Keystore/StrongBox error — conditions a desktop/CI/emulator run never
  /// exercises) previously propagated uncaught out of this method, and
  /// `LoginForm._submit()` had nothing to catch it either — silently
  /// losing the save with the user already on the Home screen, no error
  /// ever shown. Login having already succeeded must never be made to look
  /// like it also failed, so a write failure here is swallowed rather than
  /// rethrown; on failure, a best-effort [clear] avoids leaving a
  /// half-saved pair (e.g. email written, password write failed) that
  /// would otherwise restore into a misleading, inconsistent state next
  /// time this screen mounts.
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _storage.write(
        key: _emailKey,
        value: email,
        aOptions: _androidOptions,
      );
      await _storage.write(
        key: _passwordKey,
        value: password,
        aOptions: _androidOptions,
      );
    } catch (_) {
      try {
        await clear();
      } catch (_) {
        // Best-effort cleanup only — the original write failure is already
        // being treated as non-fatal; a failure to clean up afterward must
        // not surface either.
      }
    }
  }

  /// Never throws: a platform/decryption failure (see [_androidOptions])
  /// is treated the same as "nothing was ever saved" rather than crashing
  /// the Login screen's restore attempt.
  Future<String?> readEmail() => _readSafely(_emailKey);

  Future<String?> readPassword() => _readSafely(_passwordKey);

  Future<String?> _readSafely(String key) async {
    try {
      final value = await _storage.read(key: key, aOptions: _androidOptions);
      return value == _resetSentinel ? null : value;
    } on PlatformException {
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _emailKey, aOptions: _androidOptions);
    await _storage.delete(key: _passwordKey, aOptions: _androidOptions);
  }
}
