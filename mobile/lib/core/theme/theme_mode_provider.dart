import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/theme_storage.dart';

/// Settings §General — Appearance (Light/Dark/System Default). `initial`
/// is set once at startup in `main.dart` from the persisted value (if
/// any) via a provider override, matching `LocaleNotifier`'s pattern.
/// Defaults to `ThemeMode.dark` — this app's existing, unchanged
/// behavior — so anyone who never opens the Appearance setting sees
/// exactly the same look as before this option existed.
class AppThemeModeNotifier extends Notifier<ThemeMode> {
  final ThemeMode initial;

  AppThemeModeNotifier({this.initial = ThemeMode.dark});

  @override
  ThemeMode build() => initial;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(themeStorageProvider).saveThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);
