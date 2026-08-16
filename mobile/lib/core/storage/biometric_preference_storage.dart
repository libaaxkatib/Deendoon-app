import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final biometricPreferenceStorageProvider = Provider<BiometricPreferenceStorage>(
  (ref) => const BiometricPreferenceStorage(),
);

/// Persists the user's local choice to require biometric login. Device-only
/// — there is no backend field for this (Settings §Security).
class BiometricPreferenceStorage {
  static const _enabledKey = 'settings_biometric_login_enabled';

  const BiometricPreferenceStorage();

  Future<void> saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<bool> readEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }
}
