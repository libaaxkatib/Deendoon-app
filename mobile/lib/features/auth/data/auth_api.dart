import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/google_login_result.dart';
import '../domain/user.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.read(dioProvider)),
);

/// Thin wrapper around the auth endpoints — mirrors
/// `App\Http\Controllers\AuthController` exactly.
class AuthApi {
  final Dio _dio;

  const AuthApi(this._dio);

  Future<(User, String)> login(String email, String password) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return _parseAuthPayload(response.data);
  }

  /// `App\Http\Controllers\AuthController::register` — creates a Tenant,
  /// the first Business Owner user, and logs them straight in, matching
  /// `RegisterRequest`'s fields exactly.
  Future<(User, String)> register({
    required String businessName,
    required String name,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'business_name': businessName,
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return _parseAuthPayload(response.data);
  }

  /// `App\Http\Controllers\AuthController::googleLogin` — sends only the
  /// verified-on-device Google ID token, never a client-supplied email/
  /// name. Two real outcomes: an existing Google-linked account (treat
  /// like a normal login) or no account yet (the caller collects a
  /// business name and calls [googleRegister]). Any other outcome (an
  /// invalid token, or the email already belonging to a password account)
  /// is a real HTTP error and throws via the normal Dio/ApiException path.
  Future<GoogleLoginResult> googleLogin(String idToken) async {
    final response = await _dio.post(
      ApiEndpoints.googleLogin,
      data: {'id_token': idToken},
    );
    final data = response.data['data'] as Map<String, dynamic>;

    if (data['registration_required'] == true) {
      final google = data['google'] as Map<String, dynamic>;
      return GoogleLoginRegistrationRequired(
        email: google['email'] as String,
        name: google['name'] as String?,
      );
    }

    final (user, token) = _parseAuthPayload(response.data);
    return GoogleLoginAuthenticated(user: user, token: token);
  }

  /// `App\Http\Controllers\AuthController::googleRegister` — re-sends the
  /// same `id_token` from the preceding [googleLogin] call alongside the
  /// business name the user just entered; the backend re-verifies the
  /// token itself rather than trusting anything from that earlier call.
  Future<(User, String)> googleRegister({
    required String idToken,
    required String businessName,
    String? phone,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.googleRegister,
      data: {
        'id_token': idToken,
        'business_name': businessName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
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
    final response = await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
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
    final response = await _dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data['message'] as String;
  }

  /// `POST /change-password` — `ChangePasswordRequest` requires
  /// `current_password` and a `confirmed` `password` (min 12 chars, the
  /// project-wide default policy). A wrong current password returns a 422
  /// with a specific message, surfaced by `ApiException` like any other
  /// validation failure.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      'change-password',
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
    return response.data['message'] as String;
  }

  /// `POST /account/close` (`CloseAccountRequest`) — self-service Close
  /// Account. `password` re-proves ownership, same shape as
  /// `changePassword`'s `current_password`. A wrong password returns a
  /// 422, surfaced by `ApiException` like any other validation failure.
  Future<void> closeAccount({required String password}) async {
    await _dio.post('account/close', data: {'password': password});
  }

  (User, String) _parseAuthPayload(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    return (user, token);
  }
}
