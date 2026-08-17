import 'user.dart';

/// Mobile Fix #22 — Google Login. The two real outcomes of a verified
/// `POST /google-login` response (`success: true`, HTTP 200) — every
/// other outcome (invalid token, an email already tied to a password
/// account) is a genuine HTTP error and surfaces as the existing
/// `ApiException` instead, the same as every other endpoint in this app.
sealed class GoogleLoginResult {
  const GoogleLoginResult();
}

/// `google_id` already matched an existing account — the caller should
/// treat this exactly like a successful password login.
class GoogleLoginAuthenticated extends GoogleLoginResult {
  final User user;
  final String token;

  const GoogleLoginAuthenticated({required this.user, required this.token});
}

/// No account exists for this verified Google identity yet. `email`/`name`
/// come from the backend's own token verification, never from anything
/// read locally off the Google account — the caller collects a business
/// name and completes registration via `AuthApi.googleRegister()`, which
/// re-verifies the same ID token rather than trusting this response.
class GoogleLoginRegistrationRequired extends GoogleLoginResult {
  final String email;
  final String? name;

  const GoogleLoginRegistrationRequired({required this.email, this.name});
}
