import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) => const SecureTokenStorage());

/// Persists the Sanctum bearer token and a cached copy of the user's own
/// profile JSON (there is no `GET /me` endpoint to re-fetch it from).
class SecureTokenStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  const SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession({required String token, required String userJson}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
