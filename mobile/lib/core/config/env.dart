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
}
