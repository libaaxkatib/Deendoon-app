import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Attaches the bearer token to every request and forces a logout on a
/// mid-session 401. Never retries the failed request — Sanctum has no
/// separate refresh credential to retry with; `POST /refresh` itself
/// requires an already-valid token, so retrying after its own 401 would
/// just 401 again.
class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final state = _ref.read(authProvider);
    if (state is Authenticated) {
      options.headers['Authorization'] = 'Bearer ${state.token}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    final state = _ref.read(authProvider);

    // Only a 401 on a request that carried a token while a session was
    // believed active triggers a forced logout — this stops a plain
    // bad-password `POST /login` 401 (public endpoint, no token, no
    // session) from ever touching global auth state.
    if (err.response?.statusCode == 401 && hadToken && state is Authenticated) {
      _ref.read(authProvider.notifier).forceLogout();
    }

    handler.next(err);
  }
}
