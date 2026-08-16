import 'user.dart';

/// Single source of truth for session state, read by both the Dio auth
/// interceptor (to decide whether a 401 should force a logout) and
/// go_router's redirect (to decide which screen is reachable).
sealed class AuthState {
  const AuthState();
}

/// App just started; secure storage hasn't been checked yet.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Splash screen is validating a stored token via `POST /refresh`.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Login form submitted, awaiting the API response.
class Authenticating extends AuthState {
  const Authenticating();
}

class Authenticated extends AuthState {
  final User user;
  final String token;

  const Authenticated({required this.user, required this.token});
}

class AuthError extends AuthState {
  final String message;

  /// Raw per-field backend validation messages (Laravel's `errors` map),
  /// carried alongside the combined [message] so Login/Register can map
  /// them onto individual fields (Mobile Fix #10) while every other
  /// consumer of this state keeps using [message] unchanged.
  final Map<String, dynamic>? fieldErrors;

  const AuthError(this.message, {this.fieldErrors});
}
