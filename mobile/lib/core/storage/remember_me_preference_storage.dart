import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final rememberMePreferenceStorageProvider =
    Provider<RememberMePreferenceStorage>(
      (ref) => const RememberMePreferenceStorage(),
    );

/// Persists the Login screen's "Remember Me" checkbox choice — device-only,
/// and holds no secret itself. This is NOT credential storage: it only
/// remembers whether the checkbox was last left on, so the Login screen can
/// restore that choice on its next appearance. The actual "remember this
/// login" behavior is delegated entirely to the platform's own credential
/// manager (Android Autofill / Google Password Manager, iOS Keychain) via
/// `TextInput.finishAutofillContext(shouldSave: ...)` in `LoginForm` — the
/// app never reads back, stores, or has custody of the saved password.
class RememberMePreferenceStorage {
  static const _enabledKey = 'login_remember_me_enabled';

  const RememberMePreferenceStorage();

  Future<void> saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<bool> readEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }
}
