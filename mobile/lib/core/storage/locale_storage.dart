import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeStorageProvider = Provider<LocaleStorage>(
  (ref) => const LocaleStorage(),
);

/// Persists the user's chosen app language across restarts (Sprint 2 —
/// Settings §General). No backend sync: language is a device-local
/// preference per the approved scope, not a tenant/user API field.
class LocaleStorage {
  static const _languageCodeKey = 'settings_language_code';

  const LocaleStorage();

  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
  }

  Future<String?> readLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageCodeKey);
  }
}
