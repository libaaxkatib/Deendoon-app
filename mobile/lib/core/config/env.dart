/// Compile-time configuration, since no env-file convention exists for the
/// Flutter side of this project. Pass at build/run time, e.g.:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
}
