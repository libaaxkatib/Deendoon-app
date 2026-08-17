import 'package:flutter/foundation.dart' show kReleaseMode;

/// Compile-time configuration, since no env-file convention exists for the
/// Flutter side of this project. Pass at build/run time, e.g.:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`
///
/// The default (when `--dart-define` is not passed) depends on
/// `kReleaseMode` rather than always pointing at the emulator: a release
/// build produced without remembering the flag must still reach the real
/// backend, not silently fail on every real device — see mobile/RELEASE.md
/// for the incident this addresses. Debug/profile builds keep defaulting
/// to the emulator loopback address for local development.
class Env {
  static const _productionApiBaseUrl =
      'https://deendoon-app.onrender.com/api/v1';
  static const _emulatorApiBaseUrl = 'http://10.0.2.2:8000/api/v1';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode ? _productionApiBaseUrl : _emulatorApiBaseUrl,
  );

  /// Mobile Fix #22 — Google Login. The Google Cloud OAuth 2.0 "server"
  /// Client ID (Web application type) — required so a Google ID token's
  /// `aud` claim matches what the backend checks against
  /// `GOOGLE_CLIENT_ID` (`deendoon/config/services.php`). Deliberately
  /// empty by default rather than a fake placeholder — no real value
  /// exists until a Google Cloud Console project is provisioned for this
  /// app; `GoogleAuthService` refuses to attempt sign-in while this is
  /// empty rather than calling the native SDK with a value that would
  /// only fail confusingly.
  /// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=...`
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
}
