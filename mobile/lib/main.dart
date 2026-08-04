import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/localization/locale_provider.dart';
import 'core/storage/locale_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedLanguageCode = await const LocaleStorage().readLanguageCode();

  runApp(
    ProviderScope(
      overrides: [
        if (savedLanguageCode != null)
          localeProvider.overrideWith(() => LocaleNotifier(initial: Locale(savedLanguageCode))),
      ],
      child: const DeendoonApp(),
    ),
  );
}
