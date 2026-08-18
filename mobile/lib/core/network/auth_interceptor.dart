import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Dio `RequestOptions.extra` key marking the one `POST /refresh` call
/// `AuthRepository.validateAndRotate()` makes from `AuthNotifier.
/// restoreSession()`. A 401 on THIS specific request is exempt from
/// [AuthInterceptor]'s forced logout below — see the class doc for why.
const restoreSessionRefreshExtraKey = 'restoreSessionRefresh';

/// Attaches the bearer token to every request and forces a logout on a
/// mid-session 401. Never retries the failed request — Sanctum has no
/// separate refresh credential to retry with; `POST /refresh` itself
/// requires an already-valid token, so retrying after its own 401 would
/// just 401 again.
///
/// One deliberate exception: the `/refresh` call `restoreSession()` makes
/// to opportunistically rotate a cached token on app restart (marked via
/// [restoreSessionRefreshExtraKey]) does NOT trigger the forced logout
/// below on a 401. That call is a background optimization racing against
/// the biometric-lock flow, not the authoritative check of session
/// validity — forcing a full logout (and, since Mobile Fix #17, disabling
/// the user's Biometric Login preference) purely because this one
/// opportunistic request failed was wiping a still-usable session and its
/// biometric preference the user never actually invalidated, destructively
/// racing a concurrent, still-valid local biometric unlock. A genuinely
/// dead cached token is still caught correctly: the moment any *other*
/// authenticated request 401s during normal use, this exemption does not
/// apply and a real logout is forced exactly as before — this only defers
/// detection by one request, it never skips it.
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
    final isRestoreSessionRefresh =
        err.requestOptions.extra[restoreSessionRefreshExtraKey] == true;

    // Only a 401 on a request that carried a token while a session was
    // believed active triggers a forced logout — this stops a plain
    // bad-password `POST /login` 401 (public endpoint, no token, no
    // session) from ever touching global auth state. The restore-session
    // refresh is a second, separate exemption — see class doc.
    if (err.response?.statusCode == 401 &&
        hadToken &&
        state is Authenticated &&
        !isRestoreSessionRefresh) {
      _ref.read(authProvider.notifier).forceLogout();
    }

    handler.next(err);
  }
}
