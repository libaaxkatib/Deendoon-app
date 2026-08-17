import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/env.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleAuthService(),
);

/// Thrown when [Env.googleServerClientId] is empty — sign-in is refused
/// before ever calling the native SDK, rather than failing with a
/// confusing platform-specific error for a configuration gap.
class GoogleSignInNotConfiguredException implements Exception {}

/// Mobile Fix #22 — Google Login. Thin wrapper around `google_sign_in`'s
/// v7 singleton API (`GoogleSignIn.instance`), mirroring
/// `BiometricAuthService`'s constructor-injectable shape so it can be
/// overridden in widget tests the same way — the native SDK has no
/// platform-channel presence in the test sandbox.
///
/// Returns only a verified-by-Google ID token, never a plaintext
/// email/name the app would otherwise be tempted to trust directly —
/// identity is established once the backend independently verifies that
/// token (`google-login`/`google-register`), never from anything read
/// off the [GoogleSignInAccount] locally.
class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final String _serverClientId;
  bool _initialized = false;

  /// [serverClientId] defaults to [Env.googleServerClientId] — overridable
  /// (like [googleSignIn]) so a test can exercise the interactive sign-in
  /// path without depending on a real `--dart-define`, which is always
  /// empty under a plain `flutter test` run.
  GoogleAuthService([GoogleSignIn? googleSignIn, String? serverClientId])
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
      _serverClientId = serverClientId ?? Env.googleServerClientId;

  bool get isConfigured => _serverClientId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Starts an interactive Google sign-in and returns the resulting ID
  /// token, or `null` if the user cancelled the picker. Any other failure
  /// (network, misconfiguration on Google's side) rethrows
  /// [GoogleSignInException].
  Future<String?> signIn() async {
    if (!isConfigured) {
      throw GoogleSignInNotConfiguredException();
    }

    await _ensureInitialized();

    try {
      final account = await _googleSignIn.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
