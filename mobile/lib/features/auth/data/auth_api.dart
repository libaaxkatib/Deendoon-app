import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(dioProvider)));

/// Thin wrapper around the auth endpoints — mirrors
/// `App\Http\Controllers\AuthController` exactly.
class AuthApi {
  final Dio _dio;

  const AuthApi(this._dio);

  Future<(User, String)> login(String email, String password) async {
    final response = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    return _parseAuthPayload(response.data);
  }

  Future<(User, String)> refresh() async {
    final response = await _dio.post(ApiEndpoints.refresh);
    return _parseAuthPayload(response.data);
  }

  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
  }

  /// `App\Http\Controllers\AuthController::forgotPassword` — always returns
  /// the same generic message whether or not the email is registered
  /// (enumeration-safe by design; do not infer success/failure from it).
  Future<String> forgotPassword(String email) async {
    final response = await _dio.post(ApiEndpoints.forgotPassword, data: {
      'email': email,
    });
    return response.data['message'] as String;
  }

  /// `App\Http\Controllers\AuthController::resetPassword`. `token` is the
  /// one emailed to the user — there is no deep-link handling in this app,
  /// so it is entered manually, matching `ResetPasswordRequest`'s fields
  /// exactly (`email`, `token`, `password`, `password_confirmation`).
  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post(ApiEndpoints.resetPassword, data: {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return response.data['message'] as String;
  }

  (User, String) _parseAuthPayload(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    return (user, token);
  }
}
