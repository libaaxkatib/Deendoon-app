import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeStorageProvider = Provider<ThemeStorage>((ref) => const ThemeStorage());

/// Persists the user's chosen Appearance (Light/Dark/System Default)
/// across restarts — a device-local UI preference, not a backend/tenant
/// field, same rationale as `LocaleStorage`.
class ThemeStorage {
  static const _themeModeKey = 'settings_theme_mode';

  const ThemeStorage();

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// Returns null if nothing has been saved yet — the default (Dark,
  /// matching this app's existing, unchanged behavior) is decided by the
  /// caller, not this class.
  Future<ThemeMode?> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey);
    for (final mode in ThemeMode.values) {
      if (mode.name == saved) return mode;
    }
    return null;
  }
}
