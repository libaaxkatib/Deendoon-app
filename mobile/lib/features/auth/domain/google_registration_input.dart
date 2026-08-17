/// Mobile Fix #22 — Google Login. Carries the still-valid ID token and the
/// backend-verified identity from `AuthNotifier.googleLogin()`'s
/// registration-required outcome through
/// `context.push(RoutePaths.googleRegister, extra: ...)`, so
/// `GoogleRegisterScreen` never re-derives `email`/`name` from anything
/// read locally off the Google account — only from what the backend
/// already verified.
class GoogleRegistrationInput {
  final String idToken;
  final String email;
  final String? name;

  const GoogleRegistrationInput({
    required this.idToken,
    required this.email,
    this.name,
  });
}
