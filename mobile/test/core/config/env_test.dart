import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/env.dart';

void main() {
  test('apiBaseUrl resolves to a non-empty http(s) URL', () {
    expect(Env.apiBaseUrl, isNotEmpty);
    expect(
      Env.apiBaseUrl.startsWith('http://') ||
          Env.apiBaseUrl.startsWith('https://'),
      isTrue,
    );
  });

  // `flutter test` always runs in a non-release compilation mode, so this
  // exercises the debug/profile branch — the release-mode branch
  // (kReleaseMode == true) can't be toggled at test time, since it's a
  // compile-time constant fixed per build; this guards against the
  // emulator default being accidentally removed or malformed, not against
  // the kReleaseMode branch logic itself.
  test(
    'defaults to the emulator address outside release mode when no dart-define is passed',
    () {
      expect(Env.apiBaseUrl, 'http://10.0.2.2:8000/api/v1');
    },
  );
}
