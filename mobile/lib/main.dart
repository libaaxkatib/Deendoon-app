import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/localization/locale_provider.dart';
import 'core/storage/locale_storage.dart';
import 'core/storage/theme_storage.dart';
import 'core/theme/theme_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedLanguageCode = await const LocaleStorage().readLanguageCode();
  final savedThemeMode = await const ThemeStorage().readThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        if (savedLanguageCode != null)
          localeProvider.overrideWith(
            () => LocaleNotifier(initial: Locale(savedLanguageCode)),
          ),
        if (savedThemeMode != null)
          themeModeProvider.overrideWith(
            () => AppThemeModeNotifier(initial: savedThemeMode),
          ),
      ],
      child: const DeendoonApp(),
    ),
  );
}
