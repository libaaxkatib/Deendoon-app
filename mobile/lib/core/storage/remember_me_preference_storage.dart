import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final rememberMePreferenceStorageProvider =
    Provider<RememberMePreferenceStorage>(
      (ref) => const RememberMePreferenceStorage(),
    );

/// Persists the Login screen's "Remember Me" checkbox choice — device-only,
/// and holds no secret itself. This is NOT credential storage: it only
/// remembers whether the checkbox was last left on, so the Login screen can
/// restore that choice on its next appearance. The actual email/password are
/// stored separately, in [RememberedCredentialsStorage] — this class only
/// answers "was the box checked last time," it never reads or writes a
/// credential itself. `LoginForm` additionally uses this same choice to
/// decide whether to commit or cancel the platform's own Autofill/Password
/// Manager save prompt via `AutofillGroup.onDisposeAction` — that native
/// prompt is a separate mechanism from the app's own credential storage,
/// not a replacement for it.
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
