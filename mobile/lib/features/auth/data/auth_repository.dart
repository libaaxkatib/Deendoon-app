import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../domain/auth_state.dart';
import '../domain/user.dart';
import 'auth_api.dart';

/// Orchestrates `AuthApi` + `SecureTokenStorage`, translating raw Dio
/// failures into `ApiException` and persisting/clearing the session as a
/// side effect of each successful call.
class AuthRepository {
  final Ref _ref;

  AuthRepository(this._ref);

  AuthApi get _api => _ref.read(authApiProvider);
  SecureTokenStorage get _storage => _ref.read(secureTokenStorageProvider);

  /// Reads a previously-persisted session without hitting the network —
  /// used for the splash screen's optimistic, zero-latency restore.
  Future<Authenticated?> readCachedSession() async {
    final token = await _storage.readToken();
    final userJson = await _storage.readUserJson();
    if (token == null || userJson == null) return null;

    return Authenticated(
      user: User.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
      token: token,
    );
  }

  /// Calls `POST /refresh` to validate the cached token and rotate it,
  /// standing in for the missing `GET /me` endpoint. Throws `ApiException`
  /// on failure (e.g. an idle-expired token) — the Dio auth interceptor
  /// already reacts to the underlying 401 by forcing a logout, so callers
  /// only need to stop treating the session as restored.
  Future<Authenticated> validateAndRotate() async {
    try {
      final (user, token) = await _api.refresh();
      await _storage.saveSession(token: token, userJson: jsonEncode(user.toJson()));
      return Authenticated(user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Authenticated> login(String email, String password) async {
    try {
      final (user, token) = await _api.login(email, password);
      await _storage.saveSession(token: token, userJson: jsonEncode(user.toJson()));
      return Authenticated(user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Best-effort server-side revocation, always followed by clearing local
  /// storage regardless of whether the network call succeeded.
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Ignore — the token may already be invalid, which is exactly why
      // we're logging out. Local state is cleared unconditionally below.
    }
    await _storage.clear();
  }

  /// Always succeeds with a generic message server-side (enumeration-safe);
  /// a network/validation failure is the only case that throws.
  Future<String> forgotPassword(String email) async {
    try {
      return await _api.forgotPassword(email);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Throws `ApiException` on an incorrect current password (422) or a
  /// validation failure (e.g. new password too short).
  Future<String> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      return await _api.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Throws `ApiException` on an invalid/expired token or a validation
  /// failure (e.g. password too short, confirmation mismatch).
  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      return await _api.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
